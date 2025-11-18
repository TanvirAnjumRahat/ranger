import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class TimeUtils {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final local = DateTime.now().timeZoneName;
    try {
      final location = tz.getLocation(_guessLocation(local));
      tz.setLocalLocation(location);
    } catch (_) {
      // Fallback to local default
    }
    _initialized = true;
  }

  // Very naive mapping when tz database name isn't available
  static String _guessLocation(String name) {
    // Return a sensible default
    return 'UTC';
  }

  static tz.TZDateTime combineDateTime(DateTime date, DateTime time) {
    final local = tz.local;
    return tz.TZDateTime(
      local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
