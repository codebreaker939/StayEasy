import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../../discovery/application/discovery_providers.dart';
import '../../../discovery/presentation/widgets/discovery_widgets.dart';
import '../search_filter_sheet.dart';

class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchStateProvider);
    final resultsState = ref.watch(searchResultsFutureProvider);
    if (resultsState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (resultsState.hasError) {
      return Scaffold(
        body: Center(
          child: Text('Could not load search results. ${resultsState.error}'),
        ),
      );
    }
    final results = resultsState.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.explore),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        title: const Text('STAYEASY SEARCH'),
        centerTitle: true,
      ),
      body: StayEasyContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            StayEasySpacing.space24,
            StayEasySpacing.space8,
            StayEasySpacing.space24,
            StayEasySpacing.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${search.destination.isEmpty ? 'All' : search.destination} stays',
                style: StayEasyTypography.headingH2,
              ),
              const SizedBox(height: 4),
              Text(
                '${results.length} stays',
                style: StayEasyTypography.bodyMedium.copyWith(
                  color: StayEasyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const SearchSummary(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSort(context, ref),
                      icon: const Icon(Icons.swap_vert_rounded),
                      label: Text(_sortLabel(search.sort)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => showSearchFilterSheet(context, ref),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Filter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _activeFilters(ref, search),
              const SizedBox(height: 24),
              const SectionTitle('Stays matching your filters'),
              const SizedBox(height: 12),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'No stays match “${search.destination}”. Try another destination.',
                      textAlign: TextAlign.center,
                      style: StayEasyTypography.bodyLarge,
                    ),
                  ),
                )
              else
                for (final hotel in results) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HotelCard(
                      hotel: hotel,
                      imagePath: hotel.detailImage,
                    ),
                  ),
                ],
              const SizedBox(height: 8),
              Text(
                'Prices shown are per night. Availability may change.',
                style: StayEasyTypography.bodySmall.copyWith(
                  color: StayEasyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const StayEasyBottomNavigation(),
    );
  }

  Widget _activeFilters(WidgetRef ref, SearchState search) {
    final notifier = ref.read(searchStateProvider.notifier);
    final chips = <(String, String, String)>[];
    if (search.month != null) {
      chips.add(('month', _month(search.month!), ''));
    }
    if (search.checkIn != null && search.checkOut != null) {
      chips.add((
        'month',
        '${search.checkIn!.day}–${search.checkOut!.day} ${_month(search.checkIn!.month)}',
        '',
      ));
    }
    if (search.guests != 2) {
      chips.add(('guests', '${search.guests} guests', ''));
    }
    if (search.maxPriceInr != null) {
      chips.add(('price', '≤ ₹${search.maxPriceInr!.round()}', ''));
    }
    if (search.minRating != null) {
      chips.add(('rating', '★ ${search.minRating!.toStringAsFixed(1)}+', ''));
    }
    for (final value in search.amenities) {
      chips.add(('amenity', value, value));
    }
    for (final value in search.roomTypes) {
      chips.add(('room', value, value));
    }
    for (final value in search.vibes) {
      chips.add(('vibe', value, value));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final (kind, label, value) in chips)
          InputChip(
            label: Text(label),
            onDeleted: () => notifier.removeInterpretedFilter(kind, value),
          ),
      ],
    );
  }

  String _sortLabel(HotelSort sort) => switch (sort) {
    HotelSort.recommended => 'Sort · Recommended',
    HotelSort.priceLowToHigh => 'Sort · Price: low to high',
    HotelSort.ratingHighToLow => 'Sort · Top rated',
  };

  Future<void> _showSort(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<HotelSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Sort stays', style: StayEasyTypography.titleMedium),
            ),
            for (final entry in const [
              (HotelSort.recommended, 'Recommended'),
              (HotelSort.priceLowToHigh, 'Price: low to high'),
              (HotelSort.ratingHighToLow, 'Rating: high to low'),
            ])
              ListTile(
                title: Text(entry.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, entry.$1),
              ),
            const SizedBox(height: StayEasySpacing.space8),
          ],
        ),
      ),
    );
    if (selected != null) {
      ref.read(searchStateProvider.notifier).setSort(selected);
    }
  }
}

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
