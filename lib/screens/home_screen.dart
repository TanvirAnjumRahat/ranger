import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/routine_provider.dart';
import '../routes.dart';
import '../widgets/routine_card.dart';
import '../providers/filters_provider.dart';
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

    final filtersProv = context.watch<FiltersProvider>();
    final allRoutines = routinesProv.routines;

    // Get today's date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter for today's routines only
    final todayRoutines = allRoutines.where((r) {
      final routineDate = r.date.toDate();
      return routineDate.year == today.year &&
          routineDate.month == today.month &&
          routineDate.day == today.day;
    }).toList();

    final todayCompleted = todayRoutines.where((r) {
      return r.completedDates.any((ts) {
        final d = ts.toDate();
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      });
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
              child: Text(routinesProv.error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                final u = context.read<AuthProvider>().user;
                if (u != null) {
                  context.read<RoutinesProvider>().loadRoutinesForUser(u.uid);
                }
              },
            ),
          ],
        ),
      );
    }

    // Apply filters to today's routines
    var list = todayRoutines.where((r) {
      final matchesSearch = filters.matchesTitle(r.title);
      final matchesCategory =
          filters.category == null || r.category == filters.category;
      final matchesPriority =
          filters.priority == null || r.priority == filters.priority;
      return matchesSearch && matchesCategory && matchesPriority;
    }).toList();

    // Check if there are filters applied
    final hasActiveFilters =
        filters.search.isNotEmpty ||
        filters.category != null ||
        filters.priority != null;

    if (list.isEmpty) {
      return Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStatsRow(
              context,
              todayCompleted,
              todayRoutines.length,
              routinesProv.routines.length,
            ),
          ),

          // Search and Filters Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search routines...',
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) =>
                      context.read<FiltersProvider>().updateSearch(v),
                ),
                const SizedBox(height: 12),

                // Filter Chips Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
                      child: _buildFilterChip(
                        context,
                        icon: Icons.category_outlined,
                        label: filters.category?.name ?? 'Category',
                        isSelected: filters.category != null,
                        onTap: () => _showCategoryPicker(context),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Priority Filter
                    Expanded(
                      child: _buildFilterChip(
                        context,
                        icon: Icons.flag_outlined,
                        label: filters.priority?.name ?? 'Priority',
                        isSelected: filters.priority != null,
                        onTap: () => _showPriorityPicker(context),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Clear Filters Button
                    if (hasActiveFilters)
                      IconButton.filledTonal(
                        onPressed: () {
                          context.read<FiltersProvider>().clearFilters();
                        },
                        icon: const Icon(Icons.clear_all),
                        tooltip: 'Clear filters',
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Empty State Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    hasActiveFilters ? Icons.search_off : Icons.event_busy,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasActiveFilters
                        ? 'No matching routines'
                        : 'No routines for today',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasActiveFilters
                        ? 'Try adjusting your search or filters'
                        : 'Tap + to add a new routine',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<FiltersProvider>().clearFilters();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All Filters'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                  if (!hasActiveFilters) ...[
                    const SizedBox(height: 16),
                    _buildQuoteCard(context),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.templates),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Browse Templates'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Stats Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildStatsRow(
            context,
            todayCompleted,
            todayRoutines.length,
            routinesProv.routines.length,
          ),
        ),

        // Search and Filters Section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search routines...',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (v) =>
                    context.read<FiltersProvider>().updateSearch(v),
              ),
              const SizedBox(height: 12),

              // Filter Chips Row
              Row(
                children: [
                  // Category Filter
                  Expanded(
                    child: _buildFilterChip(
                      context,
                      icon: Icons.category_outlined,
                      label: filters.category?.name ?? 'Category',
                      isSelected: filters.category != null,
                      onTap: () => _showCategoryPicker(context),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority Filter
                  Expanded(
                    child: _buildFilterChip(
                      context,
                      icon: Icons.flag_outlined,
                      label: filters.priority?.name ?? 'Priority',
                      isSelected: filters.priority != null,
                      onTap: () => _showPriorityPicker(context),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Clear Filters Button
                  if (filters.category != null ||
                      filters.priority != null ||
                      filters.search.isNotEmpty)
                    IconButton.filledTonal(
                      onPressed: () {
                        context.read<FiltersProvider>().clearFilters();
                      },
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Clear filters',
                    ),
                ],
              ),

              // Results Count
              const SizedBox(height: 8),
              Text(
                '${list.length} ${list.length == 1 ? 'routine' : 'routines'} today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Routines List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final r = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RoutineCard(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    int todayCompleted,
    int totalToday,
    int totalRoutines,
  ) {
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
            '$totalRoutines',
            Icons.check_circle,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
          Text(label, style: Theme.of(context).textTheme.labelSmall),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('All Categories'),
                onTap: () {
                  final current = context.read<FiltersProvider>().filters;
                  context.read<FiltersProvider>().setFilters(
                    current.copyWith(category: null),
                  );
                  Navigator.pop(context);
                },
              ),
              ...RoutineCategory.values.map((category) {
                return ListTile(
                  leading: Icon(_getCategoryIcon(category)),
                  title: Text(category.name),
                  trailing:
                      context.watch<FiltersProvider>().filters.category ==
                          category
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    final current = context.read<FiltersProvider>().filters;
                    context.read<FiltersProvider>().setFilters(
                      current.copyWith(category: category),
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Priority',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('All Priorities'),
                onTap: () {
                  final current = context.read<FiltersProvider>().filters;
                  context.read<FiltersProvider>().setFilters(
                    current.copyWith(priority: null),
                  );
                  Navigator.pop(context);
                },
              ),
              ...RoutinePriority.values.map((priority) {
                return ListTile(
                  leading: Icon(Icons.flag, color: _getPriorityColor(priority)),
                  title: Text(priority.name),
                  trailing:
                      context.watch<FiltersProvider>().filters.priority ==
                          priority
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    final current = context.read<FiltersProvider>().filters;
                    context.read<FiltersProvider>().setFilters(
                      current.copyWith(priority: priority),
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.work:
        return Icons.work;
      case RoutineCategory.personal:
        return Icons.person;
      case RoutineCategory.health:
        return Icons.favorite;
      case RoutineCategory.exercise:
        return Icons.fitness_center;
      case RoutineCategory.study:
        return Icons.school;
      case RoutineCategory.others:
        return Icons.more_horiz;
    }
  }

  Color _getPriorityColor(RoutinePriority priority) {
    switch (priority) {
      case RoutinePriority.low:
        return Colors.green;
      case RoutinePriority.medium:
        return Colors.orange;
      case RoutinePriority.high:
        return Colors.red;
    }
  }
}
