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

Widget buildApp({String initialLocation = AppRoutes.explore}) => ProviderScope(
  child: StayEasyApp(router: createAppRouter(initialLocation: initialLocation)),
);

void main() {
  testWidgets('Explore page renders the StayEasy discovery experience', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('StayEasy'), findsOneWidget);
    expect(find.text('Where are you\nstaying next?'), findsOneWidget);
    expect(find.text('Search stays'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, StayEasyColors.primary);
  });

  testWidgets('Search CTA opens filtered results', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.ensureVisible(find.text('Search stays'));
    await tester.tap(find.text('Search stays'));
    await tester.pumpAndSettle();
    expect(find.text('Mumbai stays'), findsOneWidget);
    expect(find.text('The Mercer Mumbai'), findsWidgets);
  });

  testWidgets('hotel selection opens Hotel Details by ID', (tester) async {
    await tester.pumpWidget(buildApp());
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
