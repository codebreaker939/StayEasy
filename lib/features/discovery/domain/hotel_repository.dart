import 'models/hotel.dart';
import 'models/room.dart';

abstract interface class HotelRepository {
  Future<List<Hotel>> getHotels();
  Future<Hotel?> getHotel(String id);
  Future<List<Room>> getRooms({String? hotelId});
  Future<Room?> getRoom(String id);
}
