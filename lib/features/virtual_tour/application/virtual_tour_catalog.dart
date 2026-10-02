import '../domain/virtual_tour.dart';
import '../../discovery/domain/models/room.dart';

/// The first seed room is Harbour Queen; the seed does not include a Deluxe King.
abstract final class VirtualTourCatalog {
  static const demoRoomId = '20000000-0000-4000-8000-000000000001';

  static final demoTour = VirtualTour(
    roomId: demoRoomId,
    spaces: [
      VirtualTourSpace(
        id: 'bedroom',
        label: 'Bedroom',
        imageSource: 'assets/images/virtual_tour/bedroom_360.jpg',
        imageKind: TourImageKind.asset,
        initialLongitude: 42,
        initialLatitude: -2,
        hotspots: const [
          VirtualTourHotspot(
            label: 'King bed',
            description: 'A generous king bed anchors this restful space.',
            longitude: 94,
            latitude: -20,
          ),
          VirtualTourHotspot(
            label: 'Work desk',
            description:
                'A convenient place to plan your day or catch up on work.',
            longitude: -50,
            latitude: -24,
          ),
          VirtualTourHotspot(
            label: 'Smart TV',
            description: 'Settle in with entertainment after a day out.',
            longitude: -65,
            latitude: 7,
          ),
        ],
        attribution: '“Hotel Room” — Greg Zaal, Poly Haven',
        license: 'CC0',
        sourceUrl: Uri.parse('https://polyhaven.com/a/hotel_room'),
      ),
      VirtualTourSpace(
        id: 'bathroom',
        label: 'Bathroom',
        imageSource: 'assets/images/virtual_tour/bathroom_360.jpg',
        imageKind: TourImageKind.asset,
        initialLongitude: 0,
        initialLatitude: -2,
        hotspots: const [
          VirtualTourHotspot(
            label: 'Rain shower',
            description: 'A refreshing shower area with room to unwind.',
            longitude: -83,
            latitude: -9,
          ),
          VirtualTourHotspot(
            label: 'Vanity',
            description: 'A bright vanity with useful counter space.',
            longitude: 122,
            latitude: -22,
          ),
          VirtualTourHotspot(
            label: 'Amenities',
            description: 'Everyday essentials are close at hand.',
            longitude: -54,
            latitude: 0,
          ),
        ],
        attribution: '“En Suite” — Greg Zaal, Poly Haven',
        license: 'CC0',
        sourceUrl: Uri.parse('https://polyhaven.com/a/en_suite'),
      ),
      VirtualTourSpace(
        id: 'balcony',
        label: 'Balcony',
        imageSource: 'assets/images/virtual_tour/balcony_360.jpg',
        imageKind: TourImageKind.asset,
        initialLongitude: 90,
        initialLatitude: -3,
        hotspots: const [
          VirtualTourHotspot(
            label: 'City view',
            description: 'Look out over the surrounding skyline.',
            longitude: 97,
            latitude: -6,
          ),
          VirtualTourHotspot(
            label: 'Seating',
            description: 'A small seating area for a quiet pause.',
            longitude: -108,
            latitude: -26,
          ),
          VirtualTourHotspot(
            label: 'Evening light',
            description: 'A lovely spot to enjoy the softer light at dusk.',
            longitude: 36,
            latitude: 45,
          ),
        ],
        attribution: '“Hotel Rooftop Balcony” — Dimitrios Savva & Jarod Guest, Poly Haven',
        license: 'CC0',
        sourceUrl: Uri.parse('https://polyhaven.com/a/hotel_rooftop_balcony'),
      ),
    ],
  );

  static VirtualTour? resolve(Room room) {
    final url = _usableTourUrl(room.virtualTourUrl);
    if (url != null) {
      return VirtualTour(
        roomId: room.id,
        spaces: [
          VirtualTourSpace(
            id: 'room-tour',
            label: '360° view',
            imageSource: url.toString(),
            imageKind: TourImageKind.network,
            hotspots: const [],
          ),
        ],
      );
    }
    return room.id == demoRoomId ? demoTour : null;
  }

  static Uri? _usableTourUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }
}
