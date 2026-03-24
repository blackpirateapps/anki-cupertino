class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.completedAtIso,
    required this.minutes,
  });

  final String id;
  final String projectId;
  final String? taskId;
  final String completedAtIso;
  final int minutes;

  DateTime get completedAt => DateTime.parse(completedAtIso);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'taskId': taskId,
      'completedAtIso': completedAtIso,
      'minutes': minutes,
    };
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      projectId: json['projectId'] as String,
      taskId: json['taskId'] as String?,
      completedAtIso: json['completedAtIso'] as String,
      minutes: json['minutes'] as int,
    );
  }
}
