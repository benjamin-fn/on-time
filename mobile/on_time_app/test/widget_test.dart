// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:on_time_app/main.dart';

void main() {
  testWidgets('On Time starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const OnTimeApp());

    expect(find.text('On Time'), findsOneWidget);
    expect(find.text('Kom i tid. Ha kul.'), findsOneWidget);
    expect(find.text('Skapa träff'), findsOneWidget);
  });
}