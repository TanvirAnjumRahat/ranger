import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/routine.dart';
import '../widgets/priority_badge.dart';
import '../widgets/category_chip.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  const RoutineCard({
    super.key,
    required this.routine,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = routine.status.name == 'completed';
    final timeOfDay = routine.time.toDate();
    final formattedTime = DateFormat('h:mm a').format(timeOfDay);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 2),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        title: Text(routine.title),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            CategoryChip(category: routine.category),
            PriorityBadge(priority: routine.priority),
          ],
        ),
        trailing: IconButton(
          tooltip: isCompleted ? 'Completed' : 'Mark as done',
          icon: Icon(
            isCompleted ? Icons.check_circle : Icons.check_circle_outline,
          ),
          onPressed: isCompleted ? null : onComplete,
        ),
      ),
    );
  }
}
