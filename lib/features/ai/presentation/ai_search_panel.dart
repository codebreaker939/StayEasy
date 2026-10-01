import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/stayeasy_colors.dart';
import '../../../core/theme/stayeasy_radii.dart';
import '../../../core/theme/stayeasy_spacing.dart';
import '../../../core/theme/stayeasy_typography.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../search/presentation/search_filter_sheet.dart';
import '../application/ai_providers.dart';
import '../domain/ai_models.dart';

class AiSearchPanel extends ConsumerStatefulWidget {
  const AiSearchPanel({super.key});
  @override
  ConsumerState<AiSearchPanel> createState() => _AiSearchPanelState();
}

class _AiSearchPanelState extends ConsumerState<AiSearchPanel> {
  final _prompt = TextEditingController();

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiSearchControllerProvider);
    if (_prompt.text.isEmpty && ai.query.isNotEmpty) {
      _prompt.text = ai.query;
    }
    final search = ref.watch(searchStateProvider);
    final state = ai.result;
    return Container(
      padding: const EdgeInsets.all(StayEasySpacing.space16),
      decoration: BoxDecoration(
        color: StayEasyColors.surface,
        border: Border.all(
          color: StayEasyColors.aiAccent.withValues(alpha: .22),
        ),
        borderRadius: StayEasyRadii.rounded20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: StayEasyColors.aiAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'Ask StayEasy AI',
                style: StayEasyTypography.titleMedium.copyWith(
                  color: StayEasyColors.aiAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Describe the stay you want.',
            style: StayEasyTypography.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Use natural language. StayEasy turns your request into editable search filters.',
            style: StayEasyTypography.bodySmall.copyWith(
              color: StayEasyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _prompt,
            minLines: 2,
            maxLines: 3,
            maxLength: 500,
            enabled: !state.isLoading,
            decoration: const InputDecoration(
              hintText:
                  'e.g. Quiet room in Mumbai for two in October, under ₹5,000…',
              alignLabelWithHint: true,
            ),
            onSubmitted: state.isLoading ? null : (_) => _submit(),
          ),
          if (state.isLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(color: StayEasyColors.aiAccent),
            const SizedBox(height: 8),
            Text(
              'Understanding your request',
              style: StayEasyTypography.labelLarge,
            ),
            Text(
              'Finding destination, timing, budget, guests and preferences.',
              style: StayEasyTypography.bodySmall.copyWith(
                color: StayEasyColors.textSecondary,
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Interpret request'),
                style: FilledButton.styleFrom(
                  backgroundColor: StayEasyColors.aiAccent,
                ),
              ),
            ),
          if (state.hasError) _errorState(),
          if (state.hasValue && state.value != null) ...[
            const Divider(height: 24),
            if (state.value!.status == AiSearchStatus.needsClarification)
              _clarification(state.value!.clarification)
            else ...[
              Text(
                'StayEasy understood',
                style: StayEasyTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              _editableChips(search),
              const SizedBox(height: 8),
              ref
                  .watch(searchResultsFutureProvider)
                  .when(
                    loading: () => const LinearProgressIndicator(
                      color: StayEasyColors.aiAccent,
                    ),
                    error: (_, _) =>
                        const Text('Matching stays are unavailable right now.'),
                    data: (hotels) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.search),
                          icon: const Icon(Icons.search_rounded),
                          label: Text('Search ${hotels.length} matching stays'),
                        ),
                        TextButton(
                          onPressed: () => showSearchFilterSheet(context, ref),
                          child: const Text('Open filters'),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _submit({String? clarification}) async {
    final query = _prompt.text.trim();
    if (query.isEmpty || query.length > 500) return;
    await ref
        .read(aiSearchControllerProvider.notifier)
        .interpret(query, clarification: clarification);
  }

  Widget _errorState() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI search is unavailable right now.',
          style: StayEasyTypography.labelLarge.copyWith(
            color: StayEasyColors.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your regular search still works. Try again, or continue with normal filters without losing your request.',
          style: StayEasyTypography.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: _submit, child: const Text('Try again')),
            TextButton(
              onPressed: () => context.go(AppRoutes.search),
              child: const Text('Use filters'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _clarification(AiClarification? detail) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'ONE DETAIL TO CONFIRM',
        style: StayEasyTypography.labelMedium.copyWith(
          color: StayEasyColors.aiAccent,
          letterSpacing: .6,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        detail?.question ?? 'Which city should I search?',
        style: StayEasyTypography.titleMedium,
      ),
      if (detail?.options.isNotEmpty == true) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final option in detail!.options)
              ActionChip(
                label: Text(option),
                onPressed: () => _submit(clarification: option),
              ),
          ],
        ),
      ],
    ],
  );

  Widget _editableChips(SearchState search) {
    final chips = <(String, String, String)>[];
    if (search.destination.isNotEmpty) {
      chips.add(('city', search.destination, search.destination));
    }
    if (search.guests > 0) chips.add(('guests', '${search.guests} guests', ''));
    if (search.checkIn != null && search.checkOut != null) {
      chips.add((
        'month',
        '${search.checkIn!.day}–${search.checkOut!.day} ${_month(search.checkIn!.month)}',
        '',
      ));
    } else if (search.month != null) {
      chips.add(('month', _month(search.month!), ''));
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
    if (chips.isEmpty) {
      return const Text(
        'No filters selected yet. You can add them in search filters.',
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        for (final (kind, label, value) in chips)
          InputChip(
            label: Text(label),
            onDeleted: () => ref
                .read(searchStateProvider.notifier)
                .removeInterpretedFilter(kind, value),
            deleteIconColor: StayEasyColors.aiAccent,
            backgroundColor: StayEasyColors.aiAccent.withValues(alpha: .08),
          ),
      ],
    );
  }
}

String _month(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
