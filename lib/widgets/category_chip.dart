import 'package:flutter/material.dart';
import '../models/enums.dart';

class CategoryChip extends StatelessWidget {
  final RoutineCategory category;
  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(_label(category)));
  }

  String _label(RoutineCategory c) {
    switch (c) {
      case RoutineCategory.work:
        return 'Work';
      case RoutineCategory.exercise:
        return 'Exercise';
      case RoutineCategory.health:
        return 'Health';
      case RoutineCategory.personal:
        return 'Personal';
      case RoutineCategory.study:
        return 'Study';
      case RoutineCategory.others:
        return 'Others';
    }
  }
}
