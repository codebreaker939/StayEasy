import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/stayeasy_typography.dart';
import '../../discovery/application/discovery_providers.dart';

Future<void> showSearchFilterSheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(searchStateProvider);
  final price = TextEditingController(
    text: current.maxPriceInr?.toStringAsFixed(0) ?? '',
  );
  var city = current.destination;
  var guests = current.guests;
  var month = current.month;
  var minRating = current.minRating;
  var checkIn = current.checkIn;
  var checkOut = current.checkOut;
  final amenities = current.amenities.toSet();
  final roomTypes = current.roomTypes.toSet();
  final vibes = current.vibes.toSet();
  const amenityChoices = [
    'Wi-Fi',
    'Balcony',
    'Breakfast',
    'Pool',
    'Beach access',
    'Lake view',
    'Mountain view',
    'Heating',
  ];
  const roomChoices = [
    'Queen',
    'King',
    'Twin',
    'Suite',
    'Family suite',
    'Studio',
    'Balcony room',
    'Loft',
    'Compact room',
  ];
  const vibeChoices = [
    'Quiet stay',
    'Beach stay',
    'Business',
    'Luxury',
    'Nature',
    'Design hotel',
    'Lake view',
    'Mountain view',
    'Budget',
    'Couples',
  ];

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search filters', style: StayEasyTypography.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: city.isEmpty ? 'Any city' : city,
                    decoration: const InputDecoration(labelText: 'City'),
                    items: ['Any city', 'Mumbai', 'Goa', 'Udaipur', 'Manali']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (value) => setModal(
                      () => city = value == 'Any city' ? '' : value ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: guests,
                    decoration: const InputDecoration(labelText: 'Guests'),
                    items: [
                      for (var i = 1; i <= 8; i++)
                        DropdownMenuItem(value: i, child: Text('$i')),
                    ],
                    onChanged: (value) => setModal(() => guests = value ?? 2),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: month,
                    decoration: const InputDecoration(
                      labelText: 'Travel month',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Any month'),
                      ),
                      for (var i = 1; i <= 12; i++)
                        DropdownMenuItem<int?>(
                          value: i,
                          child: Text(_monthName(i)),
                        ),
                    ],
                    onChanged: (value) => setModal(() {
                      month = value;
                      checkIn = null;
                      checkOut = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                        initialDateRange: checkIn != null && checkOut != null
                            ? DateTimeRange(start: checkIn!, end: checkOut!)
                            : null,
                      );
                      if (range != null) {
                        setModal(() {
                          checkIn = range.start;
                          checkOut = range.end;
                          month = range.start.month;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      checkIn != null && checkOut != null
                          ? '${checkIn!.day}–${checkOut!.day} ${_monthName(checkIn!.month)}'
                          : 'Choose exact dates',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double?>(
                    initialValue: minRating,
                    decoration: const InputDecoration(
                      labelText: 'Minimum rating',
                    ),
                    items: const [
                      DropdownMenuItem<double?>(
                        value: null,
                        child: Text('Any rating'),
                      ),
                      DropdownMenuItem<double?>(value: 3, child: Text('3.0+')),
                      DropdownMenuItem<double?>(value: 4, child: Text('4.0+')),
                      DropdownMenuItem<double?>(
                        value: 4.5,
                        child: Text('4.5+'),
                      ),
                    ],
                    onChanged: (value) => setModal(() => minRating = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Maximum nightly price',
                      prefixText: '₹ ',
                    ),
                  ),
                  _choiceGroup(
                    'Amenities',
                    amenityChoices,
                    amenities,
                    setModal,
                  ),
                  _choiceGroup('Room types', roomChoices, roomTypes, setModal),
                  _choiceGroup('Stay style', vibeChoices, vibes, setModal),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final parsed = double.tryParse(price.text.trim());
                      ref
                          .read(searchStateProvider.notifier)
                          .editSearchFilters(
                            city: city,
                            guests: guests,
                            maxPrice: parsed != null && parsed >= 0
                                ? parsed
                                : null,
                            minRating: minRating,
                            month: month,
                            checkIn: checkIn,
                            checkOut: checkOut,
                            amenities: amenities.toList(),
                            roomTypes: roomTypes.toList(),
                            vibes: vibes.toList(),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply filters'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    price.dispose();
  }
}

Widget _choiceGroup(
  String title,
  List<String> choices,
  Set<String> selected,
  StateSetter setModal,
) => Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: StayEasyTypography.labelLarge),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final choice in choices)
            FilterChip(
              label: Text(choice),
              selected: selected.contains(choice),
              onSelected: (value) => setModal(() {
                if (value) {
                  selected.add(choice);
                } else {
                  selected.remove(choice);
                }
              }),
            ),
        ],
      ),
    ],
  ),
);

String _monthName(int month) => const [
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
