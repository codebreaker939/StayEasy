import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/supabase_providers.dart';
import '../../auth/data/auth_repositories.dart';
import '../../auth/domain/auth_repository.dart';
import '../data/backend_repositories.dart';
import '../data/review_repositories.dart';
import '../domain/booking_repository.dart';
import '../domain/review_repository.dart';
import '../../discovery/data/mock_stay_data.dart';
import '../../discovery/application/discovery_providers.dart';
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
    this.bookingCode,
    this.bookingDbId,
    this.actualPrice,
    this.estimatedPrice,
    this.isSubmitting = false,
    this.error,
  });
  final String? roomId;
  final DateTime? checkIn, checkOut;
  final int guests;
  final String guestName, email, phone, specialRequest;
  final bool confirmed;
  final String? bookingCode, bookingDbId, error;
  final BookingPrice? actualPrice;
  final BookingPrice? estimatedPrice;
  final bool isSubmitting;
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
  int get subtotal =>
      (actualPrice ?? estimatedPrice)?.subtotal.round() ??
      nightlyPrice * nights;
  int get taxes =>
      (actualPrice ?? estimatedPrice)?.taxes.round() ?? (subtotal / 6).round();
  int get discount =>
      (actualPrice ?? estimatedPrice)?.discount.round() ??
      (subtotal > 0 ? 500 : 0);
  int get total =>
      (actualPrice ?? estimatedPrice)?.total.round() ??
      subtotal + taxes - discount;
  String get bookingId => bookingCode ?? _draftBookingId;
  String get _draftBookingId {
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
    String? bookingCode,
    String? bookingDbId,
    BookingPrice? actualPrice,
    BookingPrice? estimatedPrice,
    bool? isSubmitting,
    String? error,
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
    bookingCode: bookingCode ?? this.bookingCode,
    bookingDbId: bookingDbId ?? this.bookingDbId,
    actualPrice: actualPrice ?? this.actualPrice,
    estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: error,
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
  void setEstimate(double subtotal) {
    final roundedSubtotal = double.parse(subtotal.toStringAsFixed(2));
    final taxes = double.parse((roundedSubtotal / 6).toStringAsFixed(2));
    final discount = roundedSubtotal > 0
        ? (roundedSubtotal + taxes).clamp(0, 500).toDouble()
        : 0.0;
    state = state.copyWith(
      estimatedPrice: BookingPrice(
        subtotal: roundedSubtotal,
        taxes: taxes,
        discount: discount,
        total: roundedSubtotal + taxes - discount,
      ),
    );
  }

  Future<void> createBooking() async {
    if (!state.isValid || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await ref
          .read(bookingRepositoryProvider)
          .create(
            roomId: state.roomId!,
            checkIn: state.checkIn!,
            checkOut: state.checkOut!,
            guests: state.guests,
            guestName: state.guestName,
            guestEmail: state.email,
            phone: state.phone.isEmpty ? null : state.phone,
          );
      state = state.copyWith(
        bookingDbId: result.$1,
        bookingCode: result.$2,
        actualPrice: result.$3,
        confirmed: true,
        isSubmitting: false,
      );
      ref.invalidate(myBookingsProvider);
      ref.invalidate(availabilityProvider(state.roomId!));
    } catch (error) {
      state = state.copyWith(isSubmitting: false, error: _bookingError(error));
    }
  }

  String _bookingError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('sold out') || message.contains('availability')) {
      return 'Those dates are no longer available. Please choose another stay.';
    }
    return 'We couldn’t confirm this booking. Please try again.';
  }
}

final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? MockReviewRepository()
      : SupabaseReviewRepository(client);
});
final reviewsProvider = FutureProvider<List<Review>>((ref) async {
  final room = await ref.watch(currentBookingRoomProvider.future);
  return ref.watch(reviewRepositoryProvider).getReviews(hotelId: room?.hotelId);
});
final hotelReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, hotelId) =>
      ref.watch(reviewRepositoryProvider).getReviews(hotelId: hotelId),
);
final roomReviewsProvider = FutureProvider.family<List<Review>, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(roomFutureProvider(roomId).future);
  if (room == null) return const [];
  final reviews = await ref
      .watch(reviewRepositoryProvider)
      .getReviews(hotelId: room.hotelId);
  return reviews
      .where((review) => review.roomId == roomId)
      .toList(growable: false);
});
final rankedReviewsProvider = Provider<AsyncValue<List<RankedReview>>>((ref) {
  final booking = ref.watch(bookingProvider);
  return ref
      .watch(reviewsProvider)
      .whenData(
        (reviews) => rankReviews(
          reviews,
          booking.checkIn ?? DateTime(2026, 10, 18),
          booking.roomId ?? '',
        ),
      );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? GuestAuthRepository()
      : SupabaseAuthRepository(client);
});
final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseProfileRepository(client);
});
final authProfileProvider = StreamProvider<StayEasyProfile?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield await repository.currentProfile();
  yield* repository.profileChanges;
});
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? MockBookingRepository()
      : SupabaseBookingRepository(client);
});
final myBookingsProvider = FutureProvider<List<StayBooking>>((ref) {
  if (ref.watch(authProfileProvider).value == null) return const [];
  return ref.watch(bookingRepositoryProvider).getMyBookings();
});
final currentBookingRoomProvider = FutureProvider<Room?>((ref) async {
  final id = ref.watch(bookingProvider).roomId;
  return id == null ? null : ref.watch(hotelRepositoryProvider).getRoom(id);
});
final currentBookingHotelProvider = FutureProvider<Hotel?>((ref) async {
  final room = await ref.watch(currentBookingRoomProvider.future);
  return room == null
      ? null
      : ref.watch(hotelRepositoryProvider).getHotel(room.hotelId);
});
final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? MockAvailabilityRepository()
      : SupabaseAvailabilityRepository(client);
});
final availabilityProvider =
    FutureProvider.family<Map<DateTime, AvailabilityDay>, String>((
      ref,
      roomId,
    ) {
      return ref
          .watch(availabilityRepositoryProvider)
          .getAvailability(
            roomId,
            DateTime(2026, 10, 1),
            DateTime(2026, 11, 1),
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
