import 'package:flutter/material.dart';

abstract final class StayEasyColors {
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F4F1);

  static const Color primary = Color(0xFF176B5B);
  static const Color primaryDark = Color(0xFF0D4F43);
  static const Color onPrimary = surface;
  static const Color accentWarm = Color(0xFFC85D3C);

  static const Color textPrimary = Color(0xFF171C1A);
  static const Color textSecondary = Color(0xFF68716D);
  static const Color border = Color(0xFFE1E5E2);

  static const Color success = Color(0xFF27835A);
  static const Color warning = Color(0xFFC58724);
  static const Color error = Color(0xFFB93A3A);

  // AI purple is intentionally a separate semantic color, not a Material role.
  static const Color aiAccent = Color(0xFF6657D9);
}
