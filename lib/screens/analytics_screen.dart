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
    final total = routines.length;
    final completed = routines
        .where((r) => r.status == RoutineStatus.completed)
        .length;
    final rate = total == 0 ? 0.0 : (completed / total);
    final byCategory = <RoutineCategory, int>{};
    final byPriority = <RoutinePriority, int>{};
    for (final r in routines) {
      byCategory[r.category] = (byCategory[r.category] ?? 0) + 1;
      byPriority[r.priority] = (byPriority[r.priority] ?? 0) + 1;
    }

    // Build 14-day completion trend: counts of completions per day
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 13));
    final buckets = List<int>.filled(14, 0);
    for (final r in routines) {
      for (final ts in r.completedDates) {
        final d = ts.toDate();
        final day = DateTime(d.year, d.month, d.day);
        if (!day.isBefore(start) &&
            !day.isAfter(DateTime(now.year, now.month, now.day))) {
          final idx = day.difference(start).inDays;
          if (idx >= 0 && idx < buckets.length) buckets[idx]++;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(label: 'Total', value: '$total'),
                _StatCard(label: 'Completed', value: '$completed'),
                _StatCard(
                  label: 'Completion Rate',
                  value: '${(rate * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'By Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...RoutineCategory.values.map((c) {
              final count = byCategory[c] ?? 0;
              return ListTile(
                dense: true,
                leading: const Icon(Icons.label_outline),
                title: Text(c.name),
                trailing: Text('$count'),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'By Priority',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...RoutinePriority.values.map((p) {
              final count = byPriority[p] ?? 0;
              return ListTile(
                dense: true,
                leading: const Icon(Icons.flag_outlined),
                title: Text(p.name),
                trailing: Text('$count'),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Completions (last 14 days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _TrendBars(buckets: buckets),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  final List<int> buckets;
  const _TrendBars({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.isEmpty
        ? 0
        : (buckets.reduce((a, b) => a > b ? a : b));
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in buckets)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: maxVal == 0 ? 2 : (v / maxVal) * 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
