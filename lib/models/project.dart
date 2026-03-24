import 'package:flutter/cupertino.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.colorValue,
    this.completedSessions = 0,
    this.completedMinutes = 0,
  });

  final String id;
  final String name;
  final int colorValue;
  final int completedSessions;
  final int completedMinutes;

  Color get color => Color(colorValue);

  Project copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? completedSessions,
    int? completedMinutes,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      completedSessions: completedSessions ?? this.completedSessions,
      completedMinutes: completedMinutes ?? this.completedMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'completedSessions': completedSessions,
      'completedMinutes': completedMinutes,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      completedSessions: json['completedSessions'] as int? ?? 0,
      completedMinutes: json['completedMinutes'] as int? ?? 0,
    );
  }
}

