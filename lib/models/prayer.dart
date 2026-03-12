// lib/models/prayer.dart

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

enum PrayerStatus { pending, prayed, missed, edited }

extension PrayerNameExt on PrayerName {
  String get displayName {
    switch (this) {
      case PrayerName.fajr: return 'Subuh';
      case PrayerName.dhuhr: return 'Zuhur';
      case PrayerName.asr: return 'Asar';
      case PrayerName.maghrib: return 'Maghrib';
      case PrayerName.isha: return 'Isyak';
    }
  }

  String get emoji {
    switch (this) {
      case PrayerName.fajr: return '🌅';
      case PrayerName.dhuhr: return '🕛';
      case PrayerName.asr: return '🌤';
      case PrayerName.maghrib: return '🌇';
      case PrayerName.isha: return '🌙';
    }
  }

  String get key => name;
}

class DailyPrayerTimes {
  final DateTime date;
  final DateTime fajr;
  final DateTime syuruk;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const DailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.syuruk,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  DateTime timeFor(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr: return fajr;
      case PrayerName.dhuhr: return dhuhr;
      case PrayerName.asr: return asr;
      case PrayerName.maghrib: return maghrib;
      case PrayerName.isha: return isha;
    }
  }

  /// End of prayer window = start of next prayer (fajr ends at syuruk, isha ends at midnight)
  DateTime windowEndFor(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr: return syuruk;
      case PrayerName.dhuhr: return asr;
      case PrayerName.asr: return maghrib;
      case PrayerName.maghrib: return isha;
      case PrayerName.isha:
        return DateTime(date.year, date.month, date.day, 23, 59);
    }
  }
}

class PrayerRecord {
  final int? id;
  final DateTime date;
  final PrayerName prayer;
  final PrayerStatus status;
  final DateTime? prayedAt;
  final bool wasEdited;

  const PrayerRecord({
    this.id,
    required this.date,
    required this.prayer,
    required this.status,
    this.prayedAt,
    this.wasEdited = false,
  });

  PrayerRecord copyWith({
    int? id,
    DateTime? date,
    PrayerName? prayer,
    PrayerStatus? status,
    DateTime? prayedAt,
    bool? wasEdited,
  }) {
    return PrayerRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      prayer: prayer ?? this.prayer,
      status: status ?? this.status,
      prayedAt: prayedAt ?? this.prayedAt,
      wasEdited: wasEdited ?? this.wasEdited,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'prayer': prayer.name,
      'status': status.name,
      'prayed_at': prayedAt?.toIso8601String(),
      'was_edited': wasEdited ? 1 : 0,
    };
  }

  factory PrayerRecord.fromMap(Map<String, dynamic> map) {
    return PrayerRecord(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      prayer: PrayerName.values.firstWhere((e) => e.name == map['prayer']),
      status: PrayerStatus.values.firstWhere((e) => e.name == map['status']),
      prayedAt: map['prayed_at'] != null
          ? DateTime.parse(map['prayed_at'] as String)
          : null,
      wasEdited: (map['was_edited'] as int) == 1,
    );
  }
}
