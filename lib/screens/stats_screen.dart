// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer.dart';
import '../services/database_service.dart';
import '../services/prayer_time_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = DatabaseService();
  Map<String, double> _rates = {};
  int _streak = 0;
  List<PrayerRecord> _weekRecords = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rates = await _db.getPrayerCompletionRates();
    final streak = await _db.getCurrentStreak();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final records = await _db.getRecordsForRange(weekStart, now);
    if (mounted) setState(() { _rates = rates; _streak = streak; _weekRecords = records; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d16),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistics', style: TextStyle(fontFamily: 'serif', fontSize: 24, color: Color(0xFF2dd4bf))),
              const Text('Ramadan 1447H · Prayer Tracking', style: TextStyle(fontSize: 12, color: Color(0xFF5a6d88))),
              const SizedBox(height: 20),
              _buildHeatmap(),
              const SizedBox(height: 16),
              _buildRateCards(),
              const SizedBox(height: 16),
              _buildStreakCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141d2b),
        border: Border.all(color: const Color(0xFF1c2c42)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('THIS WEEK', style: TextStyle(fontSize: 10, color: Color(0xFF5a6d88), letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Prayer name labels
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  ...PrayerName.values.map((p) => SizedBox(
                    height: 28,
                    child: Text(p.displayName.substring(0, p.displayName.length < 4 ? p.displayName.length : 4),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF5a6d88))),
                  )),
                ],
              ),
              const SizedBox(width: 6),
              // Day columns
              Expanded(
                child: Row(
                  children: days.map((day) {
                    final dayLabel = DateFormat('EEE').format(day).substring(0, 2);
                    final isToday = day.day == now.day;
                    return Expanded(
                      child: Column(
                        children: [
                          Text(dayLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: isToday ? const Color(0xFFe6c872) : const Color(0xFF5a6d88),
                            )),
                          const SizedBox(height: 4),
                          ...PrayerName.values.map((p) {
                            final rec = _weekRecords
                                .where((r) => r.date.day == day.day && r.prayer == p)
                                .firstOrNull;
                            return _dot(rec, isToday && day.isAfter(now));
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            children: [
              _legendItem(const Color(0x334ade80), '✓', 'Done'),
              const SizedBox(width: 12),
              _legendItem(const Color(0x33f87171), '✗', 'Missed'),
              const SizedBox(width: 12),
              _legendItem(const Color(0x33fbbf24), '✏', 'Edited'),
              const SizedBox(width: 12),
              _legendItem(const Color(0x33c8a84a), '?', 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(PrayerRecord? rec, bool isFuture) {
    Color bg; String label;
    if (isFuture || rec == null) {
      bg = const Color(0x0affffff); label = '';
    } else if (rec.status == PrayerStatus.prayed && rec.wasEdited) {
      bg = const Color(0x33fbbf24); label = '✏';
    } else if (rec.status == PrayerStatus.prayed) {
      bg = const Color(0x334ade80); label = '✓';
    } else if (rec.status == PrayerStatus.missed) {
      bg = const Color(0x33f87171); label = '✗';
    } else {
      bg = const Color(0x33c8a84a); label = '?';
    }
    return Container(
      height: 26,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFFd8e0ee))),
    );
  }

  Widget _legendItem(Color bg, String icon, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF5a6d88))),
      ],
    );
  }

  Widget _buildRateCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: PrayerName.values.map((p) {
        final rate = _rates[p.name] ?? 0.0;
        final pct = (rate * 100).round();
        final color = pct >= 80
            ? const Color(0xFF4ade80)
            : pct >= 50
                ? const Color(0xFFfbbf24)
                : const Color(0xFFf87171);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141d2b),
            border: Border.all(color: const Color(0xFF1c2c42)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(p.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p.displayName, style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88))),
                    Text('$pct%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: rate,
                        minHeight: 3,
                        backgroundColor: const Color(0x12ffffff),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF15082a), Color(0xFF0f1e2e)]),
        border: Border.all(color: const Color(0x38a78bfa)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_streak day streak', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFe6c872))),
              const Text('Complete all 5 prayers to maintain it', style: TextStyle(fontSize: 11, color: Color(0xFF5a6d88))),
            ],
          ),
        ],
      ),
    );
  }
}
