import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/routine_provider.dart';
import '../routes.dart';
import '../widgets/routine_card.dart';
import '../providers/filters_provider.dart';
import '../providers/notifications_provider.dart';
import '../models/enums.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static String? _lastLoadedUid;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final routinesProv = context.watch<RoutinesProvider>();
    if (user != null &&
        !routinesProv.loading &&
        routinesProv.routines.isEmpty &&
        _lastLoadedUid != user.uid) {
      // Initial load - schedule after first frame to avoid notify during build
      _lastLoadedUid = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<RoutinesProvider>().loadRoutinesForUser(user.uid);
        }
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine Ranger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Notifications',
            onPressed: () async {
              final np = context.read<NotificationsProvider>();
              bool current = context
                  .read<NotificationsProvider>()
                  .motivationSubscribed;
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Notifications'),
                    content: StatefulBuilder(
                      builder: (context, setState) {
                        return SwitchListTile(
                          title: const Text('Subscribe to "motivation" topic'),
                          value: current,
                          onChanged: (v) {
                            setState(() => current = v);
                          },
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await np.setMotivationSubscribed(current);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final filtersProv = context.watch<FiltersProvider>();
          final filters = filtersProv.filters;
          if (routinesProv.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (routinesProv.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      routinesProv.error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      final u = context.read<AuthProvider>().user;
                      if (u != null) {
                        context.read<RoutinesProvider>().loadRoutinesForUser(
                          u.uid,
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }
          var list = routinesProv.routines.where((r) {
            final matchesSearch = filters.matchesTitle(r.title);
            final matchesCategory =
                filters.category == null || r.category == filters.category;
            final matchesPriority =
                filters.priority == null || r.priority == filters.priority;
            return matchesSearch && matchesCategory && matchesPriority;
          }).toList();
          if (list.isEmpty) {
            return const Center(
              child: Text('No routines yet. Tap + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final r = list[index];
              return RoutineCard(
                routine: r,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.routineDetail,
                  arguments: r.id,
                ),
                onComplete: () async {
                  final when = DateTime.now();
                  await context.read<RoutinesProvider>().toggleComplete(
                    r,
                    when,
                  );
                  if (!context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Marked as done'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          context.read<RoutinesProvider>().undoComplete(
                            r,
                            when,
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by title...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) =>
                    context.read<FiltersProvider>().updateSearch(v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RoutineCategory>(
                      value: context.watch<FiltersProvider>().filters.category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<RoutineCategory>(
                          value: null,
                          child: Text('All'),
                        ),
                        ...RoutineCategory.values.map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) {
                        final current = context.read<FiltersProvider>().filters;
                        final f = current.copyWith(category: v);
                        context.read<FiltersProvider>().setFilters(f);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<RoutinePriority>(
                      value: context.watch<FiltersProvider>().filters.priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<RoutinePriority>(
                          value: null,
                          child: Text('All'),
                        ),
                        ...RoutinePriority.values.map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.name)),
                        ),
                      ],
                      onChanged: (v) {
                        final current = context.read<FiltersProvider>().filters;
                        final f = current.copyWith(priority: v);
                        context.read<FiltersProvider>().setFilters(f);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.routineNew),
        child: const Icon(Icons.add),
      ),
    );
  }
}
