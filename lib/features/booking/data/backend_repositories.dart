import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/domain/auth_repository.dart';
import '../../discovery/data/mock_stay_data.dart';
import '../domain/booking_repository.dart';

class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this.client);
  final SupabaseClient client;

  @override
  Future<(String id, String code, BookingPrice price)> create({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String guestEmail,
    String? phone,
  }) async {
    final row =
        (await client.rpc(
              'create_booking',
              params: {
                'p_room_id': roomId,
                'p_check_in': _date(checkIn),
                'p_check_out': _date(checkOut),
                'p_guest_count': guests,
                'p_guest_name': guestName,
                'p_guest_email': guestEmail,
                'p_guest_phone': phone,
              },
            ) as List).single
            as Map<String, dynamic>;
    return bookingResultFromSupabaseRow(row);
  }

  @override
  Future<List<StayBooking>> getMyBookings() async {
    final rows = await client
        .from('bookings')
        .select('*, hotels(name), rooms(name)')
        .order('created_at', ascending: false);
    return rows.map((row) {
      final hotel = row['hotels'] as Map<String, dynamic>?;
      final room = row['rooms'] as Map<String, dynamic>?;
      return StayBooking(
        id: row['id'] as String,
        code: row['booking_code'] as String,
        hotelId: row['hotel_id'] as String,
        hotelName: hotel?['name'] as String? ?? 'StayEasy hotel',
        roomId: row['room_id'] as String,
        roomName: room?['name'] as String? ?? 'Room',
        checkIn: DateTime.parse(row['check_in'] as String),
        checkOut: DateTime.parse(row['check_out'] as String),
        guests: row['guest_count'] as int,
        total: (row['total_price'] as num).toDouble(),
        status: row['status'] as String,
        guestName: row['guest_name'] as String,
        guestEmail: row['guest_email'] as String,
        phone: row['guest_phone'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> cancel(String bookingId) async {
    await client.rpc('cancel_booking', params: {'p_booking_id': bookingId});
  }
}

class SupabaseAvailabilityRepository implements AvailabilityRepository {
  SupabaseAvailabilityRepository(this.client);
  final SupabaseClient client;
  @override
  Future<Map<DateTime, AvailabilityDay>> getAvailability(
    String roomId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await client
        .from('room_availability')
        .select('date,available_rooms,price_override')
        .eq('room_id', roomId)
        .gte('date', _date(from))
        .lt('date', _date(to))
        .order('date');
    return {
      for (final row in rows)
        DateTime.parse(row['date'] as String): AvailabilityDay(
          availableRooms: row['available_rooms'] as int,
          priceOverride: (row['price_override'] as num?)?.toDouble(),
        ),
    };
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this.client);
  final SupabaseClient client;
  @override
  Future<StayEasyProfile?> getProfile(String id) async {
    final row = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return StayEasyProfile(
      id: id,
      email: row['email'] as String? ?? '',
      fullName: row['full_name'] as String?,
      role: row['role'] as String? ?? 'user',
    );
  }
}

class MockBookingRepository implements BookingRepository {
  @override
  Future<(String id, String code, BookingPrice price)> create({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String guestEmail,
    String? phone,
  }) async {
    final room = MockStayData.rooms.where((r) => r.id == roomId).firstOrNull;
    final subtotal =
        (room?.pricePerNight ?? 0) * checkOut.difference(checkIn).inDays;
    final taxes = (subtotal / 6).roundToDouble();
    final discount = subtotal > 0 ? 500.0 : 0.0;
    final suffix =
        roomId.codeUnits.fold<int>(0, (sum, value) => sum + value) % 10000;
    return (
      'mock-${DateTime.now().microsecondsSinceEpoch}',
      'SE-${checkIn.year % 100}${checkIn.month.toString().padLeft(2, '0')}${checkIn.day.toString().padLeft(2, '0')}-${suffix.toString().padLeft(4, '0')}',
      BookingPrice(
        subtotal: subtotal.toDouble(),
        taxes: taxes,
        discount: discount,
        total: subtotal + taxes - discount,
      ),
    );
  }

  @override
  Future<List<StayBooking>> getMyBookings() async => const [];
  @override
  Future<void> cancel(String bookingId) async {}
}

class MockAvailabilityRepository implements AvailabilityRepository {
  @override
  Future<Map<DateTime, AvailabilityDay>> getAvailability(
    String roomId,
    DateTime from,
    DateTime to,
  ) async {
    final result = <DateTime, AvailabilityDay>{};
    for (
      var day = DateTime(from.year, from.month, from.day);
      day.isBefore(to);
      day = day.add(const Duration(days: 1))
    ) {
      final soldOut =
          day.year == 2026 &&
          day.month == 10 &&
          const {6, 7, 13, 14, 27}.contains(day.day);
      result[day] = AvailabilityDay(availableRooms: soldOut ? 0 : 1);
    }
    return result;
  }
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

(String id, String code, BookingPrice price) bookingResultFromSupabaseRow(
  Map<String, dynamic> row,
) => (
  row['booking_id'] as String,
  row['booking_code'] as String,
  BookingPrice(
    subtotal: (row['subtotal'] as num).toDouble(),
    taxes: (row['taxes'] as num).toDouble(),
    discount: (row['discount'] as num).toDouble(),
    total: (row['total_price'] as num).toDouble(),
  ),
);
