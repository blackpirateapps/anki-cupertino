class TaskItem {
  const TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.completedSessions = 0,
    this.completedMinutes = 0,
  });

  final String id;
  final String projectId;
  final String title;
  final int completedSessions;
  final int completedMinutes;

  TaskItem copyWith({
    String? id,
    String? projectId,
    String? title,
    int? completedSessions,
    int? completedMinutes,
  }) {
    return TaskItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      completedSessions: completedSessions ?? this.completedSessions,
      completedMinutes: completedMinutes ?? this.completedMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'title': title,
      'completedSessions': completedSessions,
      'completedMinutes': completedMinutes,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      completedSessions: json['completedSessions'] as int? ?? 0,
      completedMinutes: json['completedMinutes'] as int? ?? 0,
    );
  }
}
