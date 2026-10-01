import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stayeasy/features/auth/domain/auth_repository.dart';
import 'package:stayeasy/features/booking/application/booking_provider.dart';
import 'package:stayeasy/features/booking/data/backend_repositories.dart';
import 'package:stayeasy/features/booking/data/review_repositories.dart';
import 'package:stayeasy/features/booking/domain/review.dart';
import 'package:stayeasy/features/discovery/data/hotel_repositories.dart';
import 'package:stayeasy/features/discovery/domain/models/hotel.dart';
import 'package:stayeasy/features/discovery/domain/models/room.dart';

void main() {
  test('Supabase hotel, room, review and booking rows map safely', () {
    final hotel = hotelFromSupabaseRow(
      {
        'id': 'hotel-1',
        'name': 'Lake Stay',
        'city': 'Udaipur',
        'address': 'Old City',
        'rating': 4.7,
        'review_count': 12,
        'description': 'A lakeside stay',
        'amenities': ['Wi-Fi', 'Breakfast'],
        'rooms': [
          {'price_per_night': 8200, 'is_active': true},
          {'price_per_night': 4000, 'is_active': false},
        ],
      },
      imageForCity: const {'Udaipur': 'assets/images/atelier.png'},
    );
    expect(hotel, isA<Hotel>());
    expect(hotel.pricePerNight, 8200);
    expect(hotel.image, 'assets/images/atelier.png');

    final room = roomFromSupabaseRow({
      'id': 'room-1',
      'hotel_id': 'hotel-1',
      'name': 'Lake Suite',
      'description': 'A suite',
      'price_per_night': 8200.5,
      'capacity': 3,
      'bed_type': 'King',
      'room_size': 44,
      'amenities': ['Lake view'],
    });
    expect(room, isA<Room>());
    expect(room.pricePerNight, 8201);
    expect(room.capacity, 3);

    final review = reviewFromSupabaseRow({
      'id': 'review-1',
      'stay_date': '2026-10-11',
      'created_at': '2026-10-13T10:00:00Z',
      'rating': 5,
      'title': 'Lovely',
      'body': 'A peaceful visit.',
      'room_id': 'room-1',
      'rooms': {'name': 'Lake Suite'},
      'helpful_count': 9,
      'is_verified': true,
    });
    expect(review, isA<Review>());
    expect(review.stayedOn, DateTime(2026, 10, 11));
    expect(review.roomName, 'Lake Suite');
    expect(review.verified, isTrue);

    final booking = bookingResultFromSupabaseRow({
      'booking_id': 'booking-1',
      'booking_code': 'SE-20261002-AB12CD34',
      'subtotal': 8200,
      'taxes': 1366.67,
      'discount': 500,
      'total_price': 9066.67,
    });
    expect(booking.$1, 'booking-1');
    expect(booking.$2, 'SE-20261002-AB12CD34');
    expect(booking.$3.total, 9066.67);
  });

  test(
    'availability repo includes checkout boundary and sold out nights',
    () async {
      final repo = MockAvailabilityRepository();
      final dates = await repo.getAvailability(
        'room',
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 29),
      );
      expect(dates[DateTime(2026, 10, 26)]?.availableRooms, 1);
      expect(dates[DateTime(2026, 10, 27)]?.availableRooms, 0);
      expect(dates.containsKey(DateTime(2026, 10, 29)), isFalse);
    },
  );

  test('signed-in admin identity is represented only by profile role', () {
    const user = StayEasyProfile(
      id: 'u',
      email: 'admin@example.test',
      role: 'user',
    );
    const admin = StayEasyProfile(
      id: 'a',
      email: 'guest@example.test',
      role: 'admin',
    );
    expect(user.isAdmin, isFalse);
    expect(admin.isAdmin, isTrue);
  });

  test('mock review ranking is stable for a selected month and room', () {
    final reviews = demoReviews;
    final first = rankReviews(reviews, DateTime(2026, 10, 18), 'mercer-deluxe');
    final second = rankReviews(
      reviews,
      DateTime(2026, 10, 18),
      'mercer-deluxe',
    );
    expect(
      first.map((value) => value.review.id),
      second.map((value) => value.review.id),
    );
    expect(first.first.review.stayedOn.month, 10);
  });

  test('repository providers remain replaceable without Supabase', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(bookingRepositoryProvider),
      isA<MockBookingRepository>(),
    );
  });
}
