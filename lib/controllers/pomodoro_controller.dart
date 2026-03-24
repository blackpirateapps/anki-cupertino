import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_state.dart';
import '../models/daily_stat.dart';
import '../models/persisted_snapshot.dart';
import '../models/project.dart';
import '../models/session_record.dart';
import '../models/task_item.dart';
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
  List<TaskItem> get tasks => _appState.tasks;
  List<SessionRecord> get records => _appState.records;
  int get focusMinutes => _appState.focusMinutes;
  int get shortBreakMinutes => _appState.shortBreakMinutes;
  int get longBreakMinutes => _appState.longBreakMinutes;

  Project get selectedProject {
    return _appState.projects.firstWhere(
      (project) => project.id == _appState.selectedProjectId,
      orElse: () => _appState.projects.first,
    );
  }

  TaskItem? get selectedTask {
    final selectedTaskId = _appState.selectedTaskId;
    if (selectedTaskId == null) {
      return null;
    }
    for (final task in _appState.tasks) {
      if (task.id == selectedTaskId) {
        return task;
      }
    }
    return null;
  }

  double get progress {
    final totalSeconds = (minutesForMode(timerMode) * 60).clamp(1, 86400);
    return (1 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0).toDouble();
  }

  List<TaskItem> tasksForProject(String projectId) {
    return _appState.tasks.where((task) => task.projectId == projectId).toList();
  }

  Future<void> load() async {
    final snapshot = await _storage.readSnapshot();
    _appState = _normalizeAppState(snapshot.appState);
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
    final tasks = tasksForProject(projectId);
    _appState = _appState.copyWith(
      selectedProjectId: projectId,
      selectedTaskId: tasks.isNotEmpty ? tasks.first.id : null,
      clearSelectedTaskId: tasks.isEmpty,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> selectTask(String? taskId) async {
    if (taskId == null) {
      _appState = _appState.copyWith(clearSelectedTaskId: true);
    } else {
      _appState = _appState.copyWith(selectedTaskId: taskId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> upsertProject({
    Project? editing,
    required String name,
    required int colorValue,
  }) async {
    if (editing == null) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      _appState = _appState.copyWith(
        projects: <Project>[
          ..._appState.projects,
          Project(id: id, name: name, colorValue: colorValue),
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
    final remainingTasks = _appState.tasks
        .where((task) => task.projectId != project.id)
        .toList();
    final remainingRecords = _appState.records
        .where((record) => record.projectId != project.id)
        .toList();
    final nextSelectedProjectId = _appState.selectedProjectId == project.id
        ? remainingProjects.first.id
        : _appState.selectedProjectId;
    final nextTasks = remainingTasks
        .where((task) => task.projectId == nextSelectedProjectId)
        .toList();

    _appState = _appState.copyWith(
      projects: remainingProjects,
      tasks: remainingTasks,
      records: remainingRecords,
      selectedProjectId: nextSelectedProjectId,
      selectedTaskId: nextTasks.isNotEmpty ? nextTasks.first.id : null,
      clearSelectedTaskId: nextTasks.isEmpty,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> upsertTask({
    TaskItem? editing,
    required String projectId,
    required String title,
  }) async {
    if (editing == null) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final task = TaskItem(id: id, projectId: projectId, title: title);
      _appState = _appState.copyWith(tasks: <TaskItem>[..._appState.tasks, task]);
      if (_appState.selectedProjectId == projectId &&
          _appState.selectedTaskId == null) {
        _appState = _appState.copyWith(selectedTaskId: id);
      }
    } else {
      _appState = _appState.copyWith(
        tasks: _appState.tasks.map((task) {
          if (task.id != editing.id) {
            return task;
          }
          return task.copyWith(title: title);
        }).toList(),
      );
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTask(TaskItem task) async {
    final remainingTasks = _appState.tasks
        .where((candidate) => candidate.id != task.id)
        .toList();
    final updatedRecords = _appState.records.map((record) {
      if (record.taskId != task.id) {
        return record;
      }
      return SessionRecord(
        id: record.id,
        projectId: record.projectId,
        taskId: null,
        completedAtIso: record.completedAtIso,
        minutes: record.minutes,
      );
    }).toList();
    final replacementTasks = remainingTasks
        .where((candidate) => candidate.projectId == task.projectId)
        .toList();

    _appState = _appState.copyWith(
      tasks: remainingTasks,
      records: updatedRecords,
      selectedTaskId: _appState.selectedTaskId == task.id && replacementTasks.isNotEmpty
          ? replacementTasks.first.id
          : _appState.selectedTaskId,
      clearSelectedTaskId:
          _appState.selectedTaskId == task.id && replacementTasks.isEmpty,
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

  List<DailyStat> monthlyStats() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return List<DailyStat>.generate(daysInMonth, (index) {
      final day = DateTime(now.year, now.month, index + 1);
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

  Map<Project, int> todayProjectBreakdown() {
    final now = DateTime.now();
    final totalsByProject = <String, int>{};
    for (final record in _appState.records) {
      final date = record.completedAt;
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        totalsByProject.update(
          record.projectId,
          (value) => value + record.minutes,
          ifAbsent: () => record.minutes,
        );
      }
    }

    final result = <Project, int>{};
    for (final project in _appState.projects) {
      final minutes = totalsByProject[project.id];
      if (minutes != null && minutes > 0) {
        result[project] = minutes;
      }
    }
    return result;
  }

  List<Project> topProjects() {
    final copy = List<Project>.from(_appState.projects);
    copy.sort((a, b) => b.completedMinutes.compareTo(a.completedMinutes));
    return copy;
  }

  List<TaskItem> topTasks() {
    final copy = List<TaskItem>.from(_appState.tasks);
    copy.sort((a, b) => b.completedMinutes.compareTo(a.completedMinutes));
    return copy;
  }

  String exportData() {
    return _storage.encodeSnapshot(
      PersistedSnapshot(appState: _appState, timerSnapshot: _timerSnapshot),
    );
  }

  Future<String?> importData(String raw) async {
    try {
      final snapshot = _storage.decodeSnapshot(raw);
      _stopTicker();
      _appState = _normalizeAppState(snapshot.appState);
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
      _timerSnapshot =
          _timerSnapshot.copyWith(isRunning: false, clearEndTime: true);
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
      final updatedTasks = _appState.tasks.map((task) {
        if (task.id != _appState.selectedTaskId) {
          return task;
        }
        return task.copyWith(
          completedSessions: task.completedSessions + 1,
          completedMinutes: task.completedMinutes + completedMinutes,
        );
      }).toList();
      final updatedRecords = <SessionRecord>[
        SessionRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          projectId: _appState.selectedProjectId,
          taskId: _appState.selectedTaskId,
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
        tasks: updatedTasks,
        records: updatedRecords,
      );
      _timerSnapshot = _timerSnapshot.copyWith(
        mode: nextMode,
        remainingSeconds: minutesForMode(nextMode) * 60,
        isRunning: false,
        focusCycles: nextCycles,
        clearEndTime: true,
      );
      final taskName = selectedTask?.title;
      _pendingAlert = taskName == null
          ? fromRestore
              ? 'Focus session finished while the app was closed. Break time.'
              : 'Session complete. Break time.'
          : fromRestore
              ? 'Task "$taskName" got a completed focus session while the app was closed. Break time.'
              : 'Task "$taskName" logged a focus session. Break time.';
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
      PersistedSnapshot(appState: _appState, timerSnapshot: _timerSnapshot),
    );
  }

  AppState _normalizeAppState(AppState state) {
    final selectedProjectId = state.projects.any(
      (project) => project.id == state.selectedProjectId,
    )
        ? state.selectedProjectId
        : state.projects.first.id;
    final projectTasks =
        state.tasks.where((task) => task.projectId == selectedProjectId).toList();
    final selectedTaskId = state.selectedTaskId != null &&
            projectTasks.any((task) => task.id == state.selectedTaskId)
        ? state.selectedTaskId
        : projectTasks.isNotEmpty
            ? projectTasks.first.id
            : null;
    return state.copyWith(
      selectedProjectId: selectedProjectId,
      selectedTaskId: selectedTaskId,
      clearSelectedTaskId: selectedTaskId == null,
    );
  }
}
