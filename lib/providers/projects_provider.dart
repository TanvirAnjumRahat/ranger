import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectsProvider with ChangeNotifier {
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _error;
  String _sortBy = 'priority'; // 'priority', 'deadline', 'category', 'date'
  String? _filterCategory;
  String? _filterPriority;

  ProjectsProvider() {
    loadProjects();
  }

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get sortBy => _sortBy;
  String get currentSortBy => _sortBy;
  String? get filterCategory => _filterCategory;
  String? get filterPriority => _filterPriority;
  bool get hasActiveFilters =>
      _filterCategory != null || _filterPriority != null;

  void setSortBy(String value) {
    _sortBy = value;
    notifyListeners();
  }

  void setFilterCategory(String? value) {
    _filterCategory = value;
    notifyListeners();
  }

  void setFilterPriority(String? value) {
    _filterPriority = value;
    notifyListeners();
  }

  void clearFilters() {
    _filterCategory = null;
    _filterPriority = null;
    notifyListeners();
  }

  // Get projects sorted by priority and deadline
  List<Project> get sortedProjects {
    var list = List<Project>.from(_projects);

    // Apply filters
    if (_filterCategory != null) {
      list = list.where((p) => p.category.name == _filterCategory).toList();
    }
    if (_filterPriority != null) {
      list = list.where((p) => p.priority.name == _filterPriority).toList();
    }

    // Apply sorting
    list.sort((a, b) {
      // Always show incomplete projects first
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      switch (_sortBy) {
        case 'deadline':
          // Sort by deadline (nearest first)
          if (a.deadline != null && b.deadline != null) {
            return a.deadline!.compareTo(b.deadline!);
          }
          if (a.deadline != null) return -1;
          if (b.deadline != null) return 1;
          return b.createdAt.compareTo(a.createdAt);

        case 'category':
          // Sort by category name
          final catCompare = a.category.name.compareTo(b.category.name);
          if (catCompare != 0) return catCompare;
          return b.createdAt.compareTo(a.createdAt);

        case 'date':
          // Sort by creation date (newest first)
          return b.createdAt.compareTo(a.createdAt);

        case 'priority':
        default:
          // Sort by priority
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          final aP = priorityOrder[a.priority.name] ?? 2;
          final bP = priorityOrder[b.priority.name] ?? 2;
          if (aP != bP) return aP.compareTo(bP);

          // Then by deadline
          if (a.deadline != null && b.deadline != null) {
            return a.deadline!.compareTo(b.deadline!);
          }
          if (a.deadline != null) return -1;
          if (b.deadline != null) return 1;

          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return list;
  }

  // Get active (incomplete) projects
  List<Project> get activeProjects =>
      _projects.where((p) => !p.isCompleted).toList();

  // Get completed projects
  List<Project> get completedProjects =>
      _projects.where((p) => p.isCompleted).toList();

  // Load all projects
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      _projects = snapshot.docs.map((doc) => Project.fromDoc(doc)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load projects: $e';
      _projects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new project
  Future<String?> createProject({
    required String title,
    String? description,
    required String category,
    required String priority,
    Timestamp? deadline,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final now = Timestamp.now();
      final docRef = await FirebaseFirestore.instance
          .collection('projects')
          .add({
            'uid': uid,
            'title': title,
            'description': description,
            'category': category,
            'priority': priority,
            'tasks': [],
            'deadline': deadline,
            'createdAt': now,
            'updatedAt': now,
          });

      await loadProjects();
      return docRef.id;
    } catch (e) {
      _error = 'Failed to create project: $e';
      notifyListeners();
      return null;
    }
  }

  // Update project
  Future<bool> updateProject(Project project) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(project.id)
          .update(project.copyWith(updatedAt: Timestamp.now()).toMap());

      await loadProjects();
      return true;
    } catch (e) {
      _error = 'Failed to update project: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete project
  Future<bool> deleteProject(String projectId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .delete();

      _projects.removeWhere((p) => p.id == projectId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete project: $e';
      notifyListeners();
      return false;
    }
  }

  // Add task to project
  Future<bool> addTaskToProject(
    String projectId,
    String taskTitle,
    String? taskDescription,
  ) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final newTask = ProjectTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: taskTitle,
        description: taskDescription,
        createdAt: Timestamp.now(),
      );

      final updatedTasks = [...project.tasks, newTask];
      await updateProject(project.copyWith(tasks: updatedTasks));
      return true;
    } catch (e) {
      _error = 'Failed to add task: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle task completion
  Future<bool> toggleTaskCompletion(String projectId, String taskId) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final updatedTasks = project.tasks.map((task) {
        if (task.id == taskId) {
          return task.copyWith(
            isCompleted: !task.isCompleted,
            completedAt: !task.isCompleted ? Timestamp.now() : null,
          );
        }
        return task;
      }).toList();

      await updateProject(project.copyWith(tasks: updatedTasks));
      return true;
    } catch (e) {
      _error = 'Failed to toggle task: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete task from project
  Future<bool> deleteTask(String projectId, String taskId) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final updatedTasks = project.tasks.where((t) => t.id != taskId).toList();

      await updateProject(project.copyWith(tasks: updatedTasks));
      return true;
    } catch (e) {
      _error = 'Failed to delete task: $e';
      notifyListeners();
      return false;
    }
  }

  // Get project by ID
  Project? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }
}
