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
        initialLongitude: 0,
        initialLatitude: -2,
        hotspots: const [
          VirtualTourHotspot(
            label: 'King bed',
            description: 'A generous king bed anchors this restful space.',
            longitude: -26,
            latitude: -8,
          ),
          VirtualTourHotspot(
            label: 'Work desk',
            description:
                'A convenient place to plan your day or catch up on work.',
            longitude: 32,
            latitude: 0,
          ),
          VirtualTourHotspot(
            label: 'Smart TV',
            description: 'Settle in with entertainment after a day out.',
            longitude: 104,
            latitude: 5,
          ),
        ],
        attribution: 'NOIRLab/NSF/AURA/P. Horálek',
        license: 'CC BY 4.0',
        sourceUrl: Uri.parse(
          'https://noirlab.edu/public/media/archives/images/large/2022_04_08_Pano360_Tololo_Hotel_Room-CC.jpg',
        ),
      ),
      VirtualTourSpace(
        id: 'bathroom',
        label: 'Bathroom',
        imageSource: 'assets/images/virtual_tour/bathroom_360.jpg',
        imageKind: TourImageKind.asset,
        initialLongitude: 0,
        initialLatitude: -1,
        hotspots: const [
          VirtualTourHotspot(
            label: 'Rain shower',
            description: 'A refreshing shower area with room to unwind.',
            longitude: -18,
            latitude: 4,
          ),
          VirtualTourHotspot(
            label: 'Vanity',
            description: 'A bright vanity with useful counter space.',
            longitude: 45,
            latitude: -5,
          ),
          VirtualTourHotspot(
            label: 'Amenities',
            description: 'Everyday essentials are close at hand.',
            longitude: 118,
            latitude: 2,
          ),
        ],
        attribution: 'Bart Everson',
        license: 'CC BY 2.0',
        sourceUrl: Uri.parse(
          'https://live.staticflickr.com/65535/50048674676_14f64469c8_o.jpg',
        ),
      ),
      VirtualTourSpace(
        id: 'balcony',
        label: 'Balcony',
        imageSource: 'assets/images/virtual_tour/balcony_360.jpg',
        imageKind: TourImageKind.asset,
        initialLongitude: 0,
        initialLatitude: -3,
        hotspots: const [
          VirtualTourHotspot(
            label: 'City view',
            description: 'Look out over the surrounding skyline.',
            longitude: 2,
            latitude: 5,
          ),
          VirtualTourHotspot(
            label: 'Seating',
            description: 'A small seating area for a quiet pause.',
            longitude: -55,
            latitude: -5,
          ),
          VirtualTourHotspot(
            label: 'Evening light',
            description: 'A lovely spot to enjoy the softer light at dusk.',
            longitude: 74,
            latitude: -2,
          ),
        ],
        attribution: 'ESO/P. Horálek',
        license: 'CC BY 4.0',
        sourceUrl: Uri.parse(
          'https://cdn.eso.org/images/large/2018_04_23_ES_Supernova_VT_Roof-CC.jpg',
        ),
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
