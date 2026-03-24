import 'package:anki_cupertino/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders main tabs', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const PomodoroApp());
    await tester.pumpAndSettle();

    expect(find.text('Focus'), findsWidgets);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
