// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prayer.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'prayerpal.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE prayer_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            prayer TEXT NOT NULL,
            status TEXT NOT NULL,
            prayed_at TEXT,
            was_edited INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_date_prayer ON prayer_records(date, prayer)',
        );
      },
    );
  }

  Future<void> upsertRecord(PrayerRecord record) async {
    final db = await database;
    await db.insert(
      'prayer_records',
      record.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PrayerRecord>> getRecordsForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'prayer_records',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'prayer ASC',
    );
    return maps.map((m) => PrayerRecord.fromMap(m)).toList();
  }

  Future<List<PrayerRecord>> getRecordsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'prayer_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, prayer ASC',
    );
    return maps.map((m) => PrayerRecord.fromMap(m)).toList();
  }

  Future<Map<String, int>> getWeekStats() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().substring(0, 10);

    final total = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM prayer_records WHERE date >= ?",
      [weekStartStr],
    )) ?? 0;

    final prayed = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM prayer_records WHERE date >= ? AND status = 'prayed'",
      [weekStartStr],
    )) ?? 0;

    final missed = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM prayer_records WHERE date >= ? AND status = 'missed'",
      [weekStartStr],
    )) ?? 0;

    return {'total': total, 'prayed': prayed, 'missed': missed};
  }

  /// Returns current streak of consecutive fully-prayed days
  Future<int> getCurrentStreak() async {
    final db = await database;
    int streak = 0;
    DateTime day = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final dateStr = day.toIso8601String().substring(0, 10);
      final records = await db.query(
        'prayer_records',
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      final prayed = records.where((r) => r['status'] == 'prayed').length;
      if (prayed == 5) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<Map<String, double>> getPrayerCompletionRates() async {
    final db = await database;
    final rates = <String, double>{};

    for (final prayer in PrayerName.values) {
      final total = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM prayer_records WHERE prayer = ?",
        [prayer.name],
      )) ?? 0;

      final prayed = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM prayer_records WHERE prayer = ? AND status = 'prayed'",
        [prayer.name],
      )) ?? 0;

      rates[prayer.name] = total > 0 ? prayed / total : 0.0;
    }
    return rates;
  }
}
