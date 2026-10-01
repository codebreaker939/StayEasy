import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../../discovery/application/discovery_providers.dart';
import '../../../discovery/presentation/widgets/discovery_widgets.dart';
import '../../../booking/application/booking_provider.dart';
import '../../../booking/presentation/widgets/review_preview.dart';

class HotelDetailsPage extends ConsumerStatefulWidget {
  const HotelDetailsPage({super.key, required this.hotelId});
  final String hotelId;

  @override
  ConsumerState<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends ConsumerState<HotelDetailsPage> {
  final GlobalKey _roomsSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final hotelState = ref.watch(hotelFutureProvider(widget.hotelId));
    if (hotelState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (hotelState.hasError) {
      return Scaffold(
        body: Center(
          child: Text('Could not load this stay. ${hotelState.error}'),
        ),
      );
    }
    final hotel = hotelState.value;
    if (hotel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Stay not found')),
      );
    }
    final saved = ref.watch(savedHotelIdsProvider).contains(hotel.id);
    final roomsState = ref.watch(roomsForHotelFutureProvider(hotel.id));
    if (roomsState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (roomsState.hasError) {
      return Scaffold(
        body: Center(child: Text('Could not load rooms. ${roomsState.error}')),
      );
    }
    final rooms = roomsState.value ?? const [];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 270,
            leading: IconButton.filledTonal(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
            ),
            actions: [
              IconButton.filledTonal(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing is coming soon.')),
                ),
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Share',
              ),
              IconButton.filledTonal(
                onPressed: () =>
                    ref.read(savedHotelIdsProvider.notifier).toggle(hotel.id),
                icon: Icon(
                  saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                tooltip: saved ? 'Remove saved hotel' : 'Save hotel',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  StayImage(path: hotel.detailImage ?? hotel.image),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: StayEasyColors.textPrimary.withValues(alpha: .7),
                        borderRadius: StayEasyRadii.rounded28,
                      ),
                      child: Text(
                        '1 / 8 photos',
                        style: StayEasyTypography.labelMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StayEasyContent(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  StayEasySpacing.space24,
                  StayEasySpacing.space24,
                  StayEasySpacing.space24,
                  110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name, style: StayEasyTypography.headingH2),
                    const SizedBox(height: 6),
                    Text(
                      hotel.location,
                      style: StayEasyTypography.bodyMedium.copyWith(
                        color: StayEasyColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RatingDisplay(
                          rating: hotel.rating,
                          reviewCount: hotel.reviewCount,
                        ),
                        const AmenityChip('Boutique hotel'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _stayFacts(),
                    const SizedBox(height: 24),
                    const SectionTitle('A little about this stay'),
                    const SizedBox(height: 8),
                    Text(
                      hotel.description,
                      style: StayEasyTypography.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final amenity in hotel.amenities)
                          AmenityChip(amenity),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const SectionTitle('Location'),
                    const SizedBox(height: 10),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: StayEasyColors.surfaceVariant,
                        borderRadius: StayEasyRadii.rounded16,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 32,
                              color: StayEasyColors.primary,
                            ),
                            SizedBox(height: 6),
                            Text('Colaba, Mumbai'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SectionTitle(
                      'What guests say in October',
                      action: '4.8 / 5',
                    ),
                    const SizedBox(height: 12),
                    ReviewPreview(
                      reviews: ref.watch(hotelReviewsProvider(hotel.id)),
                      title: 'Recent verified guest review',
                    ),
                    const SizedBox(height: 28),
                    SectionTitle(
                      'Available rooms',
                      key: _roomsSectionKey,
                      action: '${rooms.length} options',
                    ),
                    const SizedBox(height: 12),
                    for (final room in rooms) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RoomCard(
                          room: room,
                          onTap: () =>
                              context.push(AppRoutes.roomPath(room.id)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
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
                      'From ₹${hotel.pricePerNight}',
                      style: StayEasyTypography.titleMedium,
                    ),
                    Text(
                      'per night · taxes may apply',
                      style: StayEasyTypography.bodySmall.copyWith(
                        color: StayEasyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () {
                  final sectionContext = _roomsSectionKey.currentContext;
                  if (sectionContext != null) {
                    Scrollable.ensureVisible(
                      sectionContext,
                      alignment: .08,
                      duration: const Duration(milliseconds: 300),
                    );
                  }
                },
                child: const Text('View rooms'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stayFacts() => Container(
    padding: const EdgeInsets.all(StayEasySpacing.space16),
    decoration: BoxDecoration(
      color: StayEasyColors.surface,
      border: Border.all(color: StayEasyColors.border),
      borderRadius: StayEasyRadii.rounded16,
    ),
    child: const Wrap(
      runSpacing: 16,
      children: [
        _Fact(icon: Icons.login_rounded, title: 'Check-in', value: '2:00 PM'),
        _Fact(
          icon: Icons.logout_rounded,
          title: 'Check-out',
          value: '11:00 AM',
        ),
        _Fact(
          icon: Icons.event_available_outlined,
          title: 'Cancellation',
          value: 'Free until 16 Oct',
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: StayEasyColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: StayEasyTypography.caption.copyWith(
                  color: StayEasyColors.textSecondary,
                ),
              ),
              Text(value, style: StayEasyTypography.labelMedium),
            ],
          ),
        ),
      ],
    ),
  );
}
