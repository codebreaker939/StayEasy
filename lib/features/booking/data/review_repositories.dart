import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/review.dart';
import '../domain/review_repository.dart';

class MockReviewRepository implements ReviewRepository {
  @override
  Future<List<Review>> getReviews({String? hotelId}) async => demoReviews;
}

class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<Review>> getReviews({String? hotelId}) async {
    var query = client.from('reviews').select('*, rooms(name)');
    if (hotelId != null) query = query.eq('hotel_id', hotelId);
    final rows = await query.order('created_at', ascending: false);
    return rows.map(reviewFromSupabaseRow).toList();
  }
}

Review reviewFromSupabaseRow(Map<String, dynamic> row) {
  final room = row['rooms'] as Map<String, dynamic>?;
  final stayedOn =
      DateTime.tryParse(row['stay_date'] as String? ?? '') ??
      DateTime.parse(row['created_at'] as String).toLocal();
  return Review(
    id: row['id'] as String,
    guest: 'StayEasy guest',
    stayedOn: stayedOn,
    rating: (row['rating'] as num).toDouble(),
    text: [
      row['title'],
      row['body'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · '),
    roomId: row['room_id'] as String? ?? '',
    roomName: room?['name'] as String? ?? 'Hotel stay',
    helpful: row['helpful_count'] as int? ?? 0,
    verified: row['is_verified'] as bool? ?? false,
  );
}

final demoReviews = <Review>[
  Review(
    id: 'oct-2025',
    guest: 'Maya',
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
    guest: 'Aarav',
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
    guest: 'Nisha',
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
    guest: 'Rohan',
    stayedOn: DateTime(2024, 3, 9),
    rating: 4.5,
    text: 'Comfortable and well located for exploring the neighbourhood.',
    roomId: 'mercer-premier',
    roomName: 'Premier Balcony Room',
    helpful: 9,
    verified: false,
  ),
];
