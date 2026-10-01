import '../../auth/domain/auth_repository.dart';

class StayBooking {
  const StayBooking({
    required this.id,
    required this.code,
    required this.hotelId,
    required this.hotelName,
    required this.roomId,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.total,
    required this.status,
    required this.guestName,
    required this.guestEmail,
    this.phone,
  });
  final String id,
      code,
      hotelId,
      hotelName,
      roomId,
      roomName,
      status,
      guestName,
      guestEmail;
  final DateTime checkIn, checkOut;
  final int guests;
  final double total;
  final String? phone;
}

class BookingPrice {
  const BookingPrice({
    required this.subtotal,
    required this.taxes,
    required this.discount,
    required this.total,
  });
  final double subtotal, taxes, discount, total;
}

abstract interface class BookingRepository {
  Future<(String id, String code, BookingPrice price)> create({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String guestEmail,
    String? phone,
  });
  Future<List<StayBooking>> getMyBookings();
  Future<void> cancel(String bookingId);
}

abstract interface class AvailabilityRepository {
  Future<Map<DateTime, AvailabilityDay>> getAvailability(
    String roomId,
    DateTime from,
    DateTime to,
  );
}

class AvailabilityDay {
  const AvailabilityDay({required this.availableRooms, this.priceOverride});
  final int availableRooms;
  final double? priceOverride;
}

abstract interface class ProfileRepository {
  Future<StayEasyProfile?> getProfile(String id);
}
