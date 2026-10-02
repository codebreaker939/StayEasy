import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stayeasy/app/router/app_router.dart';
import 'package:stayeasy/app/router/app_routes.dart';
import 'package:stayeasy/app/stayeasy_app.dart';
import 'package:stayeasy/core/backend/supabase_providers.dart';
import 'package:stayeasy/features/auth/domain/auth_repository.dart';
import 'package:stayeasy/features/booking/application/booking_provider.dart';
import 'package:stayeasy/features/booking/domain/booking_repository.dart';
import 'package:stayeasy/features/booking/domain/review.dart';

Widget appAt(String location) => ProviderScope(
  child: StayEasyApp(router: createAppRouter(initialLocation: location)),
);

void main() {
  test('dates validate, unavailable nights reject, and costs share one calculation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(bookingProvider.notifier);
    notifier.chooseRoom('mercer-deluxe');
    expect(
      notifier.chooseDates(DateTime(2026, 10, 18), DateTime(2026, 10, 22)),
      isTrue,
    );
    final state = container.read(bookingProvider);
    expect(state.nights, 4);
    expect(state.subtotal, 4299 * 4);
    expect(state.taxes, (4299 * 4 / 6).round());
    expect(state.total, state.subtotal + state.taxes - 500);
    expect(
      notifier.chooseDates(DateTime(2026, 10, 22), DateTime(2026, 10, 20)),
      isFalse,
    );
    expect(
      notifier.chooseDates(DateTime(2026, 10, 26), DateTime(2026, 10, 28)),
      isFalse,
    );
  });

  test(
    'October and exact-room review relevance lead deterministic ranking',
    () {
      final reviews = [
        Review(
          id: 'nonseason-room',
          guest: 'A',
          stayedOn: DateTime(2026, 7, 1),
          rating: 5,
          text: 'Room review',
          roomId: 'target',
          roomName: 'Room',
          helpful: 40,
          verified: true,
        ),
        Review(
          id: 'oct-other',
          guest: 'B',
          stayedOn: DateTime(2025, 10, 5),
          rating: 4,
          text: 'October review',
          roomId: 'other',
          roomName: 'Other',
          helpful: 10,
          verified: true,
        ),
        Review(
          id: 'far-other',
          guest: 'C',
          stayedOn: DateTime(2024, 3, 1),
          rating: 5,
          text: 'Old review',
          roomId: 'other',
          roomName: 'Other',
          helpful: 100,
          verified: false,
        ),
      ];
      final ranked = rankReviews(reviews, DateTime(2026, 10, 18), 'target');
      expect(ranked.first.review.id, 'oct-other');
      expect(ranked[1].review.id, 'nonseason-room');
      final withoutExactRoom = rankReviews(
        reviews,
        DateTime(2026, 10, 18),
        'elsewhere',
      );
      expect(
        ranked.singleWhere((r) => r.review.id == 'nonseason-room').score,
        greaterThan(
          withoutExactRoom
              .singleWhere((r) => r.review.id == 'nonseason-room')
              .score,
        ),
      );
      expect(
        rankReviews(
          reviews,
          DateTime(2026, 10, 18),
          'target',
        ).map((r) => r.review.id),
        ranked.map((r) => r.review.id),
      );
    },
  );

  testWidgets('date to reviews to booking summary to success to My Trips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(appAt(AppRoutes.datesPath('mercer-deluxe')));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Continue ·'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Continue ·'));
    await tester.pumpAndSettle();
    expect(find.text('Relevant to your October stay'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Continue to booking'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to booking'));
    await tester.pumpAndSettle();
    expect(find.text('Guest details'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Aniket Rai');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'aniket@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '+91 9876543210');
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('StayEasy discount'), findsOneWidget);
    expect(find.text('Estimated total'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review booking'));
    await tester.pumpAndSettle();
    expect(find.text('Price details'), findsOneWidget);
    expect(find.text('₹19562'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Confirm booking'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.textContaining('Confirm booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Confirm booking'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm this booking?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Your stay is confirmed'), findsOneWidget);
    await tester.tap(find.text('View my trip'));
    await tester.pumpAndSettle();
    expect(find.text('My trips'), findsWidgets);
    expect(find.textContaining('Booking SE-'), findsOneWidget);
    expect(find.text('UPCOMING · 18 OCT'), findsOneWidget);
  });

  testWidgets('My Trips disables cancellation while the request is pending', (
    tester,
  ) async {
    final cancellation = Completer<void>();
    final repository = _PendingCancelRepository(cancellation);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendEnabledProvider.overrideWithValue(true),
          authProfileProvider.overrideWith(
            (ref) => Stream.value(
              const StayEasyProfile(
                id: 'guest-1',
                email: 'guest@example.test',
                role: 'user',
              ),
            ),
          ),
          myBookingsProvider.overrideWith(
            (ref) async => [
              StayBooking(
                id: 'booking-1',
                code: 'SE-TEST-0001',
                hotelId: 'hotel-1',
                hotelName: 'Harbour House',
                roomId: 'room-1',
                roomName: 'Deluxe King',
                checkIn: DateTime(2026, 10, 18),
                checkOut: DateTime(2026, 10, 22),
                guests: 2,
                total: 19562,
                status: 'confirmed',
                guestName: 'Maya Guest',
                guestEmail: 'maya@example.test',
              ),
            ],
          ),
          bookingRepositoryProvider.overrideWithValue(repository),
        ],
        child: StayEasyApp(
          router: createAppRouter(initialLocation: AppRoutes.trips),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel booking'));
    await tester.pump();

    expect(repository.cancelCalls, 1);
    expect(find.text('Cancelling…'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Cancelling…'),
          )
          .onPressed,
      isNull,
    );

    cancellation.complete();
    await tester.pumpAndSettle();
  });
}

class _PendingCancelRepository implements BookingRepository {
  _PendingCancelRepository(this.cancellation);
  final Completer<void> cancellation;
  int cancelCalls = 0;

  @override
  Future<void> cancel(String bookingId) {
    cancelCalls++;
    return cancellation.future;
  }

  @override
  Future<(String id, String code, BookingPrice price)> create({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String guestEmail,
    String? phone,
  }) => throw UnimplementedError();

  @override
  Future<List<StayBooking>> getMyBookings() => Future.value(const []);
}
