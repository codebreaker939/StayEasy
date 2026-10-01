import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

import '../../../booking/application/booking_provider.dart';
import '../../../booking/presentation/widgets/review_preview.dart';

import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../../discovery/application/discovery_providers.dart';
import '../../../discovery/presentation/widgets/discovery_widgets.dart';

class RoomDetailsPage extends ConsumerWidget {
  const RoomDetailsPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomFutureProvider(roomId));
    if (roomState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (roomState.hasError) {
      return Scaffold(
        body: Center(
          child: Text('Could not load this room. ${roomState.error}'),
        ),
      );
    }
    final room = roomState.value;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Room not found')),
      );
    }
    final hotel = ref.watch(hotelFutureProvider(room.hotelId)).value;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        title: const Text('ROOM DETAILS'),
        centerTitle: true,
      ),
      body: StayEasyContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            StayEasySpacing.space24,
            StayEasySpacing.space4,
            StayEasySpacing.space24,
            StayEasySpacing.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: StayEasyRadii.rounded20,
                child: Stack(
                  children: [
                    StayImage(
                      path: room.image,
                      height: 240,
                      width: double.infinity,
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: StayEasyColors.textPrimary.withValues(
                            alpha: .72,
                          ),
                          borderRadius: StayEasyRadii.rounded28,
                        ),
                        child: Text(
                          '1 / 6 photos',
                          style: StayEasyTypography.labelMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(room.name, style: StayEasyTypography.headingH2),
              const SizedBox(height: 4),
              Text(
                '${hotel?.name ?? 'StayEasy stay'} · ${room.capacity} guests · ${room.bedType} · ${room.size} m²',
                style: StayEasyTypography.bodyMedium.copyWith(
                  color: StayEasyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('360° preview coming in the next flow.'),
                  ),
                ),
                icon: const Icon(Icons.threesixty_rounded),
                label: const Text('View 360° preview'),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Room amenities'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amenity in room.amenities) AmenityChip(amenity),
                ],
              ),
              const SizedBox(height: 28),
              const SectionTitle('Stay details'),
              const SizedBox(height: 12),
              _detail(Icons.schedule_rounded, 'Check-in', 'From 2:00 PM'),
              _detail(Icons.schedule_rounded, 'Check-out', 'By 11:00 AM'),
              _detail(
                Icons.event_available_outlined,
                'Cancellation',
                'Free cancellation until 16 October',
              ),
              const SizedBox(height: 24),
              Text(room.description, style: StayEasyTypography.bodyLarge),
              const SizedBox(height: 28),
              const SectionTitle('Verified room review'),
              const SizedBox(height: 12),
              ReviewPreview(
                reviews: ref.watch(roomReviewsProvider(roomId)),
                title: 'Selected room feedback',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StayEasySpacing.space24,
            StayEasySpacing.space8,
            StayEasySpacing.space24,
            StayEasySpacing.space8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${room.pricePerNight} / night',
                      style: StayEasyTypography.titleMedium,
                    ),
                    Text(
                      room.available ? 'Available' : 'Limited availability',
                      style: StayEasyTypography.bodySmall.copyWith(
                        color: room.available
                            ? StayEasyColors.success
                            : StayEasyColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () => context.push(AppRoutes.datesPath(room.id)),
                child: const Text('Select dates'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, color: StayEasyColors.primary),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(title, style: StayEasyTypography.labelLarge),
        ),
        const SizedBox(width: StayEasySpacing.space8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: StayEasyTypography.bodySmall,
          ),
        ),
      ],
    ),
  );
}
