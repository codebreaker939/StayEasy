class Review {
  const Review({
    required this.id,
    required this.guest,
    required this.stayedOn,
    required this.rating,
    required this.text,
    required this.roomId,
    required this.roomName,
    required this.helpful,
    required this.verified,
  });
  final String id, guest, text, roomId, roomName;
  final DateTime stayedOn;
  final double rating;
  final int helpful;
  final bool verified;
}

class RankedReview {
  const RankedReview(this.review, this.score);
  final Review review;
  final int score;
}

abstract final class ReviewRankingWeights {
  static const sameMonth = 100;
  static const nearbySeason = 45;
  static const exactRoom = 35;
  static const verified = 15;
  static const helpfulnessPerTen = 1;
  static const recencyPerYear = 3;
}

List<RankedReview> rankReviews(
  List<Review> reviews,
  DateTime checkIn,
  String roomId,
) {
  final ranked = reviews.map((review) {
    final monthDistance = (review.stayedOn.month - checkIn.month).abs();
    final circularDistance = monthDistance > 6
        ? 12 - monthDistance
        : monthDistance;
    final seasonal = circularDistance == 0
        ? ReviewRankingWeights.sameMonth
        : circularDistance <= 2
        ? ReviewRankingWeights.nearbySeason
        : 0;
    final room = review.roomId == roomId ? ReviewRankingWeights.exactRoom : 0;
    final verified = review.verified ? ReviewRankingWeights.verified : 0;
    final helpful =
        review.helpful ~/ 10 * ReviewRankingWeights.helpfulnessPerTen;
    final age = (checkIn.year - review.stayedOn.year).clamp(0, 10);
    final recency = 10 - age * ReviewRankingWeights.recencyPerYear;
    return RankedReview(review, seasonal + room + verified + helpful + recency);
  }).toList();
  ranked.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.review.id.compareTo(b.review.id);
  });
  return ranked;
}
