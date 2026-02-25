class SideQuest {
  final int? id;
  final int sessionId;
  final DateTime date;
  final String title;
  final String description;
  final int xpReward;
  final bool completed;

  SideQuest({
    this.id,
    required this.sessionId,
    required this.date,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'xp_reward': xpReward,
      'completed': completed ? 1 : 0,
    };
  }

  factory SideQuest.fromMap(Map<String, dynamic> map) {
    return SideQuest(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      date: DateTime.parse(map['date'] as String),
      title: map['title'] as String,
      description: map['description'] as String,
      xpReward: map['xp_reward'] as int,
      completed: (map['completed'] as int) == 1,
    );
  }

  SideQuest copyWith({
    int? id,
    int? sessionId,
    DateTime? date,
    String? title,
    String? description,
    int? xpReward,
    bool? completed,
  }) {
    return SideQuest(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      completed: completed ?? this.completed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SideQuest &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.date == date &&
        other.title == title &&
        other.description == description &&
        other.xpReward == xpReward &&
        other.completed == completed;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        date.hashCode ^
        title.hashCode ^
        description.hashCode ^
        xpReward.hashCode ^
        completed.hashCode;
  }
}
