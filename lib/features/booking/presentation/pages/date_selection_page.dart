import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_radii.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../../discovery/application/discovery_providers.dart';
import '../../application/booking_provider.dart';
import '../../domain/booking_repository.dart';
import '../../../discovery/domain/models/room.dart';
import '../widgets/booking_widgets.dart';

class DateSelectionPage extends ConsumerStatefulWidget {
  const DateSelectionPage({super.key, required this.roomId});
  final String roomId;
  @override
  ConsumerState<DateSelectionPage> createState() => _DateSelectionPageState();
}

class _DateSelectionPageState extends ConsumerState<DateSelectionPage> {
  DateTime? first = DateTime(2026, 10, 18), last = DateTime(2026, 10, 22);
  String? error;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(bookingProvider.notifier);
      notifier.chooseRoom(widget.roomId);
      if (ref.read(bookingProvider).checkIn == null) {
        notifier.chooseDates(first!, last!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomFutureProvider(widget.roomId));
    final availabilityState = ref.watch(availabilityProvider(widget.roomId));
    final booking = ref.watch(bookingProvider);
    if (roomState.isLoading || availabilityState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (roomState.hasError || availabilityState.hasError) {
      return const Scaffold(
        body: Center(child: Text('Could not load dates. Please try again.')),
      );
    }
    final availability =
        availabilityState.value ?? const <DateTime, AvailabilityDay>{};
    final room = roomState.value;
    if (room == null) {
      return const Scaffold(body: Center(child: Text('Room not found')));
    }
    if (booking.estimatedPrice == null &&
        booking.checkIn != null &&
        booking.checkOut != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateEstimate(
          room,
          availability,
          booking.checkIn!,
          booking.checkOut!,
        ),
      );
    }
    final month = DateTime(2026, 10);
    final offset = (month.weekday + 6) % 7;
    final cells = ((offset + 31 + 6) ~/ 7) * 7;
    final selectionValid =
        first != null &&
        last != null &&
        last!.isAfter(first!) &&
        _stayHasAvailability(availability, first!, last!);
    return Scaffold(
      appBar: AppBar(title: const Text('Select your stay'), centerTitle: true),
      body: BookingContent(
        child: ListView(
          padding: const EdgeInsets.all(StayEasySpacing.space16),
          children: [
            BookingCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dateLabel('CHECK-IN', first),
                  const Icon(
                    Icons.arrow_forward,
                    color: StayEasyColors.textSecondary,
                  ),
                  _dateLabel('CHECK-OUT', last),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _caption('NIGHTS'),
                      Text(
                        '${last != null && first != null ? last!.difference(first!).inDays : '—'}',
                        style: StayEasyTypography.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: BookingCard(
                  color: StayEasyColors.surface,
                  border: StayEasyColors.error,
                  child: Text(
                    error!,
                    style: StayEasyTypography.bodyMedium.copyWith(
                      color: StayEasyColors.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            BookingCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.chevron_left),
                      Text(
                        'October 2026',
                        style: StayEasyTypography.editorialHero.copyWith(
                          fontSize: 21,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final d in [
                        'MON',
                        'TUE',
                        'WED',
                        'THU',
                        'FRI',
                        'SAT',
                        'SUN',
                      ])
                        Expanded(
                          child: Center(
                            child: Text(d, style: StayEasyTypography.caption),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cells,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                        ),
                    itemBuilder: (context, index) {
                      final day = index - offset + 1;
                      if (day < 1 || day > 31) return const SizedBox();
                      final date = DateTime(2026, 10, day);
                      final isCheckoutCandidate =
                          first != null && last == null && date.isAfter(first!);
                      final dayAvailability = availability[date];
                      final unavailable =
                          dayAvailability == null ||
                          (!isCheckoutCandidate &&
                              dayAvailability.availableRooms <= 0);
                      final selected =
                          (first != null && _same(date, first!)) ||
                          (last != null && _same(date, last!));
                      final inRange =
                          first != null &&
                          last != null &&
                          date.isAfter(first!) &&
                          date.isBefore(last!);
                      return InkWell(
                        onTap: unavailable ? null : () => _select(date),
                        borderRadius: StayEasyRadii.rounded12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? StayEasyColors.primary
                                : inRange
                                ? StayEasyColors.surfaceVariant
                                : Colors.transparent,
                            borderRadius: StayEasyRadii.rounded12,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: StayEasyTypography.bodyMedium.copyWith(
                              color: unavailable
                                  ? StayEasyColors.textSecondary.withValues(
                                      alpha: .45,
                                    )
                                  : selected
                                  ? Colors.white
                                  : StayEasyColors.textPrimary,
                              decoration: unavailable
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      LegendDot(StayEasyColors.primary, 'Selected'),
                      LegendDot(StayEasyColors.surfaceVariant, 'Unavailable'),
                      LegendDot(StayEasyColors.surface, 'Available'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price estimate', style: StayEasyTypography.titleMedium),
                  const SizedBox(height: 10),
                  PriceLine(
                    '${booking.nights} nights · from ₹${room.pricePerNight}',
                    booking.subtotal,
                  ),
                  PriceLine('Taxes & fees', booking.taxes),
                  PriceLine(
                    'Estimated total',
                    booking.subtotal + booking.taxes,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: selectionValid && booking.datesValid
                  ? () => context.push(AppRoutes.reviews)
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text('Continue · ${_short(first)}–${_short(last)}'),
            ),
          ],
        ),
      ),
    );
  }

  void _select(DateTime date) {
    setState(() => error = null);
    if (first == null || last != null) {
      setState(() {
        first = date;
        last = null;
      });
      return;
    }
    if (!date.isAfter(first!)) {
      setState(() {
        first = date;
        last = null;
      });
      return;
    }
    final availability =
        ref.read(availabilityProvider(widget.roomId)).value ??
        const <DateTime, AvailabilityDay>{};
    if (!_stayHasAvailability(availability, first!, date)) {
      setState(
        () => error =
            'One or more nights are unavailable. Try a different date range.',
      );
      return;
    }
    setState(() => last = date);
    final accepted = ref
        .read(bookingProvider.notifier)
        .chooseDates(first!, date);
    final room = ref.read(roomFutureProvider(widget.roomId)).value;
    if (accepted && room != null) {
      _updateEstimate(room, availability, first!, date);
    }
  }

  void _updateEstimate(
    Room room,
    Map<DateTime, AvailabilityDay> availability,
    DateTime from,
    DateTime to,
  ) {
    var subtotal = 0.0;
    for (
      var night = DateTime(from.year, from.month, from.day);
      night.isBefore(to);
      night = night.add(const Duration(days: 1))
    ) {
      subtotal +=
          availability[night]?.priceOverride ?? room.pricePerNight.toDouble();
    }
    ref.read(bookingProvider.notifier).setEstimate(subtotal);
  }

  Widget _dateLabel(String label, DateTime? date) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _caption(label),
      Text(_short(date), style: StayEasyTypography.titleMedium),
    ],
  );
  Widget _caption(String text) => Text(
    text,
    style: StayEasyTypography.caption.copyWith(
      color: StayEasyColors.textSecondary,
    ),
  );
  String _short(DateTime? d) => d == null ? 'Select' : '${d.day} Oct';
  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _stayHasAvailability(
  Map<DateTime, AvailabilityDay> availability,
  DateTime checkIn,
  DateTime checkOut,
) {
  if (!checkOut.isAfter(checkIn)) return false;
  for (
    var night = DateTime(checkIn.year, checkIn.month, checkIn.day);
    night.isBefore(checkOut);
    night = night.add(const Duration(days: 1))
  ) {
    final day = availability[night];
    if (day == null || day.availableRooms <= 0) return false;
  }
  return true;
}

class LegendDot extends StatelessWidget {
  const LegendDot(this.color, this.text, {super.key});
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: StayEasyColors.border),
        ),
      ),
      const SizedBox(width: 4),
      Text(text, style: StayEasyTypography.caption),
    ],
  );
}
