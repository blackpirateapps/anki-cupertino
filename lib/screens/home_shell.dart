import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/project.dart';
import '../models/task_item.dart';
import '../services/app_storage.dart';
import 'focus_tab.dart';
import 'project_detail_page.dart';
import 'projects_tab.dart';
import 'settings_tab.dart';
import 'stats_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    this.storage = const SqliteAppStorage(),
    super.key,
  });

  final AppStorage storage;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late final PomodoroController _controller;
  int _selectedTab = 0;
  bool _isShowingAlert = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PomodoroController(storage: widget.storage)
      ..addListener(_onControllerChanged);
    _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.handleAppResumed();
      return;
    }
    _controller.handleAppPaused();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final message = _controller.consumePendingAlert();
    if (message == null || _isShowingAlert) {
      return;
    }
    _isShowingAlert = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _isShowingAlert = false;
        return;
      }
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Timer Update'),
            content: Text(message),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
      _isShowingAlert = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isLoaded) {
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
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(_titleForIndex(index)),
            trailing: index == 1
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showProjectSheet(),
                    child: const Icon(CupertinoIcons.add_circled),
                  )
                : null,
          ),
          child: SafeArea(child: _buildTab(index)),
        );
      },
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return FocusTab(
          controller: _controller,
          onResetRequested: _confirmResetTimer,
          onChooseTask: _showTaskPicker,
        );
      case 1:
        return ProjectsTab(
          controller: _controller,
          onOpenProject: _openProjectPage,
          onEditProject: _showProjectSheet,
          onDeleteProject: _confirmDeleteProject,
        );
      case 2:
        return StatsTab(controller: _controller);
      case 3:
        return SettingsTab(
          controller: _controller,
          onExport: _showExportDialog,
          onImport: _showImportDialog,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Pomodoro';
      case 1:
        return 'Projects';
      case 2:
        return 'Statistics';
      case 3:
        return 'Settings';
      default:
        return '';
    }
  }

  Future<void> _showProjectSheet([Project? editing]) async {
    final controller = TextEditingController(text: editing?.name ?? '');
    var colorValue =
        editing?.colorValue ?? PomodoroController.projectColors.first;
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
                    children: PomodoroController.projectColors.map((color) {
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
                await _controller.upsertProject(
                  editing: editing,
                  name: name,
                  colorValue: colorValue,
                );
                if (mounted) {
                  navigator.pop();
                }
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

  Future<void> _showTaskSheet(Project project) async {
    await _showTaskEditor(project: project);
  }

  Future<void> _showEditTaskSheet(TaskItem task) async {
    final project = _controller.projects.firstWhere(
      (item) => item.id == task.projectId,
      orElse: () => _controller.selectedProject,
    );
    await _showTaskEditor(project: project, editing: task);
  }

  Future<void> _showTaskEditor({
    required Project project,
    TaskItem? editing,
  }) async {
    final controller = TextEditingController(text: editing?.title ?? '');
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(editing == null ? 'New Task' : 'Edit Task'),
          message: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Task title',
                padding: const EdgeInsets.all(14),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final title = controller.text.trim();
                if (title.isEmpty) {
                  navigator.pop();
                  return;
                }
                await _controller.upsertTask(
                  editing: editing,
                  projectId: project.id,
                  title: title,
                );
                if (mounted) {
                  navigator.pop();
                }
              },
              child: Text(editing == null ? 'Save Task' : 'Update Task'),
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

  Future<void> _showTaskPicker() async {
    await _openProjectPage(
      _controller.selectedProject,
      isTaskSelection: true,
    );
  }

  Future<void> _openProjectPage(
    Project project, {
    bool isTaskSelection = false,
  }) async {
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) {
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final currentProject = _controller.projects.firstWhere(
                (item) => item.id == project.id,
                orElse: () => project,
              );
              return ProjectDetailPage(
                controller: _controller,
                project: currentProject,
                isTaskSelection: isTaskSelection,
                onSelectTask: (task) => _controller.selectTask(task?.id),
                onEditProject: _showProjectSheet,
                onDeleteProject: _confirmDeleteProject,
                onAddTask: _showTaskSheet,
                onEditTask: _showEditTaskSheet,
                onDeleteTask: _confirmDeleteTask,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteProject(Project project) async {
    if (_controller.projects.length == 1) {
      return;
    }
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Project?'),
          content: Text(
            'Delete "${project.name}" with all of its tasks and sessions?',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _controller.deleteProject(project);
                if (mounted) {
                  navigator.pop();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteTask(TaskItem task) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Task?'),
          content: Text(
            'Delete "${task.title}"? Existing sessions will remain but lose their task link.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _controller.deleteTask(task);
                if (mounted) {
                  navigator.pop();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmResetTimer() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Reset Timer?'),
          content: const Text('This will stop the current timer and reset it.'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _controller.resetTimer();
                if (mounted) {
                  navigator.pop();
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExportDialog() async {
    final exportText = _controller.exportData();
    final exportController = TextEditingController(text: exportText);
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Export Data'),
          content: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: exportController,
                readOnly: true,
                maxLines: 8,
                minLines: 8,
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await Clipboard.setData(ClipboardData(text: exportText));
                if (mounted) {
                  navigator.pop();
                }
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportDialog() async {
    final textController = TextEditingController();
    var errorText = '';
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('Import Data'),
              content: Column(
                children: <Widget>[
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: textController,
                    placeholder: 'Paste exported JSON',
                    maxLines: 8,
                    minLines: 8,
                  ),
                  if (errorText.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      errorText,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    setDialogState(() {
                      textController.text = data?.text ?? '';
                    });
                  },
                  child: const Text('Paste'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final error = await _controller.importData(
                      textController.text.trim(),
                    );
                    if (error != null) {
                      setDialogState(() {
                        errorText = error;
                      });
                      return;
                    }
                    if (mounted) {
                      navigator.pop();
                    }
                  },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
