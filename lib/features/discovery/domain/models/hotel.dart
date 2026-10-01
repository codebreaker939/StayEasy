class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    required this.image,
    this.detailImage,
    required this.description,
    required this.amenities,
    required this.tags,
    this.isSaved = false,
  });

  final String id;
  final String name;
  final String city;
  final String location;
  final double rating;
  final int reviewCount;
  final int pricePerNight;
  final String image;
  final String? detailImage;
  final String description;
  final List<String> amenities;
  final List<String> tags;
  final bool isSaved;
}
