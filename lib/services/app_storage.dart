import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';
import '../models/persisted_snapshot.dart';
import '../models/timer_snapshot.dart';

class AppStorage {
  const AppStorage();

  static const _storageKey = 'anki_cupertino_state_v2';
  static const _legacyStorageKey = 'anki_cupertino_state_v1';

  Future<PersistedSnapshot> readSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PersistedSnapshot.fromJson(json);
    }

    final legacyRaw = prefs.getString(_legacyStorageKey);
    if (legacyRaw == null || legacyRaw.isEmpty) {
      return PersistedSnapshot.initial();
    }

    final legacyJson = jsonDecode(legacyRaw) as Map<String, dynamic>;
    final appState = AppState.fromJson(legacyJson);
    return PersistedSnapshot(
      appState: appState,
      timerSnapshot: TimerSnapshot.initial(focusMinutes: appState.focusMinutes),
    );
  }

  Future<void> writeSnapshot(PersistedSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, encodeSnapshot(snapshot));
  }

  String encodeSnapshot(PersistedSnapshot snapshot) {
    return jsonEncode(snapshot.toJson());
  }

  PersistedSnapshot decodeSnapshot(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PersistedSnapshot.fromJson(json);
  }
}
