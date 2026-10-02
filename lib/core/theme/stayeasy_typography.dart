import 'package:flutter/material.dart';

abstract final class StayEasyTypography {
  static const String operationalFont = 'Manrope';
  static const String editorialFont = 'DM Serif Display';

  static const TextStyle editorialHero = TextStyle(
    fontFamily: editorialFont,
    fontSize: 40,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0,
  );
  static const TextStyle displayLarge = TextStyle(
    fontFamily: operationalFont,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: operationalFont,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 42 / 34,
    letterSpacing: 0,
  );
  static const TextStyle headingH1 = TextStyle(
    fontFamily: operationalFont,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 38 / 30,
    letterSpacing: 0,
  );
  static const TextStyle headingH2 = TextStyle(
    fontFamily: operationalFont,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 34 / 26,
    letterSpacing: 0,
  );
  static const TextStyle headingH3 = TextStyle(
    fontFamily: operationalFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 30 / 22,
    letterSpacing: 0,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: operationalFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: operationalFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 26 / 18,
    letterSpacing: 0,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: operationalFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: operationalFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: operationalFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle labelLarge = TextStyle(
    fontFamily: operationalFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: operationalFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: operationalFont,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16 / 11,
    letterSpacing: 0,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    headlineLarge: headingH1,
    headlineMedium: headingH2,
    headlineSmall: headingH3,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: caption,
  );
}
