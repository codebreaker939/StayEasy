import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../domain/review.dart';

class ReviewPreview extends StatelessWidget {
  const ReviewPreview({super.key, required this.reviews, required this.title});
  final AsyncValue<List<Review>> reviews;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(StayEasySpacing.space16),
    decoration: BoxDecoration(
      color: StayEasyColors.surface,
      border: Border.all(color: StayEasyColors.border),
      borderRadius: StayEasyRadii.rounded16,
    ),
    child: reviews.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('Guest reviews are unavailable right now.'),
      data: (rows) {
        final eligible = rows
            .where((review) => review.verified && review.text.trim().isNotEmpty)
            .toList();
        if (eligible.isEmpty) {
          return const Text(
            'No verified review is available for this stay yet.',
          );
        }
        final review = eligible.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: StayEasyTypography.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: StayEasyColors.surfaceVariant,
                  child: Text(
                    _initials(review.guest),
                    style: const TextStyle(color: StayEasyColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.guest, style: StayEasyTypography.labelLarge),
                      Text(
                        '${review.stayedOn.day.toString().padLeft(2, '0')} ${_month(review.stayedOn.month)} ${review.stayedOn.year}',
                        style: StayEasyTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.star_rounded,
                  color: StayEasyColors.warning,
                  size: 18,
                ),
                Text(review.rating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 10),
            Text(review.text, style: StayEasyTypography.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Verified stay · ${review.helpful} found this helpful',
              style: StayEasyTypography.caption.copyWith(
                color: StayEasyColors.textSecondary,
              ),
            ),
          ],
        );
      },
    ),
  );
}

String _initials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => word[0].toUpperCase())
    .join();
String _month(int month) => const [
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
][month - 1];
