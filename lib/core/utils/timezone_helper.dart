/// Timezone helper — detects device timezone and calculates
/// Valorant store reset time relative to user's local time.
///
/// Store resets daily at 00:00 UTC.

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneHelper {
  static bool _initialized = false;

  /// Initialize timezone database. Call once at app startup.
  static Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    _initialized = true;
  }

  /// Get the current time in the device's timezone.
  static tz.TZDateTime get now => tz.TZDateTime.now(tz.local);

  /// Get the next Valorant store reset time (00:00 UTC) in local time.
  static tz.TZDateTime get nextStoreReset {
    final utcNow = DateTime.now().toUtc();
    DateTime nextResetUtc = DateTime.utc(
      utcNow.year,
      utcNow.month,
      utcNow.day,
    );
    // If we're past midnight UTC, the next reset is tomorrow
    if (utcNow.isAfter(nextResetUtc) ||
        utcNow.isAtSameMomentAs(nextResetUtc)) {
      nextResetUtc = nextResetUtc.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(nextResetUtc, tz.local);
  }

  /// Duration until next store reset.
  static Duration get timeUntilReset {
    final resetTime = nextStoreReset;
    return resetTime.difference(now);
  }

  /// Format duration as "HH:MM:SS".
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
