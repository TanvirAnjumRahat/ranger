import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/routine_provider.dart';
import '../models/routine.dart';
import '../models/enums.dart';
import '../routes.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _CalendarBody(),
    );
  }
}

class _CalendarBody extends StatefulWidget {
  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Routine>> _occurrenceIndex = {};

  List<Routine> _eventsForDay(DateTime day, List<Routine> routines) {
    final key = DateTime(day.year, day.month, day.day);
    return _occurrenceIndex[key] ?? const [];
  }

  void _rebuildOccurrences(List<Routine> routines) {
    final rangeStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final rangeEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final map = <DateTime, List<Routine>>{};

    DateTime clampStart(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
    DateTime clampEnd(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

    for (final r in routines) {
      final startDate = DateTime(
        r.date.toDate().year,
        r.date.toDate().month,
        r.date.toDate().day,
      );
      final until = r.repeat.endDate?.toDate();
      final repeatEnd = until == null
          ? rangeEnd
          : DateTime(until.year, until.month, until.day);
      final effectiveStart = clampStart(startDate, rangeStart);
      final effectiveEnd = clampEnd(repeatEnd, rangeEnd);
      if (effectiveStart.isAfter(effectiveEnd)) continue;

      void addOn(DateTime d) {
        final key = DateTime(d.year, d.month, d.day);
        (map[key] ??= []).add(r);
      }

      if (r.repeat.type == RepeatType.none) {
        if (!startDate.isBefore(rangeStart) && !startDate.isAfter(rangeEnd)) {
          addOn(startDate);
        }
        continue;
      }

      if (r.repeat.type == RepeatType.daily) {
        for (
          DateTime d = effectiveStart;
          !d.isAfter(effectiveEnd);
          d = d.add(const Duration(days: 1))
        ) {
          addOn(d);
        }
        continue;
      }

      if (r.repeat.type == RepeatType.weekly ||
          r.repeat.type == RepeatType.custom) {
        final days = r.repeat.daysOfWeek.isEmpty
            ? List<int>.generate(7, (i) => i + 1)
            : r.repeat.daysOfWeek;
        for (final wd in days) {
          final startWday = effectiveStart.weekday; // 1..7 Mon..Sun
          var daysAhead = (wd - startWday) % 7;
          var first = effectiveStart.add(Duration(days: daysAhead));
          if (first.isBefore(startDate)) {
            final diff = startDate.difference(first).inDays;
            final adjust = ((diff + 6) ~/ 7) * 7; // ceil to next week boundary
            first = first.add(Duration(days: adjust));
          }
          for (
            DateTime d = first;
            !d.isAfter(effectiveEnd);
            d = d.add(const Duration(days: 7))
          ) {
            addOn(d);
          }
        }
        continue;
      }
    }
    _occurrenceIndex = map;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RoutinesProvider>();
    final routines = prov.routines;
    _rebuildOccurrences(routines);
    final selected = _selectedDay ?? _focusedDay;
    final dayEvents = _eventsForDay(selected, routines);

    return Column(
      children: [
        TableCalendar<Routine>(
          firstDay: DateTime.utc(2015, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          eventLoader: (day) => _eventsForDay(day, routines),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: dayEvents.length,
            itemBuilder: (context, index) {
              final r = dayEvents[index];
              return ListTile(
                title: Text(r.title),
                subtitle: Text(r.category.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.routineDetail,
                  arguments: r.id,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
