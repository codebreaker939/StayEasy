import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stayeasy/features/ai/application/ai_providers.dart';
import 'package:stayeasy/features/ai/data/ai_repositories.dart';
import 'package:stayeasy/features/ai/domain/ai_models.dart';
import 'package:stayeasy/features/booking/application/booking_provider.dart';
import 'package:stayeasy/features/booking/domain/review.dart';
import 'package:stayeasy/features/booking/data/review_repositories.dart';
import 'package:stayeasy/features/booking/presentation/pages/reviews_page.dart';
import 'package:stayeasy/features/discovery/application/discovery_providers.dart';
import 'package:stayeasy/features/discovery/data/mock_stay_data.dart';

void main() {
  test('search JSON mapping is defensive and retains canonical fields', () {
    final value = AiSearchInterpretation.fromJson({
      'status': 'parsed',
      'filters': {
        'city': 'Mumbai',
        'month': 10,
        'check_in': '2026-10-18',
        'check_out': '2026-10-22',
        'guests': 2,
        'max_price_inr': 5000,
        'min_rating': 4,
        'amenities': ['Wi-Fi'],
        'room_types': ['Queen'],
        'vibes': ['Quiet stay'],
      },
      'clarification': null,
    });
    expect(value.filters.city, 'Mumbai');
    expect(value.filters.month, 10);
    expect(value.filters.checkIn, DateTime(2026, 10, 18));
    expect(value.filters.maxPriceInr, 5000);
    expect(value.filters.amenities, ['Wi-Fi']);
    expect(
      () => AiSearchInterpretation.fromJson({'status': 'bad'}),
      throwsFormatException,
    );
  });

  test(
    'parsed AI filters populate normal search state and remain editable',
    () async {
      const interpretation = AiSearchInterpretation(
        status: AiSearchStatus.parsed,
        filters: AiSearchFilters(
          city: 'Mumbai',
          month: 10,
          guests: 2,
          maxPriceInr: 5000,
          amenities: ['Wi-Fi'],
          vibes: ['Quiet stay'],
        ),
        clarification: null,
      );
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(
            FakeAiRepository(search: interpretation),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(aiSearchControllerProvider.notifier)
          .interpret('quiet Mumbai in October');
      var search = container.read(searchStateProvider);
      expect(search.destination, 'Mumbai');
      expect(search.month, 10);
      expect(search.maxPriceInr, 5000);
      expect(search.amenities, ['Wi-Fi']);
      container
          .read(searchStateProvider.notifier)
          .removeInterpretedFilter('amenity', 'Wi-Fi');
      container
          .read(searchStateProvider.notifier)
          .removeInterpretedFilter('price');
      search = container.read(searchStateProvider);
      expect(search.amenities, isEmpty);
      expect(search.maxPriceInr, isNull);
      expect(search.destination, 'Mumbai');
    },
  );

  test('clarification is represented without losing the query', () async {
    const interpretation = AiSearchInterpretation(
      status: AiSearchStatus.needsClarification,
      filters: AiSearchFilters(month: 10),
      clarification: AiClarification(
        question: 'Which city?',
        options: ['Mumbai', 'Goa'],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(
          FakeAiRepository(search: interpretation),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(aiSearchControllerProvider.notifier)
        .interpret('Somewhere quiet in October');
    final state = container.read(aiSearchControllerProvider);
    expect(state.query, 'Somewhere quiet in October');
    expect(state.result.value?.status, AiSearchStatus.needsClarification);
    expect(state.result.value?.clarification?.options, ['Mumbai', 'Goa']);
  });

  test('AI repository failure leaves regular search usable', () async {
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(
          FakeAiRepository(failure: StateError('offline')),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(aiSearchControllerProvider.notifier)
        .interpret('quiet in Mumbai');
    expect(container.read(aiSearchControllerProvider).result.hasError, isTrue);
    expect(container.read(searchStateProvider).destination, 'Mumbai');
    final regularResults = filterHotelsForSearch(
      MockStayData.hotels,
      MockStayData.rooms,
      const SearchState(destination: 'Mumbai'),
    );
    expect(regularResults, isNotEmpty);
  });

  test(
    'real-result filter count comes from hotel and room repository data',
    () {
      final results = filterHotelsForSearch(
        MockStayData.hotels,
        MockStayData.rooms,
        const SearchState(
          destination: 'Mumbai',
          guests: 2,
          maxPriceInr: 5000,
          amenities: ['Free Wi-Fi'],
        ),
      );
      expect(results.map((hotel) => hotel.id), ['mercer-mumbai']);
    },
  );

  test('review AI response mapping supports insufficient evidence and sourced bullets', () {
    final insufficient = ReviewAiInsight.fromJson({
      'status': 'insufficient_evidence',
      'title': 'October stay insights',
      'bullets': [],
      'caution': null,
      'source_count': 2,
    });
    expect(insufficient.status, ReviewAiStatus.insufficientEvidence);
    expect(insufficient.sourceCount, 2);
    final ready = ReviewAiInsight.fromJson({
      'status': 'ready',
      'title': 'October stay insights',
      'source_count': 3,
      'bullets': [
        {
          'text': 'Guests liked the rooms.',
          'source_review_ids': ['internal-review-id'],
        },
      ],
      'caution': null,
    });
    expect(ready.bullets.single.text, 'Guests liked the rooms.');
    expect(
      () => ReviewAiInsight.fromJson({'status': 'ready', 'bullets': 'invalid'}),
      throwsFormatException,
    );
  });

  testWidgets(
    'insufficient-evidence and AI-error UI keeps deterministic reviews visible',
    (tester) async {
      final context = ReviewAiContext(
        hotelId: 'hotel',
        roomId: 'room',
        stayDate: DateTime(2026, 10, 18),
      );
      const insufficient = ReviewAiInsight(
        status: ReviewAiStatus.insufficientEvidence,
        title: 'October stay insights',
        bullets: [],
        caution: null,
        sourceCount: 2,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rankedReviewsProvider.overrideWith(
              (ref) => AsyncData([RankedReview(demoReviews.first, 100)]),
            ),
            reviewAiContextProvider.overrideWith((ref) async => context),
            reviewAiInsightProvider.overrideWith(
              (ref, key) async => insufficient,
            ),
          ],
          child: const MaterialApp(home: ReviewsPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(
          'Not enough relevant verified reviews for an AI summary yet.',
        ),
        420,
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Not enough relevant verified reviews for an AI summary yet.',
        ),
        findsOneWidget,
      );
      expect(find.text(demoReviews.first.text), findsOneWidget);
    },
  );

  testWidgets('AI summary error shows fallback and never hides reviews', (
    tester,
  ) async {
    final context = ReviewAiContext(
      hotelId: 'hotel',
      roomId: 'room',
      stayDate: DateTime(2026, 10, 18),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankedReviewsProvider.overrideWith(
            (ref) => AsyncData([RankedReview(demoReviews.first, 100)]),
          ),
          reviewAiContextProvider.overrideWith((ref) async => context),
          reviewAiInsightProvider.overrideWith(
            (ref, key) async => throw StateError('offline'),
          ),
        ],
        child: const MaterialApp(home: ReviewsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('AI summary unavailable'), 420);
    await tester.pumpAndSettle();
    expect(find.text('AI summary unavailable'), findsOneWidget);
    expect(
      find.text('Your reviews are still ranked by stay relevance.'),
      findsOneWidget,
    );
    expect(find.text(demoReviews.first.text), findsOneWidget);
  });

  test('AI insight remains independent from deterministic review ordering', () {
    final before = rankReviews(
      demoReviews,
      DateTime(2026, 10, 18),
      'mercer-deluxe',
    ).map((item) => item.review.id).toList();
    final parsedInsight = ReviewAiInsight.fromJson({
      'status': 'ready',
      'title': 'October insights',
      'source_count': 3,
      'bullets': [
        {
          'text': 'Quiet rooms are mentioned.',
          'source_review_ids': ['oct-2025'],
        },
        {
          'text': 'Guests enjoyed the service.',
          'source_review_ids': ['winter-2025'],
        },
      ],
      'caution': null,
    });
    expect(parsedInsight.status, ReviewAiStatus.ready);
    final after = rankReviews(
      demoReviews,
      DateTime(2026, 10, 18),
      'mercer-deluxe',
    ).map((item) => item.review.id).toList();
    expect(after, before);
  });

  test(
    'Dart review ordering matches the server evidence-selection parity fixture',
    () {
      final fixture = jsonDecode(
        File('supabase/functions/_shared/fixtures/review-ranking.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final reviews = (fixture['reviews'] as List).map((row) {
        final value = row as Map<String, dynamic>;
        return Review(
          id: value['id'] as String,
          guest: 'Guest',
          stayedOn: DateTime.parse(value['stay_date'] as String),
          rating: (value['rating'] as num).toDouble(),
          text: value['body'] as String,
          roomId: value['room_id'] as String? ?? '',
          roomName: 'Room',
          helpful: value['helpful_count'] as int,
          verified: value['is_verified'] as bool,
        );
      }).toList();
      final ranked = rankReviews(
        reviews,
        DateTime(2026, 10, 1),
        fixture['room_id'] as String,
      ).map((item) => item.review.id).toList();
      expect(ranked, fixture['ranked_ids']);
      final verifiedEvidence = ranked
          .where(
            (id) =>
                (fixture['reviews'] as List)
                    .cast<Map<String, dynamic>>()
                    .firstWhere((row) => row['id'] == id)['is_verified'] ==
                true,
          )
          .where((id) => (fixture['evidence_ids'] as List).contains(id))
          .toList();
      expect(verifiedEvidence, fixture['evidence_ids']);
    },
  );
}
