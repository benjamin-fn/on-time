import 'package:flutter_test/flutter_test.dart';
import 'package:on_time_app/main.dart';

void main() {
  testWidgets(
    'On Time visar login när användaren inte är inloggad',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const OnTimeApp(
          savedUser: null,
        ),
      );

      expect(find.text('On Time'), findsOneWidget);
      expect(find.text('Kom i tid. Ha kul.'), findsOneWidget);
      expect(find.text('Logga in'), findsOneWidget);
      expect(
        find.text('Har du inget konto? Skapa konto'),
        findsOneWidget,
      );
    },
  );
}