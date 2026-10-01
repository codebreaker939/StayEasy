import 'package:flutter/material.dart';

abstract final class StayEasyTheme {
  // Temporary Material 3 seed; replace with Figma-derived StayEasy tokens.
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    useMaterial3: true,
  );
}
