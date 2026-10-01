import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_elevation.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../application/discovery_providers.dart';
import '../../domain/models/hotel.dart';
import '../../domain/models/room.dart';

class StayEasyContent extends StatelessWidget {
  const StayEasyContent({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: child,
    ),
  );
}

class StayEasyBottomNavigation extends StatelessWidget {
  const StayEasyBottomNavigation({super.key, this.selectedIndex = 0});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    height: 76,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Explore',
      ),
      NavigationDestination(icon: Icon(Icons.luggage_outlined), label: 'Trips'),
      NavigationDestination(
        icon: Icon(Icons.favorite_border_rounded),
        label: 'Saved',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        label: 'Profile',
      ),
    ],
    onDestinationSelected: (index) {
      if (index == 1) {
        context.go(AppRoutes.trips);
      } else if (index == 3) {
        context.go(AppRoutes.signIn);
      } else if (index == 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved stays are coming soon.')),
        );
      }
    },
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: StayEasyTypography.headingH3)),
      if (action != null)
        onAction == null
            ? Text(
                action!,
                style: StayEasyTypography.labelLarge.copyWith(
                  color: StayEasyColors.primary,
                ),
              )
            : TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(action!),
              ),
    ],
  );
}

class RatingDisplay extends StatelessWidget {
  const RatingDisplay({
    super.key,
    required this.rating,
    required this.reviewCount,
  });
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star_rounded, size: 18, color: StayEasyColors.warning),
      const SizedBox(width: 3),
      Text(rating.toStringAsFixed(1), style: StayEasyTypography.labelLarge),
      const SizedBox(width: 4),
      Text(
        '($reviewCount)',
        style: StayEasyTypography.bodySmall.copyWith(
          color: StayEasyColors.textSecondary,
        ),
      ),
    ],
  );
}

class AmenityChip extends StatelessWidget {
  const AmenityChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: StayEasyColors.surfaceVariant,
      borderRadius: StayEasyRadii.rounded28,
    ),
    child: Text(
      label,
      style: StayEasyTypography.labelMedium.copyWith(
        color: StayEasyColors.textPrimary,
      ),
    ),
  );
}

class AIInsightCard extends StatelessWidget {
  const AIInsightCard({
    super.key,
    required this.title,
    required this.body,
    this.caption = 'AI insights are based on guest reviews.',
  });
  final String title;
  final String body;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(StayEasySpacing.space16),
    decoration: BoxDecoration(
      color: StayEasyColors.surface,
      border: Border.all(color: StayEasyColors.aiAccent.withValues(alpha: .2)),
      borderRadius: StayEasyRadii.rounded16,
      boxShadow: StayEasyElevation.level1,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, color: StayEasyColors.aiAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: StayEasyTypography.titleMedium.copyWith(
                  color: StayEasyColors.aiAccent,
                ),
              ),
              const SizedBox(height: 6),
              Text(body, style: StayEasyTypography.bodyMedium),
              const SizedBox(height: 6),
              Text(
                caption,
                style: StayEasyTypography.caption.copyWith(
                  color: StayEasyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class HotelCard extends ConsumerWidget {
  const HotelCard({
    super.key,
    required this.hotel,
    this.compact = false,
    this.matchLabel,
    this.imagePath,
  });
  final Hotel hotel;
  final bool compact;
  final String? matchLabel;
  final String? imagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedHotelIdsProvider).contains(hotel.id);
    return Semantics(
      button: true,
      label: '${hotel.name}, ${hotel.city}, ₹${hotel.pricePerNight} per night',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: StayEasyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: StayEasyRadii.rounded16,
          side: const BorderSide(color: StayEasyColors.border),
        ),
        child: InkWell(
          key: ValueKey('hotel-${hotel.id}'),
          onTap: () => context.push(AppRoutes.hotelPath(hotel.id)),
          child: compact
              ? Row(
                  children: [
                    _StayImage(
                      path: imagePath ?? hotel.image,
                      height: 152,
                      width: 132,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _hotelText(context, saved, ref),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        _StayImage(
                          path: imagePath ?? hotel.image,
                          height: 184,
                          width: double.infinity,
                        ),
                        if (matchLabel != null)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _badge(matchLabel!, StayEasyColors.primary),
                          ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton.filledTonal(
                            onPressed: () => ref
                                .read(savedHotelIdsProvider.notifier)
                                .toggle(hotel.id),
                            icon: Icon(
                              saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                            ),
                            tooltip: saved
                                ? 'Remove saved hotel'
                                : 'Save hotel',
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(StayEasySpacing.space16),
                      child: _hotelText(context, saved, ref),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _hotelText(BuildContext context, bool saved, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        hotel.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: StayEasyTypography.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(
        hotel.location,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: StayEasyTypography.bodySmall.copyWith(
          color: StayEasyColors.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          RatingDisplay(rating: hotel.rating, reviewCount: hotel.reviewCount),
          if (hotel.tags.isNotEmpty)
            _badge(hotel.tags.first, StayEasyColors.surfaceVariant),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '₹${hotel.pricePerNight}',
                  style: StayEasyTypography.titleMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  '/ night',
                  style: StayEasyTypography.bodySmall.copyWith(
                    color: StayEasyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (saved)
            const Icon(
              Icons.favorite_rounded,
              size: 18,
              color: StayEasyColors.accentWarm,
            ),
        ],
      ),
    ],
  );
}

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, required this.onTap});
  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: StayEasyRadii.rounded16,
      side: const BorderSide(color: StayEasyColors.border),
    ),
    child: InkWell(
      key: ValueKey('room-${room.id}'),
      onTap: onTap,
      child: Row(
        children: [
          _StayImage(path: room.image, height: 116, width: 116),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StayEasyTypography.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${room.capacity} guests · ${room.size} m²',
                    style: StayEasyTypography.bodySmall.copyWith(
                      color: StayEasyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '₹${room.pricePerNight}',
                        style: StayEasyTypography.titleMedium,
                      ),
                      const SizedBox(width: 4),
                      Text('/ night', style: StayEasyTypography.bodySmall),
                      const Spacer(),
                      Icon(
                        room.available
                            ? Icons.arrow_forward_rounded
                            : Icons.info_outline,
                        color: StayEasyColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SearchSummary extends ConsumerWidget {
  const SearchSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchStateProvider);
    return Container(
      padding: const EdgeInsets.all(StayEasySpacing.space16),
      decoration: BoxDecoration(
        color: StayEasyColors.surface,
        borderRadius: StayEasyRadii.rounded16,
        border: Border.all(color: StayEasyColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: StayEasyColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  search.destination.isEmpty ? 'Anywhere' : search.destination,
                  style: StayEasyTypography.labelLarge,
                ),
                Text(
                  '${search.dates} · ${search.guests} guests',
                  style: StayEasyTypography.bodySmall.copyWith(
                    color: StayEasyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.explore),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class StayImage extends StatelessWidget {
  const StayImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) =>
      _StayImage(path: path, height: height, width: width, fit: fit);
}

Widget _badge(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: color,
    borderRadius: StayEasyRadii.rounded28,
  ),
  child: Text(
    text,
    style: StayEasyTypography.caption.copyWith(
      color: color == StayEasyColors.primary
          ? StayEasyColors.onPrimary
          : StayEasyColors.textPrimary,
    ),
  ),
);

class _StayImage extends StatelessWidget {
  const _StayImage({
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => Container(
      width: width,
      height: height,
      color: StayEasyColors.surfaceVariant,
      alignment: Alignment.center,
      child: const Icon(
        Icons.hotel_outlined,
        color: StayEasyColors.textSecondary,
        size: 36,
      ),
    ),
  );
}
