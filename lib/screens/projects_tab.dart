import 'package:flutter/cupertino.dart';

import '../controllers/pomodoro_controller.dart';
import '../models/project.dart';
import '../widgets/glass_card.dart';

class ProjectsTab extends StatelessWidget {
  const ProjectsTab({
    required this.controller,
    required this.onEditProject,
    required this.onDeleteProject,
    super.key,
  });

  final PomodoroController controller;
  final Future<void> Function(Project? editing) onEditProject;
  final Future<void> Function(Project project) onDeleteProject;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final project = controller.projects[index];
        return GlassCard(
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
                      style: const TextStyle(color: CupertinoColors.systemGrey),
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
        );
      },
    );
  }
}

