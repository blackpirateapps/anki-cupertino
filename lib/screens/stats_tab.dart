import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/daily_stat.dart';
import '../models/project.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_summary.dart';

enum _StatsRange { daily, weekly, monthly }

class StatsTab extends StatelessWidget {
  const StatsTab({
    required this.controller,
    super.key,
  });

  final PomodoroController controller;

  @override
  Widget build(BuildContext context) {
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
        _ChartCard(controller: controller),
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

class _ChartCard extends StatefulWidget {
  const _ChartCard({required this.controller});

  final PomodoroController controller;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  _StatsRange _range = _StatsRange.daily;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CupertinoSlidingSegmentedControl<_StatsRange>(
            groupValue: _range,
            children: const {
              _StatsRange.daily: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Daily'),
              ),
              _StatsRange.weekly: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Weekly'),
              ),
              _StatsRange.monthly: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Monthly'),
              ),
            },
            onValueChanged: (value) {
              if (value != null) {
                setState(() {
                  _range = value;
                });
              }
            },
          ),
          const SizedBox(height: 18),
          Text(
            _title(),
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 240, child: _buildChart()),
        ],
      ),
    );
  }

  String _title() {
    switch (_range) {
      case _StatsRange.daily:
        return 'Today by Project';
      case _StatsRange.weekly:
        return 'Last 7 Days';
      case _StatsRange.monthly:
        return 'This Month';
    }
  }

  Widget _buildChart() {
    switch (_range) {
      case _StatsRange.daily:
        return _DailyPieChart(controller: widget.controller);
      case _StatsRange.weekly:
        return _BarStatsChart(
          stats: widget.controller.dailyStats(),
          color: widget.controller.selectedProject.color,
          labelBuilder: (stat) => _weekdayLabel(stat.day.weekday),
        );
      case _StatsRange.monthly:
        return _BarStatsChart(
          stats: widget.controller.monthlyStats(),
          color: widget.controller.selectedProject.color,
          labelBuilder: (stat) => '${stat.day.day}',
        );
    }
  }
}

class _DailyPieChart extends StatelessWidget {
  const _DailyPieChart({required this.controller});

  final PomodoroController controller;

  @override
  Widget build(BuildContext context) {
    final breakdown = controller.todayProjectBreakdown();
    if (breakdown.isEmpty) {
      return const Center(
        child: Text(
          'No sessions logged today.',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);

    return Column(
      children: <Widget>[
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 48,
              sections: entries.map((entry) {
                final percent = (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  color: entry.key.color,
                  radius: 52,
                  title: '${percent.round()}%',
                  titleStyle: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: entries.map((entry) {
            return _LegendChip(project: entry.key, minutes: entry.value);
          }).toList(),
        ),
      ],
    );
  }
}

class _BarStatsChart extends StatelessWidget {
  const _BarStatsChart({
    required this.stats,
    required this.color,
    required this.labelBuilder,
  });

  final List<DailyStat> stats;
  final Color color;
  final String Function(DailyStat stat) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = stats.fold<int>(1, (max, stat) {
      return stat.minutes > max ? stat.minutes : max;
    });

    return BarChart(
      BarChartData(
        maxY: maxMinutes.toDouble() + 10,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: maxMinutes <= 60 ? 15 : 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey2,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= stats.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labelBuilder(stats[index]),
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey2,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(stats.length, (index) {
          final stat = stats[index];
          return BarChartGroupData(
            x: index,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: stat.minutes.toDouble(),
                width: stats.length > 16 ? 7 : 12,
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    color,
                    color.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.project,
    required this.minutes,
  });

  final Project project;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: project.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${project.name} $minutes min',
          style: const TextStyle(
            color: CupertinoColors.systemGrey2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
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
