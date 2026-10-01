import 'ai_models.dart';

abstract interface class AiRepository {
  Future<AiSearchInterpretation> interpretSearch(
    String query, {
    String? clarification,
  });
  Future<ReviewAiInsight> getReviewInsights({
    required String hotelId,
    String? roomId,
    required DateTime intendedStay,
  });
}

class AiUnavailableException implements Exception {
  const AiUnavailableException([this.message = 'AI service unavailable']);
  final String message;
  @override
  String toString() => message;
}

class UnavailableAiRepository implements AiRepository {
  const UnavailableAiRepository();
  @override
  Future<AiSearchInterpretation> interpretSearch(
    String query, {
    String? clarification,
  }) => Future.error(const AiUnavailableException());
  @override
  Future<ReviewAiInsight> getReviewInsights({
    required String hotelId,
    String? roomId,
    required DateTime intendedStay,
  }) => Future.error(const AiUnavailableException());
}
