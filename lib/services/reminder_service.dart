import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_planner.dart';

/// Schedules the planned reminders as local notifications on the phone.
class ReminderService {
  ReminderService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Bills due and tax filing deadlines',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // Users are in Malaysia; one fixed zone avoids another plugin dependency.
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Ask for permission only when the user turns a reminder on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asks the OS for permission to show notifications. Returns false if denied.
  static Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
    return granted;
  }

  /// Replaces every scheduled reminder with [reminders].
  static Future<void> schedule(List<PlannedReminder> reminders) async {
    try {
      await _init();
      await _plugin.cancelAll();
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: r.id,
          scheduledDate: tz.TZDateTime(tz.local, r.when.year, r.when.month, r.when.day, r.when.hour, r.when.minute),
          notificationDetails: _details,
          // Inexact is fine for a 9am nudge and needs no exact-alarm permission.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
        );
      }
    } catch (e) {
      debugPrint('Scheduling reminders failed: $e');
    }
  }
}
