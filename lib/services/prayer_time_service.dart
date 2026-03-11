// lib/services/prayer_time_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/prayer.dart';

class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();
  factory PrayerTimeService() => _instance;
  PrayerTimeService._internal();

  Map<String, dynamic>? _rawData;

  Future<void> init() async {
    final jsonStr = await rootBundle.loadString('assets/prayer_times.json');
    _rawData = jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Get prayer times for a given date.
  /// Interpolates from nearest available entry for dates not explicitly listed.
  DailyPrayerTimes? getTimesForDate(DateTime date) {
    final prayers = _rawData?['prayers'] as Map<String, dynamic>?;
    if (prayers == null) return null;

    final dateStr = _formatDate(date);

    // Try exact match first
    if (prayers.containsKey(dateStr)) {
      return _parseEntry(date, prayers[dateStr] as Map<String, dynamic>);
    }

    // Find nearest date (for months with only anchor points)
    final keys = prayers.keys.toList()..sort();
    String? nearestKey;
    Duration? smallestDiff;

    for (final key in keys) {
      final keyDate = DateTime.parse(key);
      final diff = date.difference(keyDate).abs();
      if (smallestDiff == null || diff < smallestDiff) {
        smallestDiff = diff;
        nearestKey = key;
      }
    }

    if (nearestKey != null) {
      return _parseEntry(date, prayers[nearestKey] as Map<String, dynamic>);
    }

    return null;
  }

  DailyPrayerTimes _parseEntry(DateTime date, Map<String, dynamic> entry) {
    return DailyPrayerTimes(
      date: date,
      fajr: _parseTime(date, entry['fajr'] as String),
      dhuhr: _parseTime(date, entry['dhuhr'] as String),
      asr: _parseTime(date, entry['asr'] as String),
      maghrib: _parseTime(date, entry['maghrib'] as String),
      isha: _parseTime(date, entry['isha'] as String),
    );
  }

  DateTime _parseTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  PrayerName? getCurrentPrayer() {
    final now = DateTime.now();
    final times = getTimesForDate(now);
    if (times == null) return null;

    if (now.isAfter(times.isha)) return PrayerName.isha;
    if (now.isAfter(times.maghrib)) return PrayerName.maghrib;
    if (now.isAfter(times.asr)) return PrayerName.asr;
    if (now.isAfter(times.dhuhr)) return PrayerName.dhuhr;
    if (now.isAfter(times.fajr)) return PrayerName.fajr;
    return null; // before fajr
  }

  PrayerName? getNextPrayer() {
    final now = DateTime.now();
    final times = getTimesForDate(now);
    if (times == null) return null;

    if (now.isBefore(times.fajr)) return PrayerName.fajr;
    if (now.isBefore(times.dhuhr)) return PrayerName.dhuhr;
    if (now.isBefore(times.asr)) return PrayerName.asr;
    if (now.isBefore(times.maghrib)) return PrayerName.maghrib;
    if (now.isBefore(times.isha)) return PrayerName.isha;
    // After Isha — next day's Fajr
    final tomorrow = now.add(const Duration(days: 1));
    return PrayerName.fajr;
  }

  Duration? timeUntilNextPrayer() {
    final now = DateTime.now();
    final times = getTimesForDate(now);
    if (times == null) return null;

    final prayers = [times.fajr, times.dhuhr, times.asr, times.maghrib, times.isha];
    for (final t in prayers) {
      if (t.isAfter(now)) return t.difference(now);
    }
    // After Isha — time to tomorrow Fajr
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowTimes = getTimesForDate(tomorrow);
    return tomorrowTimes?.fajr.difference(now);
  }

  Duration? timeUntilCurrentWindowCloses() {
    final now = DateTime.now();
    final times = getTimesForDate(now);
    if (times == null) return null;
    final current = getCurrentPrayer();
    if (current == null) return null;
    final end = times.windowEndFor(current);
    return end.isAfter(now) ? end.difference(now) : null;
  }
}
