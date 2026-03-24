class SessionRecord {
  const SessionRecord({
    required this.projectId,
    required this.completedAtIso,
    required this.minutes,
  });

  final String projectId;
  final String completedAtIso;
  final int minutes;

  DateTime get completedAt => DateTime.parse(completedAtIso);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'projectId': projectId,
      'completedAtIso': completedAtIso,
      'minutes': minutes,
    };
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      projectId: json['projectId'] as String,
      completedAtIso: json['completedAtIso'] as String,
      minutes: json['minutes'] as int,
    );
  }
}

