import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ranger/screens/routine_detail_screen.dart';
import 'package:ranger/providers/routine_provider.dart';
import 'package:ranger/models/routine.dart';
import 'package:ranger/models/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _FakeRoutinesProvider extends RoutinesProvider {
  final List<Routine> _fakeRoutines;
  int exportCalls = 0;
  _FakeRoutinesProvider(this._fakeRoutines)
    : super(service: null, notifier: null, calendar: null);

  @override
  List<Routine> get routines => _fakeRoutines;

  @override
  Future<Routine?> exportToCalendar(Routine r) async {
    exportCalls++;
    return r.copyWith(calendarEventId: 'evt_abc');
  }
}

Routine _makeRoutine() {
  final now = DateTime(2025, 10, 12);
  return Routine(
    id: 'r1',
    uid: 'u1',
    title: 'Morning Run',
    description: 'Run 5k',
    date: Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
    time: Timestamp.fromDate(DateTime(now.year, now.month, now.day, 7, 30)),
    repeat: const RepeatSettings(type: RepeatType.none),
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
  testWidgets('Export button calls provider.exportToCalendar', (tester) async {
    final routine = _makeRoutine();
    final provider = _FakeRoutinesProvider([routine]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RoutinesProvider>.value(value: provider),
        ],
        child: const MaterialApp(home: RoutineDetailScreen(routineId: 'r1')),
      ),
    );

    // Tap Export button
    final exportText = find.text('Export to Google Calendar');
    expect(exportText, findsOneWidget);
    await tester.tap(exportText);
    await tester.pumpAndSettle();

    expect(provider.exportCalls, 1);
  });
}
