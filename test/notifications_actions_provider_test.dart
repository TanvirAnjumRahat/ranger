import 'package:flutter_test/flutter_test.dart';
import 'package:ranger/providers/routine_provider.dart';
import 'package:ranger/models/routine.dart';
import 'package:ranger/models/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ranger/services/routine_service.dart';

class _FakeService extends RoutineService {
  Routine _r;
  _FakeService(this._r);
  @override
  Future<List<Routine>> fetchForUser(String uid) async {
    return [_r];
  }

  @override
  Future<Routine> markComplete(String id, {DateTime? at}) async {
    final ts = Timestamp.fromDate(at ?? DateTime.now());
    final updated = _r.copyWith(
      status: RoutineStatus.completed,
      completedDates: [..._r.completedDates, ts],
      updatedAt: Timestamp.now(),
    );
    _r = updated;
    return updated;
  }

  @override
  Future<Routine> unmarkComplete(String id, {required DateTime at}) async {
    final ms = at.millisecondsSinceEpoch;
    final filtered = _r.completedDates
        .where((t) => t.toDate().millisecondsSinceEpoch != ms)
        .toList();
    final updated = _r.copyWith(
      status: filtered.isEmpty ? RoutineStatus.pending : _r.status,
      completedDates: filtered,
      updatedAt: Timestamp.now(),
    );
    _r = updated;
    return updated;
  }

  @override
  Future<Routine> unmarkLastComplete(String id) async {
    if (_r.completedDates.isEmpty) return _r;
    final sorted = [..._r.completedDates]
      ..sort((a, b) => b.toDate().compareTo(a.toDate()));
    final latest = sorted.first;
    final filtered = _r.completedDates
        .where(
          (t) =>
              t.toDate().millisecondsSinceEpoch !=
              latest.toDate().millisecondsSinceEpoch,
        )
        .toList();
    final updated = _r.copyWith(
      status: filtered.isEmpty ? RoutineStatus.pending : _r.status,
      completedDates: filtered,
      updatedAt: Timestamp.now(),
    );
    _r = updated;
    return updated;
  }
}

Routine _mkRoutine() {
  final now = DateTime(2025, 10, 12, 7, 30);
  return Routine(
    id: 'r1',
    uid: 'u1',
    title: 'Test',
    description: null,
    date: Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
    time: Timestamp.fromDate(now),
    repeat: const RepeatSettings(type: RepeatType.none),
    category: RoutineCategory.work,
    priority: RoutinePriority.medium,
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
  test('toggleComplete then undoComplete reverts state', () async {
    final r0 = _mkRoutine();
    final fake = _FakeService(r0);
    final prov = RoutinesProvider(service: fake, notifier: null);

    // Seed provider with routine via load
    await prov.loadRoutinesForUser('u1');

    // Manually set routines list by calling private members isn't possible.
    // So we simulate by toggling complete and relying on index lookup by id.

    // First, mark complete
    await prov.toggleComplete(r0, DateTime(2025, 10, 12, 8));
    expect(prov.routines.any((e) => e.id == r0.id), isTrue);
    final after = prov.routines.firstWhere((e) => e.id == r0.id);
    expect(after.status, RoutineStatus.completed);
    expect(after.completedDates, isNotEmpty);

    // Undo the specific completion
    await prov.undoComplete(after, DateTime(2025, 10, 12, 8));
    final afterUndo = prov.routines.firstWhere((e) => e.id == r0.id);
    expect(afterUndo.status, RoutineStatus.pending);
  });
}
