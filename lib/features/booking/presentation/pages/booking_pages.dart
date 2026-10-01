import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/stayeasy_colors.dart';
import '../../../../core/theme/stayeasy_spacing.dart';
import '../../../../core/theme/stayeasy_typography.dart';
import '../../application/booking_provider.dart';
import '../widgets/booking_widgets.dart';

class BookingGuestPage extends ConsumerWidget {
  const BookingGuestPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final hotel = bookingHotel(state);
    final room = bookingRoom(state);
    return Scaffold(
      appBar: AppBar(title: const Text('Guest details'), centerTitle: true),
      body: BookingContent(
        child: ListView(
          padding: const EdgeInsets.all(StayEasySpacing.space16),
          children: [
            BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel?.name ?? 'Your stay',
                    style: StayEasyTypography.editorialHero.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  Text(room?.name ?? ''),
                  Text(
                    '${_dates(state)} · ${state.nights} nights · ${state.guests} guests',
                    style: StayEasyTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Primary guest', style: StayEasyTypography.titleMedium),
            const SizedBox(height: 8),
            _input(
              'Full name',
              state.guestName,
              (v) => ref.read(bookingProvider.notifier).setGuest(name: v),
              validator: (v) => v == null || v.trim().length < 2
                  ? 'Enter the guest name'
                  : null,
            ),
            _input(
              'Email',
              state.email,
              (v) => ref.read(bookingProvider.notifier).setGuest(email: v),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
              keyboard: TextInputType.emailAddress,
            ),
            _input(
              'Phone',
              state.phone,
              (v) => ref.read(bookingProvider.notifier).setGuest(phone: v),
              keyboard: TextInputType.phone,
            ),
            BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special requests',
                    style: StayEasyTypography.titleMedium,
                  ),
                  const Text(
                    'Optional requests are shared with the hotel and are not guaranteed.',
                  ),
                  TextFormField(
                    initialValue: state.specialRequest,
                    onChanged: (v) =>
                        ref.read(bookingProvider.notifier).setGuest(request: v),
                    decoration: const InputDecoration(labelText: 'Request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BookingCard(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Before you continue'),
                  SizedBox(height: 8),
                  Text(
                    'Free cancellation until 16 Oct, 11:59 PM. Pay at property; card guarantee may be required.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BookingCard(
              child: Column(
                children: [
                  PriceLine(
                    '${state.nights} nights · ₹${state.nightlyPrice}/night',
                    state.subtotal,
                  ),
                  PriceLine('Taxes & fees', state.taxes),
                  PriceLine('Total', state.total, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.isValid
                  ? () => context.push(AppRoutes.bookingReview)
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Review booking'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _input(
  String label,
  String initial,
  ValueChanged<String> changed, {
  String? Function(String?)? validator,
  TextInputType? keyboard,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: BookingCard(
    child: TextFormField(
      key: ValueKey(label),
      initialValue: initial,
      onChanged: changed,
      validator: validator,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, border: InputBorder.none),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    ),
  ),
);

class BookingSummaryPage extends ConsumerWidget {
  const BookingSummaryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final hotel = bookingHotel(state);
    final room = bookingRoom(state);
    return Scaffold(
      appBar: AppBar(title: const Text('Review booking'), centerTitle: true),
      body: BookingContent(
        child: ListView(
          padding: const EdgeInsets.all(StayEasySpacing.space16),
          children: [
            BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel?.name ?? 'Your stay',
                    style: StayEasyTypography.editorialHero.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(room?.name ?? ''),
                  Text(
                    hotel?.location ?? '',
                    style: StayEasyTypography.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text('${_dates(state)} · ${state.nights} nights'),
                  Text('${state.guests} guests · ${state.guestName}'),
                  Text(state.email, style: StayEasyTypography.bodySmall),
                  if (state.phone.isNotEmpty)
                    Text(state.phone, style: StayEasyTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price details', style: StayEasyTypography.titleMedium),
                  PriceLine('Room · ${state.nights} nights', state.subtotal),
                  PriceLine('Taxes & fees', state.taxes),
                  PriceLine('StayEasy discount', -state.discount),
                  PriceLine('Total', state.total, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BookingCard(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cancel before 16 Oct, 11:59 PM for no cancellation fee.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Payment',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No charge today in this prototype. Booking confirmation is simulated.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.isValid
                  ? () => context.push(AppRoutes.bookingConfirmation)
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text('Confirm booking · ₹${state.total}'),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingConfirmationPage extends ConsumerWidget {
  const BookingConfirmationPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final hotel = bookingHotel(state);
    final room = bookingRoom(state);
    return Scaffold(
      appBar: AppBar(title: const Text('Review booking'), centerTitle: true),
      body: BookingContent(
        child: Center(
          child: BookingCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm this booking?',
                  style: StayEasyTypography.editorialHero.copyWith(
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text('${hotel?.name ?? ''} · ${room?.name ?? ''}'),
                Text('${_dates(state)} · ${state.guests} guests'),
                Text('Total ₹${state.total}'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go back'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          ref.read(bookingProvider.notifier).confirm();
                          context.go(AppRoutes.bookingSuccess);
                        },
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookingSuccessPage extends ConsumerWidget {
  const BookingSuccessPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final hotel = bookingHotel(state);
    final room = bookingRoom(state);
    return Scaffold(
      body: BookingContent(
        child: ListView(
          padding: const EdgeInsets.all(StayEasySpacing.space16),
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.check_circle_rounded,
              size: 72,
              color: StayEasyColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Your stay is confirmed',
              style: StayEasyTypography.editorialHero.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 8),
            Text(
              'You’re booked at ${hotel?.name ?? 'your StayEasy hotel'}.',
              style: StayEasyTypography.bodyMedium.copyWith(
                color: StayEasyColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            BookingCard(
              child: Column(
                children: [
                  _ticket('Booking ID', state.bookingId),
                  _ticket('Room', room?.name ?? '—'),
                  _ticket('Dates', '${_dates(state)} 2026'),
                  _ticket('Guests', '${state.guests}'),
                  _ticket('Total', '₹${state.total}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BookingCard(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens next',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your trip appears in My Trips. You can review the hotel details or manage the booking from there.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.trips),
              child: const Text('View my trip'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.explore),
              child: const Text('Back to Explore'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyTripsPage extends ConsumerWidget {
  const MyTripsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final hotel = bookingHotel(state);
    final room = bookingRoom(state);
    return Scaffold(
      appBar: AppBar(title: const Text('My trips'), centerTitle: true),
      body: BookingContent(
        child: ListView(
          padding: const EdgeInsets.all(StayEasySpacing.space16),
          children: [
            Text(
              'YOUR STAYS',
              style: StayEasyTypography.labelMedium.copyWith(
                color: StayEasyColors.primary,
              ),
            ),
            Text(
              'My trips',
              style: StayEasyTypography.editorialHero.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: Chip(label: Center(child: Text('Upcoming'))),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Chip(label: Center(child: Text('Past'))),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Chip(label: Center(child: Text('Cancelled'))),
                ),
              ],
            ),
            if (state.confirmed && hotel != null && room != null)
              BookingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPCOMING · ${state.checkIn?.day} OCT',
                      style: StayEasyTypography.labelMedium.copyWith(
                        color: StayEasyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hotel.name,
                      style: StayEasyTypography.editorialHero.copyWith(
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(room.name),
                    Text(
                      '${_dates(state)} 2026 · ${state.nights} nights · ${state.guests} guests',
                    ),
                    Text(
                      'Booking ${state.bookingId}',
                      style: StayEasyTypography.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => context.go(AppRoutes.bookingSuccess),
                          child: const Text('View trip'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              context.go(AppRoutes.hotelPath(hotel.id)),
                          child: const Text('Hotel details'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              const BookingCard(child: Text('No upcoming stays yet.')),
            const SizedBox(height: 16),
            const BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Past stays will appear here'),
                  SizedBox(height: 8),
                  Text('Completed trips can be reviewed after checkout.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _ticket(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: StayEasyColors.textSecondary),
        ),
      ),
      Flexible(child: Text(value, textAlign: TextAlign.end)),
    ],
  ),
);
String _dates(BookingState state) =>
    state.checkIn == null || state.checkOut == null
    ? '18–22 Oct'
    : '${state.checkIn!.day}–${state.checkOut!.day} Oct';
