/// Custom exception for validation errors
/// Provides user-friendly error messages for invalid inputs
class ValidationException implements Exception {
  final String message;
  final String userMessage;
  final String? field;

  ValidationException({
    required this.message,
    required this.userMessage,
    this.field,
  });

  @override
  String toString() => 'ValidationException: $message';

  /// Factory for invalid tilawah pages
  factory ValidationException.invalidTilawahPages(int pages) {
    return ValidationException(
      message: 'Invalid tilawah pages: $pages',
      userMessage:
          'Tilawah pages must be between 0 and 604 (total Quran pages).',
      field: 'tilawahPages',
    );
  }

  /// Factory for invalid sedekah amount
  factory ValidationException.invalidSedekahAmount(double amount) {
    return ValidationException(
      message: 'Invalid sedekah amount: $amount',
      userMessage: 'Sedekah amount must be non-negative.',
      field: 'sedekahAmount',
    );
  }

  /// Factory for invalid date
  factory ValidationException.invalidDate(String reason) {
    return ValidationException(
      message: 'Invalid date: $reason',
      userMessage: 'The selected date is not valid. $reason',
      field: 'date',
    );
  }

  /// Factory for backdating violation
  factory ValidationException.backdatingViolation() {
    return ValidationException(
      message: 'Backdating limit exceeded',
      userMessage:
          'You can only modify records from the past 2 days (H-1 and H-2).',
      field: 'date',
    );
  }

  /// Factory for date outside session range
  factory ValidationException.dateOutsideSession() {
    return ValidationException(
      message: 'Date outside session range',
      userMessage: 'The selected date is outside the Ramadhan session period.',
      field: 'date',
    );
  }

  /// Factory for invalid XP value
  factory ValidationException.invalidXp(int xp) {
    return ValidationException(
      message: 'Invalid XP value: $xp',
      userMessage: 'XP value must be non-negative.',
      field: 'xp',
    );
  }

  /// Factory for invalid streak value
  factory ValidationException.invalidStreak(int streak) {
    return ValidationException(
      message: 'Invalid streak value: $streak',
      userMessage: 'Streak value must be non-negative.',
      field: 'streak',
    );
  }

  /// Factory for invalid session year
  factory ValidationException.invalidYear(int year) {
    return ValidationException(
      message: 'Invalid year: $year',
      userMessage: 'Please enter a valid year.',
      field: 'year',
    );
  }

  /// Factory for invalid session duration
  factory ValidationException.invalidDuration(int days) {
    return ValidationException(
      message: 'Invalid duration: $days',
      userMessage: 'Ramadhan duration must be 29 or 30 days.',
      field: 'totalDays',
    );
  }
}
