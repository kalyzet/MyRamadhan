class Achievement {
  final int? id;
  final int sessionId;
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedDate;
  final String iconName;

  Achievement({
    this.id,
    required this.sessionId,
    required this.title,
    required this.description,
    required this.unlocked,
    this.unlockedDate,
    required this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'title': title,
      'description': description,
      'unlocked': unlocked ? 1 : 0,
      'unlocked_date': unlockedDate?.toIso8601String(),
      'icon_name': iconName,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      unlocked: (map['unlocked'] as int) == 1,
      unlockedDate: map['unlocked_date'] != null
          ? DateTime.parse(map['unlocked_date'] as String)
          : null,
      iconName: map['icon_name'] as String,
    );
  }

  Achievement copyWith({
    int? id,
    int? sessionId,
    String? title,
    String? description,
    bool? unlocked,
    DateTime? unlockedDate,
    String? iconName,
  }) {
    return Achievement(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      description: description ?? this.description,
      unlocked: unlocked ?? this.unlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Achievement &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.title == title &&
        other.description == description &&
        other.unlocked == unlocked &&
        other.unlockedDate == unlockedDate &&
        other.iconName == iconName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        unlocked.hashCode ^
        unlockedDate.hashCode ^
        iconName.hashCode;
  }
}
