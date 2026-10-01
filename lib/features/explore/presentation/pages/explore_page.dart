import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/stayeasy_breakpoints.dart';
import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_elevation.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../../booking/application/booking_provider.dart';
import '../../../discovery/application/discovery_providers.dart';
import '../../../discovery/presentation/widgets/discovery_widgets.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchStateProvider);
    final hotelsState = ref.watch(hotelsFutureProvider);
    final profile = ref.watch(authProfileProvider).value;
    if (hotelsState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (hotelsState.hasError) {
      return Scaffold(
        body: Center(child: Text('Could not load stays. ${hotelsState.error}')),
      );
    }
    final hotels = hotelsState.value ?? const [];
    final width = MediaQuery.sizeOf(context).width;
    final expanded =
        StayEasyBreakpoints.classify(width) == StayEasyLayoutSize.expanded;
    final featured = hotels.take(2).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StayEasy',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (action) async {
              switch (action) {
                case 'sign-in':
                  context.push(AppRoutes.signIn);
                case 'trips':
                  context.push(AppRoutes.trips);
                case 'admin':
                  context.push(AppRoutes.admin);
                case 'sign-out':
                  await ref.read(authRepositoryProvider).signOut();
                  ref.invalidate(authProfileProvider);
                  if (context.mounted) context.go(AppRoutes.explore);
              }
            },
            itemBuilder: (context) => [
              if (profile == null)
                const PopupMenuItem(value: 'sign-in', child: Text('Sign in')),
              if (profile != null) ...[
                PopupMenuItem(
                  value: 'trips',
                  child: Text('My trips · ${profile.email}'),
                ),
                if (profile.isAdmin)
                  const PopupMenuItem(
                    value: 'admin',
                    child: Text('Admin workspace'),
                  ),
                const PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
              ],
            ],
          ),
        ],
      ),
      body: StayEasyContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            StayEasySpacing.space24,
            StayEasySpacing.space12,
            StayEasySpacing.space24,
            StayEasySpacing.space32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONDAY · 12 OCTOBER',
                style: StayEasyTypography.labelMedium.copyWith(
                  color: StayEasyColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text('Good morning, Maya', style: StayEasyTypography.titleLarge),
              const SizedBox(height: 24),
              Text(
                'Where are you\nstaying next?',
                style: StayEasyTypography.editorialHero.copyWith(
                  fontSize: expanded ? 48 : 36,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compare location, workspace, and comfort at a glance.',
                style: StayEasyTypography.bodyLarge.copyWith(
                  color: StayEasyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _searchCard(context, ref, search.destination, search.guests),
              const SizedBox(height: 20),
              const AIInsightCard(
                title: 'Ask StayEasy AI',
                body: 'Find me a quiet room with a balcony under ₹5,000.',
                caption: 'A little help finding your kind of stay.',
              ),
              const SizedBox(height: 28),
              const SectionTitle('Browse by trip'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tripChip(ref, 'Beach', 'Goa', Icons.waves_rounded),
                  _tripChip(
                    ref,
                    'Business',
                    'Mumbai',
                    Icons.work_outline_rounded,
                  ),
                  _tripChip(ref, 'Luxury', 'Udaipur', Icons.diamond_outlined),
                  _tripChip(
                    ref,
                    'Budget',
                    'Manali',
                    Icons.account_balance_wallet_outlined,
                  ),
                  _tripChip(ref, 'Nature', 'Manali', Icons.park_outlined),
                ],
              ),
              const SizedBox(height: 28),
              SectionTitle(
                'Recommended stays',
                action: 'See all',
                onAction: () => context.go(AppRoutes.search),
              ),
              const SizedBox(height: 12),
              if (expanded)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: featured.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 354,
                  ),
                  itemBuilder: (context, index) => HotelCard(
                    hotel: featured[index],
                    matchLabel: index == 0 ? '94% match' : null,
                  ),
                )
              else
                Column(
                  children: [
                    for (final hotel in featured)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HotelCard(
                          hotel: hotel,
                          matchLabel: hotel.id == 'mercer-mumbai'
                              ? '94% match'
                              : null,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              const SectionTitle('Popular stays'),
              const SizedBox(height: 12),
              for (final hotel in hotels.skip(2)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HotelCard(hotel: hotel, compact: true),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const StayEasyBottomNavigation(),
    );
  }

  Widget _searchCard(
    BuildContext context,
    WidgetRef ref,
    String destination,
    int guests,
  ) => Container(
    padding: const EdgeInsets.all(StayEasySpacing.space16),
    decoration: BoxDecoration(
      color: StayEasyColors.surface,
      borderRadius: StayEasyRadii.rounded20,
      border: Border.all(color: StayEasyColors.border),
      boxShadow: StayEasyElevation.level2,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Plan a stay', style: StayEasyTypography.titleMedium),
            ),
            Text(
              'Work + weekend',
              style: StayEasyTypography.bodySmall.copyWith(
                color: StayEasyColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('destination-field'),
          initialValue: destination,
          onChanged: ref.read(searchStateProvider.notifier).setDestination,
          decoration: const InputDecoration(
            labelText: 'Destination',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _selectionTile(
                icon: Icons.calendar_month_outlined,
                label: 'Check-in — out',
                value: '18 — 22 Oct',
              ),
            ),
            const SizedBox(width: StayEasySpacing.space8),
            SizedBox(width: 126, child: _guestTile(context, ref, guests)),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => context.go(AppRoutes.search),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search stays'),
          ),
        ),
      ],
    ),
  );

  Widget _selectionTile({
    required IconData icon,
    required String label,
    required String value,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 72),
    padding: const EdgeInsets.all(StayEasySpacing.space12),
    decoration: BoxDecoration(
      color: StayEasyColors.surface,
      border: Border.all(color: StayEasyColors.border),
      borderRadius: StayEasyRadii.rounded12,
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: StayEasyColors.primary),
        const SizedBox(width: StayEasySpacing.space8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _guestTile(BuildContext context, WidgetRef ref, int guests) => InkWell(
    borderRadius: StayEasyRadii.rounded12,
    onTap: () => showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(StayEasySpacing.space24),
          child: Consumer(
            builder: (context, ref, child) {
              final count = ref.watch(searchStateProvider).guests;
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Guests',
                      style: StayEasyTypography.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fewer guests',
                    onPressed: () => ref
                        .read(searchStateProvider.notifier)
                        .setGuests(count - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$count', style: StayEasyTypography.titleMedium),
                  IconButton(
                    tooltip: 'More guests',
                    onPressed: () => ref
                        .read(searchStateProvider.notifier)
                        .setGuests(count + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
    child: _selectionTile(
      icon: Icons.people_outline,
      label: 'Guests',
      value: '$guests guests',
    ),
  );

  Widget _tripChip(
    WidgetRef ref,
    String label,
    String destination,
    IconData icon,
  ) => ActionChip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    onPressed: () =>
        ref.read(searchStateProvider.notifier).setDestination(destination),
  );
}
