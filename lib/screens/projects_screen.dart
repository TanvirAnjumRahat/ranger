import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/projects_provider.dart';
import '../models/project.dart';
import '../models/enums.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectsProvider(),
      child: const _ProjectsScreenContent(),
    );
  }
}

class _ProjectsScreenContent extends StatelessWidget {
  const _ProjectsScreenContent();

  @override
  Widget build(BuildContext context) {
    final projectsProv = context.watch<ProjectsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: projectsProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : projectsProv.error != null
          ? _buildErrorState(context, projectsProv)
          : projectsProv.projects.isEmpty
          ? _buildEmptyState(context)
          : _buildProjectsList(context, projectsProv),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context),
        heroTag: 'projectsFAB',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ProjectsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => provider.loadProjects(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_special_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Projects Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first project and start tracking tasks',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Organize your work into projects and break them down into manageable tasks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList(BuildContext context, ProjectsProvider provider) {
    final projects = provider.sortedProjects;

    return RefreshIndicator(
      onRefresh: provider.loadProjects,
      child: CustomScrollView(
        slivers: [
          // Overview Stats Card
          // Commented out - can be enabled later if needed
          // if (projects.isNotEmpty)
          //   SliverToBoxAdapter(child: _buildOverviewCard(context, projects)),

          // Projects List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final project = projects[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildProjectCard(context, project, provider),
                );
              }, childCount: projects.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, List<Project> projects) {
    final totalProjects = projects.length;
    final completedProjects = projects.where((p) => p.isCompleted).length;
    final totalTasks = projects.fold<int>(0, (sum, p) => sum + p.tasks.length);
    final completedTasks = projects.fold<int>(
      0,
      (sum, p) => sum + p.completedTasksCount,
    );
    final overallProgress = totalTasks > 0
        ? (completedTasks / totalTasks) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Projects',
                  '$completedProjects / $totalProjects',
                  Icons.folder_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Tasks',
                  '$completedTasks / $totalTasks',
                  Icons.task_alt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress / 100,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${overallProgress.toStringAsFixed(1)}% Complete',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    Project project,
    ProjectsProvider provider,
  ) {
    final progress = project.completionPercentage;
    final isOverdue =
        project.deadline != null &&
        project.deadline!.toDate().isBefore(DateTime.now()) &&
        !project.isCompleted;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProjectDetail(context, project.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        project.category,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(project.category),
                      color: _getCategoryColor(project.category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Tasks Count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${project.completedTasksCount}/${project.tasks.length} tasks',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        project.priority,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPriorityName(project.priority),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(project.priority),
                      ),
                    ),
                  ),
                ],
              ),

              // Description
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  project.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Progress Bar with enhanced visual
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: _getProgressColor(context, progress),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Progress',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getProgressColor(
                              context,
                              progress,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${progress.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getProgressColor(context, progress),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(context, progress),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${project.completedTasksCount} of ${project.tasks.length} tasks completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Row
              if (project.deadline != null || project.isCompleted) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (project.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (project.deadline != null && !project.isCompleted) ...[
                      Icon(
                        isOverdue ? Icons.warning_amber : Icons.calendar_today,
                        size: 14,
                        color: isOverdue
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue
                            ? 'Overdue'
                            : 'Due ${DateFormat('MMM d, y').format(project.deadline!.toDate())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOverdue
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isOverdue
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.work:
        return Colors.blue;
      case RoutineCategory.personal:
        return Colors.purple;
      case RoutineCategory.health:
        return Colors.green;
      case RoutineCategory.exercise:
        return Colors.orange;
      case RoutineCategory.study:
        return Colors.indigo;
      case RoutineCategory.others:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.work:
        return Icons.work_outline;
      case RoutineCategory.personal:
        return Icons.person_outline;
      case RoutineCategory.health:
        return Icons.favorite_outline;
      case RoutineCategory.exercise:
        return Icons.fitness_center_outlined;
      case RoutineCategory.study:
        return Icons.school_outlined;
      case RoutineCategory.others:
        return Icons.more_horiz;
    }
  }

  Color _getPriorityColor(RoutinePriority priority) {
    switch (priority) {
      case RoutinePriority.low:
        return Colors.blue;
      case RoutinePriority.medium:
        return Colors.orange;
      case RoutinePriority.high:
        return Colors.red;
    }
  }

  String _getPriorityName(RoutinePriority priority) {
    switch (priority) {
      case RoutinePriority.low:
        return 'Low';
      case RoutinePriority.medium:
        return 'Medium';
      case RoutinePriority.high:
        return 'High';
    }
  }

  Color _getProgressColor(BuildContext context, double progress) {
    if (progress >= 100) return Colors.green;
    if (progress >= 70) return Colors.blue;
    if (progress >= 40) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }

  void _navigateToProjectDetail(BuildContext context, String projectId) {
    final provider = context.read<ProjectsProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (newContext) => ChangeNotifierProvider.value(
          value: provider,
          child: ProjectDetailScreen(projectId: projectId),
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    final provider = context.read<ProjectsProvider>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    RoutineCategory selectedCategory = RoutineCategory.others;
    RoutinePriority selectedPriority = RoutinePriority.medium;
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          title: const Text('Create New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Project Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoutineCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: RoutineCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(cat),
                            size: 20,
                            color: _getCategoryColor(cat),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat.name[0].toUpperCase() + cat.name.substring(1),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoutinePriority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: RoutinePriority.values.map((pri) {
                    return DropdownMenuItem(
                      value: pri,
                      child: Text(_getPriorityName(pri)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPriority = val!),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: builderContext,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDeadline = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Deadline (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedDeadline == null
                          ? 'Tap to set deadline'
                          : DateFormat('MMM d, y').format(selectedDeadline!),
                      style: TextStyle(
                        color: selectedDeadline == null
                            ? Theme.of(
                                builderContext,
                              ).colorScheme.onSurfaceVariant
                            : Theme.of(builderContext).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a project title'),
                    ),
                  );
                  return;
                }

                final projectId = await provider.createProject(
                  title: titleController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  category: selectedCategory.name,
                  priority: selectedPriority.name,
                  deadline: selectedDeadline != null
                      ? Timestamp.fromDate(selectedDeadline!)
                      : null,
                );

                if (projectId != null && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Project created successfully'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper functions for category and priority styling
IconData _getCategoryIconHelper(RoutineCategory category) {
  switch (category) {
    case RoutineCategory.work:
      return Icons.work_outline;
    case RoutineCategory.personal:
      return Icons.person_outline;
    case RoutineCategory.health:
      return Icons.favorite_outline;
    case RoutineCategory.exercise:
      return Icons.fitness_center_outlined;
    case RoutineCategory.study:
      return Icons.school_outlined;
    case RoutineCategory.others:
      return Icons.more_horiz;
  }
}

Color _getCategoryColorHelper(RoutineCategory category) {
  switch (category) {
    case RoutineCategory.work:
      return Colors.blue;
    case RoutineCategory.personal:
      return Colors.purple;
    case RoutineCategory.health:
      return Colors.green;
    case RoutineCategory.exercise:
      return Colors.orange;
    case RoutineCategory.study:
      return Colors.indigo;
    case RoutineCategory.others:
      return Colors.grey;
  }
}

String _getPriorityNameHelper(RoutinePriority priority) {
  switch (priority) {
    case RoutinePriority.low:
      return 'Low';
    case RoutinePriority.medium:
      return 'Medium';
    case RoutinePriority.high:
      return 'High';
  }
}

// Project Detail Screen
class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();
    final project = provider.getProjectById(projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Not Found')),
        body: const Center(child: Text('Project not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProjectDialog(context, provider, project),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, provider, projectId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Project Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description != null &&
                    project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Task Progress',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${project.completedTasksCount} / ${project.tasks.length} completed',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: project.tasks.isEmpty
                                ? 0
                                : project.completionPercentage / 100,
                            strokeWidth: 7,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${project.completionPercentage.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // Deadline info
                if (project.deadline != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Deadline: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM d, y',
                        ).format(project.deadline!.toDate()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (project.deadline!.toDate().isBefore(DateTime.now()) &&
                          !project.isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: project.tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add tasks to track your progress',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: project.tasks.length,
                    itemBuilder: (context, index) {
                      final task = project.tasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) => provider.toggleTaskCompletion(
                              projectId,
                              task.id,
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: task.description != null
                              ? Text(
                                  task.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDeleteTask(
                              context,
                              provider,
                              projectId,
                              task.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, provider, projectId),
        heroTag: 'projectDetailFAB',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditProjectDialog(
    BuildContext context,
    ProjectsProvider provider,
    Project project,
  ) {
    final titleController = TextEditingController(text: project.title);
    final descController = TextEditingController(
      text: project.description ?? '',
    );
    RoutineCategory selectedCategory = project.category;
    RoutinePriority selectedPriority = project.priority;
    DateTime? selectedDeadline = project.deadline?.toDate();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          title: const Text('Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Project Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoutineCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: RoutineCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIconHelper(cat),
                            size: 20,
                            color: _getCategoryColorHelper(cat),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat.name[0].toUpperCase() + cat.name.substring(1),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoutinePriority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: RoutinePriority.values.map((pri) {
                    return DropdownMenuItem(
                      value: pri,
                      child: Text(_getPriorityNameHelper(pri)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPriority = val!),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: builderContext,
                      initialDate:
                          selectedDeadline ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDeadline = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Deadline (Optional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: selectedDeadline != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => selectedDeadline = null),
                            )
                          : null,
                    ),
                    child: Text(
                      selectedDeadline == null
                          ? 'Tap to set deadline'
                          : DateFormat('MMM d, y').format(selectedDeadline!),
                      style: TextStyle(
                        color: selectedDeadline == null
                            ? Theme.of(
                                builderContext,
                              ).colorScheme.onSurfaceVariant
                            : Theme.of(builderContext).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a project title'),
                    ),
                  );
                  return;
                }

                final updatedProject = project.copyWith(
                  title: titleController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  category: selectedCategory,
                  priority: selectedPriority,
                  deadline: selectedDeadline != null
                      ? Timestamp.fromDate(selectedDeadline!)
                      : null,
                );

                final success = await provider.updateProject(updatedProject);

                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Project updated successfully'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    ProjectsProvider provider,
    String projectId,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a task title')),
                );
                return;
              }

              await provider.addTaskToProject(
                projectId,
                titleController.text.trim(),
                descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(
    BuildContext context,
    ProjectsProvider provider,
    String projectId,
    String taskId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.deleteTask(projectId, taskId);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProjectsProvider provider,
    String projectId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text(
          'Are you sure you want to delete this project? This will also delete all tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.deleteProject(projectId);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to projects list
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
