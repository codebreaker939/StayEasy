import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../../discovery/application/discovery_providers.dart';
import '../../../discovery/presentation/widgets/discovery_widgets.dart';

class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchStateProvider);
    final results = ref.watch(searchResultsProvider);
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
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Filters are coming soon.')),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Filter ·2'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(context, ref, 'Business', 'Mumbai'),
                  _filterChip(context, ref, 'Wi-Fi', 'Mumbai'),
                  ActionChip(
                    avatar: const Icon(
                      Icons.auto_awesome_rounded,
                      color: StayEasyColors.aiAccent,
                      size: 16,
                    ),
                    label: const Text('AI match'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI matching is a visual preview.'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle(
                'Recommended for your stay',
                action: 'Best match',
              ),
              const SizedBox(height: 12),
              const AIInsightCard(
                title: '94% match',
                body: 'Quiet area · strong Wi-Fi · under ₹5,000',
                caption:
                    'Based on your destination, dates and guest preferences.',
              ),
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
                      matchLabel: hotel.id == 'mercer-mumbai'
                          ? '94% match'
                          : null,
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

  Widget _filterChip(
    BuildContext context,
    WidgetRef ref,
    String text,
    String destination,
  ) => ActionChip(
    label: Text(text),
    onPressed: () =>
        ref.read(searchStateProvider.notifier).setDestination(destination),
  );

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
