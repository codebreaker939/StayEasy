import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/supabase_providers.dart';
import '../data/hotel_repositories.dart';
import '../domain/hotel_repository.dart';
import '../data/mock_stay_data.dart';
import '../domain/models/hotel.dart';
import '../domain/models/room.dart';
import '../../ai/domain/ai_models.dart';

enum HotelSort { recommended, priceLowToHigh, ratingHighToLow }

class SearchState {
  const SearchState({
    this.destination = 'Mumbai',
    this.dates = '18–22 Oct',
    this.guests = 2,
    this.sort = HotelSort.recommended,
    this.month,
    this.checkIn,
    this.checkOut,
    this.maxPriceInr,
    this.minRating,
    this.amenities = const [],
    this.roomTypes = const [],
    this.vibes = const [],
  });

  final String destination;
  final String dates;
  final int guests;
  final HotelSort sort;
  final int? month;
  final DateTime? checkIn, checkOut;
  final double? maxPriceInr, minRating;
  final List<String> amenities, roomTypes, vibes;

  SearchState copyWith({
    String? destination,
    String? dates,
    int? guests,
    HotelSort? sort,
    Object? month = _unsetSearch,
    Object? checkIn = _unsetSearch,
    Object? checkOut = _unsetSearch,
    Object? maxPriceInr = _unsetSearch,
    Object? minRating = _unsetSearch,
    List<String>? amenities,
    List<String>? roomTypes,
    List<String>? vibes,
  }) => SearchState(
    destination: destination ?? this.destination,
    dates: dates ?? this.dates,
    guests: guests ?? this.guests,
    sort: sort ?? this.sort,
    month: identical(month, _unsetSearch) ? this.month : month as int?,
    checkIn: identical(checkIn, _unsetSearch)
        ? this.checkIn
        : checkIn as DateTime?,
    checkOut: identical(checkOut, _unsetSearch)
        ? this.checkOut
        : checkOut as DateTime?,
    maxPriceInr: identical(maxPriceInr, _unsetSearch)
        ? this.maxPriceInr
        : maxPriceInr as double?,
    minRating: identical(minRating, _unsetSearch)
        ? this.minRating
        : minRating as double?,
    amenities: amenities ?? this.amenities,
    roomTypes: roomTypes ?? this.roomTypes,
    vibes: vibes ?? this.vibes,
  );
}

const _unsetSearch = Object();

class SearchStateNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void setDestination(String value) =>
      state = state.copyWith(destination: value);

  void resetFilters() =>
      state = const SearchState(destination: '', dates: 'Any dates');
  void setGuests(int value) =>
      state = state.copyWith(guests: value.clamp(1, 8));
  void setSort(HotelSort value) => state = state.copyWith(sort: value);

  void applyAiFilters(AiSearchFilters filters) {
    state = state.copyWith(
      destination: filters.city ?? '',
      dates: _dateLabel(filters),
      guests: filters.guests ?? state.guests,
      month: filters.month,
      checkIn: filters.checkIn,
      checkOut: filters.checkOut,
      maxPriceInr: filters.maxPriceInr,
      minRating: filters.minRating,
      amenities: filters.amenities,
      roomTypes: filters.roomTypes,
      vibes: filters.vibes,
    );
  }

  void removeInterpretedFilter(String kind, [String? value]) {
    switch (kind) {
      case 'city':
        state = state.copyWith(destination: '');
        break;
      case 'month':
        state = state.copyWith(
          month: null,
          checkIn: null,
          checkOut: null,
          dates: 'Any dates',
        );
        break;
      case 'guests':
        state = state.copyWith(guests: 2);
        break;
      case 'price':
        state = state.copyWith(maxPriceInr: null);
        break;
      case 'rating':
        state = state.copyWith(minRating: null);
        break;
      case 'amenity':
        state = state.copyWith(
          amenities: state.amenities.where((item) => item != value).toList(),
        );
        break;
      case 'room':
        state = state.copyWith(
          roomTypes: state.roomTypes.where((item) => item != value).toList(),
        );
        break;
      case 'vibe':
        state = state.copyWith(
          vibes: state.vibes.where((item) => item != value).toList(),
        );
        break;
    }
  }

  void editSearchFilters({
    String? city,
    int? guests,
    double? maxPrice,
    double? minRating,
    int? month,
    DateTime? checkIn,
    DateTime? checkOut,
    List<String>? amenities,
    List<String>? roomTypes,
    List<String>? vibes,
  }) {
    state = state.copyWith(
      destination: city ?? state.destination,
      guests: guests ?? state.guests,
      maxPriceInr: maxPrice,
      minRating: minRating,
      month: month,
      checkIn: checkIn,
      checkOut: checkOut,
      amenities: amenities,
      roomTypes: roomTypes,
      vibes: vibes,
    );
  }
}

String _dateLabel(AiSearchFilters filters) {
  if (filters.checkIn != null && filters.checkOut != null) {
    return '${filters.checkIn!.day}–${filters.checkOut!.day} ${_monthName(filters.checkIn!.month)}';
  }
  if (filters.month case final int month) return _monthName(month);
  return 'Any dates';
}

String _monthName(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

final searchStateProvider = NotifierProvider<SearchStateNotifier, SearchState>(
  SearchStateNotifier.new,
);
final hotelsProvider = Provider<List<Hotel>>((ref) => MockStayData.hotels);
final roomsProvider = Provider<List<Room>>((ref) => MockStayData.rooms);
final hotelRepositoryProvider = Provider<HotelRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? MockHotelRepository()
      : SupabaseHotelRepository(client);
});
final hotelsFutureProvider = FutureProvider<List<Hotel>>(
  (ref) => ref.watch(hotelRepositoryProvider).getHotels(),
);
final hotelFutureProvider = FutureProvider.family<Hotel?, String>(
  (ref, id) => ref.watch(hotelRepositoryProvider).getHotel(id),
);
final roomsForHotelFutureProvider = FutureProvider.family<List<Room>, String>(
  (ref, id) => ref.watch(hotelRepositoryProvider).getRooms(hotelId: id),
);
final allRoomsFutureProvider = FutureProvider<List<Room>>(
  (ref) => ref.watch(hotelRepositoryProvider).getRooms(),
);
final roomFutureProvider = FutureProvider.family<Room?, String>(
  (ref, id) => ref.watch(hotelRepositoryProvider).getRoom(id),
);
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
final searchResultsFutureProvider = FutureProvider<List<Hotel>>((ref) async {
  final search = ref.watch(searchStateProvider);
  final hotels = await ref.watch(hotelsFutureProvider.future);
  final rooms = await ref.watch(allRoomsFutureProvider.future);
  return filterHotelsForSearch(hotels, rooms, search);
});

List<Hotel> filterHotelsForSearch(
  List<Hotel> hotels,
  List<Room> rooms,
  SearchState search,
) {
  final base = filterAndSortHotels(hotels, search.destination, search.sort);
  return base
      .where((hotel) {
        if (search.minRating != null && hotel.rating < search.minRating!) {
          return false;
        }
        final hotelAmenities = hotel.amenities.map(_searchKey).toSet();
        final hotelRooms = rooms
            .where(
              (room) =>
                  room.hotelId == hotel.id && room.capacity >= search.guests,
            )
            .toList();
        if (hotelRooms.isEmpty) return false;
        if (!search.vibes.every(
          (vibe) => _matchesVibe(vibe, hotel, hotelRooms),
        )) {
          return false;
        }
        if (search.roomTypes.isEmpty &&
            search.amenities.isEmpty &&
            search.maxPriceInr == null) {
          return true;
        }
        return hotelRooms.any((room) {
          if (search.maxPriceInr != null &&
              room.pricePerNight > search.maxPriceInr!) {
            return false;
          }
          final roomText = _searchKey(
            '${room.name} ${room.bedType} ${room.amenities.join(' ')} ${room.description}',
          );
          if (!search.roomTypes.every(
            (type) => _matchesRoomType(type, roomText),
          )) {
            return false;
          }
          final roomAmenities = room.amenities.map(_searchKey).toSet();
          return search.amenities.every(
            (item) =>
                roomAmenities.any(
                  (amenity) => _matchesAmenity(amenity, item),
                ) ||
                hotelAmenities.any((amenity) => _matchesAmenity(amenity, item)),
          );
        });
      })
      .toList(growable: false);
}

String _searchKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

bool _matchesRoomType(String type, String roomText) {
  final key = _searchKey(type);
  if (key == 'balcony room') return roomText.contains('balcony');
  if (key == 'compact room') return roomText.contains('compact');
  final words = key.split(' ');
  return words.every(roomText.contains);
}

bool _matchesAmenity(String candidate, String requested) {
  final candidateKey = _searchKey(candidate).replaceAll(' ', '');
  final requestedKey = _searchKey(requested).replaceAll(' ', '');
  if (requestedKey == 'wifi') return candidateKey.contains('wifi');
  return candidateKey == requestedKey || candidateKey.contains(requestedKey);
}

bool _matchesVibe(String vibe, Hotel hotel, List<Room> rooms) {
  final key = _searchKey(vibe);
  final text = _searchKey(
    '${hotel.name} ${hotel.location} ${hotel.description} ${hotel.tags.join(' ')} ${hotel.amenities.join(' ')} ${rooms.map((room) => '${room.name} ${room.description} ${room.amenities.join(' ')}').join(' ')}',
  );
  return switch (key) {
    'quiet stay' => RegExp(r'\b(quiet|calm|peaceful|serene)\b').hasMatch(text),
    'beach stay' => RegExp(r'\b(beach|coastal|sea|ocean)\b').hasMatch(text),
    'business' => RegExp(r'\b(business|work|desk|wifi)\b').hasMatch(text),
    'luxury' =>
      hotel.rating >= 4.7 ||
          RegExp(r'\b(luxury|premium|design led)\b').hasMatch(text),
    'nature' => RegExp(
      r'\b(nature|mountain|pine|garden|forest|bonfire)\b',
    ).hasMatch(text),
    'design hotel' => RegExp(r'\b(design|heritage)\b').hasMatch(text),
    'lake view' => text.contains('lake view') || text.contains('lake'),
    'mountain view' =>
      text.contains('mountain view') || text.contains('valley view'),
    'budget' => hotel.pricePerNight <= 5000,
    'couples' => rooms.any((room) => room.capacity == 2),
    _ => false,
  };
}

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
