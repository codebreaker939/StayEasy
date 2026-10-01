import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stayeasy/app/stayeasy_app.dart';
import 'package:stayeasy/core/theme/stayeasy_breakpoints.dart';
import 'package:stayeasy/core/theme/stayeasy_colors.dart';

void main() {
  testWidgets('boots with the StayEasy theme and token demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: StayEasyApp()));

    expect(find.text('StayEasy'), findsOneWidget);
    expect(find.text('Design system preview'), findsOneWidget);
    expect(find.text('Primary action'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, StayEasyColors.primary);
  });

  test('layout classification uses Flutter implementation thresholds', () {
    expect(StayEasyBreakpoints.classify(390), StayEasyLayoutSize.compact);
    expect(StayEasyBreakpoints.classify(599), StayEasyLayoutSize.compact);
    expect(StayEasyBreakpoints.classify(600), StayEasyLayoutSize.medium);
    expect(StayEasyBreakpoints.classify(834), StayEasyLayoutSize.medium);
    expect(StayEasyBreakpoints.classify(1023), StayEasyLayoutSize.medium);
    expect(StayEasyBreakpoints.classify(1024), StayEasyLayoutSize.expanded);
    expect(StayEasyBreakpoints.classify(1440), StayEasyLayoutSize.expanded);
  });

  test('Figma widths remain visual reference widths', () {
    expect(StayEasyBreakpoints.mobileReferenceWidth, 390);
    expect(StayEasyBreakpoints.tabletReferenceWidth, 834);
    expect(StayEasyBreakpoints.webReferenceWidth, 1440);
  });
}
