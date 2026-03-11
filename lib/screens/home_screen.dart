// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer.dart';
import '../services/prayer_time_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _prayerSvc = PrayerTimeService();
  final _db = DatabaseService();
  final _notifSvc = NotificationService();

  DailyPrayerTimes? _times;
  List<PrayerRecord> _todayRecords = [];
  Timer? _ticker;
  DateTime _now = DateTime.now();

  // Ramadan config
  final _ramadanStart = DateTime(2026, 2, 19);
  final _ramadanEnd   = DateTime(2026, 3, 20);

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    NotificationEvents.prayerMarked.listen((_) => _load());
    NotificationEvents.prayerMissed.listen((_) => _load());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final times = _prayerSvc.getTimesForDate(_now);
    final records = await _db.getRecordsForDate(_now);
    if (mounted) setState(() { _times = times; _todayRecords = records; });
  }

  bool get _isRamadan =>
    !_now.isBefore(_ramadanStart) && !_now.isAfter(_ramadanEnd);

  int get _ramadanDay => _now.difference(_ramadanStart).inDays + 1;

  PrayerStatus _statusOf(PrayerName prayer) {
    final rec = _todayRecords.where((r) => r.prayer == prayer).firstOrNull;
    return rec?.status ?? PrayerStatus.pending;
  }

  bool _isPrayerActive(PrayerName prayer) {
    if (_times == null) return false;
    final start = _times!.timeFor(prayer);
    final end   = _times!.windowEndFor(prayer);
    return _now.isAfter(start) && _now.isBefore(end);
  }

  Duration? _windowTimeLeft(PrayerName prayer) {
    if (_times == null) return null;
    final end = _times!.windowEndFor(prayer);
    if (end.isAfter(_now)) return end.difference(_now);
    return null;
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  Future<void> _markPrayed(PrayerName prayer) async {
    final record = PrayerRecord(
      date: _now,
      prayer: prayer,
      status: PrayerStatus.prayed,
      prayedAt: _now,
    );
    await _db.upsertRecord(record);
    await _notifSvc.cancelPrayerNotifications(prayer);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final times = _times;

    return Scaffold(
      backgroundColor: const Color(0xFF080d16),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(times),
              _buildPrayerList(times),
              if (_isRamadan) _buildRamadanStrip(times),
              _buildStatsStrip(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(DailyPrayerTimes? times) {
    final activePrayer = _prayerSvc.getCurrentPrayer();
    final windowLeft = activePrayer != null ? _windowTimeLeft(activePrayer) : null;
    final iftarLeft = times != null && _isRamadan && times.maghrib.isAfter(_now)
        ? times.maghrib.difference(_now)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0b1828), Color(0xFF0d1a24), Color(0xFF0e1520)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRamadan ? 'Ramadan Mubarak' : 'Assalamu Alaikum',
                      style: const TextStyle(
                        fontSize: 11, color: Color(0xFFc8a84a), letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEE, d MMM yyyy').format(_now),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5a6d88)),
                    ),
                    if (_isRamadan)
                      Text(
                        '${_ramadanDay} Ramadan 1447H · Day $_ramadanDay of 30',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFa78bfa)),
                      ),
                  ],
                ),
              ),
              const Text('☪️', style: TextStyle(fontSize: 32)),
            ],
          ),
          const SizedBox(height: 14),
          // Current prayer card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x28c8a84a), Color(0x0ac8a84a)],
              ),
              border: Border.all(color: const Color(0x46c8a84a)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Current Prayer',
                      style: TextStyle(fontSize: 10, color: Color(0xFFc8a84a), letterSpacing: 1.2),
                    ),
                    const Spacer(),
                    if (activePrayer != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x204ade80),
                          border: Border.all(color: const Color(0x404ade80)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('Window Open', style: TextStyle(fontSize: 10, color: Color(0xFF4ade80))),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activePrayer?.displayName ?? 'Before Fajr',
                  style: const TextStyle(
                    fontFamily: 'serif', fontSize: 28, color: Color(0xFFe6c872), height: 1,
                  ),
                ),
                if (activePrayer != null && times != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtTime(times.timeFor(activePrayer))} — ${_fmtTime(times.windowEndFor(activePrayer))}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88)),
                  ),
                ],
                const SizedBox(height: 10),
                // Dual countdown row
                Row(
                  children: [
                    Expanded(child: _countdownBox(
                      'Prayer window ends',
                      windowLeft != null ? _fmtDuration(windowLeft) : '—',
                      const Color(0xFFfbbf24),
                    )),
                    const SizedBox(width: 8),
                    if (_isRamadan)
                      Expanded(child: _countdownBox(
                        'Iftar',
                        iftarLeft != null ? _fmtDuration(iftarLeft) : '—',
                        const Color(0xFFa78bfa),
                      )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        border: Border.all(color: const Color(0xFF1c2c42)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF5a6d88), letterSpacing: 1)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(
            fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w500, color: color,
          )),
        ],
      ),
    );
  }

  Widget _buildPrayerList(DailyPrayerTimes? times) {
    if (times == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TODAY\'S PRAYERS',
            style: TextStyle(fontSize: 10, color: Color(0xFF5a6d88), letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ...PrayerName.values.map((p) => _prayerRow(p, times)),
        ],
      ),
    );
  }

  Widget _prayerRow(PrayerName prayer, DailyPrayerTimes times) {
    final status = _statusOf(prayer);
    final isActive = _isPrayerActive(prayer);
    final isPast = times.windowEndFor(prayer).isBefore(_now);
    final timeLeft = isActive ? _windowTimeLeft(prayer) : null;

    Color iconBg;
    Color nameColor = const Color(0xFFd8e0ee);
    Widget badge;

    switch (status) {
      case PrayerStatus.prayed:
      case PrayerStatus.edited:
        iconBg = const Color(0x1a4ade80);
        badge = _pill('✓ Done', const Color(0xFF4ade80), const Color(0x1a4ade80));
      case PrayerStatus.missed:
        iconBg = const Color(0x1af87171);
        badge = _pill('Missed', const Color(0xFFf87171), const Color(0x1af87171));
      case PrayerStatus.pending:
        if (isActive) {
          iconBg = const Color(0x1ac8a84a);
          nameColor = const Color(0xFFe6c872);
          badge = _pill('Now', const Color(0xFFc8a84a), const Color(0x1ac8a84a));
        } else {
          iconBg = const Color(0x0affffff);
          badge = _pill('—', const Color(0xFF5a6d88), const Color(0x0affffff));
        }
    }

    return GestureDetector(
      onTap: (status == PrayerStatus.pending && (isActive || !isPast))
          ? () => _showMarkPrayedSheet(prayer)
          : (status == PrayerStatus.missed || status == PrayerStatus.pending && isPast)
              ? () => _showEditSheet(prayer)
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1c2c42))),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(prayer.emoji, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prayer.displayName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: nameColor)),
                  Text(
                    _fmtTime(times.timeFor(prayer)),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5a6d88)),
                  ),
                  if (timeLeft != null)
                    Text('${timeLeft.inMinutes}m left',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF2dd4bf))),
                ],
              ),
            ),
            badge,
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg)),
    );
  }

  void _showMarkPrayedSheet(PrayerName prayer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141d2b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF1c2c42), borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            Text('${prayer.emoji} Mark ${prayer.displayName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Did you just pray?',
              style: TextStyle(fontSize: 12, color: Color(0xFF5a6d88))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _sheetBtn('✅ Yes, I Prayed',
                    const Color(0xFF4ade80), const Color(0x1a4ade80), () {
                      Navigator.pop(context);
                      _markPrayed(prayer);
                    }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sheetBtn('Cancel',
                    const Color(0xFF5a6d88), const Color(0x0affffff), () => Navigator.pop(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(PrayerName prayer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141d2b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF1c2c42), borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            Text('Edit ${prayer.displayName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Did you actually pray this?',
              style: TextStyle(fontSize: 12, color: Color(0xFF5a6d88))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _sheetBtn('✅ Yes, I Prayed',
                    const Color(0xFF4ade80), const Color(0x1a4ade80), () async {
                      Navigator.pop(context);
                      final record = PrayerRecord(
                        date: _now,
                        prayer: prayer,
                        status: PrayerStatus.prayed,
                        prayedAt: _now,
                        wasEdited: true,
                      );
                      await _db.upsertRecord(record);
                      await _load();
                    }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sheetBtn('Keep as Missed',
                    const Color(0xFF5a6d88), const Color(0x0affffff), () => Navigator.pop(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn(String label, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: fg.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  Widget _buildRamadanStrip(DailyPrayerTimes? times) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF15082a), Color(0xFF0f1e2e)]),
        border: Border.all(color: const Color(0x38a78bfa)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ramadan Day $_ramadanDay of 30',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFa78bfa))),
                const SizedBox(height: 2),
                const Text(
                  'Every desire resisted is extra reward.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5a6d88)),
                ),
              ],
            ),
          ),
          if (times != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x1aa78bfa),
                border: Border.all(color: const Color(0x38a78bfa)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                children: [
                  Text(
                    _fmtTime(times.maghrib).replaceAll(' ', '\n'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFa78bfa)),
                    textAlign: TextAlign.center,
                  ),
                  const Text('Iftar', style: TextStyle(fontSize: 9, color: Color(0xFF5a6d88))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    return FutureBuilder<Map<String, int>>(
      future: _db.getWeekStats(),
      builder: (context, snap) {
        final stats = snap.data ?? {};
        final total  = stats['total'] ?? 0;
        final prayed = stats['prayed'] ?? 0;
        final missed = stats['missed'] ?? 0;
        final pct    = total > 0 ? (prayed / total * 100).round() : 0;

        return FutureBuilder<int>(
          future: _db.getCurrentStreak(),
          builder: (context, streakSnap) {
            final streak = streakSnap.data ?? 0;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _statCard('$streak', 'Streak 🔥'),
                  const SizedBox(width: 8),
                  _statCard('$pct%', 'This week'),
                  const SizedBox(width: 8),
                  _statCard('$missed', 'Missed'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCard(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141d2b),
          border: Border.all(color: const Color(0xFF1c2c42)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFe6c872))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF5a6d88))),
          ],
        ),
      ),
    );
  }
}
