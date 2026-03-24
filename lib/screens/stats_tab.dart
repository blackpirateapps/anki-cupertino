import 'package:flutter/cupertino.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/daily_stat.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_summary.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({
    required this.controller,
    super.key,
  });

  final PomodoroController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.dailyStats();
    final maxMinutes = stats.fold<int>(1, (max, stat) {
      return stat.minutes > max ? stat.minutes : max;
    });

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: GlassCard(
                child: StatSummary(
                  label: 'Today',
                  value: '${controller.todayMinutes()}',
                  suffix: 'min',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GlassCard(
                child: StatSummary(
                  label: 'This Week',
                  value: '${controller.weekMinutes()}',
                  suffix: 'min',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Last 7 Days',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: stats.map((stat) {
                    final ratio = stat.minutes / maxMinutes;
                    return _StatBar(
                      stat: stat,
                      ratio: ratio,
                      color: controller.selectedProject.color,
                    );
                  }).toList(),
                ),
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
                'Top Projects',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ...controller.topProjects().map((project) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: project.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(color: CupertinoColors.white),
                        ),
                      ),
                      Text(
                        '${project.completedMinutes} min',
                        style: const TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Top Tasks',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ...controller.topTasks().take(6).map((task) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(color: CupertinoColors.white),
                        ),
                      ),
                      Text(
                        '${task.completedMinutes} min',
                        style: const TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.stat,
    required this.ratio,
    required this.color,
  });

  final DailyStat stat;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              '${stat.minutes}',
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              height: 18 + (110 * ratio),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[color, color.withValues(alpha: 0.4)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _weekdayLabel(stat.day.weekday),
              style: const TextStyle(color: CupertinoColors.systemGrey2),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }
}
