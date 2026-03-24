import 'project.dart';
import 'session_record.dart';

class AppState {
  const AppState({
    required this.projects,
    required this.records,
    required this.selectedProjectId,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
  });

  final List<Project> projects;
  final List<SessionRecord> records;
  final String selectedProjectId;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  AppState copyWith({
    List<Project>? projects,
    List<SessionRecord>? records,
    String? selectedProjectId,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) {
    return AppState(
      projects: projects ?? this.projects,
      records: records ?? this.records,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'projects': projects.map((project) => project.toJson()).toList(),
      'records': records.map((record) => record.toJson()).toList(),
      'selectedProjectId': selectedProjectId,
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
      records: <SessionRecord>[],
      selectedProjectId: 'starter',
      focusMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
    );
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    final rawProjects = (json['projects'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final rawRecords = (json['records'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final projects = rawProjects.map(Project.fromJson).toList();
    final selectedId = json['selectedProjectId'] as String? ??
        (projects.isNotEmpty ? projects.first.id : 'starter');

    return AppState(
      projects: projects.isNotEmpty ? projects : AppState.initial().projects,
      records: rawRecords.map(SessionRecord.fromJson).toList(),
      selectedProjectId: selectedId,
      focusMinutes: json['focusMinutes'] as int? ?? 25,
      shortBreakMinutes: json['shortBreakMinutes'] as int? ?? 5,
      longBreakMinutes: json['longBreakMinutes'] as int? ?? 15,
    );
  }
}

