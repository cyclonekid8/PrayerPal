// lib/services/permission_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final _notifService = NotificationService();

  /// Call this on first app launch — runs the full permission sequence.
  /// Returns true if all critical permissions granted.
  Future<bool> requestAllPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('permissions_done') ?? false;
    if (done) return await _checkAll();

    // Step 1: Notifications
    final notifGranted = await _requestNotifications(context);
    if (!notifGranted) return false;

    await Future.delayed(const Duration(milliseconds: 600));

    // Step 2: Exact alarms (opens system settings on Android 12+)
    await _requestExactAlarms(context);

    await Future.delayed(const Duration(milliseconds: 600));

    // Step 3: Battery optimisation exemption
    await _requestBatteryExemption(context);

    await Future.delayed(const Duration(milliseconds: 600));

    // Step 4: Camera (for wudu check)
    await _requestCamera(context);

    await prefs.setBool('permissions_done', true);
    return await _checkAll();
  }

  Future<bool> _requestNotifications(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await _notifService.requestNotificationPermission();
    return result;
  }

  Future<void> _requestExactAlarms(BuildContext context) async {
    final canExact = await _notifService.canScheduleExactAlarms();
    if (canExact) return;

    // Show explanation dialog before redirecting to settings
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF141d2b),
          title: const Text(
            'Exact Alarm Permission',
            style: TextStyle(color: Color(0xFFe6c872)),
          ),
          content: const Text(
            'PrayerPal needs to schedule prayer alarms at exact times.\n\n'
            'On the next screen, find PrayerPal and enable "Alarms & reminders".',
            style: TextStyle(color: Color(0xFFd8e0ee)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Open Settings', style: TextStyle(color: Color(0xFF2dd4bf))),
            ),
          ],
        ),
      );
    }
    await _notifService.requestExactAlarmPermission();
  }

  Future<void> _requestBatteryExemption(BuildContext context) async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return;

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF141d2b),
          title: const Text(
            'Battery Optimisation',
            style: TextStyle(color: Color(0xFFe6c872)),
          ),
          content: const Text(
            'To ensure prayer alarms fire reliably — especially on Samsung — '
            'PrayerPal needs to be exempt from battery optimisation.\n\n'
            'Tap "Allow" on the next prompt.',
            style: TextStyle(color: Color(0xFFd8e0ee)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue', style: TextStyle(color: Color(0xFF2dd4bf))),
            ),
          ],
        ),
      );
    }
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> _requestCamera(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;
    await Permission.camera.request();
  }

  Future<bool> _checkAll() async {
    final notif = await Permission.notification.isGranted;
    final camera = await Permission.camera.isGranted;
    final exact = await _notifService.canScheduleExactAlarms();
    return notif && exact; // camera is optional
  }

  Future<Map<String, bool>> getPermissionStatuses() async {
    return {
      'notifications': await Permission.notification.isGranted,
      'exact_alarms': await _notifService.canScheduleExactAlarms(),
      'battery_exempt': await Permission.ignoreBatteryOptimizations.isGranted,
      'camera': await Permission.camera.isGranted,
    };
  }
}
