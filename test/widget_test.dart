import 'package:anki_cupertino/main.dart';
import 'package:anki_cupertino/models/app_state.dart';
import 'package:anki_cupertino/models/project.dart';
import 'package:anki_cupertino/models/persisted_snapshot.dart';
import 'package:anki_cupertino/models/task_item.dart';
import 'package:anki_cupertino/services/app_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends AppStorage {
  const _MemoryStorage([this.snapshot]);

  final PersistedSnapshot? snapshot;

  @override
  Future<PersistedSnapshot> readSnapshot() async {
    return snapshot ?? PersistedSnapshot.initial();
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

  testWidgets('focus task picker opens selected project page', (tester) async {
    const project = Project(
      id: 'starter',
      name: 'Deep Work',
      colorValue: 0xFFFF9F0A,
      completedSessions: 3,
      completedMinutes: 75,
    );
    const task = TaskItem(
      id: 'task-1',
      projectId: 'starter',
      title: 'Write notes',
      completedSessions: 2,
      completedMinutes: 50,
    );
    final snapshot = PersistedSnapshot(
      appState: const AppState(
        projects: <Project>[project],
        tasks: <TaskItem>[task],
        records: [],
        selectedProjectId: 'starter',
        selectedTaskId: null,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
      ),
      timerSnapshot: PersistedSnapshot.initial().timerSnapshot,
    );

    await tester.pumpWidget(PomodoroApp(storage: _MemoryStorage(snapshot)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose task'));
    await tester.pumpAndSettle();

    expect(find.text('Focused in this project'), findsOneWidget);
    expect(find.text('Write notes'), findsOneWidget);

    await tester.tap(find.text('Write notes'));
    await tester.pumpAndSettle();

    expect(find.text('No task selected'), findsNothing);
    expect(find.text('Write notes'), findsWidgets);
  });
}
