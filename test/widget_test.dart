import 'package:anki_cupertino/main.dart';
import 'package:anki_cupertino/models/persisted_snapshot.dart';
import 'package:anki_cupertino/services/app_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends AppStorage {
  const _MemoryStorage();

  @override
  Future<PersistedSnapshot> readSnapshot() async {
    return PersistedSnapshot.initial();
  }

  @override
  Future<void> writeSnapshot(PersistedSnapshot snapshot) async {}
}

void main() {
  testWidgets('app renders main tabs', (tester) async {
    await tester.pumpWidget(const PomodoroApp(storage: _MemoryStorage()));
    await tester.pumpAndSettle();

    expect(find.text('Focus'), findsWidgets);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
