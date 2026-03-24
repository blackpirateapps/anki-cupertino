import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_state.dart';
import '../models/daily_stat.dart';
import '../models/persisted_snapshot.dart';
import '../models/project.dart';
import '../models/session_record.dart';
import '../models/timer_mode.dart';
import '../models/timer_snapshot.dart';
import '../services/app_storage.dart';

class PomodoroController extends ChangeNotifier {
  PomodoroController({required AppStorage storage}) : _storage = storage;

  static const projectColors = <int>[
    0xFFFF9F0A,
    0xFF30D158,
    0xFF64D2FF,
    0xFFBF5AF2,
    0xFFFF453A,
    0xFFFFD60A,
  ];

  final AppStorage _storage;

  AppState _appState = AppState.initial();
  TimerSnapshot _timerSnapshot = TimerSnapshot.initial(focusMinutes: 25);
  Timer? _ticker;
  bool _isLoaded = false;
  String? _pendingAlert;

  bool get isLoaded => _isLoaded;
  AppState get appState => _appState;
  TimerMode get timerMode => _timerSnapshot.mode;
  bool get isRunning => _timerSnapshot.isRunning;
  int get remainingSeconds => _timerSnapshot.remainingSeconds;
  List<Project> get projects => _appState.projects;
  List<SessionRecord> get records => _appState.records;

  Project get selectedProject {
    return _appState.projects.firstWhere(
      (project) => project.id == _appState.selectedProjectId,
      orElse: () => _appState.projects.first,
    );
  }

  int get focusMinutes => _appState.focusMinutes;
  int get shortBreakMinutes => _appState.shortBreakMinutes;
  int get longBreakMinutes => _appState.longBreakMinutes;

  double get progress {
    final totalSeconds = (minutesForMode(timerMode) * 60).clamp(1, 86400);
    return (1 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0).toDouble();
  }

  Future<void> load() async {
    final snapshot = await _storage.readSnapshot();
    _appState = snapshot.appState;
    _timerSnapshot = snapshot.timerSnapshot;
    await _restoreTimerState();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> handleAppResumed() async {
    await _restoreTimerState();
    notifyListeners();
  }

  Future<void> handleAppPaused() async {
    await _persist();
  }

  Future<void> toggleTimer() async {
    if (isRunning) {
      await pauseTimer();
      return;
    }

    final endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
    _timerSnapshot = _timerSnapshot.copyWith(
      isRunning: true,
      endTimeIso: endTime.toIso8601String(),
    );
    _startTicker();
    notifyListeners();
    await _persist();
  }

  Future<void> pauseTimer() async {
    _syncRemainingWithClock();
    _stopTicker();
    _timerSnapshot = _timerSnapshot.copyWith(
      isRunning: false,
      clearEndTime: true,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> resetTimer() async {
    _stopTicker();
    _timerSnapshot = _timerSnapshot.copyWith(
      isRunning: false,
      remainingSeconds: minutesForMode(timerMode) * 60,
      clearEndTime: true,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> setTimerMode(TimerMode mode) async {
    _stopTicker();
    _timerSnapshot = _timerSnapshot.copyWith(
      mode: mode,
      isRunning: false,
      remainingSeconds: minutesForMode(mode) * 60,
      clearEndTime: true,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> setModeMinutes(TimerMode mode, int minutes) async {
    _appState = _appState.copyWith(
      focusMinutes: mode == TimerMode.focus ? minutes : null,
      shortBreakMinutes: mode == TimerMode.shortBreak ? minutes : null,
      longBreakMinutes: mode == TimerMode.longBreak ? minutes : null,
    );
    if (timerMode == mode) {
      _stopTicker();
      _timerSnapshot = _timerSnapshot.copyWith(
        isRunning: false,
        remainingSeconds: minutes * 60,
        clearEndTime: true,
      );
    }
    notifyListeners();
    await _persist();
  }

  Future<void> selectProject(String projectId) async {
    _appState = _appState.copyWith(selectedProjectId: projectId);
    notifyListeners();
    await _persist();
  }

  Future<void> upsertProject({
    Project? editing,
    required String name,
    required int colorValue,
  }) async {
    if (editing == null) {
      _appState = _appState.copyWith(
        projects: <Project>[
          ..._appState.projects,
          Project(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name,
            colorValue: colorValue,
          ),
        ],
      );
    } else {
      _appState = _appState.copyWith(
        projects: _appState.projects.map((project) {
          if (project.id != editing.id) {
            return project;
          }
          return project.copyWith(name: name, colorValue: colorValue);
        }).toList(),
      );
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteProject(Project project) async {
    if (_appState.projects.length == 1) {
      return;
    }

    final remainingProjects = _appState.projects
        .where((candidate) => candidate.id != project.id)
        .toList();
    final nextSelected = _appState.selectedProjectId == project.id
        ? remainingProjects.first.id
        : _appState.selectedProjectId;

    _appState = _appState.copyWith(
      projects: remainingProjects,
      selectedProjectId: nextSelected,
      records: _appState.records
          .where((record) => record.projectId != project.id)
          .toList(),
    );
    notifyListeners();
    await _persist();
  }

  int minutesForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return _appState.focusMinutes;
      case TimerMode.shortBreak:
        return _appState.shortBreakMinutes;
      case TimerMode.longBreak:
        return _appState.longBreakMinutes;
    }
  }

  int todayMinutes() {
    final now = DateTime.now();
    return _appState.records
        .where((record) {
          final date = record.completedAt;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<int>(0, (sum, record) => sum + record.minutes);
  }

  int weekMinutes() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _appState.records
        .where((record) {
          final date = record.completedAt;
          return !date.isBefore(start) && date.isBefore(end);
        })
        .fold<int>(0, (sum, record) => sum + record.minutes);
  }

  List<DailyStat> dailyStats() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return List<DailyStat>.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final minutes = _appState.records
          .where((record) {
            final date = record.completedAt;
            return date.year == day.year &&
                date.month == day.month &&
                date.day == day.day;
          })
          .fold<int>(0, (sum, record) => sum + record.minutes);
      return DailyStat(day: day, minutes: minutes);
    });
  }

  List<Project> topProjects() {
    final copy = List<Project>.from(_appState.projects);
    copy.sort((a, b) => b.completedMinutes.compareTo(a.completedMinutes));
    return copy;
  }

  String exportData() {
    return _storage.encodeSnapshot(
      PersistedSnapshot(
        appState: _appState,
        timerSnapshot: _timerSnapshot,
      ),
    );
  }

  Future<String?> importData(String raw) async {
    try {
      final snapshot = _storage.decodeSnapshot(raw);
      _stopTicker();
      _appState = snapshot.appState;
      _timerSnapshot = snapshot.timerSnapshot;
      await _restoreTimerState();
      notifyListeners();
      await _persist();
      return null;
    } catch (_) {
      return 'Invalid import data.';
    }
  }

  String? consumePendingAlert() {
    final message = _pendingAlert;
    _pendingAlert = null;
    return message;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  Future<void> _restoreTimerState() async {
    if (!_timerSnapshot.isRunning || _timerSnapshot.endTime == null) {
      _timerSnapshot = _timerSnapshot.copyWith(isRunning: false, clearEndTime: true);
      return;
    }

    _syncRemainingWithClock();
    if (_timerSnapshot.remainingSeconds <= 0) {
      await _completeSession(fromRestore: true);
      return;
    }
    _startTicker();
  }

  void _startTicker() {
    _stopTicker();
    if (!_timerSnapshot.isRunning) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRemainingWithClock();
      if (_timerSnapshot.remainingSeconds <= 0) {
        _completeSession();
        return;
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _syncRemainingWithClock() {
    final endTime = _timerSnapshot.endTime;
    if (!_timerSnapshot.isRunning || endTime == null) {
      return;
    }
    final seconds = endTime.difference(DateTime.now()).inSeconds;
    _timerSnapshot = _timerSnapshot.copyWith(
      remainingSeconds: seconds <= 0 ? 0 : seconds,
    );
  }

  Future<void> _completeSession({bool fromRestore = false}) async {
    _stopTicker();
    final completedMode = timerMode;
    final completedMinutes = minutesForMode(completedMode);

    if (completedMode == TimerMode.focus) {
      final updatedProjects = _appState.projects.map((project) {
        if (project.id != _appState.selectedProjectId) {
          return project;
        }
        return project.copyWith(
          completedSessions: project.completedSessions + 1,
          completedMinutes: project.completedMinutes + completedMinutes,
        );
      }).toList();
      final updatedRecords = <SessionRecord>[
        SessionRecord(
          projectId: _appState.selectedProjectId,
          completedAtIso: DateTime.now().toIso8601String(),
          minutes: completedMinutes,
        ),
        ..._appState.records,
      ];
      final nextCycles = _timerSnapshot.focusCycles + 1;
      final nextMode =
          nextCycles % 4 == 0 ? TimerMode.longBreak : TimerMode.shortBreak;
      _appState = _appState.copyWith(
        projects: updatedProjects,
        records: updatedRecords,
      );
      _timerSnapshot = _timerSnapshot.copyWith(
        mode: nextMode,
        remainingSeconds: minutesForMode(nextMode) * 60,
        isRunning: false,
        focusCycles: nextCycles,
        clearEndTime: true,
      );
      _pendingAlert = fromRestore
          ? 'Focus session finished while the app was closed. Break time.'
          : 'Session complete. Break time.';
    } else {
      _timerSnapshot = _timerSnapshot.copyWith(
        mode: TimerMode.focus,
        remainingSeconds: minutesForMode(TimerMode.focus) * 60,
        isRunning: false,
        clearEndTime: true,
      );
      _pendingAlert = fromRestore
          ? 'Break finished while the app was closed. Ready to focus again.'
          : 'Session complete. Ready to focus again.';
    }

    notifyListeners();
    await _persist();
  }

  Future<void> _persist() {
    return _storage.writeSnapshot(
      PersistedSnapshot(
        appState: _appState,
        timerSnapshot: _timerSnapshot,
      ),
    );
  }
}

