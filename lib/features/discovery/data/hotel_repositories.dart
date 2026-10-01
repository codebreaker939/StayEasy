import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/hotel_repository.dart';
import '../domain/models/hotel.dart';
import '../domain/models/room.dart';
import 'mock_stay_data.dart';

class MockHotelRepository implements HotelRepository {
  @override
  Future<List<Hotel>> getHotels() async => MockStayData.hotels;

  @override
  Future<Hotel?> getHotel(String id) async =>
      MockStayData.hotels.where((hotel) => hotel.id == id).firstOrNull;

  @override
  Future<List<Room>> getRooms({String? hotelId}) async => MockStayData.rooms
      .where((room) => hotelId == null || room.hotelId == hotelId)
      .toList();

  @override
  Future<Room?> getRoom(String id) async =>
      MockStayData.rooms.where((room) => room.id == id).firstOrNull;
}

class SupabaseHotelRepository implements HotelRepository {
  SupabaseHotelRepository(this.client);

  final SupabaseClient client;

  static const _hotelImages = <String, String>{
    'Mumbai': 'assets/images/mercer.png',
    'Goa': 'assets/images/cala-house.png',
    'Udaipur': 'assets/images/atelier.png',
    'Manali': 'assets/images/dune-pine.png',
  };

  @override
  Future<List<Hotel>> getHotels() async {
    final rows = await client
        .from('hotels')
        .select('*, rooms(price_per_night,is_active)')
        .eq('is_active', true)
        .order('rating', ascending: false);
    return rows.map(_hotel).toList();
  }

  @override
  Future<Hotel?> getHotel(String id) async {
    final row = await client
        .from('hotels')
        .select('*, rooms(price_per_night,is_active)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _hotel(row);
  }

  @override
  Future<List<Room>> getRooms({String? hotelId}) async {
    var query = client.from('rooms').select().eq('is_active', true);
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await query.order('price_per_night');
    return rows.map(_room).toList();
  }

  @override
  Future<Room?> getRoom(String id) async {
    final row = await client
        .from('rooms')
        .select()
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();
    return row == null ? null : _room(row);
  }

  Hotel _hotel(Map<String, dynamic> row) {
    return hotelFromSupabaseRow(row, imageForCity: _hotelImages);
  }

  Room _room(Map<String, dynamic> row) => roomFromSupabaseRow(row);
}

Hotel hotelFromSupabaseRow(
  Map<String, dynamic> row, {
  Map<String, String> imageForCity = const {},
}) {
  final city = row['city'] as String? ?? '';
  final roomPrices = (row['rooms'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .where((room) => room['is_active'] == true)
      .map((room) => (room['price_per_night'] as num).round())
      .toList();
  return Hotel(
    id: row['id'] as String,
    name: row['name'] as String,
    city: city,
    location: [row['address'], city].whereType<String>().join(' · '),
    rating: (row['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: row['review_count'] as int? ?? 0,
    pricePerNight: roomPrices.isEmpty
        ? 0
        : roomPrices.reduce((a, b) => a < b ? a : b),
    image: imageForCity[city] ?? 'assets/images/hotel-detail.png',
    description: row['description'] as String? ?? '',
    amenities: (row['amenities'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    tags: const [],
  );
}

Room roomFromSupabaseRow(Map<String, dynamic> row) => Room(
  id: row['id'] as String,
  hotelId: row['hotel_id'] as String,
  name: row['name'] as String,
  description: row['description'] as String? ?? '',
  pricePerNight: (row['price_per_night'] as num).round(),
  capacity: row['capacity'] as int,
  bedType: row['bed_type'] as String? ?? 'Bed type not specified',
  size: (row['room_size'] as num?)?.round() ?? 0,
  image: 'assets/images/room-detail.png',
  amenities: (row['amenities'] as List<dynamic>? ?? const [])
      .whereType<String>()
      .toList(),
);
