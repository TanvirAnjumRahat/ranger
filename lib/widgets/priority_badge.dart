import 'package:flutter/material.dart';
import '../models/enums.dart';

class PriorityBadge extends StatelessWidget {
  final RoutinePriority priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case RoutinePriority.high:
        color = Colors.red;
        break;
      case RoutinePriority.medium:
        color = Colors.orange;
        break;
      case RoutinePriority.low:
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        priority.name,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
