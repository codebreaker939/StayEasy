import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../application/booking_provider.dart';
import '../widgets/booking_widgets.dart';

class ReviewsPage extends ConsumerWidget {
  const ReviewsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider);
    final reviews = ref.watch(rankedReviewsProvider);
    final sameMonth = reviews.any(
      (r) => r.review.stayedOn.month == (booking.checkIn?.month ?? 10),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Guest reviews'), centerTitle: true),
      body: BookingContent(
        child: ListView(
          padding: const EdgeInsets.all(StayEasySpacing.space16),
          children: [
            BookingCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '4.8',
                      style: StayEasyTypography.editorialHero.copyWith(
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Excellent'),
                        Text('1,248 verified reviews'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relevant to your October stay',
                    style: StayEasyTypography.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sameMonth
                        ? 'October reviews are prioritized, then room relevance, helpfulness and recency.'
                        : 'No October reviews yet; showing nearby-season and recent verified stays instead.',
                    style: StayEasyTypography.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How ranking works',
                    style: StayEasyTypography.labelLarge.copyWith(
                      color: StayEasyColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final ranked in reviews) ...[
              BookingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: StayEasyColors.surfaceVariant,
                        borderRadius: StayEasyRadii.rounded12,
                      ),
                      child: Text(
                        ranked.review.roomId == booking.roomId
                            ? 'Relevant to your selected room'
                            : ranked.review.stayedOn.month ==
                                  (booking.checkIn?.month ?? 10)
                            ? 'Relevant to your October stay'
                            : 'Nearby-season review',
                        style: StayEasyTypography.labelMedium.copyWith(
                          color: StayEasyColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: StayEasyColors.primary,
                          child: Text(
                            ranked.review.guest
                                .split(' ')
                                .map((s) => s[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ranked.review.guest,
                                style: StayEasyTypography.labelLarge,
                              ),
                              Text(
                                '${ranked.review.stayedOn.day.toString().padLeft(2, '0')} ${_month(ranked.review.stayedOn.month)} ${ranked.review.stayedOn.year}',
                                style: StayEasyTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text('★ ${ranked.review.rating.toStringAsFixed(1)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (ranked.review.verified)
                          const Chip(label: Text('Verified stay')),
                        Chip(
                          label: Text(
                            'Stayed ${_month(ranked.review.stayedOn.month)} ${ranked.review.stayedOn.year}',
                          ),
                        ),
                        if (ranked.review.roomId == booking.roomId)
                          Chip(label: Text(ranked.review.roomName)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ranked.review.text,
                      style: StayEasyTypography.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '👍 Helpful · ${ranked.review.helpful}',
                      style: StayEasyTypography.labelMedium.copyWith(
                        color: StayEasyColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            BookingCard(
              color: StayEasyColors.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'StayEasy AI · Guest sentiment',
                    style: StayEasyTypography.titleMedium.copyWith(
                      color: StayEasyColors.aiAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Guests frequently praise the thoughtful service, comfortable beds and convenient neighbourhood. October visitors especially appreciate how easy it is to explore nearby Colaba.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI summary of review themes · Ranking is deterministic',
                    style: StayEasyTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: booking.datesValid
                  ? () => context.push('/booking/guest')
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Continue to booking'),
            ),
          ],
        ),
      ),
    );
  }
}

String _month(int n) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][n - 1];
