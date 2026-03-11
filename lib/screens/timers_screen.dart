// lib/screens/timers_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer.dart';
import '../services/prayer_time_service.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({super.key});
  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  final _svc = PrayerTimeService();
  Timer? _ticker;
  DateTime _now = DateTime.now();

  final _ramadanStart = DateTime(2026, 2, 19);
  final _ramadanEnd   = DateTime(2026, 3, 20);
  final _eid          = DateTime(2026, 3, 21);

  bool get _isRamadan => !_now.isBefore(_ramadanStart) && !_now.isAfter(_ramadanEnd);
  int  get _ramadanDay => _now.difference(_ramadanStart).inDays + 1;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }

  String _fmt(Duration d) {
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    final times = _svc.getTimesForDate(_now);
    final current = _svc.getCurrentPrayer();
    final next    = _svc.getNextPrayer();

    Duration? windowLeft;
    DateTime? windowEnd;
    if (current != null && times != null) {
      windowEnd = times.windowEndFor(current);
      windowLeft = windowEnd.isAfter(_now) ? windowEnd.difference(_now) : null;
    }

    Duration? iftarLeft;
    if (_isRamadan && times != null && times.maghrib.isAfter(_now)) {
      iftarLeft = times.maghrib.difference(_now);
    }

    Duration? nextPrayerLeft;
    if (times != null && next != null) {
      final nextTime = next == PrayerName.fajr && (current == PrayerName.isha || current == null)
          ? _svc.getTimesForDate(_now.add(const Duration(days: 1)))?.fajr
          : times.timeFor(next);
      if (nextTime != null && nextTime.isAfter(_now)) {
        nextPrayerLeft = nextTime.difference(_now);
      }
    }

    // Fasting progress (Fajr → Maghrib)
    double fastingProgress = 0;
    if (_isRamadan && times != null) {
      final total = times.maghrib.difference(times.fajr).inSeconds;
      final elapsed = _now.difference(times.fajr).inSeconds.clamp(0, total);
      fastingProgress = elapsed / total;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080d16),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('Timers', style: TextStyle(fontFamily: 'serif', fontSize: 24, color: Color(0xFFe6c872))),
              Text(DateFormat('EEE d MMM yyyy').format(_now),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5a6d88))),
              if (_isRamadan)
                Text('21 Ramadan 1447H · Day $_ramadanDay',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFa78bfa))),
              const SizedBox(height: 20),

              // Prayer window countdown
              _bigCard(
                label: 'CURRENT PRAYER WINDOW',
                title: current?.displayName ?? 'Before Fajr',
                subtitle: windowEnd != null ? 'Until ${_fmtTime(windowEnd)}' : '',
                value: _fmt(windowLeft ?? Duration.zero),
                color: const Color(0xFFfbbf24),
                borderColor: const Color(0x46c8a84a),
                gradient: const [Color(0x28c8a84a), Color(0x0ac8a84a)],
              ),
              const SizedBox(height: 10),

              // Next prayer pill
              if (next != null && nextPrayerLeft != null)
                _nextPill(next, nextPrayerLeft, times),
              const SizedBox(height: 10),

              // Fasting countdown (Ramadan only)
              if (_isRamadan) ...[
                _bigCard(
                  label: 'IFTAR COUNTDOWN',
                  title: 'Fasting — Day $_ramadanDay',
                  subtitle: times != null ? 'Maghrib at ${_fmtTime(times.maghrib)}' : '',
                  value: _fmt(iftarLeft ?? Duration.zero),
                  color: const Color(0xFFa78bfa),
                  borderColor: const Color(0x38a78bfa),
                  gradient: const [Color(0x20a78bfa), Color(0x08a78bfa)],
                  extra: _fastingProgressBar(fastingProgress, times),
                ),
                const SizedBox(height: 10),
                // Suhoor + Eid row
                _suhoorRow(times),
              ],

              const SizedBox(height: 10),
              // All prayers today
              _todaySchedule(times),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigCard({
    required String label,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required Color borderColor,
    required List<Color> gradient,
    Widget? extra,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF5a6d88), letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 22, color: Color(0xFFe6c872))),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88))),
          const SizedBox(height: 12),
          Center(
            child: Text(value, style: TextStyle(
              fontFamily: 'monospace', fontSize: 52, fontWeight: FontWeight.w500,
              color: color, letterSpacing: 2,
            )),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['HRS', 'MIN', 'SEC'].map((u) =>
                SizedBox(width: 80, child: Text(u,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF5a6d88), letterSpacing: 1))
                )
              ).toList(),
            ),
          ),
          if (extra != null) ...[const SizedBox(height: 12), extra],
        ],
      ),
    );
  }

  Widget _fastingProgressBar(double progress, DailyPrayerTimes? times) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(times != null ? _fmtTime(times.fajr) : '', style: const TextStyle(fontSize: 10, color: Color(0xFF5a6d88))),
            Text('${(progress * 100).round()}% of fast done', style: const TextStyle(fontSize: 10, color: Color(0xFFa78bfa))),
            Text(times != null ? _fmtTime(times.maghrib) : '', style: const TextStyle(fontSize: 10, color: Color(0xFF5a6d88))),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0x12ffffff),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFa78bfa)),
          ),
        ),
      ],
    );
  }

  Widget _nextPill(PrayerName next, Duration left, DailyPrayerTimes? times) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141d2b),
        border: Border.all(color: const Color(0xFF1c2c42)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Text(next.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next: ${next.displayName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (times != null)
                  Text(_fmtTime(times.timeFor(next)), style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88))),
              ],
            ),
          ),
          Text(_fmt(left), style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Color(0xFF2dd4bf))),
        ],
      ),
    );
  }

  Widget _suhoorRow(DailyPrayerTimes? times) {
    final tomorrow = _now.add(const Duration(days: 1));
    final tomorrowTimes = _svc.getTimesForDate(tomorrow);
    final daysToEid = _eid.difference(_now).inDays;

    return Row(
      children: [
        _miniCard('Tomorrow Suhoor', tomorrowTimes != null ? _fmtTime(tomorrowTimes.fajr) : '—', ''),
        const SizedBox(width: 8),
        _miniCard('Tomorrow Fajr', tomorrowTimes != null ? _fmtTime(tomorrowTimes.fajr) : '—', 'Fast begins'),
        const SizedBox(width: 8),
        _miniCard('Eid al-Fitr', '21 Mar', 'in $daysToEid days 🎉'),
      ],
    );
  }

  Widget _miniCard(String title, String val, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF141d2b),
          border: Border.all(color: const Color(0xFF1c2c42)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF5a6d88))),
            const SizedBox(height: 3),
            Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (sub.isNotEmpty)
              Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFFa78bfa))),
          ],
        ),
      ),
    );
  }

  Widget _todaySchedule(DailyPrayerTimes? times) {
    if (times == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TODAY'S SCHEDULE",
          style: TextStyle(fontSize: 10, color: Color(0xFF5a6d88), letterSpacing: 1.5)),
        const SizedBox(height: 8),
        ...PrayerName.values.map((p) {
          final t = times.timeFor(p);
          final isPast = times.windowEndFor(p).isBefore(_now);
          final isNow  = t.isBefore(_now) && !isPast;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(p.displayName, style: TextStyle(
                  fontSize: 13,
                  color: isNow ? const Color(0xFFe6c872) : const Color(0xFFd8e0ee),
                  fontWeight: isNow ? FontWeight.w600 : FontWeight.normal,
                )),
                const Spacer(),
                Text(_fmtTime(t), style: TextStyle(
                  fontSize: 13, fontFamily: 'monospace',
                  color: isPast ? const Color(0xFF3a4d66) : const Color(0xFFd8e0ee),
                )),
              ],
            ),
          );
        }),
      ],
    );
  }
}
