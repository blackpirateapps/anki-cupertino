import 'package:flutter/cupertino.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/timer_mode.dart';
import '../widgets/glass_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/progress_ring.dart';

class FocusTab extends StatelessWidget {
  const FocusTab({
    required this.controller,
    required this.onResetRequested,
    required this.onChooseTask,
    super.key,
  });

  final PomodoroController controller;
  final Future<void> Function() onResetRequested;
  final Future<void> Function() onChooseTask;

  @override
  Widget build(BuildContext context) {
    final minutes =
        (controller.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds =
        (controller.remainingSeconds % 60).toString().padLeft(2, '0');
    final sliderValue =
        controller.minutesForMode(controller.timerMode).toDouble();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        GlassCard(
          child: Column(
            children: <Widget>[
              CupertinoSlidingSegmentedControl<TimerMode>(
                groupValue: controller.timerMode,
                children: {
                  for (final mode in TimerMode.values)
                    mode: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(mode.label),
                    ),
                },
                onValueChanged: (mode) {
                  if (mode != null) {
                    controller.setTimerMode(mode);
                  }
                },
              ),
              const SizedBox(height: 28),
              ProgressRing(
                progress: controller.progress,
                color: controller.selectedProject.color,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$minutes:$seconds',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.selectedProject.name,
                      style: TextStyle(
                        color: controller.selectedProject.color,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.selectedTask?.title ?? 'No task selected',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey2,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${controller.timerMode.label} Minutes: ${sliderValue.round()}',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey2,
                    fontSize: 14,
                  ),
                ),
              ),
              CupertinoSlider(
                value: sliderValue,
                min: 1,
                max: 90,
                divisions: 89,
                onChanged: (value) {
                  controller.setModeMinutes(
                    controller.timerMode,
                    value.round(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: controller.toggleTimer,
                      child: Text(controller.isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    onPressed: onResetRequested,
                    child: const Text('Reset'),
                  ),
                ],
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
                'Current Project',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: controller.appState.selectedProjectId,
                children: {
                  for (final project in controller.projects)
                    project.id: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(project.name),
                    ),
                },
                onValueChanged: (projectId) {
                  if (projectId != null) {
                    controller.selectProject(projectId);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Task',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onChooseTask,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        controller.selectedTask?.title ?? 'Choose task',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_down),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  MetricTile(
                    label: 'Today',
                    value: '${controller.todayMinutes()} min',
                  ),
                  const SizedBox(width: 12),
                  MetricTile(
                    label: 'Week',
                    value: '${controller.weekMinutes()} min',
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
