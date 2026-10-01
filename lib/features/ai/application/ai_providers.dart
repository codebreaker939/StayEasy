import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/supabase_providers.dart';
import '../../booking/application/booking_provider.dart';
import '../../discovery/application/discovery_providers.dart';
import '../data/ai_repositories.dart';
import '../domain/ai_models.dart';
import '../domain/ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnavailableAiRepository()
      : SupabaseAiRepository(client);
});

class AiSearchState {
  const AiSearchState({this.query = '', this.result = const AsyncData(null)});
  final String query;
  final AsyncValue<AiSearchInterpretation?> result;
  AiSearchState copyWith({
    String? query,
    AsyncValue<AiSearchInterpretation?>? result,
  }) =>
      AiSearchState(query: query ?? this.query, result: result ?? this.result);
}

class AiSearchController extends Notifier<AiSearchState> {
  @override
  AiSearchState build() => const AiSearchState();

  Future<void> interpret(String query, {String? clarification}) async {
    state = AiSearchState(query: query, result: const AsyncLoading());
    try {
      final interpretation = await ref
          .read(aiRepositoryProvider)
          .interpretSearch(query, clarification: clarification);
      if (interpretation.status == AiSearchStatus.parsed) {
        ref
            .read(searchStateProvider.notifier)
            .applyAiFilters(interpretation.filters);
      }
      state = AiSearchState(query: query, result: AsyncData(interpretation));
    } catch (error, stack) {
      state = AiSearchState(query: query, result: AsyncError(error, stack));
    }
  }

  void reset() => state = const AiSearchState();
}

final aiSearchControllerProvider =
    NotifierProvider<AiSearchController, AiSearchState>(AiSearchController.new);

class ReviewAiContext {
  const ReviewAiContext({
    required this.hotelId,
    required this.roomId,
    required this.stayDate,
  });
  final String hotelId;
  final String roomId;
  final DateTime stayDate;
  @override
  bool operator ==(Object other) =>
      other is ReviewAiContext &&
      other.hotelId == hotelId &&
      other.roomId == roomId &&
      other.stayDate.year == stayDate.year &&
      other.stayDate.month == stayDate.month;
  @override
  int get hashCode =>
      Object.hash(hotelId, roomId, stayDate.year, stayDate.month);
}

final reviewAiContextProvider = FutureProvider<ReviewAiContext?>((ref) async {
  final booking = ref.watch(bookingProvider);
  final roomId = booking.roomId;
  if (roomId == null) return null;
  final room = await ref.watch(roomFutureProvider(roomId).future);
  if (room == null) return null;
  final date = booking.checkIn ?? DateTime(2026, 10, 18);
  return ReviewAiContext(
    hotelId: room.hotelId,
    roomId: room.id,
    stayDate: date,
  );
});

final reviewAiInsightProvider =
    FutureProvider.family<ReviewAiInsight?, ReviewAiContext>(
      (ref, context) => ref
          .watch(aiRepositoryProvider)
          .getReviewInsights(
            hotelId: context.hotelId,
            roomId: context.roomId,
            intendedStay: context.stayDate,
          ),
    );
