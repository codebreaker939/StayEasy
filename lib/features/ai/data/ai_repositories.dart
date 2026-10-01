import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/ai_models.dart';
import '../domain/ai_repository.dart';

class SupabaseAiRepository implements AiRepository {
  SupabaseAiRepository(this.client);
  final SupabaseClient client;

  @override
  Future<AiSearchInterpretation> interpretSearch(
    String query, {
    String? clarification,
  }) async {
    final text = query.trim();
    if (text.isEmpty || text.length > 500) {
      throw const FormatException('Enter a request up to 500 characters.');
    }
    try {
      final response = await client.functions.invoke(
        'ai-search',
        body: {'query': text, 'clarification_city': clarification},
      );
      return AiSearchInterpretation.fromJson(response.data);
    } on FunctionException catch (error) {
      throw AiUnavailableException(_safeMessage(error.details));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const AiUnavailableException();
    }
  }

  @override
  Future<ReviewAiInsight> getReviewInsights({
    required String hotelId,
    String? roomId,
    required DateTime intendedStay,
  }) async {
    try {
      final response = await client.functions.invoke(
        'ai-review-insights',
        body: {
          'hotel_id': hotelId,
          if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
          'stay_date':
              '${intendedStay.year.toString().padLeft(4, '0')}-${intendedStay.month.toString().padLeft(2, '0')}-${intendedStay.day.toString().padLeft(2, '0')}',
        },
      );
      return ReviewAiInsight.fromJson(response.data);
    } on FunctionException catch (error) {
      throw AiUnavailableException(_safeMessage(error.details));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const AiUnavailableException();
    }
  }
}

/// Offline-only fake for focused provider/widget tests. Production never selects it.
class FakeAiRepository implements AiRepository {
  FakeAiRepository({this.search, this.insight, this.failure});
  final AiSearchInterpretation? search;
  final ReviewAiInsight? insight;
  final Object? failure;

  @override
  Future<AiSearchInterpretation> interpretSearch(
    String query, {
    String? clarification,
  }) async {
    if (failure != null) throw failure!;
    if (search == null) throw const AiUnavailableException();
    return search!;
  }

  @override
  Future<ReviewAiInsight> getReviewInsights({
    required String hotelId,
    String? roomId,
    required DateTime intendedStay,
  }) async {
    if (failure != null) throw failure!;
    if (insight == null) throw const AiUnavailableException();
    return insight!;
  }
}

String _safeMessage(Object? value) {
  if (value is Map && value['error'] is String) {
    return switch (value['error']) {
      'AUTH_REQUIRED' => 'Sign in to use StayEasy AI.',
      'AI_NOT_CONFIGURED' => 'AI service is not configured yet.',
      _ => 'AI service unavailable',
    };
  }
  return 'AI service unavailable';
}
