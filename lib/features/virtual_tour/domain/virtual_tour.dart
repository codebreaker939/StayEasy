import 'package:flutter/foundation.dart';

enum TourImageKind { asset, network }

@immutable
class VirtualTourHotspot {
  const VirtualTourHotspot({
    required this.label,
    this.description,
    required this.longitude,
    required this.latitude,
  });

  final String label;
  final String? description;
  final double longitude;
  final double latitude;
}

@immutable
class VirtualTourSpace {
  const VirtualTourSpace({
    required this.id,
    required this.label,
    required this.imageSource,
    required this.imageKind,
    this.initialLongitude = 0,
    this.initialLatitude = 0,
    this.initialZoom = 1,
    this.hotspots = const [],
    this.attribution,
    this.license,
    this.sourceUrl,
  });

  final String id;
  final String label;
  final String imageSource;
  final TourImageKind imageKind;
  final double initialLongitude;
  final double initialLatitude;
  final double initialZoom;
  final List<VirtualTourHotspot> hotspots;
  final String? attribution;
  final String? license;
  final Uri? sourceUrl;
}

@immutable
class VirtualTour {
  const VirtualTour({required this.roomId, required this.spaces});

  final String roomId;
  final List<VirtualTourSpace> spaces;
}
