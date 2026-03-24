import 'app_state.dart';
import 'timer_snapshot.dart';

class PersistedSnapshot {
  const PersistedSnapshot({
    required this.appState,
    required this.timerSnapshot,
  });

  final AppState appState;
  final TimerSnapshot timerSnapshot;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'appState': appState.toJson(),
      'timerSnapshot': timerSnapshot.toJson(),
    };
  }

  factory PersistedSnapshot.initial() {
    final appState = AppState.initial();
    return PersistedSnapshot(
      appState: appState,
      timerSnapshot: TimerSnapshot.initial(focusMinutes: appState.focusMinutes),
    );
  }

  factory PersistedSnapshot.fromJson(Map<String, dynamic> json) {
    final appJson =
        Map<String, dynamic>.from(json['appState'] as Map? ?? <String, dynamic>{});
    final timerJson = Map<String, dynamic>.from(
      json['timerSnapshot'] as Map? ?? <String, dynamic>{},
    );
    final appState = AppState.fromJson(appJson);
    return PersistedSnapshot(
      appState: appState,
      timerSnapshot: timerJson.isEmpty
          ? TimerSnapshot.initial(focusMinutes: appState.focusMinutes)
          : TimerSnapshot.fromJson(timerJson),
    );
  }
}

