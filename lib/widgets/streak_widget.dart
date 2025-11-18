import 'package:flutter/material.dart';
import '../models/routine.dart';

class StreakWidget extends StatelessWidget {
  final Routine routine;

  const StreakWidget({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final currentStreak = _calculateCurrentStreak(routine);
    final longestStreak = _calculateLongestStreak(routine);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: currentStreak > 0
                      ? Colors.orange
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Streak Tracking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStreakCard(
                    context,
                    'Current',
                    currentStreak,
                    Colors.orange,
                    '🔥',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStreakCard(
                    context,
                    'Longest',
                    longestStreak,
                    Colors.blue,
                    '🏆',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStreakCard(
                    context,
                    'Total',
                    routine.completedDates.length,
                    Colors.green,
                    '✅',
                  ),
                ),
              ],
            ),
            if (currentStreak > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getStreakMessage(currentStreak),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    String label,
    int count,
    Color color,
    String emoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCurrentStreak(Routine routine) {
    if (routine.completedDates.isEmpty) return 0;

    final sortedDates = routine.completedDates.map((ts) => ts.toDate()).toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime checkDate = todayDate;

    for (var completedDate in sortedDates) {
      final completed = DateTime(
        completedDate.year,
        completedDate.month,
        completedDate.day,
      );

      if (completed.isAtSameMomentAs(checkDate) ||
          completed.isAfter(checkDate.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = completed.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateLongestStreak(Routine routine) {
    if (routine.completedDates.isEmpty) return 0;

    final sortedDates =
        routine.completedDates
            .map((ts) => ts.toDate())
            .map((dt) => DateTime(dt.year, dt.month, dt.day))
            .toSet()
            .toList()
          ..sort();

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;

      if (diff == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  String _getStreakMessage(int streak) {
    if (streak >= 30) return 'Amazing! 30+ day streak!';
    if (streak >= 21) return 'Incredible! 21+ day streak!';
    if (streak >= 14) return 'Great job! 2 week streak!';
    if (streak >= 7) return 'Keep it up! 1 week streak!';
    if (streak >= 3) return 'Building momentum! $streak days!';
    return 'Nice start! Keep going!';
  }
}
