import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stayeasy/app/router/app_router.dart';
import 'package:stayeasy/app/router/app_routes.dart';
import 'package:stayeasy/app/stayeasy_app.dart';
import 'package:stayeasy/core/theme/stayeasy_colors.dart';
import 'package:stayeasy/features/discovery/application/discovery_providers.dart';
import 'package:stayeasy/features/discovery/data/mock_stay_data.dart';
import 'package:stayeasy/features/discovery/data/hotel_repositories.dart';
import 'package:stayeasy/features/discovery/domain/hotel_repository.dart';
import 'package:stayeasy/features/discovery/domain/models/hotel.dart';
import 'package:stayeasy/features/discovery/domain/models/room.dart';

Widget buildApp({String initialLocation = AppRoutes.explore}) => ProviderScope(
  child: StayEasyApp(router: createAppRouter(initialLocation: initialLocation)),
);

void main() {
  testWidgets('Explore data error is safe and retries successfully', (
    tester,
  ) async {
    final repository = _RetryHotelRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hotelRepositoryProvider.overrideWithValue(repository)],
        child: StayEasyApp(router: createAppRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stays are temporarily unavailable'), findsOneWidget);
    expect(find.textContaining('connection failed internally'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.hotelRequests, 2);
    expect(find.text('Where are you\nstaying next?'), findsOneWidget);
  });

  testWidgets('Empty search can clear filters and browse available stays', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchStateProvider.overrideWith(_NoResultsSearch.new)],
        child: StayEasyApp(
          router: createAppRouter(initialLocation: AppRoutes.search),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching stays'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('All stays'), findsOneWidget);
    expect(find.text('The Mercer Mumbai'), findsWidgets);
  });

  testWidgets('Explore page renders the StayEasy discovery experience', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('StayEasy'), findsOneWidget);
    expect(find.text('Where are you\nstaying next?'), findsOneWidget);
    expect(find.text('Search stays'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, StayEasyColors.primary);
  });

  testWidgets('Search CTA opens filtered results', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Search stays'));
    await tester.tap(find.text('Search stays'));
    await tester.pumpAndSettle();
    expect(find.text('Mumbai stays'), findsOneWidget);
    expect(find.text('The Mercer Mumbai'), findsWidgets);
  });

  testWidgets('Search filters sheet fits reference widths', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final width in [390.0, 834.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(buildApp(initialLocation: AppRoutes.search));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      expect(find.text('Search filters'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'filter sheet at $width');
      await tester.scrollUntilVisible(
        find.text('Apply filters'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'filter apply at $width');
    }
  });

  testWidgets('hotel selection opens Hotel Details by ID', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Search stays'));
    await tester.tap(find.text('Search stays'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('hotel-mercer-mumbai')).first,
    );
    await tester.tap(find.byKey(const ValueKey('hotel-mercer-mumbai')).first);
    await tester.pumpAndSettle();
    expect(find.text('The Mercer Mumbai'), findsWidgets);
    expect(find.text('Available rooms'), findsOneWidget);
  });

  testWidgets('room selection opens Room Details by ID', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Search stays'));
    await tester.tap(find.text('Search stays'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('hotel-mercer-mumbai')).first,
    );
    await tester.tap(find.byKey(const ValueKey('hotel-mercer-mumbai')).first);
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('room-mercer-deluxe')));
    await tester.pumpAndSettle();
    expect(find.text('ROOM DETAILS'), findsOneWidget);
    expect(find.text('Deluxe King — City View'), findsOneWidget);
  });

  testWidgets('View rooms CTA scrolls to the available rooms section', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(initialLocation: AppRoutes.hotelPath('mercer-mumbai')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View rooms'));
    await tester.pumpAndSettle();
    expect(find.text('Available rooms'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Available rooms')).dy,
      lessThan(tester.view.physicalSize.height),
    );
  });

  test('mock search filters hotels by city and name', () {
    expect(
      filterAndSortHotels(
        MockStayData.hotels,
        'goa',
        HotelSort.recommended,
      ).single.id,
      'cala-goa',
    );
    expect(
      filterAndSortHotels(
        MockStayData.hotels,
        'Mercer',
        HotelSort.recommended,
      ).single.city,
      'Mumbai',
    );
    expect(
      filterAndSortHotels(
        MockStayData.hotels,
        'not-a-city',
        HotelSort.recommended,
      ),
      isEmpty,
    );
  });

  testWidgets('all hotel and room IDs resolve to detail screens', (
    tester,
  ) async {
    for (final hotel in MockStayData.hotels) {
      await tester.pumpWidget(
        buildApp(initialLocation: AppRoutes.hotelPath(hotel.id)),
      );
      await tester.pumpAndSettle();
      expect(find.text(hotel.name), findsOneWidget);
      expect(find.text('Stay not found'), findsNothing);
    }
    for (final room in MockStayData.rooms) {
      await tester.pumpWidget(
        buildApp(initialLocation: AppRoutes.roomPath(room.id)),
      );
      await tester.pumpAndSettle();
      expect(find.text(room.name), findsOneWidget);
      expect(find.text('Room not found'), findsNothing);
    }
  });

  testWidgets('discovery layouts fit the three reference widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const widths = [390.0, 834.0, 1440.0];
    const locations = [
      AppRoutes.explore,
      AppRoutes.search,
      '/hotel/mercer-mumbai',
      '/room/mercer-deluxe',
      '/room/mercer-deluxe/dates',
      '/reviews',
      '/booking/guest',
      '/booking/review',
      '/booking/confirmation',
      '/booking/success',
      '/trips',
      AppRoutes.signIn,
      AppRoutes.signUp,
    ];
    for (final width in widths) {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      for (final location in locations) {
        await tester.pumpWidget(buildApp(initialLocation: location));
        await tester.pumpAndSettle();
        final error = tester.takeException();
        expect(
          error,
          isNull,
          reason: 'Unexpected layout exception at $width px on $location',
        );
      }
    }
  });

  test('all referenced hotel and room photos are bundled locally', () async {
    final paths = <String>{
      for (final hotel in MockStayData.hotels) hotel.image,
      for (final hotel in MockStayData.hotels)
        if (hotel.detailImage != null) hotel.detailImage!,
      for (final room in MockStayData.rooms) room.image,
    };
    for (final path in paths) {
      final asset = await rootBundle.load(path);
      expect(asset.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}

class _NoResultsSearch extends SearchStateNotifier {
  @override
  SearchState build() => const SearchState(destination: 'Atlantis');
}

class _RetryHotelRepository implements HotelRepository {
  final MockHotelRepository _delegate = MockHotelRepository();
  int hotelRequests = 0;

  @override
  Future<List<Hotel>> getHotels() async {
    hotelRequests++;
    if (hotelRequests == 1) throw StateError('connection failed internally');
    return _delegate.getHotels();
  }

  @override
  Future<Hotel?> getHotel(String id) => _delegate.getHotel(id);

  @override
  Future<List<Room>> getRooms({String? hotelId}) =>
      _delegate.getRooms(hotelId: hotelId);

  @override
  Future<Room?> getRoom(String id) => _delegate.getRoom(id);
}
