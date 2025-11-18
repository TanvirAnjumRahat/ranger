import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/routine.dart';
import '../models/enums.dart';
import '../app_navigator.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../utils/time_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb)
      return; // local notifications unsupported on web
    await TimeUtils.ensureInitialized();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS categories for actions
    final iosSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'ROUTINE_ACTIONS',
          actions: [
            DarwinNotificationAction.plain('MARK_COMPLETE', 'Mark Complete'),
            DarwinNotificationAction.plain('UNDO_COMPLETE', 'Undo'),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onAction,
    );
    _initialized = true;
  }

  void _onAction(NotificationResponse response) {
    final action = response.actionId;
    final routineId = response.payload;
    if (routineId == null) return;
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    final prov = context.read<RoutinesProvider>();
    Routine? r;
    for (final e in prov.routines) {
      if (e.id == routineId) {
        r = e;
        break;
      }
    }
    if (r == null) return;
    if (action == 'MARK_COMPLETE') {
      prov.toggleComplete(r, DateTime.now());
    } else if (action == 'UNDO_COMPLETE') {
      prov.undoLastComplete(r);
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final android = _fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    } else {
      final ios = _fln
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> scheduleForRoutine(Routine r) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();
    final androidChannel = AndroidNotificationDetails(
      'routine_channel',
      'Routine Reminders',
      channelDescription: 'Notifications for routine reminders',
      importance: Importance.max,
      priority: Priority.high,
      actions: const [
        AndroidNotificationAction(
          'MARK_COMPLETE',
          'Mark Complete',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'UNDO_COMPLETE',
          'Undo',
          showsUserInterface: true,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'ROUTINE_ACTIONS',
    );
    final details = NotificationDetails(
      android: androidChannel,
      iOS: iosDetails,
    );

    final date = r.date.toDate();
    final time = r.time.toDate();

    // Determine schedule times based on repeat type
    final List<_ScheduleSpec> specs = _buildScheduleSpecs(r, date, time);
    final idBase = r.id.hashCode & 0x7fffffff;

    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      // Base notification
      await _fln.zonedSchedule(
        idBase + i * 20,
        r.title,
        r.description ?? 'Routine reminder',
        spec.when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: spec.match,
        payload: r.id,
      );
      // Reminder offsets under this occurrence
      for (var j = 0; j < r.reminders.length; j++) {
        final rem = r.reminders[j];
        final at = spec.when.subtract(Duration(minutes: rem.minutesBefore));
        await _fln.zonedSchedule(
          idBase + i * 20 + j + 1,
          r.title,
          'Reminder in ${rem.minutesBefore} minutes',
          at,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: spec.match,
          payload: r.id,
        );
      }
    }
  }

  Future<void> cancelForRoutine(Routine r) async {
    if (kIsWeb) return;
    final idBase = r.id.hashCode & 0x7fffffff;
    // Cancel across a reasonable window for occurrences and reminders
    for (int i = 0; i < 200; i++) {
      await _fln.cancel(idBase + i);
    }
  }

  List<_ScheduleSpec> _buildScheduleSpecs(
    Routine r,
    DateTime date,
    DateTime time,
  ) {
    final local = tz.local;
    tz.TZDateTime makeWhen(DateTime d) =>
        tz.TZDateTime(local, d.year, d.month, d.day, time.hour, time.minute);

    if (r.repeat.type == RepeatType.none) {
      final when = makeWhen(date);
      return [_ScheduleSpec(when: _futureOrNextDay(when), match: null)];
    }
    if (r.repeat.type == RepeatType.daily) {
      final when = makeWhen(DateTime.now());
      return [
        _ScheduleSpec(
          when: _futureOrTomorrow(when),
          match: DateTimeComponents.time,
        ),
      ];
    }
    // Weekly or Custom weekly days
    final days = (r.repeat.daysOfWeek.isEmpty)
        ? List<int>.generate(7, (i) => i + 1)
        : r.repeat.daysOfWeek;
    final now = tz.TZDateTime.now(local);
    final specs = <_ScheduleSpec>[];
    for (final day in days) {
      final when = _nextInstanceOfWeekday(
        day,
        now,
        hour: time.hour,
        minute: time.minute,
      );
      specs.add(
        _ScheduleSpec(when: when, match: DateTimeComponents.dayOfWeekAndTime),
      );
    }
    return specs;
  }

  tz.TZDateTime _futureOrNextDay(tz.TZDateTime when) {
    final now = tz.TZDateTime.now(tz.local);
    if (when.isBefore(now)) {
      return when.add(const Duration(days: 1));
    }
    return when;
  }

  tz.TZDateTime _futureOrTomorrow(tz.TZDateTime when) {
    final now = tz.TZDateTime.now(tz.local);
    if (when.isBefore(now)) {
      return when.add(const Duration(days: 1));
    }
    return when;
  }

  tz.TZDateTime _nextInstanceOfWeekday(
    int weekdayMon1,
    tz.TZDateTime from, {
    required int hour,
    required int minute,
  }) {
    // Convert our 1..7 Mon..Sun to Dart's 1..7 Mon..Sun tz.TZDateTime.weekday matches same
    var daysAhead = (weekdayMon1 - from.weekday) % 7;
    if (daysAhead == 0) {
      final candidate = tz.TZDateTime(
        tz.local,
        from.year,
        from.month,
        from.day,
        hour,
        minute,
      );
      if (!candidate.isAfter(from)) daysAhead = 7;
    }
    final next = from.add(Duration(days: daysAhead));
    return tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      hour,
      minute,
    );
  }
}

class _ScheduleSpec {
  final tz.TZDateTime when;
  final DateTimeComponents? match;
  const _ScheduleSpec({required this.when, required this.match});
}
