import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stayeasy/app/stayeasy_app.dart';

void main() {
  testWidgets('boots into the Explore foundation screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: StayEasyApp()));

    expect(find.text('StayEasy'), findsOneWidget);
    expect(find.text('The Flutter foundation is ready.'), findsOneWidget);
  });
}
