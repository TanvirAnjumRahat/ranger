import 'enums.dart';

class Filters {
  final DateTime? date;
  final RoutineCategory? category;
  final RoutinePriority? priority;
  final RoutineStatus? status;
  final String search;

  const Filters({
    this.date,
    this.category,
    this.priority,
    this.status,
    this.search = '',
  });

  Filters copyWith({
    DateTime? date,
    RoutineCategory? category,
    RoutinePriority? priority,
    RoutineStatus? status,
    String? search,
  }) => Filters(
    date: date ?? this.date,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    search: search ?? this.search,
  );

  bool matchesTitle(String title) {
    if (search.isEmpty) return true;
    return title.toLowerCase().contains(search.toLowerCase());
  }
}
