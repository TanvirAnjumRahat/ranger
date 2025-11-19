import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/routine_card.dart';
import '../routes.dart';

class IncompleteTasksScreen extends StatelessWidget {
  const IncompleteTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routinesProv = context.watch<RoutinesProvider>();
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incomplete Tasks'), elevation: 0),
        body: const Center(child: Text('Please sign in to view your tasks')),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    // Get incomplete tasks from the last 7 days
    final incompleteTasks = routinesProv.routines.where((routine) {
      final routineDate = routine.date.toDate();
      final routineDay = DateTime(
        routineDate.year,
        routineDate.month,
        routineDate.day,
      );

      // Check if routine is in the last 7 days range
      if (routineDay.isBefore(sevenDaysAgo) || routineDay.isAfter(today)) {
        return false;
      }

      // Check if not completed on that specific date
      final isCompleted = routine.completedDates.any((ts) {
        final completedDate = ts.toDate();
        return completedDate.year == routineDay.year &&
            completedDate.month == routineDay.month &&
            completedDate.day == routineDay.day;
      });

      return !isCompleted;
    }).toList();

    // Sort by date (oldest first)
    incompleteTasks.sort((a, b) => a.date.compareTo(b.date));

    // Group by date
    final Map<String, List<dynamic>> groupedTasks = {};
    for (var task in incompleteTasks) {
      final date = task.date.toDate();
      final dateKey = _formatDate(date);
      if (!groupedTasks.containsKey(dateKey)) {
        groupedTasks[dateKey] = [];
      }
      groupedTasks[dateKey]!.add(task);
    }

    if (routinesProv.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incomplete Tasks'), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Incomplete Tasks'), elevation: 0),
      body: incompleteTasks.isEmpty
          ? _buildEmptyState(context)
          : _buildTasksList(context, groupedTasks, today, incompleteTasks),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No incomplete tasks from the last 7 days',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(
    BuildContext context,
    Map<String, List<dynamic>> groupedTasks,
    DateTime today,
    List<dynamic> incompleteTasks,
  ) {
    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.errorContainer,
                Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: Theme.of(context).colorScheme.onError,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${incompleteTasks.length} Pending',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                    ),
                    Text(
                      'Tasks from last 7 days',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tasks List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groupedTasks.length,
            itemBuilder: (context, index) {
              final dateKey = groupedTasks.keys.elementAt(index);
              final tasks = groupedTasks[dateKey]!;
              final date = tasks[0].date.toDate();
              final isToday = _isToday(date);
              final daysAgo = today
                  .difference(DateTime(date.year, date.month, date.day))
                  .inDays;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 12,
                      left: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          dateKey,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (!isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tasks for this date
                  ...tasks.map((routine) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RoutineCard(
                        routine: routine,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.routineDetail,
                          arguments: routine.id,
                        ),
                        onComplete: () async {
                          final when = DateTime.now();
                          await context.read<RoutinesProvider>().toggleComplete(
                            routine,
                            when,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Marked as done'),
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  context.read<RoutinesProvider>().undoComplete(
                                    routine,
                                    when,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
