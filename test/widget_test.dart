import 'package:anki_cupertino/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders main tabs', (tester) async {
    await tester.pumpWidget(const PomodoroApp());
    await tester.pump();

    expect(find.text('Focus'), findsWidgets);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
