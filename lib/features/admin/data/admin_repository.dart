import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_providers.dart';

class AdminRepository {
  AdminRepository(this.client);
  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> hotels() async =>
      _maps(await client.from('hotels').select('*, rooms(id)').order('name'));
  Future<List<Map<String, dynamic>>> rooms() async =>
      _maps(await client.from('rooms').select('*, hotels(name)').order('name'));
  Future<List<Map<String, dynamic>>> availability() async => _maps(
    await client
        .from('room_availability')
        .select('*, rooms(name, hotel_id, hotels(name))')
        .gte('date', _today())
        .order('date')
        .limit(250),
  );
  Future<List<Map<String, dynamic>>> bookings({String? status}) async {
    final query = client
        .from('bookings')
        .select('*, hotels(name, city), rooms(name)');
    final filtered = status != null && status != 'all'
        ? query.eq('status', status)
        : query;
    return _maps(
      await filtered.order('created_at', ascending: false).limit(250),
    );
  }

  Future<List<Map<String, dynamic>>> reviews() async => _maps(
    await client
        .from('reviews')
        .select('*, hotels(name), rooms(name)')
        .order('created_at', ascending: false)
        .limit(250),
  );
  Future<int> countActiveHotels() async =>
      (await client.from('hotels').select('id').eq('is_active', true)).length;
  Future<int> countRooms() async =>
      (await client.from('rooms').select('id')).length;
  Future<int> countUpcomingBookings() async =>
      (await client
              .from('bookings')
              .select('id')
              .eq('status', 'confirmed')
              .gte('check_out', _today()))
          .length;
  Future<int> countReviews() async =>
      (await client.from('reviews').select('id')).length;
  Future<void> saveHotel(Map<String, dynamic> values, {String? id}) async {
    if (id == null) {
      await client.from('hotels').insert(values);
    } else {
      await client.from('hotels').update(values).eq('id', id);
    }
  }

  Future<void> saveRoom(Map<String, dynamic> values, {String? id}) async {
    if (id == null) {
      await client.from('rooms').insert(values);
    } else {
      await client.from('rooms').update(values).eq('id', id);
    }
  }

  Future<void> upsertAvailability(
    String roomId,
    DateTime from,
    DateTime to,
    int count,
    double? price,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (
      var day = DateTime(from.year, from.month, from.day);
      day.isBefore(to);
      day = day.add(const Duration(days: 1))
    ) {
      rows.add({
        'room_id': roomId,
        'date': _date(day),
        'available_rooms': count,
        'price_override': price,
      });
    }
    await client
        .from('room_availability')
        .upsert(rows, onConflict: 'room_id,date');
  }

  Future<void> moderateReview(
    String id, {
    required bool verified,
    required int helpfulCount,
  }) async {
    await client
        .from('reviews')
        .update({'is_verified': verified, 'helpful_count': helpfulCount})
        .eq('id', id);
  }
}

List<Map<String, dynamic>> _maps(dynamic rows) =>
    (rows as List).cast<Map<String, dynamic>>();
String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _today() => _date(DateTime.now());
final adminRepositoryProvider = Provider<AdminRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : AdminRepository(client);
});
