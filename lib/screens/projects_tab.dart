import 'package:flutter/cupertino.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/project.dart';
import '../models/task_item.dart';
import '../widgets/glass_card.dart';

class ProjectsTab extends StatelessWidget {
  const ProjectsTab({
    required this.controller,
    required this.onEditProject,
    required this.onDeleteProject,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    super.key,
  });

  final PomodoroController controller;
  final Future<void> Function(Project? editing) onEditProject;
  final Future<void> Function(Project project) onDeleteProject;
  final Future<void> Function(Project project) onAddTask;
  final Future<void> Function(TaskItem task) onEditTask;
  final Future<void> Function(TaskItem task) onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final project = controller.projects[index];
        final tasks = controller.tasksForProject(project.id);
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
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
                    onPressed: () => onEditProject(project),
                    child: const Icon(CupertinoIcons.pencil),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => onDeleteProject(project),
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Tasks',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => onAddTask(project),
                    child: const Text('Add Task'),
                  ),
                ],
              ),
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'No tasks yet.',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                )
              else
                ...tasks.map((task) => _TaskRow(
                      task: task,
                      onEdit: () => onEditTask(task),
                      onDelete: () => onDeleteTask(task),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1014),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.completedSessions} sessions  |  ${task.completedMinutes} min',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onEdit,
                child: const Icon(CupertinoIcons.pencil),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.systemRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
