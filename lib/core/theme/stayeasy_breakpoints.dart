enum StayEasyLayoutSize { compact, medium, expanded }

abstract final class StayEasyBreakpoints {
  // Flutter implementation thresholds, not values specified by Figma.
  static const double compactEnd = 600;
  static const double expandedStart = 1024;

  // Figma validation/reference widths only. Keep layouts fluid between them.
  static const double mobileReferenceWidth = 390;
  static const double tabletReferenceWidth = 834;
  static const double webReferenceWidth = 1440;

  static StayEasyLayoutSize classify(double width) {
    if (width < compactEnd) return StayEasyLayoutSize.compact;
    if (width < expandedStart) return StayEasyLayoutSize.medium;
    return StayEasyLayoutSize.expanded;
  }
}
