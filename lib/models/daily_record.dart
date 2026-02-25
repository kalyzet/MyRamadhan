class DailyRecord {
  final int? id;
  final int sessionId;
  final DateTime date;
  final bool fajrComplete;
  final bool dhuhrComplete;
  final bool asrComplete;
  final bool maghribComplete;
  final bool ishaComplete;
  final bool puasaComplete;
  final bool tarawihComplete;
  final int tilawahPages;
  final bool dzikirComplete;
  final double sedekahAmount;
  final int xpEarned;
  final bool isPerfectDay;

  DailyRecord({
    this.id,
    required this.sessionId,
    required this.date,
    required this.fajrComplete,
    required this.dhuhrComplete,
    required this.asrComplete,
    required this.maghribComplete,
    required this.ishaComplete,
    required this.puasaComplete,
    required this.tarawihComplete,
    required this.tilawahPages,
    required this.dzikirComplete,
    required this.sedekahAmount,
    required this.xpEarned,
    required this.isPerfectDay,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'date': date.toIso8601String(),
      'fajr_complete': fajrComplete ? 1 : 0,
      'dhuhr_complete': dhuhrComplete ? 1 : 0,
      'asr_complete': asrComplete ? 1 : 0,
      'maghrib_complete': maghribComplete ? 1 : 0,
      'isha_complete': ishaComplete ? 1 : 0,
      'puasa_complete': puasaComplete ? 1 : 0,
      'tarawih_complete': tarawihComplete ? 1 : 0,
      'tilawah_pages': tilawahPages,
      'dzikir_complete': dzikirComplete ? 1 : 0,
      'sedekah_amount': sedekahAmount,
      'xp_earned': xpEarned,
      'is_perfect_day': isPerfectDay ? 1 : 0,
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      date: DateTime.parse(map['date'] as String),
      fajrComplete: (map['fajr_complete'] as int) == 1,
      dhuhrComplete: (map['dhuhr_complete'] as int) == 1,
      asrComplete: (map['asr_complete'] as int) == 1,
      maghribComplete: (map['maghrib_complete'] as int) == 1,
      ishaComplete: (map['isha_complete'] as int) == 1,
      puasaComplete: (map['puasa_complete'] as int) == 1,
      tarawihComplete: (map['tarawih_complete'] as int) == 1,
      tilawahPages: map['tilawah_pages'] as int,
      dzikirComplete: (map['dzikir_complete'] as int) == 1,
      sedekahAmount: (map['sedekah_amount'] as num).toDouble(),
      xpEarned: map['xp_earned'] as int,
      isPerfectDay: (map['is_perfect_day'] as int) == 1,
    );
  }

  DailyRecord copyWith({
    int? id,
    int? sessionId,
    DateTime? date,
    bool? fajrComplete,
    bool? dhuhrComplete,
    bool? asrComplete,
    bool? maghribComplete,
    bool? ishaComplete,
    bool? puasaComplete,
    bool? tarawihComplete,
    int? tilawahPages,
    bool? dzikirComplete,
    double? sedekahAmount,
    int? xpEarned,
    bool? isPerfectDay,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      date: date ?? this.date,
      fajrComplete: fajrComplete ?? this.fajrComplete,
      dhuhrComplete: dhuhrComplete ?? this.dhuhrComplete,
      asrComplete: asrComplete ?? this.asrComplete,
      maghribComplete: maghribComplete ?? this.maghribComplete,
      ishaComplete: ishaComplete ?? this.ishaComplete,
      puasaComplete: puasaComplete ?? this.puasaComplete,
      tarawihComplete: tarawihComplete ?? this.tarawihComplete,
      tilawahPages: tilawahPages ?? this.tilawahPages,
      dzikirComplete: dzikirComplete ?? this.dzikirComplete,
      sedekahAmount: sedekahAmount ?? this.sedekahAmount,
      xpEarned: xpEarned ?? this.xpEarned,
      isPerfectDay: isPerfectDay ?? this.isPerfectDay,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailyRecord &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.date == date &&
        other.fajrComplete == fajrComplete &&
        other.dhuhrComplete == dhuhrComplete &&
        other.asrComplete == asrComplete &&
        other.maghribComplete == maghribComplete &&
        other.ishaComplete == ishaComplete &&
        other.puasaComplete == puasaComplete &&
        other.tarawihComplete == tarawihComplete &&
        other.tilawahPages == tilawahPages &&
        other.dzikirComplete == dzikirComplete &&
        other.sedekahAmount == sedekahAmount &&
        other.xpEarned == xpEarned &&
        other.isPerfectDay == isPerfectDay;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        date.hashCode ^
        fajrComplete.hashCode ^
        dhuhrComplete.hashCode ^
        asrComplete.hashCode ^
        maghribComplete.hashCode ^
        ishaComplete.hashCode ^
        puasaComplete.hashCode ^
        tarawihComplete.hashCode ^
        tilawahPages.hashCode ^
        dzikirComplete.hashCode ^
        sedekahAmount.hashCode ^
        xpEarned.hashCode ^
        isPerfectDay.hashCode;
  }
}
