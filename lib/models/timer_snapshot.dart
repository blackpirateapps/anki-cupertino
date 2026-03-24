import 'timer_mode.dart';

class TimerSnapshot {
  const TimerSnapshot({
    required this.mode,
    required this.remainingSeconds,
    required this.isRunning,
    required this.focusCycles,
    this.endTimeIso,
  });

  final TimerMode mode;
  final int remainingSeconds;
  final bool isRunning;
  final int focusCycles;
  final String? endTimeIso;

  DateTime? get endTime =>
      endTimeIso == null ? null : DateTime.parse(endTimeIso!);

  TimerSnapshot copyWith({
    TimerMode? mode,
    int? remainingSeconds,
    bool? isRunning,
    int? focusCycles,
    String? endTimeIso,
    bool clearEndTime = false,
  }) {
    return TimerSnapshot(
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      focusCycles: focusCycles ?? this.focusCycles,
      endTimeIso: clearEndTime ? null : endTimeIso ?? this.endTimeIso,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode.storageValue,
      'remainingSeconds': remainingSeconds,
      'isRunning': isRunning,
      'focusCycles': focusCycles,
      'endTimeIso': endTimeIso,
    };
  }

  factory TimerSnapshot.initial({required int focusMinutes}) {
    return TimerSnapshot(
      mode: TimerMode.focus,
      remainingSeconds: focusMinutes * 60,
      isRunning: false,
      focusCycles: 0,
    );
  }

  factory TimerSnapshot.fromJson(Map<String, dynamic> json) {
    return TimerSnapshot(
      mode: TimerModeX.fromStorageValue(json['mode'] as String? ?? 'focus'),
      remainingSeconds: json['remainingSeconds'] as int? ?? 25 * 60,
      isRunning: json['isRunning'] as bool? ?? false,
      focusCycles: json['focusCycles'] as int? ?? 0,
      endTimeIso: json['endTimeIso'] as String?,
    );
  }
}

