import 'package:ranger/models/enums.dart';

/// Pre-built routine templates for quick setup
class RoutineTemplate {
  final String id;
  final String title;
  final String description;
  final RoutineCategory category;
  final RoutinePriority priority;
  final RepeatType repeatType;
  final List<int> daysOfWeek;
  final int durationMinutes;
  final String icon;
  final List<String> tips;

  const RoutineTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.repeatType,
    this.daysOfWeek = const [],
    this.durationMinutes = 30,
    required this.icon,
    this.tips = const [],
  });
}

class RoutineTemplates {
  static const List<RoutineTemplate> all = [
    RoutineTemplate(
      id: 'morning_routine',
      title: 'Morning Routine',
      description: 'Start your day with energy and focus',
      category: RoutineCategory.health,
      priority: RoutinePriority.high,
      repeatType: RepeatType.daily,
      durationMinutes: 30,
      icon: '🌅',
      tips: [
        'Wake up at the same time daily',
        'Hydrate with water first thing',
        'Do light stretching or yoga',
      ],
    ),
    RoutineTemplate(
      id: 'workout',
      title: 'Daily Workout',
      description: 'Exercise for physical and mental health',
      category: RoutineCategory.exercise,
      priority: RoutinePriority.high,
      repeatType: RepeatType.daily,
      durationMinutes: 45,
      icon: '💪',
      tips: [
        'Start with warm-up exercises',
        'Mix cardio and strength training',
        'Stay consistent with timing',
      ],
    ),
    RoutineTemplate(
      id: 'meditation',
      title: 'Meditation',
      description: 'Practice mindfulness and reduce stress',
      category: RoutineCategory.health,
      priority: RoutinePriority.medium,
      repeatType: RepeatType.daily,
      durationMinutes: 15,
      icon: '🧘',
      tips: [
        'Find a quiet, comfortable space',
        'Start with just 5 minutes',
        'Focus on your breath',
      ],
    ),
    RoutineTemplate(
      id: 'reading',
      title: 'Daily Reading',
      description: 'Expand your knowledge and relax',
      category: RoutineCategory.personal,
      priority: RoutinePriority.medium,
      repeatType: RepeatType.daily,
      durationMinutes: 30,
      icon: '📚',
      tips: [
        'Set a page or time goal',
        'Choose a quiet environment',
        'Keep a reading list',
      ],
    ),
    RoutineTemplate(
      id: 'meal_prep',
      title: 'Meal Prep Sunday',
      description: 'Prepare healthy meals for the week',
      category: RoutineCategory.health,
      priority: RoutinePriority.high,
      repeatType: RepeatType.weekly,
      daysOfWeek: [7],
      durationMinutes: 120,
      icon: '🥗',
      tips: [
        'Plan meals in advance',
        'Shop for fresh ingredients',
        'Use containers for portions',
      ],
    ),
    RoutineTemplate(
      id: 'study_session',
      title: 'Study Session',
      description: 'Focused learning and skill development',
      category: RoutineCategory.work,
      priority: RoutinePriority.high,
      repeatType: RepeatType.weekly,
      daysOfWeek: [1, 3, 5],
      durationMinutes: 60,
      icon: '📖',
      tips: [
        'Use the Pomodoro technique',
        'Eliminate distractions',
        'Take regular breaks',
      ],
    ),
    RoutineTemplate(
      id: 'deep_work',
      title: 'Deep Work Block',
      description: 'Focused time for important tasks',
      category: RoutineCategory.work,
      priority: RoutinePriority.high,
      repeatType: RepeatType.weekly,
      daysOfWeek: [1, 2, 3, 4, 5],
      durationMinutes: 90,
      icon: '💼',
      tips: [
        'Block calendar time',
        'Turn off notifications',
        'Work on one task at a time',
      ],
    ),
    RoutineTemplate(
      id: 'evening_wind_down',
      title: 'Evening Wind Down',
      description: 'Relax and prepare for quality sleep',
      category: RoutineCategory.health,
      priority: RoutinePriority.medium,
      repeatType: RepeatType.daily,
      durationMinutes: 30,
      icon: '🌙',
      tips: [
        'Avoid screens 1 hour before bed',
        'Keep bedroom cool and dark',
        'Practice gratitude journaling',
      ],
    ),
    RoutineTemplate(
      id: 'family_time',
      title: 'Family Time',
      description: 'Quality time with loved ones',
      category: RoutineCategory.personal,
      priority: RoutinePriority.high,
      repeatType: RepeatType.daily,
      durationMinutes: 60,
      icon: '👨‍👩‍👧‍👦',
      tips: [
        'Put away devices',
        'Plan activities together',
        'Share meals without distractions',
      ],
    ),
    RoutineTemplate(
      id: 'weekly_review',
      title: 'Weekly Review',
      description: 'Reflect on progress and plan ahead',
      category: RoutineCategory.personal,
      priority: RoutinePriority.medium,
      repeatType: RepeatType.weekly,
      daysOfWeek: [7],
      durationMinutes: 45,
      icon: '📊',
      tips: [
        'Review completed tasks',
        'Set goals for next week',
        'Celebrate small wins',
      ],
    ),
  ];
}
