import 'package:flutter/painting.dart';

abstract final class StayEasyElevation {
  static const List<BoxShadow> level0 = [];

  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0F000000), // Figma black at 6% opacity.
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x14000000), // Figma black at 8% opacity.
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x1F000000), // Figma black at 12% opacity.
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}
