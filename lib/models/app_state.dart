import 'project.dart';
import 'session_record.dart';
import 'task_item.dart';

class AppState {
  const AppState({
    required this.projects,
    required this.tasks,
    required this.records,
    required this.selectedProjectId,
    required this.selectedTaskId,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
  });

  final List<Project> projects;
  final List<TaskItem> tasks;
  final List<SessionRecord> records;
  final String selectedProjectId;
  final String? selectedTaskId;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  AppState copyWith({
    List<Project>? projects,
    List<TaskItem>? tasks,
    List<SessionRecord>? records,
    String? selectedProjectId,
    String? selectedTaskId,
    bool clearSelectedTaskId = false,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) {
    return AppState(
      projects: projects ?? this.projects,
      tasks: tasks ?? this.tasks,
      records: records ?? this.records,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      selectedTaskId: clearSelectedTaskId
          ? null
          : selectedTaskId ?? this.selectedTaskId,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'projects': projects.map((project) => project.toJson()).toList(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'records': records.map((record) => record.toJson()).toList(),
      'selectedProjectId': selectedProjectId,
      'selectedTaskId': selectedTaskId,
      'focusMinutes': focusMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
    };
  }

  static AppState initial() {
    const starterProject = Project(
      id: 'starter',
      name: 'Deep Work',
      colorValue: 0xFFFF9F0A,
    );
    return const AppState(
      projects: <Project>[starterProject],
      tasks: <TaskItem>[],
      records: <SessionRecord>[],
      selectedProjectId: 'starter',
      selectedTaskId: null,
      focusMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
    );
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    final rawProjects = (json['projects'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final rawTasks = (json['tasks'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final rawRecords = (json['records'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final projects = rawProjects.map(Project.fromJson).toList();
    final tasks = rawTasks.map(TaskItem.fromJson).toList();
    final selectedId = json['selectedProjectId'] as String? ??
        (projects.isNotEmpty ? projects.first.id : 'starter');
    final selectedTaskId = json['selectedTaskId'] as String?;

    return AppState(
      projects: projects.isNotEmpty ? projects : AppState.initial().projects,
      tasks: tasks,
      records: rawRecords.map(SessionRecord.fromJson).toList(),
      selectedProjectId: selectedId,
      selectedTaskId: selectedTaskId,
      focusMinutes: json['focusMinutes'] as int? ?? 25,
      shortBreakMinutes: json['shortBreakMinutes'] as int? ?? 5,
      longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
    );
  }
}
