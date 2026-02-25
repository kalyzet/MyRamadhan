class RamadhanSession {
  final int? id;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final DateTime createdAt;
  final bool isActive;

  RamadhanSession({
    this.id,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_days': totalDays,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory RamadhanSession.fromMap(Map<String, dynamic> map) {
    return RamadhanSession(
      id: map['id'] as int?,
      year: map['year'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      totalDays: map['total_days'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  RamadhanSession copyWith({
    int? id,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return RamadhanSession(
      id: id ?? this.id,
      year: year ?? this.year,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RamadhanSession &&
        other.id == id &&
        other.year == year &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.totalDays == totalDays &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        year.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        totalDays.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
