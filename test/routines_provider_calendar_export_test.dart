import 'package:flutter_test/flutter_test.dart';
import 'package:ranger/providers/routine_provider.dart';
import 'package:ranger/models/routine.dart';
import 'package:ranger/models/enums.dart';
import 'package:ranger/services/routine_service.dart';
import 'package:ranger/services/calendar_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _FakeRoutineService extends RoutineService {
  Routine? lastUpdated;
  _FakeRoutineService();
  @override
  Future<Routine> update(Routine data) async {
    lastUpdated = data;
    return data;
  }

  @override
  Future<Routine> create(Routine data) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Routine>> fetchForUser(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<Routine> markComplete(String id, {DateTime? at}) {
    throw UnimplementedError();
  }
}

class _FakeCalendarService extends CalendarService {
  String? lastRRule;
  String? lastEventId;
  DateTime? lastStart;
  DateTime? lastEnd;
  String? lastSummary;
  _FakeCalendarService();
  @override
  Future<String?> upsertEvent({
    required String summary,
    required DateTime start,
    required DateTime end,
    String? eventId,
    String? rrule,
  }) async {
    lastSummary = summary;
    lastStart = start;
    lastEnd = end;
    lastRRule = rrule;
    lastEventId = eventId;
    return 'evt_123';
  }
}

Routine _makeRoutine({
  RepeatType repeat = RepeatType.none,
  List<int> days = const [],
}) {
  final now = DateTime(2025, 10, 12, 9, 0);
  return Routine(
    id: 'r1',
    uid: 'u1',
    title: 'Run',
    description: null,
    date: Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
    time: Timestamp.fromDate(DateTime(now.year, now.month, now.day, 7, 30)),
    repeat: RepeatSettings(type: repeat, daysOfWeek: days),
    category: RoutineCategory.exercise,
    priority: RoutinePriority.high,
    reminders: const [],
    status: RoutineStatus.pending,
    completedDates: const [],
    attachments: const [],
    calendarEventId: null,
    createdAt: Timestamp.fromDate(now),
    updatedAt: Timestamp.fromDate(now),
  );
}

void main() {
  test('exportToCalendar updates eventId and uses RRULE', () async {
    final fakeService = _FakeRoutineService();
    final fakeCalendar = _FakeCalendarService();
    final provider = RoutinesProvider(
      service: fakeService,
      calendar: fakeCalendar,
    );
    final r = _makeRoutine(repeat: RepeatType.weekly, days: [1, 3, 5]);

    final updated = await provider.exportToCalendar(r);

    expect(updated, isNotNull);
    expect(updated!.calendarEventId, 'evt_123');
    // Verify RRULE contains BYDAY for MO,WE,FR
    expect(fakeCalendar.lastRRule, contains('FREQ=WEEKLY'));
    expect(fakeCalendar.lastRRule, contains('BYDAY=MO,WE,FR'));
  });
}
