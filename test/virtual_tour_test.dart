import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stayeasy/app/router/app_router.dart';
import 'package:stayeasy/app/router/app_routes.dart';
import 'package:stayeasy/features/discovery/application/discovery_providers.dart';
import 'package:stayeasy/features/discovery/data/mock_stay_data.dart';
import 'package:stayeasy/features/discovery/domain/hotel_repository.dart';
import 'package:stayeasy/features/discovery/domain/models/hotel.dart';
import 'package:stayeasy/features/discovery/domain/models/room.dart';
import 'package:stayeasy/features/virtual_tour/application/virtual_tour_catalog.dart';
import 'package:stayeasy/features/virtual_tour/domain/virtual_tour.dart';
import 'package:stayeasy/features/virtual_tour/presentation/virtual_tour_page.dart';

const _seededRoom = Room(
  id: VirtualTourCatalog.demoRoomId,
  hotelId: 'demo-hotel',
  name: 'Harbour Queen',
  description: 'A sample room.',
  pricePerNight: 4299,
  capacity: 2,
  bedType: 'Queen',
  size: 26,
  image: 'assets/images/room-detail.png',
  amenities: ['Wi-Fi'],
);

class _TourRepository implements HotelRepository {
  _TourRepository(this.room);
  final Room? room;

  @override
  Future<List<Hotel>> getHotels() async => MockStayData.hotels;
  @override
  Future<Hotel?> getHotel(String id) async => MockStayData.hotels.firstOrNull;
  @override
  Future<List<Room>> getRooms({String? hotelId}) async => [?room];
  @override
  Future<Room?> getRoom(String id) async => room?.id == id ? room : null;
}

Widget _app({
  required String location,
  Room? room = _seededRoom,
  VirtualTourImageLoader? imageLoader,
}) {
  final overrides = [
    hotelRepositoryProvider.overrideWithValue(_TourRepository(room)),
    virtualTourViewerBuilderProvider.overrideWith(
      (ref) =>
          (context, space, onHotspotTap) => ColoredBox(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Test sphere: ${space.label}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  for (final hotspot in space.hotspots)
                    TextButton(
                      onPressed: () => onHotspotTap(hotspot),
                      child: Text('Open ${hotspot.label} details'),
                    ),
                ],
              ),
            ),
          ),
    ),
    virtualTourImageLoaderProvider.overrideWith(
      (ref) => imageLoader ?? (image, context) async {},
    ),
  ];
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: createAppRouter(initialLocation: location),
    ),
  );
}

void _setViewport(WidgetTester tester, Size? size) {
  if (size == null) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  } else {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
  }
}

void main() {
  test(
    'seeded room resolves three 2:1 bundled spaces and spherical hotspots',
    () {
      final tour = VirtualTourCatalog.resolve(_seededRoom)!;
      expect(tour.spaces.map((space) => space.id), [
        'bedroom',
        'bathroom',
        'balcony',
      ]);
      expect(
        tour.spaces.first.imageSource,
        'assets/images/virtual_tour/bedroom_360.jpg',
      );
      expect(tour.spaces.first.hotspots.map((hotspot) => hotspot.label), [
        'King bed',
        'Work desk',
        'Smart TV',
      ]);
      expect(tour.spaces.first.hotspots.first.longitude, isA<double>());
      expect(tour.spaces.first.hotspots.first.latitude, isA<double>());
      expect(
        tour.spaces.every((space) => space.imageKind == TourImageKind.asset),
        isTrue,
      );
    },
  );

  test(
    'a safe real tour URL takes precedence and invalid URLs are ignored',
    () {
      final remote = VirtualTourCatalog.resolve(
        _seededRoom.copyWithTour('https://example.test/pano.jpg'),
      )!;
      expect(remote.spaces, hasLength(1));
      expect(remote.spaces.single.imageKind, TourImageKind.network);
      expect(
        VirtualTourCatalog.resolve(
          _seededRoom.copyWithTour('javascript:alert(1)'),
        )?.spaces.first.imageSource,
        'assets/images/virtual_tour/bedroom_360.jpg',
      );
    },
  );

  testWidgets('Room Details opens the routed 360 tour for the seeded room', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(_app(location: AppRoutes.roomPath(_seededRoom.id)));
    await tester.pumpAndSettle();
    expect(find.text('View 360° preview'), findsOneWidget);
    await tester.tap(find.text('View 360° preview'));
    await tester.pumpAndSettle();
    expect(find.text('Explore the room'), findsOneWidget);
    expect(find.text('Test sphere: Bedroom'), findsOneWidget);
    expect(find.text('Harbour Queen'), findsWidgets);
    _setViewport(tester, null);
  });

  testWidgets(
    'rooms without a resolvable tour hide CTA and show graceful route fallback',
    (tester) async {
      final unavailable = _seededRoom.copyWithTour(null, id: 'ordinary-room');
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(location: AppRoutes.roomPath(unavailable.id), room: unavailable),
      );
      await tester.pumpAndSettle();
      expect(find.text('View 360° preview'), findsNothing);
      await tester.pumpWidget(
        _app(
          location: AppRoutes.virtualTourPath(unavailable.id),
          room: unavailable,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('360 preview unavailable'), findsOneWidget);
      expect(find.text('Room photos are still available.'), findsOneWidget);
      expect(find.text('Back to room'), findsOneWidget);
      _setViewport(tester, null);
    },
  );

  testWidgets(
    'Bedroom is initial; switching spaces updates the view and active tab',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(location: AppRoutes.virtualTourPath(_seededRoom.id)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bedroom', skipOffstage: false), findsWidgets);
      expect(find.text('Test sphere: Bedroom'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tour-space-bathroom')));
      await tester.pumpAndSettle();
      expect(find.text('Test sphere: Bathroom'), findsOneWidget);
      expect(find.text('Bathroom', skipOffstage: false), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('tour-space-balcony')));
      await tester.pumpAndSettle();
      expect(find.text('Test sphere: Balcony'), findsOneWidget);
      expect(find.text('Balcony', skipOffstage: false), findsWidgets);
      _setViewport(tester, null);
    },
  );

  testWidgets('hotspot tap opens explanatory details', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(location: AppRoutes.virtualTourPath(_seededRoom.id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open King bed details'));
    await tester.pumpAndSettle();
    expect(find.text('King bed'), findsOneWidget);
    expect(
      find.text('A generous king bed anchors this restful space.'),
      findsOneWidget,
    );
    _setViewport(tester, null);
  });

  testWidgets('info sheet explains controls and attributes demo imagery', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(location: AppRoutes.virtualTourPath(_seededRoom.id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tour information'));
    await tester.pumpAndSettle();
    expect(find.text('How to explore'), findsOneWidget);
    expect(find.textContaining('Hotel Room'), findsOneWidget);
    expect(find.textContaining('Greg Zaal, Poly Haven'), findsNWidgets(2));
    expect(find.textContaining('En Suite'), findsOneWidget);
    expect(
      find.textContaining('Dimitrios Savva & Jarod Guest, Poly Haven'),
      findsOneWidget,
    );
    expect(
      find.textContaining('do not represent the seeded Harbour Queen property'),
      findsOneWidget,
    );
    _setViewport(tester, null);
  });

  testWidgets('fullscreen opens and closes without replacing the tour state', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(location: AppRoutes.virtualTourPath(_seededRoom.id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tour-fullscreen-open')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close full screen'), findsOneWidget);
    expect(find.text('Test sphere: Bedroom'), findsOneWidget);
    await tester.tap(find.byTooltip('Close full screen'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tour-fullscreen-open')), findsOneWidget);
    expect(find.text('Test sphere: Bedroom'), findsOneWidget);
    _setViewport(tester, null);
  });

  testWidgets('panorama loading failures show the safe fallback', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        location: AppRoutes.virtualTourPath(_seededRoom.id),
        imageLoader: (image, context) async => throw StateError('image failed'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('360 preview unavailable'), findsOneWidget);
    expect(find.text('Room photos are still available.'), findsOneWidget);
    expect(find.text('Back to room'), findsOneWidget);
    _setViewport(tester, null);
  });

  testWidgets(
    'tour layout fits compact, medium, and expanded reference widths',
    (tester) async {
      for (final size in [
        const Size(390, 844),
        const Size(834, 900),
        const Size(1440, 1000),
      ]) {
        _setViewport(tester, size);
        await tester.pumpWidget(
          _app(location: AppRoutes.virtualTourPath(_seededRoom.id)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'overflow at $size');
        expect(find.text('Explore the room'), findsOneWidget);
      }
      _setViewport(tester, null);
    },
  );
}

extension on Room {
  Room copyWithTour(String? url, {String? id}) => Room(
    id: id ?? this.id,
    hotelId: hotelId,
    name: name,
    description: description,
    pricePerNight: pricePerNight,
    capacity: capacity,
    bedType: bedType,
    size: size,
    image: image,
    amenities: amenities,
    available: available,
    virtualTourUrl: url,
  );
}
