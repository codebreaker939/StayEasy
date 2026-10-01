import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/data/mock_stay_data.dart';
import '../../discovery/domain/models/hotel.dart';
import '../../discovery/domain/models/room.dart';
import '../domain/review.dart';

class BookingState {
  const BookingState({
    this.roomId,
    this.checkIn,
    this.checkOut,
    this.guests = 2,
    this.guestName = '',
    this.email = '',
    this.phone = '',
    this.specialRequest = '',
    this.confirmed = false,
  });
  final String? roomId;
  final DateTime? checkIn, checkOut;
  final int guests;
  final String guestName, email, phone, specialRequest;
  final bool confirmed;
  int get nights => checkIn == null || checkOut == null
      ? 0
      : checkOut!.difference(checkIn!).inDays;
  bool get datesValid =>
      roomId != null &&
      checkIn != null &&
      checkOut != null &&
      nights > 0 &&
      !unavailableStayNights(checkIn!, checkOut!);
  bool get isValid =>
      datesValid && guestName.trim().isNotEmpty && email.contains('@');
  int get nightlyPrice =>
      MockStayData.rooms
          .where((r) => r.id == roomId)
          .firstOrNull
          ?.pricePerNight ??
      0;
  int get subtotal => nightlyPrice * nights;
  int get taxes => (subtotal / 6).round();
  int get discount => subtotal > 0 ? 500 : 0;
  int get total => subtotal + taxes - discount;
  String get bookingId {
    final date = checkIn == null
        ? '261018'
        : '${checkIn!.year % 100}${checkIn!.month.toString().padLeft(2, '0')}${checkIn!.day.toString().padLeft(2, '0')}';
    final suffix =
        (roomId ?? 'room').codeUnits.fold<int>(0, (sum, code) => sum + code) %
        10000;
    return 'SE-$date-${suffix.toString().padLeft(4, '0')}';
  }

  BookingState copyWith({
    String? roomId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String? guestName,
    String? email,
    String? phone,
    String? specialRequest,
    bool? confirmed,
    bool clearDates = false,
  }) => BookingState(
    roomId: roomId ?? this.roomId,
    checkIn: clearDates ? null : checkIn ?? this.checkIn,
    checkOut: clearDates ? null : checkOut ?? this.checkOut,
    guests: guests ?? this.guests,
    guestName: guestName ?? this.guestName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    specialRequest: specialRequest ?? this.specialRequest,
    confirmed: confirmed ?? this.confirmed,
  );
}

final unavailableOctoberDays = <int>{6, 7, 13, 14, 27};
bool unavailableStayNights(DateTime start, DateTime end) {
  for (
    var day = start;
    day.isBefore(end);
    day = day.add(const Duration(days: 1))
  ) {
    if (day.year == 2026 &&
        day.month == 10 &&
        unavailableOctoberDays.contains(day.day)) {
      return true;
    }
  }
  return false;
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();
  void chooseRoom(String id) =>
      state = BookingState(roomId: id, guests: state.guests);
  bool chooseDates(DateTime start, DateTime end) {
    if (!end.isAfter(start) || unavailableStayNights(start, end)) return false;
    state = state.copyWith(checkIn: start, checkOut: end);
    return true;
  }

  void setGuest({
    String? name,
    String? email,
    String? phone,
    String? request,
  }) => state = state.copyWith(
    guestName: name,
    email: email,
    phone: phone,
    specialRequest: request,
  );
  void confirm() => state = state.copyWith(confirmed: true);
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);

final reviewsProvider = Provider<List<Review>>(
  (ref) => [
    Review(
      id: 'oct-2025',
      guest: 'Rohan Mehta',
      stayedOn: DateTime(2025, 10, 28),
      rating: 4.8,
      text: 'A comfortable stay with thoughtful service. The team made our October city break feel easy.',
      roomId: 'mercer-deluxe',
      roomName: 'Deluxe King — City View',
      helpful: 42,
      verified: true,
    ),
    Review(
      id: 'room-jul-2026',
      guest: 'Mira Iyer',
      stayedOn: DateTime(2026, 7, 4),
      rating: 4.8,
      text: 'The room was quiet and the bed was genuinely comfortable. Loved having a proper desk too.',
      roomId: 'mercer-deluxe',
      roomName: 'Deluxe King — City View',
      helpful: 42,
      verified: true,
    ),
    Review(
      id: 'winter-2025',
      guest: 'Aarav Shah',
      stayedOn: DateTime(2025, 12, 18),
      rating: 4.6,
      text: 'Warm service and a lovely breakfast made this a relaxing visit.',
      roomId: 'mercer-premier',
      roomName: 'Premier Balcony Room',
      helpful: 18,
      verified: true,
    ),
    Review(
      id: 'spring-2024',
      guest: 'Nisha Rao',
      stayedOn: DateTime(2024, 3, 9),
      rating: 4.5,
      text: 'Comfortable and well located for exploring the neighbourhood.',
      roomId: 'mercer-premier',
      roomName: 'Premier Balcony Room',
      helpful: 9,
      verified: false,
    ),
  ],
);
final rankedReviewsProvider = Provider<List<RankedReview>>((ref) {
  final booking = ref.watch(bookingProvider);
  return rankReviews(
    ref.watch(reviewsProvider),
    booking.checkIn ?? DateTime(2026, 10, 18),
    booking.roomId ?? '',
  );
});

Room? bookingRoom(BookingState state) =>
    MockStayData.rooms.where((r) => r.id == state.roomId).firstOrNull;
Hotel? bookingHotel(BookingState state) {
  final room = bookingRoom(state);
  return room == null
      ? null
      : MockStayData.hotels.where((h) => h.id == room.hotelId).firstOrNull;
}
