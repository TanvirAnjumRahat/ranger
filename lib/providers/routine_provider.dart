import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/enums.dart';
import '../services/routine_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/calendar_service.dart';

class RoutinesProvider extends ChangeNotifier {
  final RoutineService _service;
  final NotificationService _notifier;
  CalendarService? _calendar;
  RoutinesProvider({
    RoutineService? service,
    NotificationService? notifier,
    CalendarService? calendar,
  }) : _service = service ?? RoutineService(),
       _notifier = notifier ?? NotificationService(),
       _calendar = calendar;

  List<Routine> _routines = [];
  List<Routine> get routines => _routines;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  Future<void> loadRoutinesForUser(String uid) async {
    _setError(null);
    _setLoading(true);
    try {
      _routines = await _service.fetchForUser(uid);
      // Schedule notifications for all loaded routines
      await _rescheduleAllNotifications();
    } catch (e) {
      _setError('Failed to load routines: ' + e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Reschedule notifications for all active routines
  Future<void> _rescheduleAllNotifications() async {
    if (kDebugMode) {
      print('📱 Rescheduling notifications for ${_routines.length} routines');
    }
    for (final routine in _routines) {
      // Only schedule for non-completed routines
      if (routine.status != RoutineStatus.completed) {
        try {
          await _notifier.scheduleForRoutine(routine);
        } catch (e) {
          if (kDebugMode) {
            print(
              '⚠️ Failed to schedule notification for ${routine.title}: $e',
            );
          }
        }
      }
    }
    if (kDebugMode) {
      print('✅ Notification rescheduling completed');
    }
  }

  /// Manually reschedule all notifications (useful for troubleshooting)
  Future<void> rescheduleAllNotifications() async {
    await _rescheduleAllNotifications();
  }

  Future<void> addRoutine(Routine r) async {
    _setError(null);
    try {
      final created = await _service.create(r);
      _routines = [..._routines, created];
      notifyListeners();
      await _notifier.scheduleForRoutine(created);
    } catch (e) {
      _setError('Failed to create routine');
    }
  }

  Future<void> updateRoutine(Routine r) async {
    _setError(null);
    try {
      final updated = await _service.update(r);
      final idx = _routines.indexWhere((x) => x.id == r.id);
      if (idx != -1) {
        _routines = [..._routines]..[idx] = updated;
      }
      notifyListeners();
      await _notifier.cancelForRoutine(r);
      await _notifier.scheduleForRoutine(updated);
    } catch (e) {
      _setError('Failed to update routine');
    }
  }

  Future<void> deleteRoutine(String id) async {
    _setError(null);
    try {
      final existing = _routines.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('not-found'),
      );
      // Clean up notifications and attachments
      await _notifier.cancelForRoutine(existing);
      final storage = StorageService();
      for (final a in existing.attachments) {
        await storage.deleteByUrl(a.url);
      }
      await _service.delete(id);
      _routines = _routines.where((e) => e.id != id).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete routine');
    }
  }

  Future<void> toggleComplete(Routine r, DateTime date) async {
    try {
      final updated = await _service.markComplete(r.id, at: date);
      final idx = _routines.indexWhere((x) => x.id == r.id);
      if (idx != -1) {
        _routines = [..._routines]..[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark complete');
    }
  }

  Future<void> undoComplete(Routine r, DateTime date) async {
    try {
      final updated = await _service.unmarkComplete(r.id, at: date);
      final idx = _routines.indexWhere((x) => x.id == r.id);
      if (idx != -1) {
        _routines = [..._routines]..[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to undo completion');
    }
  }

  Future<void> undoLastComplete(Routine r) async {
    try {
      final updated = await _service.unmarkLastComplete(r.id);
      final idx = _routines.indexWhere((x) => x.id == r.id);
      if (idx != -1) {
        _routines = [..._routines]..[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to undo completion');
    }
  }

  // Export or update a Google Calendar event for a routine.
  Future<Routine?> exportToCalendar(Routine r) async {
    try {
      // Lazily create calendar service to avoid early GoogleSignIn init on web
      final calendar = _calendar ??= CalendarService();
      // Determine start and end time from routine's date/time
      final d = r.date.toDate();
      final t = r.time.toDate();
      final start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      final end = start.add(Duration(minutes: r.durationMinutes));
      final rrule = CalendarService.buildRRule(r.repeat);
      final newId = await calendar.upsertEvent(
        summary: r.title,
        start: start,
        end: end,
        eventId: r.calendarEventId,
        rrule: rrule,
      );
      if (newId == null) return null;
      final updated = await _service.update(r.copyWith(calendarEventId: newId));
      final idx = _routines.indexWhere((x) => x.id == r.id);
      if (idx != -1) {
        _routines = [..._routines]..[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _setError('Failed to export to calendar');
      return null;
    }
  }
}
