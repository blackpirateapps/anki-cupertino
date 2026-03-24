import 'package:flutter/cupertino.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/timer_mode.dart';
import '../widgets/glass_card.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    required this.controller,
    required this.onExport,
    required this.onImport,
    super.key,
  });

  final PomodoroController controller;
  final Future<void> Function() onExport;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Default Durations',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _DurationSlider(
                label: 'Focus',
                minutes: controller.focusMinutes,
                onChanged: (value) {
                  controller.setModeMinutes(TimerMode.focus, value.round());
                },
              ),
              _DurationSlider(
                label: 'Short Break',
                minutes: controller.shortBreakMinutes,
                onChanged: (value) {
                  controller.setModeMinutes(TimerMode.shortBreak, value.round());
                },
              ),
              _DurationSlider(
                label: 'Long Break',
                minutes: controller.longBreakMinutes,
                onChanged: (value) {
                  controller.setModeMinutes(TimerMode.longBreak, value.round());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Backup',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Export your projects, statistics, and timer state as JSON, or import a saved snapshot.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: onExport,
                      child: const Text('Export'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      onPressed: onImport,
                      child: const Text('Import'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$label: $minutes min',
            style: const TextStyle(
              color: CupertinoColors.systemGrey2,
              fontSize: 14,
            ),
          ),
          CupertinoSlider(
            value: minutes.toDouble(),
            min: 1,
            max: 90,
            divisions: 89,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

