import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_state.dart';
import '../models/persisted_snapshot.dart';
import '../models/project.dart';
import '../models/session_record.dart';
import '../models/task_item.dart';
import '../models/timer_mode.dart';
import '../models/timer_snapshot.dart';

abstract class AppStorage {
  const AppStorage();

  Future<PersistedSnapshot> readSnapshot();

  Future<void> writeSnapshot(PersistedSnapshot snapshot);

  String encodeSnapshot(PersistedSnapshot snapshot) {
    return jsonEncode(snapshot.toJson());
  }

  PersistedSnapshot decodeSnapshot(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PersistedSnapshot.fromJson(json);
  }
}

class SqliteAppStorage extends AppStorage {
  const SqliteAppStorage();

  static const _dbName = 'anki_cupertino.db';
  static const _dbVersion = 1;

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE timer_state (
            id INTEGER PRIMARY KEY,
            mode TEXT NOT NULL,
            remaining_seconds INTEGER NOT NULL,
            is_running INTEGER NOT NULL,
            focus_cycles INTEGER NOT NULL,
            end_time_iso TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color_value INTEGER NOT NULL,
            completed_sessions INTEGER NOT NULL,
            completed_minutes INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            title TEXT NOT NULL,
            completed_sessions INTEGER NOT NULL,
            completed_minutes INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            task_id TEXT,
            completed_at_iso TEXT NOT NULL,
            minutes INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<PersistedSnapshot> readSnapshot() async {
    final db = await _openDatabase();
    final settingsRows = await db.query('app_settings');
    final settings = <String, String?>{
      for (final row in settingsRows)
        row['key'] as String: row['value'] as String?,
    };
    final projectRows = await db.query('projects');
    final taskRows = await db.query('tasks');
    final sessionRows = await db.query(
      'sessions',
      orderBy: 'completed_at_iso DESC',
    );
    final timerRows = await db.query('timer_state', where: 'id = 1');

    if (projectRows.isEmpty && settingsRows.isEmpty && timerRows.isEmpty) {
      return PersistedSnapshot.initial();
    }

    final projects = projectRows.map((row) {
      return Project(
        id: row['id'] as String,
        name: row['name'] as String,
        colorValue: row['color_value'] as int,
        completedSessions: row['completed_sessions'] as int,
        completedMinutes: row['completed_minutes'] as int,
      );
    }).toList();

    final tasks = taskRows.map((row) {
      return TaskItem(
        id: row['id'] as String,
        projectId: row['project_id'] as String,
        title: row['title'] as String,
        completedSessions: row['completed_sessions'] as int,
        completedMinutes: row['completed_minutes'] as int,
      );
    }).toList();

    final sessions = sessionRows.map((row) {
      return SessionRecord(
        id: row['id'] as String,
        projectId: row['project_id'] as String,
        taskId: row['task_id'] as String?,
        completedAtIso: row['completed_at_iso'] as String,
        minutes: row['minutes'] as int,
      );
    }).toList();

    final appState = AppState(
      projects: projects.isEmpty ? AppState.initial().projects : projects,
      tasks: tasks,
      records: sessions,
      selectedProjectId: settings['selected_project_id'] ??
          (projects.isNotEmpty ? projects.first.id : 'starter'),
      selectedTaskId: settings['selected_task_id'],
      focusMinutes: int.tryParse(settings['focus_minutes'] ?? '') ?? 25,
      shortBreakMinutes:
          int.tryParse(settings['short_break_minutes'] ?? '') ?? 5,
      longBreakMinutes: int.tryParse(settings['long_break_minutes'] ?? '') ?? 15,
    );

    final timerSnapshot = timerRows.isEmpty
        ? TimerSnapshot.initial(focusMinutes: appState.focusMinutes)
        : TimerSnapshot(
            mode: _modeFromStorage(timerRows.first['mode'] as String),
            remainingSeconds: timerRows.first['remaining_seconds'] as int,
            isRunning: (timerRows.first['is_running'] as int) == 1,
            focusCycles: timerRows.first['focus_cycles'] as int,
            endTimeIso: timerRows.first['end_time_iso'] as String?,
          );

    return PersistedSnapshot(appState: appState, timerSnapshot: timerSnapshot);
  }

  @override
  Future<void> writeSnapshot(PersistedSnapshot snapshot) async {
    final db = await _openDatabase();
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete('app_settings');
      batch.delete('timer_state');
      batch.delete('projects');
      batch.delete('tasks');
      batch.delete('sessions');

      final settings = <String, String?>{
        'selected_project_id': snapshot.appState.selectedProjectId,
        'selected_task_id': snapshot.appState.selectedTaskId,
        'focus_minutes': snapshot.appState.focusMinutes.toString(),
        'short_break_minutes': snapshot.appState.shortBreakMinutes.toString(),
        'long_break_minutes': snapshot.appState.longBreakMinutes.toString(),
      };
      for (final entry in settings.entries) {
        batch.insert('app_settings', <String, Object?>{
          'key': entry.key,
          'value': entry.value,
        });
      }

      batch.insert('timer_state', <String, Object?>{
        'id': 1,
        'mode': snapshot.timerSnapshot.mode.storageValue,
        'remaining_seconds': snapshot.timerSnapshot.remainingSeconds,
        'is_running': snapshot.timerSnapshot.isRunning ? 1 : 0,
        'focus_cycles': snapshot.timerSnapshot.focusCycles,
        'end_time_iso': snapshot.timerSnapshot.endTimeIso,
      });

      for (final project in snapshot.appState.projects) {
        batch.insert('projects', <String, Object?>{
          'id': project.id,
          'name': project.name,
          'color_value': project.colorValue,
          'completed_sessions': project.completedSessions,
          'completed_minutes': project.completedMinutes,
        });
      }

      for (final task in snapshot.appState.tasks) {
        batch.insert('tasks', <String, Object?>{
          'id': task.id,
          'project_id': task.projectId,
          'title': task.title,
          'completed_sessions': task.completedSessions,
          'completed_minutes': task.completedMinutes,
        });
      }

      for (final record in snapshot.appState.records) {
        batch.insert('sessions', <String, Object?>{
          'id': record.id,
          'project_id': record.projectId,
          'task_id': record.taskId,
          'completed_at_iso': record.completedAtIso,
          'minutes': record.minutes,
        });
      }

      await batch.commit(noResult: true);
    });
  }

  TimerMode _modeFromStorage(String value) {
    switch (value) {
      case 'shortBreak':
        return TimerMode.shortBreak;
      case 'longBreak':
        return TimerMode.longBreak;
      case 'focus':
      default:
        return TimerMode.focus;
    }
  }
}
