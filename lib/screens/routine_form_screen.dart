import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/routine.dart';
import '../models/reminder.dart';
import '../providers/routine_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';

class RoutineFormScreen extends StatefulWidget {
  final String? routineId;
  const RoutineFormScreen({super.key, this.routineId});

  @override
  State<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends State<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  RoutineCategory _category = RoutineCategory.others;
  RoutinePriority _priority = RoutinePriority.medium;
  RepeatType _repeatType = RepeatType.none;
  final List<int> _daysOfWeek = [];
  final List<Reminder> _reminders = [];
  final List<AttachmentMeta> _attachments = [];
  final _storage = StorageService();
  final Set<String> _originalAttachmentUrls = {};

  Routine? _editing;

  @override
  void initState() {
    super.initState();
    if (widget.routineId != null) {
      final prov = context.read<RoutinesProvider>();
      _editing = prov.routines.firstWhere(
        (e) => e.id == widget.routineId,
        orElse: () => _editing ?? (throw Exception('Routine not found')),
      );
      _titleCtrl.text = _editing!.title;
      _descCtrl.text = _editing!.description ?? '';
      final d = _editing!.date.toDate();
      final t = _editing!.time.toDate();
      _date = DateTime(d.year, d.month, d.day);
      _time = TimeOfDay(hour: t.hour, minute: t.minute);
      _category = _editing!.category;
      _priority = _editing!.priority;
      _repeatType = _editing!.repeat.type;
      _daysOfWeek.addAll(_editing!.repeat.daysOfWeek);
      _reminders.addAll(_editing!.reminders);
      _attachments.addAll(_editing!.attachments);
      _originalAttachmentUrls.addAll(_editing!.attachments.map((a) => a.url));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _addReminder() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add reminder (minutes before)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g., 30'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v == null || v < 0) return;
              Navigator.pop(context, v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != null) setState(() => _reminders.add(Reminder(minutesBefore: ok)));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final d = DateTime(_date!.year, _date!.month, _date!.day);
    final dateTs = Timestamp.fromDate(d);
    final timeTs = Timestamp.fromDate(
      DateTime(d.year, d.month, d.day, _time!.hour, _time!.minute),
    );
    final repeat = RepeatSettings(
      type: _repeatType,
      daysOfWeek: List.of(_daysOfWeek),
    );
    final now = Timestamp.now();

    final base = Routine(
      id: _editing?.id ?? '',
      uid: user.uid,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: dateTs,
      time: timeTs,
      repeat: repeat,
      category: _category,
      priority: _priority,
      reminders: List.of(_reminders),
      status: _editing?.status ?? RoutineStatus.pending,
      createdAt: _editing?.createdAt ?? now,
      updatedAt: now,
      location: _editing?.location,
      completedDates: _editing?.completedDates ?? const [],
      attachments: List.of(_attachments),
      calendarEventId: _editing?.calendarEventId,
    );

    final prov = context.read<RoutinesProvider>();
    if (_editing == null) {
      await prov.addRoutine(base);
    } else {
      await prov.updateRoutine(base);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.routineId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Routine' : 'New Routine'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        Validators.requiredText(v, field: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _date == null
                                ? 'Pick date'
                                : '${_date!.year}-${_date!.month}-${_date!.day}',
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _time == null
                                ? 'Pick time'
                                : _time!.format(context),
                          ),
                          onPressed: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<RoutineCategory>(
                          value: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: RoutineCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _category = v ?? _category),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<RoutinePriority>(
                          value: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: RoutinePriority.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _priority = v ?? _priority),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RepeatType>(
                    value: _repeatType,
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      border: OutlineInputBorder(),
                    ),
                    items: RepeatType.values
                        .map(
                          (r) =>
                              DropdownMenuItem(value: r, child: Text(r.name)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _repeatType = v ?? _repeatType),
                  ),
                  if (_repeatType == RepeatType.weekly ||
                      _repeatType == RepeatType.custom) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (i) {
                        final day = i + 1; // 1..7
                        final selected = _daysOfWeek.contains(day);
                        const labels = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        return FilterChip(
                          label: Text(labels[i]),
                          selected: selected,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _daysOfWeek.add(day);
                            } else {
                              _daysOfWeek.remove(day);
                            }
                          }),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reminders',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: _addReminder,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: _reminders
                        .asMap()
                        .entries
                        .map(
                          (e) => Chip(
                            label: Text('${e.value.minutesBefore} min before'),
                            onDeleted: () =>
                                setState(() => _reminders.removeAt(e.key)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attachments',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            withData: true,
                            allowMultiple: true,
                          );
                          if (res == null) return;
                          final user = context.read<AuthProvider>().user;
                          if (user == null) return;
                          for (final f in res.files) {
                            try {
                              final path =
                                  'attachments/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${f.name}';
                              final url = await _storage.uploadFile(
                                path: path,
                                bytes: f.bytes,
                                contentType: f.bytes != null
                                    ? f.extension
                                    : null,
                              );
                              setState(() {
                                _attachments.add(
                                  AttachmentMeta(
                                    url: url,
                                    type:
                                        (f.extension != null &&
                                            [
                                              'png',
                                              'jpg',
                                              'jpeg',
                                              'gif',
                                              'webp',
                                            ].contains(
                                              f.extension!.toLowerCase(),
                                            ))
                                        ? 'image'
                                        : 'file',
                                    name: f.name,
                                    size: f.size,
                                  ),
                                );
                              });
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to upload ${f.name}'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachments
                        .asMap()
                        .entries
                        .map(
                          (e) => Chip(
                            avatar: Icon(
                              e.value.type == 'image'
                                  ? Icons.image
                                  : Icons.insert_drive_file,
                            ),
                            label: Text(
                              e.value.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () async {
                              // Only delete from storage if this was an original (previously saved) attachment
                              if (_originalAttachmentUrls.contains(
                                e.value.url,
                              )) {
                                try {
                                  await _storage.deleteByUrl(e.value.url);
                                } catch (_) {}
                              }
                              if (mounted)
                                setState(() => _attachments.removeAt(e.key));
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(isEdit ? 'Save Changes' : 'Create Routine'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
