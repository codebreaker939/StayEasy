class Room {
  const Room({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.description,
    required this.pricePerNight,
    required this.capacity,
    required this.bedType,
    required this.size,
    required this.image,
    required this.amenities,
    this.available = true,
    this.virtualTourUrl,
  });

  final String id;
  final String hotelId;
  final String name;
  final String description;
  final int pricePerNight;
  final int capacity;
  final String bedType;
  final int size;
  final String image;
  final List<String> amenities;
  final bool available;
  final String? virtualTourUrl;
}
