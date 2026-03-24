import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Anki Cupertino',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: Color(0xFF111216),
        barBackgroundColor: Color(0xCC16181D),
      ),
      home: PomodoroHomePage(),
    );
  }
}

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

enum TimerMode { focus, shortBreak, longBreak }

class PomodoroHomePage extends StatefulWidget {
  const PomodoroHomePage({super.key});

  @override
  State<PomodoroHomePage> createState() => _PomodoroHomePageState();
}

class _PomodoroHomePageState extends State<PomodoroHomePage> {
  static const _storageKey = 'anki_cupertino_state_v1';
  static const _projectColors = <int>[
    0xFFFF9F0A,
    0xFF30D158,
    0xFF64D2FF,
    0xFFBF5AF2,
    0xFFFF453A,
    0xFFFFD60A,
  ];

  AppState _state = AppState.initial();
  TimerMode _timerMode = TimerMode.focus;
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _focusCycles = 0;
  int _selectedTab = 0;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final rawState = prefs.getString(_storageKey);
    if (rawState != null) {
      final json = jsonDecode(rawState) as Map<String, dynamic>;
      _state = AppState.fromJson(json);
    }
    _resetTimer(notify: false);
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_state.toJson()));
  }

  int _minutesForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return _state.focusMinutes;
      case TimerMode.shortBreak:
        return _state.shortBreakMinutes;
      case TimerMode.longBreak:
        return _state.longBreakMinutes;
    }
  }

  Project get _selectedProject {
    return _state.projects.firstWhere(
      (project) => project.id == _state.selectedProjectId,
      orElse: () => _state.projects.first,
    );
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _completeSession();
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });

    setState(() {
      _isRunning = true;
    });
  }

  void _resetTimer({bool notify = true}) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _minutesForMode(_timerMode) * 60;
    });
    if (notify) {
      _saveState();
    }
  }

  Future<void> _setTimerMode(TimerMode mode) async {
    setState(() {
      _timerMode = mode;
    });
    _resetTimer(notify: false);
    await _saveState();
  }

  Future<void> _completeSession() async {
    final completedMode = _timerMode;
    final completedMinutes = _minutesForMode(_timerMode);
    if (_timerMode == TimerMode.focus) {
      final updatedProjects = _state.projects.map((project) {
        if (project.id != _state.selectedProjectId) {
          return project;
        }
        return project.copyWith(
          completedSessions: project.completedSessions + 1,
          completedMinutes: project.completedMinutes + completedMinutes,
        );
      }).toList();
      final updatedRecords = <SessionRecord>[
        SessionRecord(
          projectId: _state.selectedProjectId,
          completedAtIso: DateTime.now().toIso8601String(),
          minutes: completedMinutes,
        ),
        ..._state.records,
      ];
      _focusCycles += 1;
      _state = _state.copyWith(
        projects: updatedProjects,
        records: updatedRecords,
      );
      _timerMode = _focusCycles % 4 == 0
          ? TimerMode.longBreak
          : TimerMode.shortBreak;
    } else {
      _timerMode = TimerMode.focus;
    }

    _resetTimer(notify: false);
    await _saveState();
    if (mounted) {
      showCupertinoDialog<void>(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Session complete'),
            content: Text(
              completedMode == TimerMode.focus
                  ? 'Break time.'
                  : 'Ready to focus again.',
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _showProjectSheet({Project? editing}) async {
    final controller = TextEditingController(text: editing?.name ?? '');
    var colorValue = editing?.colorValue ?? _projectColors.first;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(editing == null ? 'New Project' : 'Edit Project'),
          message: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                children: <Widget>[
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: controller,
                    placeholder: 'Project name',
                    padding: const EdgeInsets.all(14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: _projectColors.map((color) {
                      final selected = color == colorValue;
                      return GestureDetector(
                        onTap: () => setSheetState(() => colorValue = color),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? CupertinoColors.white
                                  : CupertinoColors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final name = controller.text.trim();
                if (name.isEmpty) {
                  navigator.pop();
                  return;
                }
                if (editing == null) {
                  _state = _state.copyWith(
                    projects: <Project>[
                      ..._state.projects,
                      Project(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        colorValue: colorValue,
                      ),
                    ],
                  );
                } else {
                  _state = _state.copyWith(
                    projects: _state.projects.map((project) {
                      if (project.id != editing.id) {
                        return project;
                      }
                      return project.copyWith(
                        name: name,
                        colorValue: colorValue,
                      );
                    }).toList(),
                  );
                }
                await _saveState();
                if (mounted) {
                  setState(() {});
                }
                navigator.pop();
              },
              child: Text(editing == null ? 'Save Project' : 'Update Project'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _deleteProject(Project project) async {
    if (_state.projects.length == 1) {
      return;
    }
    final remainingProjects = _state.projects
        .where((candidate) => candidate.id != project.id)
        .toList();
    final nextSelected = _state.selectedProjectId == project.id
        ? remainingProjects.first.id
        : _state.selectedProjectId;
    _state = _state.copyWith(
      projects: remainingProjects,
      selectedProjectId: nextSelected,
      records: _state.records
          .where((record) => record.projectId != project.id)
          .toList(),
    );
    await _saveState();
    if (mounted) {
      setState(() {});
    }
  }

  int _todayMinutes() {
    final now = DateTime.now();
    return _state.records
        .where((record) {
          final date = record.completedAt;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<int>(0, (sum, record) => sum + record.minutes);
  }

  int _weekMinutes() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _state.records
        .where((record) {
          final date = record.completedAt;
          return !date.isBefore(start) && date.isBefore(end);
        })
        .fold<int>(0, (sum, record) => sum + record.minutes);
  }

  List<_DailyStat> _dailyStats() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return List<_DailyStat>.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final minutes = _state.records
          .where((record) {
            final date = record.completedAt;
            return date.year == day.year &&
                date.month == day.month &&
                date.day == day.day;
          })
          .fold<int>(0, (sum, record) => sum + record.minutes);
      return _DailyStat(day: day, minutes: minutes);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.timer),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.folder),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Stats',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              switch (index) {
                0 => 'Pomodoro',
                1 => 'Projects',
                _ => 'Statistics',
              },
            ),
            trailing: index == 1
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showProjectSheet,
                    child: const Icon(CupertinoIcons.add_circled),
                  )
                : null,
          ),
          child: SafeArea(
            child: switch (index) {
              0 => _buildTimerTab(),
              1 => _buildProjectsTab(),
              _ => _buildStatsTab(),
            },
          ),
        );
      },
    );
  }

  Widget _buildTimerTab() {
    final totalSeconds = (_minutesForMode(_timerMode) * 60).clamp(1, 86400);
    final progress =
        (1 - (_remainingSeconds / totalSeconds)).clamp(0.0, 1.0).toDouble();
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _GlassCard(
          child: Column(
            children: <Widget>[
              CupertinoSlidingSegmentedControl<TimerMode>(
                groupValue: _timerMode,
                children: const <TimerMode, Widget>{
                  TimerMode.focus: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Focus'),
                  ),
                  TimerMode.shortBreak: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Short'),
                  ),
                  TimerMode.longBreak: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Long'),
                  ),
                },
                onValueChanged: (mode) {
                  if (mode != null) {
                    _setTimerMode(mode);
                  }
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 220,
                width: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          progress: progress,
                          color: _selectedProject.color,
                        ),
                      ),
                    ),
                    Column(
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
                          _selectedProject.name,
                          style: TextStyle(
                            color: _selectedProject.color,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _toggleTimer,
                      child: Text(_isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    onPressed: _resetTimer,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _GlassCard(
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
                groupValue: _state.selectedProjectId,
                children: {
                  for (final project in _state.projects)
                    project.id: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(project.name),
                    ),
                },
                onValueChanged: (projectId) async {
                  if (projectId == null) {
                    return;
                  }
                  setState(() {
                    _state = _state.copyWith(selectedProjectId: projectId);
                  });
                  await _saveState();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _MetricTile(label: 'Today', value: '${_todayMinutes()} min'),
                  const SizedBox(width: 12),
                  _MetricTile(label: 'Week', value: '${_weekMinutes()} min'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _state.projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final project = _state.projects[index];
        return _GlassCard(
          child: Row(
            children: <Widget>[
              Container(
                width: 14,
                height: 56,
                decoration: BoxDecoration(
                  color: project.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      project.name,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${project.completedSessions} sessions  |  ${project.completedMinutes} min',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showProjectSheet(editing: project),
                child: const Icon(CupertinoIcons.pencil),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _deleteProject(project),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.systemRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    final stats = _dailyStats();
    final maxMinutes = stats.fold<int>(1, (max, stat) {
      return stat.minutes > max ? stat.minutes : max;
    });

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _GlassCard(
                child: _StatSummary(
                  label: 'Today',
                  value: '${_todayMinutes()}',
                  suffix: 'min',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _GlassCard(
                child: _StatSummary(
                  label: 'This Week',
                  value: '${_weekMinutes()}',
                  suffix: 'min',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _GlassCard(
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
                                  colors: <Color>[
                                    _selectedProject.color,
                                    _selectedProject.color.withValues(alpha: 0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _weekdayLabel(stat.day.weekday),
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _GlassCard(
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
              ..._state.projects
                  .toList()
                  .sorted((a, b) => b.completedMinutes.compareTo(a.completedMinutes))
                  .map((project) => Padding(
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
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                            Text(
                              '${project.completedMinutes} min',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ),
        ),
      ],
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1B1E25),
            Color(0xFF16181E),
          ],
        ),
        border: Border.all(color: const Color(0xFF2B2F38)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 16),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1014),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatSummary extends StatelessWidget {
  const _StatSummary({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' $suffix',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final backgroundPaint = Paint()
      ..color = const Color(0xFF2A2D34)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0.45)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 7, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7),
      -1.5708,
      6.28318 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _DailyStat {
  const _DailyStat({required this.day, required this.minutes});

  final DateTime day;
  final int minutes;
}

extension on List<Project> {
  List<Project> sorted(int Function(Project a, Project b) compare) {
    final copy = List<Project>.from(this);
    copy.sort(compare);
    return copy;
  }
}
