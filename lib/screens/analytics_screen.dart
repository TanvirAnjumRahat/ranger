import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../models/enums.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RoutinesProvider>();
    final routines = prov.routines;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Today's statistics
    final todayRoutines = routines.where((r) {
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

    final todayTotal = todayRoutines.length;
    final todayRate = todayTotal == 0 ? 0.0 : (todayCompleted / todayTotal);

    // Overall statistics
    final total = routines.length;
    final byCategory = <RoutineCategory, int>{};
    final byCategoryCompleted = <RoutineCategory, int>{};
    final byPriority = <RoutinePriority, int>{};

    for (final r in routines) {
      byCategory[r.category] = (byCategory[r.category] ?? 0) + 1;
      byPriority[r.priority] = (byPriority[r.priority] ?? 0) + 1;
      if (r.completedDates.isNotEmpty) {
        byCategoryCompleted[r.category] =
            (byCategoryCompleted[r.category] ?? 0) + 1;
      }
    }

    // 7-day streak
    int currentStreak = 0;
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final hasCompletion = routines.any((r) {
        return r.completedDates.any((ts) {
          final d = ts.toDate();
          return d.year == checkDate.year &&
              d.month == checkDate.month &&
              d.day == checkDate.day;
        });
      });
      if (hasCompletion) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Build 7-day completion trend
    final start = today.subtract(const Duration(days: 6));
    final buckets = List<Map<String, dynamic>>.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final dayRoutines = routines.where((r) {
        final routineDate = r.date.toDate();
        return routineDate.year == date.year &&
            routineDate.month == date.month &&
            routineDate.day == date.day;
      }).toList();

      final completed = dayRoutines.where((r) {
        return r.completedDates.any((ts) {
          final d = ts.toDate();
          return d.year == date.year &&
              d.month == date.month &&
              d.day == date.day;
        });
      }).length;

      return {
        'date': date,
        'total': dayRoutines.length,
        'completed': completed,
        'rate': dayRoutines.isEmpty ? 0.0 : (completed / dayRoutines.length),
      };
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Progress Card
            _buildTodayProgressCard(
              context,
              todayCompleted,
              todayTotal,
              todayRate,
            ),
            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(context, total, currentStreak),
            const SizedBox(height: 24),

            // 7-Day Trend
            _buildSectionTitle(context, 'Weekly Performance'),
            const SizedBox(height: 12),
            _WeeklyTrendChart(buckets: buckets),
            const SizedBox(height: 24),

            // Category Breakdown
            _buildSectionTitle(context, 'By Category'),
            const SizedBox(height: 12),
            _buildCategoryBreakdown(context, byCategory, byCategoryCompleted),
            const SizedBox(height: 24),

            // Priority Breakdown
            _buildSectionTitle(context, 'By Priority'),
            const SizedBox(height: 12),
            _buildPriorityBreakdown(context, byPriority),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgressCard(
    BuildContext context,
    int completed,
    int total,
    double rate,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 12,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completed of $total tasks completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, int total, int streak) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.list_alt,
            label: 'Total Routines',
            value: '$total',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.local_fire_department,
            label: 'Current Streak',
            value: '$streak ${streak == 1 ? 'day' : 'days'}',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    Map<RoutineCategory, int> byCategory,
    Map<RoutineCategory, int> byCategoryCompleted,
  ) {
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: sortedCategories.map((entry) {
            final category = entry.key;
            final count = entry.value;
            final completed = byCategoryCompleted[category] ?? 0;
            final rate = count == 0 ? 0.0 : (completed / count);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        '$count',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 6,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriorityBreakdown(
    BuildContext context,
    Map<RoutinePriority, int> byPriority,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: RoutinePriority.values.map((priority) {
            final count = byPriority[priority] ?? 0;
            final color = _getPriorityColor(priority);

            return ListTile(
              dense: true,
              leading: Icon(Icons.flag, color: color),
              title: Text(priority.name),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            );
          }).toList(),
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

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> buckets;

  const _WeeklyTrendChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.fold<int>(
      0,
      (max, b) => b['total'] > max ? b['total'] : max,
    );
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.asMap().entries.map((entry) {
                final bucket = entry.value;
                final total = bucket['total'] as int;
                final completed = bucket['completed'] as int;
                final rate = bucket['rate'] as double;
                final date = bucket['date'] as DateTime;
                final dayName = days[date.weekday - 1];

                final heightFactor = maxVal == 0 ? 0.0 : (total / maxVal);
                final completedFactor = total == 0 ? 0.0 : (completed / total);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          '${(rate * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 100 * heightFactor,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primaryContainer,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 100 * heightFactor * (1 - completedFactor),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Completed', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Incomplete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
