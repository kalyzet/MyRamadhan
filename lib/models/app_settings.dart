/// Model representing application settings
class AppSettings {
  final int? id;
  final String languageCode; // 'en' or 'id'
  final DateTime updatedAt;

  AppSettings({
    this.id,
    required this.languageCode,
    required this.updatedAt,
  });

  /// Convert model to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language_code': languageCode,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create model from database map
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int?,
      languageCode: map['language_code'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Create a copy with updated fields
  AppSettings copyWith({
    int? id,
    String? languageCode,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppSettings(id: $id, languageCode: $languageCode, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.id == id &&
        other.languageCode == languageCode &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ languageCode.hashCode ^ updatedAt.hashCode;
  }
}
