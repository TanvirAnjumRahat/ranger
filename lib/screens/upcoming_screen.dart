import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/routine_provider.dart';
import '../widgets/routine_card.dart';
import '../routes.dart';
import '../models/enums.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Sort state
  String _sortBy = 'date'; // 'date', 'time', 'category', 'title'
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final routinesProv = context.watch<RoutinesProvider>();
    final now = DateTime.now();

    // Use selected day or tomorrow as start date
    final startDate =
        _selectedDay ?? DateTime(now.year, now.month, now.day + 1);
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

    // Get upcoming routines from selected date forward
    var upcomingRoutines = routinesProv.routines.where((r) {
      final routineDate = r.date.toDate();
      final routineDateOnly = DateTime(
        routineDate.year,
        routineDate.month,
        routineDate.day,
      );
      return routineDateOnly.isAfter(startOfDay) ||
          routineDateOnly.isAtSameMomentAs(startOfDay);
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'date':
        upcomingRoutines.sort((a, b) {
          final comparison = a.date.compareTo(b.date);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'time':
        upcomingRoutines.sort((a, b) {
          final aTime = a.time.toDate();
          final bTime = b.time.toDate();
          final comparison = (aTime.hour * 60 + aTime.minute).compareTo(
            bTime.hour * 60 + bTime.minute,
          );
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'category':
        upcomingRoutines.sort((a, b) {
          final comparison = a.category.name.compareTo(b.category.name);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'title':
        upcomingRoutines.sort((a, b) {
          final comparison = a.title.toLowerCase().compareTo(
            b.title.toLowerCase(),
          );
          return _sortAscending ? comparison : -comparison;
        });
        break;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Calendar Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (selectedDay.isBefore(DateTime.now())) return;
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                    ),
                  ),
                ),

                // Sort Button - Icon only in top-right corner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: () {
                          _showSortOptions(context);
                        },
                        icon: Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                        tooltip: 'Sort',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Date Range Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDay != null
                              ? 'Showing from ${_formatDate(_selectedDay!)} onwards'
                              : 'Showing from tomorrow onwards',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Text(
                        '${upcomingRoutines.length} routine${upcomingRoutines.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),
              ],
            ),
          ),

          // Routines List
          upcomingRoutines.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming routines',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDay != null
                              ? 'No routines from selected date'
                              : 'Create a routine for future dates',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (_selectedDay != null) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedDay = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear selection'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final r = upcomingRoutines[index];
                    return RoutineCard(
                      routine: r,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.routineDetail,
                        arguments: r.id,
                      ),
                      onComplete: () async {
                        final when = DateTime.now();
                        await context.read<RoutinesProvider>().toggleComplete(
                          r,
                          when,
                        );
                        if (!context.mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text('Marked as done'),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                context.read<RoutinesProvider>().undoComplete(
                                  r,
                                  when,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }, childCount: upcomingRoutines.length),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.routineNew);
        },
        tooltip: 'Add Routine',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sort by',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    trailing: _sortBy == 'date'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      setState(() {
                        _sortBy = 'date';
                      });
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time'),
                    trailing: _sortBy == 'time'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      setState(() {
                        _sortBy = 'time';
                      });
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Category'),
                    trailing: _sortBy == 'category'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      setState(() {
                        _sortBy = 'category';
                      });
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.title),
                    title: const Text('Title'),
                    trailing: _sortBy == 'title'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      setState(() {
                        _sortBy = 'title';
                      });
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    title: Text(_sortAscending ? 'Ascending' : 'Descending'),
                    trailing: Switch(
                      value: _sortAscending,
                      onChanged: (value) {
                        setState(() {
                          _sortAscending = value;
                        });
                        setModalState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
