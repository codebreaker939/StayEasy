import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_stay_data.dart';
import '../domain/models/hotel.dart';
import '../domain/models/room.dart';

enum HotelSort { recommended, priceLowToHigh, ratingHighToLow }

class SearchState {
  const SearchState({
    this.destination = 'Mumbai',
    this.dates = '18–22 Oct',
    this.guests = 2,
    this.sort = HotelSort.recommended,
  });

  final String destination;
  final String dates;
  final int guests;
  final HotelSort sort;

  SearchState copyWith({
    String? destination,
    String? dates,
    int? guests,
    HotelSort? sort,
  }) => SearchState(
    destination: destination ?? this.destination,
    dates: dates ?? this.dates,
    guests: guests ?? this.guests,
    sort: sort ?? this.sort,
  );
}

class SearchStateNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void setDestination(String value) =>
      state = state.copyWith(destination: value);
  void setGuests(int value) =>
      state = state.copyWith(guests: value.clamp(1, 8));
  void setSort(HotelSort value) => state = state.copyWith(sort: value);
}

final searchStateProvider = NotifierProvider<SearchStateNotifier, SearchState>(
  SearchStateNotifier.new,
);
final hotelsProvider = Provider<List<Hotel>>((ref) => MockStayData.hotels);
final roomsProvider = Provider<List<Room>>((ref) => MockStayData.rooms);
final savedHotelIdsProvider =
    NotifierProvider<SavedHotelIdsNotifier, Set<String>>(
      SavedHotelIdsNotifier.new,
    );

class SavedHotelIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void toggle(String id) {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
  }
}

List<Hotel> filterAndSortHotels(
  List<Hotel> hotels,
  String query,
  HotelSort sort,
) {
  final term = query.trim().toLowerCase();
  final matches = hotels
      .where(
        (hotel) =>
            term.isEmpty ||
            hotel.city.toLowerCase().contains(term) ||
            hotel.name.toLowerCase().contains(term) ||
            hotel.location.toLowerCase().contains(term),
      )
      .toList();
  switch (sort) {
    case HotelSort.recommended:
      return matches;
    case HotelSort.priceLowToHigh:
      return matches
        ..sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
    case HotelSort.ratingHighToLow:
      return matches..sort((a, b) => b.rating.compareTo(a.rating));
  }
}

final searchResultsProvider = Provider<List<Hotel>>((ref) {
  final search = ref.watch(searchStateProvider);
  return filterAndSortHotels(
    ref.watch(hotelsProvider),
    search.destination,
    search.sort,
  );
});

Hotel? findHotel(WidgetRef ref, String id) {
  for (final hotel in ref.watch(hotelsProvider)) {
    if (hotel.id == id) return hotel;
  }
  return null;
}

Room? findRoom(WidgetRef ref, String id) {
  for (final room in ref.watch(roomsProvider)) {
    if (room.id == id) return room;
  }
  return null;
}
