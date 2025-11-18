class Reminder {
  final int minutesBefore;
  final String? sound;

  const Reminder({required this.minutesBefore, this.sound});

  Map<String, dynamic> toMap() => {
    'minutesBefore': minutesBefore,
    if (sound != null) 'sound': sound,
  };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
    minutesBefore: (map['minutesBefore'] ?? 0) as int,
    sound: map['sound'] as String?,
  );
}

class AttachmentMeta {
  final String url;
  final String type; // image | file
  final String name;
  final int size;

  const AttachmentMeta({
    required this.url,
    required this.type,
    required this.name,
    required this.size,
  });

  Map<String, dynamic> toMap() => {
    'url': url,
    'type': type,
    'name': name,
    'size': size,
  };

  factory AttachmentMeta.fromMap(Map<String, dynamic> map) => AttachmentMeta(
    url: map['url'] as String,
    type: map['type'] as String,
    name: map['name'] as String,
    size: (map['size'] ?? 0) as int,
  );
}
