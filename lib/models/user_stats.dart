class UserStats {
  final int? id;
  final int sessionId;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int prayerStreak;
  final int tilawahStreak;

  UserStats({
    this.id,
    required this.sessionId,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.prayerStreak,
    required this.tilawahStreak,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'total_xp': totalXp,
      'level': level,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'prayer_streak': prayerStreak,
      'tilawah_streak': tilawahStreak,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      totalXp: map['total_xp'] as int,
      level: map['level'] as int,
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      prayerStreak: map['prayer_streak'] as int,
      tilawahStreak: map['tilawah_streak'] as int,
    );
  }

  UserStats copyWith({
    int? id,
    int? sessionId,
    int? totalXp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    int? prayerStreak,
    int? tilawahStreak,
  }) {
    return UserStats(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      prayerStreak: prayerStreak ?? this.prayerStreak,
      tilawahStreak: tilawahStreak ?? this.tilawahStreak,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserStats &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.totalXp == totalXp &&
        other.level == level &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.prayerStreak == prayerStreak &&
        other.tilawahStreak == tilawahStreak;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        totalXp.hashCode ^
        level.hashCode ^
        currentStreak.hashCode ^
        longestStreak.hashCode ^
        prayerStreak.hashCode ^
        tilawahStreak.hashCode;
  }
}
