import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/routine_detail_screen.dart';
import 'screens/routine_form_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/templates_screen.dart';
import 'screens/incomplete_tasks_screen.dart';

class AppRoutes {
  static const home = '/home';
  static const routineNew = '/routine/new';
  static const routineDetail = '/routine/:id';
  static const routineEdit = '/routine/:id/edit';
  static const analytics = '/analytics';
  static const settings = '/settings';
  static const templates = '/templates';
  static const incompleteTasks = '/incomplete-tasks';
}

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final name = settings.name;
  final args = settings.arguments;
  if (name == AppRoutes.home) {
    return MaterialPageRoute(builder: (_) => const HomeScreen());
  }
  if (name == AppRoutes.routineNew) {
    return MaterialPageRoute(builder: (_) => const RoutineFormScreen());
  }
  if (name == AppRoutes.analytics) {
    return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
  }
  if (name == AppRoutes.settings) {
    return MaterialPageRoute(builder: (_) => const SettingsScreen());
  }
  if (name == AppRoutes.templates) {
    return MaterialPageRoute(builder: (_) => const TemplatesScreen());
  }
  if (name == AppRoutes.incompleteTasks) {
    return MaterialPageRoute(builder: (_) => const IncompleteTasksScreen());
  }

  // Fallback for detail/edit with dynamic id should be handled by pushNamed with args
  if (name == AppRoutes.routineDetail && args is String) {
    return MaterialPageRoute(
      builder: (_) => RoutineDetailScreen(routineId: args),
    );
  }
  if (name == AppRoutes.routineEdit && args is String) {
    return MaterialPageRoute(
      builder: (_) => RoutineFormScreen(routineId: args),
    );
  }
  return null;
}
