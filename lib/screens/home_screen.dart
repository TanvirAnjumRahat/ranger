import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/routine_provider.dart';
import '../routes.dart';
import '../widgets/routine_card.dart';
import '../providers/filters_provider.dart';
import '../providers/notifications_provider.dart';
import '../models/enums.dart';
import 'dart:math' as math;

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
        title: const Text('My Routines'),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'refresh') {
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  context.read<RoutinesProvider>().loadRoutinesForUser(
                    user.uid,
                  );
                }
              } else if (value == 'export_all') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export all feature coming soon'),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Export All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final filtersProv = context.watch<FiltersProvider>();
          final allRoutines = routinesProv.routines;
          final todayCompleted = allRoutines.where((r) {
            final today = DateTime.now();
            return r.completedDates.any((ts) {
              final d = ts.toDate();
              return d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day;
            });
          }).length;
          final totalToday = allRoutines.where((r) {
            final today = DateTime.now();
            return r.date.toDate().isBefore(today.add(const Duration(days: 1)));
          }).length;
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsRow(context, todayCompleted, totalToday, routinesProv.routines.length),
                  const SizedBox(height: 16),
                  _buildQuoteCard(context),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/templates'),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Browse Templates'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('No routines yet. Tap + to add one.'),
                ],
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatsRow(context, todayCompleted, totalToday, routinesProv.routines.length),
              ),
              Expanded(
                child: ListView.builder(
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
                ),
              ),
            ],
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

  Widget _buildStatsRow(BuildContext context, int todayCompleted, int totalToday, int totalRoutines) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Today',
            '$todayCompleted/$totalToday',
            Icons.today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Total',
            '$totalRoutines',
            Icons.list,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Active',
            '${totalRoutines}',
            Icons.check_circle,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context) {
    final quotes = [
      "Success is the sum of small efforts repeated day in and day out.",
      "You don't have to be great to start, but you have to start to be great.",
      "The secret of getting ahead is getting started.",
      "Your future is created by what you do today, not tomorrow.",
      "Small daily improvements lead to stunning results.",
    ];
    final quote = quotes[math.Random().nextInt(quotes.length)];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.format_quote,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
