import 'package:flutter/material.dart';

import 'stayeasy_colors.dart';
import 'stayeasy_typography.dart';

abstract final class StayEasyTheme {
  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: StayEasyColors.primary,
    onPrimary: StayEasyColors.onPrimary,
    primaryContainer: StayEasyColors.primaryDark,
    onPrimaryContainer: StayEasyColors.onPrimary,
    secondary: StayEasyColors.accentWarm,
    onSecondary: StayEasyColors.onPrimary,
    secondaryContainer: StayEasyColors.surfaceVariant,
    onSecondaryContainer: StayEasyColors.textPrimary,
    error: StayEasyColors.error,
    onError: StayEasyColors.onPrimary,
    surface: StayEasyColors.surface,
    onSurface: StayEasyColors.textPrimary,
    surfaceDim: StayEasyColors.background,
    surfaceBright: StayEasyColors.surface,
    surfaceContainerLowest: StayEasyColors.surface,
    surfaceContainerLow: StayEasyColors.background,
    surfaceContainer: StayEasyColors.surfaceVariant,
    surfaceContainerHigh: StayEasyColors.surfaceVariant,
    surfaceContainerHighest: StayEasyColors.surfaceVariant,
    onSurfaceVariant: StayEasyColors.textSecondary,
    outline: StayEasyColors.border,
    outlineVariant: StayEasyColors.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: StayEasyColors.textPrimary,
    onInverseSurface: StayEasyColors.surface,
    inversePrimary: StayEasyColors.primaryDark,
    surfaceTint: StayEasyColors.primary,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: StayEasyColors.background,
    canvasColor: StayEasyColors.background,
    textTheme: StayEasyTypography.textTheme,
  );
}
