import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'prayer.dart';
import 'store.dart';

/// Local notifications for prayer times and reminders (no server needed).
/// Scheduling is "inexact while idle" so no special exact-alarm permission is needed;
/// Android may deliver a notification a few minutes late in battery saver.
class Notifs {
  static final _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (kIsWeb || _ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (_) {}
    await _p.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();
    final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return (await a?.requestNotificationsPermission()) ?? false;
  }

  static NotificationDetails _d(String ch, String name) => NotificationDetails(
      android: AndroidNotificationDetails(ch, name,
          importance: Importance.high, priority: Priority.high));

  static Future<void> _at(int id, DateTime t, String title, String body, String ch, String chName) async {
    if (t.isBefore(DateTime.now())) return;
    await _p.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(t, tz.local),
        notificationDetails: _d(ch, chName),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
  }

  /// Cancels everything and schedules the next 7 days according to settings.
  static Future<void> reschedule() async {
    if (kIsWeb) return;
    await init();
    await _p.cancelAll();
    final s = Store.i;
    final place = await resolvePlace();
    final now = DateTime.now();
    var id = 1;
    for (var d = 0; d < 7; d++) {
      final day = now.add(Duration(days: d));
      if (place != null && s.flag('n_prayer', false)) {
        final t = timesFor(place, day);
        final before = s.intVal('n_before', 0);
        for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
          final pt = t.timeForPrayer(p)!;
          final name = prayerNames[p]!;
          await _at(id++, pt, 'حان وقت صلاة $name', 'حيّ على الصلاة', 'adhan', 'مواقيت الصلاة');
          if (before > 0) {
            await _at(id++, pt.subtract(Duration(minutes: before)), 'اقترب وقت $name',
                'بعد ${ar(before)} دقيقة', 'adhan_before', 'تنبيه قبل الصلاة');
          }
        }
      }
      if (s.flag('n_adhkar', false)) {
        await _at(id++, DateTime(day.year, day.month, day.day, 6, 30), 'أذكار الصباح', 'ابدأ يومك بذكر الله', 'adhkar', 'الأذكار');
        await _at(id++, DateTime(day.year, day.month, day.day, 17, 30), 'أذكار المساء', 'لا تنسَ أذكار المساء', 'adhkar', 'الأذكار');
      }
      if (s.flag('n_quran', false)) {
        await _at(id++, DateTime(day.year, day.month, day.day, 21, 0), 'وردك من القرآن', 'اقرأ ولو آيات قليلة', 'quran', 'تذكير القرآن');
      }
    }
  }
}
