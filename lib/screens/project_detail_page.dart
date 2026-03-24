import 'package:flutter/cupertino.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/project.dart';
import '../models/task_item.dart';
import '../widgets/glass_card.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    required this.controller,
    required this.project,
    required this.onEditProject,
    required this.onDeleteProject,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    this.isTaskSelection = false,
    this.onSelectTask,
    super.key,
  });

  final PomodoroController controller;
  final Project project;
  final Future<void> Function(Project project) onEditProject;
  final Future<void> Function(Project project) onDeleteProject;
  final Future<void> Function(Project project) onAddTask;
  final Future<void> Function(TaskItem task) onEditTask;
  final Future<void> Function(TaskItem task) onDeleteTask;
  final bool isTaskSelection;
  final Future<void> Function(TaskItem? task)? onSelectTask;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasksForProject(project.id);
    final selectedTaskId = controller.selectedTask?.id;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: isTaskSelection ? 'Focus' : 'Projects',
        middle: Text(project.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => onEditProject(project),
              child: const Icon(CupertinoIcons.pencil, size: 20),
            ),
            const SizedBox(width: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => onAddTask(project),
              child: const Icon(CupertinoIcons.add_circled, size: 20),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: <Widget>[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${project.completedMinutes} min',
                    style: TextStyle(
                      color: project.color,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Focused in this project',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey2,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ProjectMetric(
                          label: 'Sessions',
                          value: '${project.completedSessions}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProjectMetric(
                          label: 'Tasks',
                          value: '${tasks.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await onDeleteProject(project);
                      final wasDeleted = !controller.projects.any(
                        (candidate) => candidate.id == project.id,
                      );
                      if (context.mounted && wasDeleted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      'Delete Project',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Tasks',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isTaskSelection)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await onSelectTask?.call(null);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('No Task'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              const GlassCard(
                child: Text(
                  'No tasks yet. Add one to start organizing this project.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 15,
                  ),
                ),
              )
            else
              ...tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TaskManagerTile(
                    task: task,
                    accentColor: project.color,
                    isSelected: selectedTaskId == task.id,
                    isSelectionMode: isTaskSelection,
                    onTap: () async {
                      if (!isTaskSelection) {
                        return;
                      }
                      await onSelectTask?.call(task);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    onEdit: isTaskSelection ? null : () => onEditTask(task),
                    onDelete:
                        isTaskSelection ? null : () => onDeleteTask(task),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectMetric extends StatelessWidget {
  const _ProjectMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1014),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF242834)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskManagerTile extends StatelessWidget {
  const _TaskManagerTile({
    required this.task,
    required this.accentColor,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final TaskItem task;
  final Color accentColor;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF13161D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFF262B36),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? accentColor : const Color(0xFF4B5261),
                    width: 2,
                  ),
                  color: isSelected ? accentColor : CupertinoColors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 12,
                        color: CupertinoColors.black,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        _TaskBadge(
                          label: '${task.completedMinutes} min',
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        _TaskBadge(
                          label: '${task.completedSessions} sessions',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelectionMode)
                Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                  size: 18,
                )
              else ...<Widget>[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onEdit,
                  child: const Icon(CupertinoIcons.pencil, size: 20),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onDelete,
                  child: const Icon(
                    CupertinoIcons.delete,
                    size: 20,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF1C202A)).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color?.withValues(alpha: 0.35) ?? const Color(0xFF303647),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color ?? CupertinoColors.systemGrey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
