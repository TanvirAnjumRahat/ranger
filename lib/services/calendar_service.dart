import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';
import '../models/enums.dart';

class CalendarService {
  final GoogleSignIn _googleSignIn;
  CalendarService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ?? GoogleSignIn(scopes: [cal.CalendarApi.calendarScope]);

  // Build an RFC5545 RRULE string (without the leading "RRULE:") from repeat settings.
  // Supports: none -> null, daily -> FREQ=DAILY, weekly/custom -> FREQ=WEEKLY;BYDAY=...
  // Adds UNTIL when an endDate is provided.
  static String? buildRRule(RepeatSettings repeat) {
    if (repeat.type == RepeatType.none) return null;
    if (repeat.type == RepeatType.daily) {
      final parts = <String>["FREQ=DAILY"];
      if (repeat.endDate != null) {
        parts.add("UNTIL=${_untilString(repeat.endDate!)}");
      }
      return parts.join(';');
    }
    // Weekly/custom map to weekly with BYDAY
    if (repeat.type == RepeatType.weekly || repeat.type == RepeatType.custom) {
      const map = {
        1: 'MO',
        2: 'TU',
        3: 'WE',
        4: 'TH',
        5: 'FR',
        6: 'SA',
        7: 'SU',
      };
      final bydays = repeat.daysOfWeek.map((d) => map[d]!).toList();
      final parts = <String>[
        "FREQ=WEEKLY",
        if (bydays.isNotEmpty) "BYDAY=${bydays.join(',')}",
      ];
      if (repeat.endDate != null) {
        parts.add("UNTIL=${_untilString(repeat.endDate!)}");
      }
      return parts.join(';');
    }
    return null;
  }

  static String _untilString(Timestamp ts) {
    final dt = ts.toDate().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    // Use 23:59:59Z at the end date's day to include the entire day
    final y = dt.year.toString().padLeft(4, '0');
    final m = two(dt.month);
    final d = two(dt.day);
    return '$y${m}${d}T235959Z';
  }

  Future<cal.CalendarApi?> _getApi() async {
    final account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) return null;
    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return cal.CalendarApi(client);
  }

  Future<String?> upsertEvent({
    required String summary,
    required DateTime start,
    required DateTime end,
    String? eventId,
    String? rrule,
  }) async {
    final api = await _getApi();
    if (api == null) return null;
    final event = cal.Event()
      ..summary = summary
      ..start = (cal.EventDateTime()..dateTime = start.toUtc())
      ..end = (cal.EventDateTime()..dateTime = end.toUtc());
    if (rrule != null) {
      event.recurrence = ['RRULE:$rrule'];
    }
    if (eventId != null) {
      final updated = await api.events.patch(event, 'primary', eventId);
      return updated.id;
    } else {
      final created = await api.events.insert(event, 'primary');
      return created.id;
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = IOClient();
  _GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
