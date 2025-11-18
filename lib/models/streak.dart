import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks user streaks for consistency
class StreakData {
  final String routineId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int totalCompletions;

  StreakData({
    required this.routineId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
    required this.totalCompletions,
  });

  Map<String, dynamic> toMap() {
    return {
      'routineId': routineId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate != null
          ? Timestamp.fromDate(lastCompletedDate!)
          : null,
      'totalCompletions': totalCompletions,
    };
  }

  factory StreakData.fromMap(Map<String, dynamic> map) {
    return StreakData(
      routineId: map['routineId'] ?? '',
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastCompletedDate: map['lastCompletedDate'] != null
          ? (map['lastCompletedDate'] as Timestamp).toDate()
          : null,
      totalCompletions: map['totalCompletions'] ?? 0,
    );
  }

  StreakData copyWith({
    String? routineId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    int? totalCompletions,
  }) {
    return StreakData(
      routineId: routineId ?? this.routineId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      totalCompletions: totalCompletions ?? this.totalCompletions,
    );
  }
}
