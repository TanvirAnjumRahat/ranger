import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class ProjectTask {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final Timestamp? completedAt;
  final Timestamp createdAt;

  const ProjectTask({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'isCompleted': isCompleted,
    if (completedAt != null) 'completedAt': completedAt,
    'createdAt': createdAt,
  };

  factory ProjectTask.fromMap(Map<String, dynamic> map) => ProjectTask(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    isCompleted: (map['isCompleted'] as bool?) ?? false,
    completedAt: map['completedAt'] as Timestamp?,
    createdAt: (map['createdAt'] as Timestamp?) ?? Timestamp.now(),
  );

  ProjectTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    Timestamp? completedAt,
    Timestamp? createdAt,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Project {
  final String id;
  final String uid;
  final String title;
  final String? description;
  final RoutineCategory category;
  final RoutinePriority priority;
  final List<ProjectTask> tasks;
  final Timestamp? deadline;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const Project({
    required this.id,
    required this.uid,
    required this.title,
    this.description,
    this.category = RoutineCategory.others,
    this.priority = RoutinePriority.medium,
    this.tasks = const [],
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    return (completedCount / tasks.length) * 100;
  }

  // Get completed tasks count
  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;

  // Check if project is completed
  bool get isCompleted => tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'title': title,
    if (description != null) 'description': description,
    'category': category.name,
    'priority': priority.name,
    'tasks': tasks.map((e) => e.toMap()).toList(),
    if (deadline != null) 'deadline': deadline,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Project.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Project(
      id: doc.id,
      uid: data['uid'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      category: RoutineCategory.values.firstWhere(
        (e) => e.name == (data['category'] as String? ?? 'others'),
        orElse: () => RoutineCategory.others,
      ),
      priority: RoutinePriority.values.firstWhere(
        (e) => e.name == (data['priority'] as String? ?? 'medium'),
        orElse: () => RoutinePriority.medium,
      ),
      tasks: ((data['tasks'] as List?) ?? const [])
          .map((e) => ProjectTask.fromMap((e as Map).cast<String, dynamic>()))
          .toList(),
      deadline: data['deadline'] as Timestamp?,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Project copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    RoutineCategory? category,
    RoutinePriority? priority,
    List<ProjectTask>? tasks,
    Timestamp? deadline,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      tasks: tasks ?? this.tasks,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
