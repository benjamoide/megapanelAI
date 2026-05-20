import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _channelId = 'blueprint_one_plans';
  static const _channelName = 'Planned treatments';
  static const _channelDescription =
      'Reminders for planned red light therapy sessions.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isSupported => !kIsWeb;

  Future<void> initialize() async {
    if (_initialized || !isSupported) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initializationSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macosPlugin = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    var granted = true;

    final androidGranted =
        await androidPlugin?.requestNotificationsPermission();
    if (androidGranted != null) {
      granted = granted && androidGranted;
    }

    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );
    if (iosGranted != null) {
      granted = granted && iosGranted;
    }

    final macosGranted = await macosPlugin?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );
    if (macosGranted != null) {
      granted = granted && macosGranted;
    }

    return granted;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!isSupported) return false;
    await initialize();

    final androidEnabled = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    if (androidEnabled != null) {
      return androidEnabled;
    }

    return true;
  }

  Future<void> cancelAll() async {
    if (!isSupported) return;
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> syncPlannedReminders({
    required List<ResolvedPlannedSession> plans,
    required ReminderSettings settings,
    required AppLanguage language,
  }) async {
    if (!isSupported) return;
    await initialize();
    await _plugin.cancelAll();

    if (!settings.enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var notificationId = 3000;
    final strings = BlueprintStrings(language);

    for (final entry in plans) {
      for (final reminder in settings.reminders) {
        if (!reminder.enabled) continue;

        final scheduled = tz.TZDateTime(
          tz.local,
          entry.date.year,
          entry.date.month,
          entry.date.day - reminder.leadTime.daysOffset,
          reminder.hour,
          reminder.minute,
        );

        if (scheduled.isBefore(now)) continue;

        final leadLabel = reminder.leadTime == ReminderLeadTime.dayBefore
            ? (strings.isSpanish
                ? 'Planificado para manana'
                : 'Planned for tomorrow')
            : (strings.isSpanish
                ? 'Planificado para hoy'
                : 'Planned for today');

        await _plugin.zonedSchedule(
          notificationId++,
          entry.treatment.title(strings.isSpanish),
          '$leadLabel - ${strings.translateMomentLabel(entry.session.momentLabel)}',
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }
}
