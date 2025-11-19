import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../models/routine.dart';
import '../routes.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/streak_widget.dart';

class RoutineDetailScreen extends StatelessWidget {
  final String routineId;
  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RoutinesProvider>();
    Routine? r;
    for (final e in prov.routines) {
      if (e.id == routineId) {
        r = e;
        break;
      }
    }
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Routine Details')),
        body: const Center(child: Text('Routine not found')),
      );
    }
    final rr = r;
    return Scaffold(
      appBar: AppBar(
        title: Text(rr.title),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.routineEdit,
              arguments: rr.id,
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete routine?'),
                  content: const Text(
                    'This will remove the routine and its attachments.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await context.read<RoutinesProvider>().deleteRoutine(rr.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streak Tracking
          StreakWidget(routine: rr),
          const SizedBox(height: 16),
          if (rr.description != null && rr.description!.isNotEmpty) ...[
            Text(rr.description!),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Category: ${rr.category.name}')),
              Chip(label: Text('Priority: ${rr.priority.name}')),
              Chip(label: Text('Status: ${rr.status.name}')),
            ],
          ),
          const Divider(height: 24),
          const Text(
            'Attachments',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (rr.attachments.isEmpty) const Text('No attachments'),
          ...rr.attachments.map(
            (a) => ListTile(
              leading: Icon(
                a.type == 'image' ? Icons.image : Icons.insert_drive_file,
              ),
              title: Text(a.name, overflow: TextOverflow.ellipsis),
              subtitle: Text('${a.size} bytes'),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () async {
                  final uri = Uri.parse(a.url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.routineEdit,
              arguments: rr.id,
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Exporting ${rr.title} to Google Calendar...'),
                ),
              );
              final updated = await context
                  .read<RoutinesProvider>()
                  .exportToCalendar(rr);
              messenger.hideCurrentSnackBar();
              if (updated != null) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Exported to Google Calendar')),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Calendar export failed')),
                );
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              rr.calendarEventId == null
                  ? 'Export to Google Calendar'
                  : 'Update Google Calendar Event',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: rr.status.name == 'completed'
                ? null
                : () async {
                    final when = DateTime.now();
                    await context.read<RoutinesProvider>().toggleComplete(
                      rr,
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
                              rr,
                              when,
                            );
                          },
                        ),
                      ),
                    );
                  },
            icon: Icon(
              rr.status.name == 'completed'
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
            ),
            label: Text(
              rr.status.name == 'completed' ? 'Completed' : 'Mark as done',
            ),
          ),
        ],
      ),
    );
  }
}
