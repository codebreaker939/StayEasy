abstract final class AppRoutes {
  static const explore = '/';
  static const exploreName = 'explore';
  static const search = '/search';
  static const searchName = 'search';
  static const hotel = '/hotel/:hotelId';
  static const hotelName = 'hotel-details';
  static const room = '/room/:roomId';
  static const roomName = 'room-details';

  static String hotelPath(String id) => '/hotel/$id';
  static String roomPath(String id) => '/room/$id';
}
