// lib/services/notification_service.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prayer.dart';
import '../data/quotes.dart';
import 'prayer_time_service.dart';

// ── Notification IDs ──────────────────────────────
// Each prayer gets a block of 10 IDs:
//   base + 0 = prayer open
//   base + 1 = 30-min reminder 1
//   base + 2 = 30-min reminder 2
//   ...
//   base + 8 = 30-min reminder 8
//   base + 9 = 15-min urgent
const int _fajrBase    = 100;
const int _dhuhrBase   = 110;
const int _asrBase     = 120;
const int _maghribBase = 130;
const int _ishaBase    = 140;
// Fasting notifications: 200–204
const int _fastingBase = 200;

int _baseFor(PrayerName p) {
  switch (p) {
    case PrayerName.fajr:    return _fajrBase;
    case PrayerName.dhuhr:   return _dhuhrBase;
    case PrayerName.asr:     return _asrBase;
    case PrayerName.maghrib: return _maghribBase;
    case PrayerName.isha:    return _ishaBase;
  }
}

// ── Channel IDs ───────────────────────────────────
const String _chPrayerOpen     = 'prayer_open';
const String _chPrayerReminder = 'prayer_reminder';
const String _chPrayerUrgent   = 'prayer_urgent';
const String _chRamadan        = 'ramadan';

// ── Vibration patterns ────────────────────────────
const _vibSingle   = [0, 300];
const _vibDouble   = [0, 200, 100, 200];
const _vibTriple   = [0, 300, 100, 300, 100, 300];

// Ramadan date constants for 1447H Singapore
const _ramadanStart = '2026-02-19'; // editable via settings
const _ramadanEnd   = '2026-03-20';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Handled in main isolate via onDidReceiveNotificationResponse
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _prayerService = PrayerTimeService();
  final _random = Random();

  String _selectedSoundKey = 'three_beeps';

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Singapore'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createChannels();

    final prefs = await SharedPreferences.getInstance();
    _selectedSoundKey = prefs.getString('alarm_sound') ?? 'three_beeps';
  }

  // ── Channels ─────────────────────────────────────
  Future<void> _createChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(AndroidNotificationChannel(
      _chPrayerOpen,
      'Prayer Time',
      description: 'Notification when a prayer window opens',
      importance: Importance.high,
      vibrationPattern: Int64List.fromList(_vibSingle),
    ));

    await android?.createNotificationChannel(AndroidNotificationChannel(
      _chPrayerReminder,
      'Prayer Reminder',
      description: '30-minute prayer reminders',
      importance: Importance.high,
      vibrationPattern: Int64List.fromList(_vibDouble),
    ));

    await android?.createNotificationChannel(AndroidNotificationChannel(
      _chPrayerUrgent,
      'Prayer Urgent',
      description: 'Closing window alarm — 15 min before end',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound(_selectedSoundKey),
      vibrationPattern: Int64List.fromList(_vibTriple),
      enableVibration: true,
      playSound: true,
    ));

    await android?.createNotificationChannel(AndroidNotificationChannel(
      _chRamadan,
      'Ramadan Encouragement',
      description: 'Fasting quotes and Ramadan reminders',
      importance: Importance.defaultImportance,
      vibrationPattern: Int64List.fromList(_vibSingle),
    ));
  }

  // ── Permission helpers (call from UI) ─────────────
  Future<bool> requestNotificationPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? false;
    return granted;
  }

  Future<bool> canScheduleExactAlarms() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<void> requestExactAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  // ── Schedule all notifications for a day ──────────
  /// DEBUG ONLY — fires a notification 10 seconds after called
  Future<void> scheduleTestNotification() async {
    final scheduledAt = DateTime.now().add(const Duration(seconds: 10));
    final tzTime = tz.TZDateTime.from(scheduledAt, tz.local);
    final canExact = await canScheduleExactAlarms();
    await _plugin.zonedSchedule(
      9999,
      '✅ PrayerPal Test',
      'Notifications are working!',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chPrayerOpen,
          'Prayer Time',
          importance: Importance.high,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList(_vibSingle),
          enableVibration: true,
        ),
      ),
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'test',
    );
  }

  Future<void> scheduleDay(DateTime date) async {
    final times = _prayerService.getTimesForDate(date);
    if (times == null) {
      await _plugin.show(9998, 'DEBUG', 'times is NULL',
        const NotificationDetails(android: AndroidNotificationDetails('prayer_open', 'Prayer Time')));
      return;
    }

    final canExact = await canScheduleExactAlarms();

    await _plugin.show(9995, 'DEBUG scheduleDay', 'canExact=' + canExact.toString() + ' date=' + date.toString(),
      const NotificationDetails(android: AndroidNotificationDetails('prayer_open', 'Prayer Time')));
    for (final prayer in PrayerName.values) {
      final start = times.timeFor(prayer);
      final end   = times.windowEndFor(prayer);
      final base  = _baseFor(prayer);
      final now   = DateTime.now();

      if (end.isBefore(now)) continue; // already passed

      // 1. Prayer window opens
      if (start.isAfter(now)) {
        await _scheduleNotification(
          id: base,
          scheduledAt: start,
          channelId: _chPrayerOpen,
          title: '${prayer.emoji} ${prayer.displayName} — Prayer Time',
          body: _prayerOpenBody(prayer, end),
          payload: 'prayer_open:${prayer.name}',
          canExact: canExact,
          vibration: _vibSingle,
        );
      }

      // 2. 30-min reminders (skip if already prayed — checked at schedule time)
      int reminderIndex = 1;
      DateTime reminderTime = start.add(const Duration(minutes: 30));
      while (reminderTime.isBefore(end.subtract(const Duration(minutes: 20)))) {
        if (reminderTime.isAfter(now)) {
          final remaining = end.difference(reminderTime);
          await _scheduleNotification(
            id: base + reminderIndex,
            scheduledAt: reminderTime,
            channelId: _chPrayerReminder,
            title: '⏰ Still time for ${prayer.displayName}',
            body: _reminderBody(prayer, remaining),
            payload: 'prayer_reminder:${prayer.name}',
            canExact: canExact,
            vibration: _vibDouble,
          );
        }
        reminderTime = reminderTime.add(const Duration(minutes: 30));
        reminderIndex++;
      }

      // 3. Urgent 15-min alarm
      final urgentTime = end.subtract(const Duration(minutes: 15));
      if (urgentTime.isAfter(now)) {
        await _scheduleNotification(
          id: base + 9,
          scheduledAt: urgentTime,
          channelId: _chPrayerUrgent,
          title: '⚠️ ${prayer.displayName} closing in 15 minutes!',
          body: '${prayer.displayName} ends at ${_fmt(end)}. Don\'t miss it!',
          payload: 'prayer_urgent:${prayer.name}',
          canExact: canExact,
          vibration: _vibTriple,
          sound: _selectedSoundKey,
        );
      }
    }

    // 4. Ramadan fasting notifications (10am, 12pm, 2pm, 4pm, 6pm)
    if (_isRamadan(date)) {
      await _scheduleFastingNotifications(date, canExact);
    }
    // 2-min test from scheduleDay (same method as prayer notifs)
    final testDateTime = DateTime.now().add(const Duration(minutes: 2));
    final testTzTime = tz.TZDateTime.from(testDateTime, tz.local);
    await _plugin.zonedSchedule(
      9993,
      '⏱ scheduleDay 2min test',
      'tz=${tz.local.name} fires=${testTzTime.toString().substring(0, 16)}',
      testTzTime,
      const NotificationDetails(android: AndroidNotificationDetails('prayer_open', 'Prayer Time',
        importance: Importance.high, priority: Priority.high)),
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    final pending = await _plugin.pendingNotificationRequests();
    await _plugin.show(9994, 'DEBUG pending', pending.length.toString() + ' scheduled',
      const NotificationDetails(android: AndroidNotificationDetails('prayer_open', 'Prayer Time')));
  }

  Future<void> _scheduleFastingNotifications(DateTime date, bool canExact) async {
    final slots = [10, 12, 14, 16, 18];
    for (int i = 0; i < slots.length; i++) {
      final slotTime = DateTime(date.year, date.month, date.day, slots[i], 0);
      if (slotTime.isAfter(DateTime.now())) {
        final quote = _randomFastingQuote();
        final body = quote.attribution.isNotEmpty
            ? '${quote.text}\n— ${quote.attribution}'
            : quote.text;
        await _scheduleNotification(
          id: _fastingBase + i,
          scheduledAt: slotTime,
          channelId: _chRamadan,
          title: _fastingTitle(slots[i]),
          body: body,
          payload: 'fasting:$i',
          canExact: canExact,
          vibration: _vibSingle,
        );
      }
    }
  }

  // ── Cancel prayer notifications (when prayed) ─────
  Future<void> cancelPrayerNotifications(PrayerName prayer) async {
    final base = _baseFor(prayer);
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(base + i);
    }
  }

  // ── Core scheduler ────────────────────────────────
  Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledAt,
    required String channelId,
    required String title,
    required String body,
    required String payload,
    required bool canExact,
    required List<int> vibration,
    String? sound,
  }) async {
    late tz.TZDateTime tzTime;
    try {
      tzTime = tz.TZDateTime.from(scheduledAt, tz.local);
    } catch (e) {
      await _plugin.show(9997, 'DEBUG tz error', e.toString(),
        const NotificationDetails(android: AndroidNotificationDetails('prayer_open', 'Prayer Time')));
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: channelId == _chPrayerUrgent ? Importance.max : Importance.high,
      priority: channelId == _chPrayerUrgent ? Priority.max : Priority.high,
      vibrationPattern: Int64List.fromList(vibration),
      enableVibration: true,
      playSound: true,
      sound: sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      fullScreenIntent: channelId == _chPrayerUrgent,
      category: channelId == _chPrayerUrgent
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      actions: _actionsFor(payload),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      if (canExact) {
        await _plugin.zonedSchedule(
          id, title, body, tzTime, details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else {
        await _plugin.zonedSchedule(
          id, title, body, tzTime, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
    } catch (e) {
      final errId = DateTime.now().millisecondsSinceEpoch.remainder(9000);
      await _plugin.show(errId, 'DEBUG schedule error', e.toString(),
        const NotificationDetails(android: AndroidNotificationDetails('prayer_open', 'Prayer Time')));
    }
  }

  // ── Notification tap handler ──────────────────────
  void _onNotificationTap(NotificationResponse response) {
    // Navigation handled via app's NavigatorKey
    final payload = response.payload ?? '';
    final actionId = response.actionId ?? '';

    if (actionId == 'mark_prayed') {
      _handleMarkPrayed(payload);
    } else if (actionId == 'open_camera') {
      _handleOpenCamera(payload);
    } else if (actionId == 'mark_missed') {
      _handleMarkMissed(payload);
    }
  }

  void _handleMarkPrayed(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return;
    final prayer = PrayerName.values.firstWhere(
      (p) => p.name == parts[1],
      orElse: () => PrayerName.fajr,
    );
    cancelPrayerNotifications(prayer);
    // Emit event for app to pick up
    NotificationEvents.prayerMarked.add(prayer);
  }

  void _handleOpenCamera(String payload) {
    NotificationEvents.openCamera.add(payload);
  }

  void _handleMarkMissed(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return;
    final prayer = PrayerName.values.firstWhere(
      (p) => p.name == parts[1],
      orElse: () => PrayerName.fajr,
    );
    cancelPrayerNotifications(prayer);
    NotificationEvents.prayerMissed.add(prayer);
  }

  // ── Notification actions ──────────────────────────
  List<AndroidNotificationAction> _actionsFor(String payload) {
    if (payload.startsWith('fasting')) return [];

    final isUrgent = payload.startsWith('prayer_urgent');

    return [
      const AndroidNotificationAction(
        'mark_prayed',
        '✅ I\'ve Prayed',
        showsUserInterface: false,
      ),
      const AndroidNotificationAction(
        'open_camera',
        '📸 Verify Wudu',
        showsUserInterface: true, // opens app
      ),
      if (isUrgent)
        const AndroidNotificationAction(
          'mark_missed',
          '😔 Mark Missed',
          showsUserInterface: false,
        ),
    ];
  }

  // ── Quote helpers ─────────────────────────────────
  String _prayerOpenBody(PrayerName prayer, DateTime end) {
    final quotes = prayerQuotes
        .where((q) => q.category == PrayerQuoteCategory.encouraging)
        .toList();
    final q = quotes[_random.nextInt(quotes.length)];
    final attribution = q.attribution.isNotEmpty ? '\n— ${q.attribution}' : '';
    return '"${q.text}"$attribution\n\nWindow open until ${_fmt(end)}.';
  }

  String _reminderBody(PrayerName prayer, Duration remaining) {
    final quotes = prayerQuotes
        .where((q) => q.category == PrayerQuoteCategory.motivating)
        .toList();
    final q = quotes[_random.nextInt(quotes.length)];
    final mins = remaining.inMinutes;
    final attribution = q.attribution.isNotEmpty ? '\n— ${q.attribution}' : '';
    return '"${q.text}"$attribution\n\n${mins}min remaining.';
  }

  FastingQuote _randomFastingQuote() {
    return fastingQuotes[_random.nextInt(fastingQuotes.length)];
  }

  PrayerQuote _randomSternQuote() {
    final quotes = prayerQuotes
        .where((q) => q.category == PrayerQuoteCategory.stern)
        .toList();
    return quotes[_random.nextInt(quotes.length)];
  }

  String _fastingTitle(int hour) {
    if (hour == 10) return '🌤 Morning — Keep Going!';
    if (hour == 12) return '☀️ Midday Reminder';
    if (hour == 14) return '🌞 Afternoon Check-in';
    if (hour == 16) return '💪 You\'re Almost There!';
    return '🌇 Final Push — Iftar Soon!';
  }

  // ── Ramadan check ─────────────────────────────────
  bool _isRamadan(DateTime date) {
    final start = DateTime.parse(_ramadanStart);
    final end = DateTime.parse(_ramadanEnd);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  // ── Sound selection ───────────────────────────────
  Future<void> setAlarmSound(String soundKey) async {
    _selectedSoundKey = soundKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_sound', soundKey);
    // Recreate urgent channel with new sound
    await _createChannels();
  }

  String get selectedSoundKey => _selectedSoundKey;
}

// Simple event streams for notification actions
class NotificationEvents {
  static final prayerMarked = _EventBus<PrayerName>();
  static final prayerMissed = _EventBus<PrayerName>();
  static final openCamera   = _EventBus<String>();
}

class _EventBus<T> {
  final List<void Function(T)> _listeners = [];
  void listen(void Function(T) cb) => _listeners.add(cb);
  void add(T event) { for (final l in _listeners) { l(event); } }
}
