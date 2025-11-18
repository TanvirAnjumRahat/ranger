import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/routine_provider.dart';
import '../routes.dart';
import '../widgets/routine_card.dart';
import '../models/enums.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final routinesProv = context.watch<RoutinesProvider>();

    // Filter for long-term routines (no repeat or custom repeat)
    final longTermRoutines = routinesProv.routines.where((r) {
      return r.repeat.type == RepeatType.none ||
          r.repeat.type == RepeatType.custom;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'filter') {
                // Show filter options
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Filter Goals'),
                    content: const Text('Filter by category or priority'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else if (value == 'sort') {
                // Show sort options
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sort Goals'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('By Date'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          title: const Text('By Priority'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          title: const Text('By Category'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    Icon(Icons.sort),
                    SizedBox(width: 8),
                    Text('Sort'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: routinesProv.loading
          ? const Center(child: CircularProgressIndicator())
          : routinesProv.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(routinesProv.error!),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      if (user != null) {
                        context.read<RoutinesProvider>().loadRoutinesForUser(
                          user.uid,
                        );
                      }
                    },
                  ),
                ],
              ),
            )
          : longTermRoutines.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Goals Yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create long-term goals and track your progress',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.routineNew),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Goal'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: longTermRoutines.length,
              itemBuilder: (context, index) {
                final routine = longTermRoutines[index];
                return RoutineCard(
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
                    if (context.mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Marked as done'),
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
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.routineNew),
        child: const Icon(Icons.add),
      ),
    );
  }
}
