import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';
import 'reminder.dart';

class RepeatSettings {
  final RepeatType type;
  final List<int> daysOfWeek; // 1..7 (Mon=1)
  final Timestamp? endDate;

  const RepeatSettings({
    required this.type,
    this.daysOfWeek = const [],
    this.endDate,
  });

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'daysOfWeek': daysOfWeek,
    'endDate': endDate,
  };

  factory RepeatSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const RepeatSettings(type: RepeatType.none);
    }
    return RepeatSettings(
      type: RepeatType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'none'),
        orElse: () => RepeatType.none,
      ),
      daysOfWeek: ((map['daysOfWeek'] as List?)?.cast<int>()) ?? const [],
      endDate: map['endDate'] as Timestamp?,
    );
  }
}

class GeoLocation {
  final double lat;
  final double lng;
  final double radiusMeters;

  const GeoLocation({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    'radiusMeters': radiusMeters,
  };

  factory GeoLocation.fromMap(Map<String, dynamic> map) => GeoLocation(
    lat: (map['lat'] as num).toDouble(),
    lng: (map['lng'] as num).toDouble(),
    radiusMeters: (map['radiusMeters'] as num).toDouble(),
  );
}

class Routine {
  final String id;
  final String uid;
  final String title;
  final String? description;
  final Timestamp date; // start date (00:00 time)
  final Timestamp time; // time of day stored as Timestamp on date
  final int durationMinutes;
  final RepeatSettings repeat;
  final RoutineCategory category;
  final RoutinePriority priority;
  final List<Reminder> reminders;
  final GeoLocation? location;
  final RoutineStatus status;
  final List<Timestamp> completedDates;
  final List<AttachmentMeta> attachments;
  final String? calendarEventId;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const Routine({
    required this.id,
    required this.uid,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.durationMinutes = 60,
    this.repeat = const RepeatSettings(type: RepeatType.none),
    this.category = RoutineCategory.others,
    this.priority = RoutinePriority.medium,
    this.reminders = const [],
    this.location,
    this.status = RoutineStatus.pending,
    this.completedDates = const [],
    this.attachments = const [],
    this.calendarEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'title': title,
    if (description != null) 'description': description,
    'date': date,
    'time': time,
    'durationMinutes': durationMinutes,
    'repeat': repeat.toMap(),
    'category': category.name,
    'priority': priority.name,
    'reminders': reminders.map((e) => e.toMap()).toList(),
    if (location != null) 'location': location!.toMap(),
    'status': status.name,
    'completedDates': completedDates,
    'attachments': attachments.map((e) => e.toMap()).toList(),
    if (calendarEventId != null) 'calendarEventId': calendarEventId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Routine.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    Timestamp _toTs(dynamic v) {
      if (v is Timestamp) return v;
      if (v is DateTime) return Timestamp.fromDate(v);
      if (v is int) return Timestamp.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        try {
          return Timestamp.fromDate(DateTime.parse(v));
        } catch (_) {}
      }
      throw StateError('Invalid timestamp value: ' + v.toString());
    }

    // Cope with missing date/time by deriving one from the other or defaulting to now
    final rawDate = data['date'];
    final rawTime = data['time'];
    final tsDate = rawDate == null ? Timestamp.now() : _toTs(rawDate);
    final tsTime = rawTime == null
        ? Timestamp.fromDate(tsDate.toDate())
        : _toTs(rawTime);

    return Routine(
      id: doc.id,
      uid: data['uid'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      date: tsDate,
      time: tsTime,
      durationMinutes: (data['durationMinutes'] as int?) ?? 60,
      repeat: RepeatSettings.fromMap(data['repeat'] as Map<String, dynamic>?),
      category: RoutineCategory.values.firstWhere(
        (e) => e.name == (data['category'] as String? ?? 'others'),
        orElse: () => RoutineCategory.others,
      ),
      priority: RoutinePriority.values.firstWhere(
        (e) => e.name == (data['priority'] as String? ?? 'medium'),
        orElse: () => RoutinePriority.medium,
      ),
      reminders: ((data['reminders'] as List?) ?? const [])
          .map((e) => Reminder.fromMap((e as Map).cast<String, dynamic>()))
          .toList(),
      location: (data['location'] == null)
          ? null
          : GeoLocation.fromMap(
              (data['location'] as Map).cast<String, dynamic>(),
            ),
      status: RoutineStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => RoutineStatus.pending,
      ),
      completedDates: ((data['completedDates'] as List?) ?? const [])
          .map((e) => e as Timestamp)
          .toList(),
      attachments: ((data['attachments'] as List?) ?? const [])
          .map(
            (e) => AttachmentMeta.fromMap((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      calendarEventId: data['calendarEventId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Routine copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    Timestamp? date,
    Timestamp? time,
    int? durationMinutes,
    RepeatSettings? repeat,
    RoutineCategory? category,
    RoutinePriority? priority,
    List<Reminder>? reminders,
    GeoLocation? location,
    RoutineStatus? status,
    List<Timestamp>? completedDates,
    List<AttachmentMeta>? attachments,
    String? calendarEventId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      repeat: repeat ?? this.repeat,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      reminders: reminders ?? this.reminders,
      location: location ?? this.location,
      status: status ?? this.status,
      completedDates: completedDates ?? this.completedDates,
      attachments: attachments ?? this.attachments,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
