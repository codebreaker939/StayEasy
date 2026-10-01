import 'review.dart';

abstract interface class ReviewRepository {
  Future<List<Review>> getReviews({String? hotelId});
}
