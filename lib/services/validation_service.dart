import '../exceptions/validation_exception.dart';
import '../models/daily_record.dart';
import '../models/ramadhan_session.dart';

/// Service for validating user inputs and business rules
/// Requirements: 2.4, 2.8
class ValidationService {
  /// Maximum number of pages in the Quran
  static const int maxQuranPages = 604;

  /// Maximum backdating days allowed (H-1 and H-2)
  static const int maxBackdatingDays = 2;

  /// Validate tilawah pages
  /// Requirements: 2.4
  void validateTilawahPages(int pages) {
    if (pages < 0 || pages > maxQuranPages) {
      throw ValidationException.invalidTilawahPages(pages);
    }
  }

  /// Validate sedekah amount
  /// Requirements: 2.6
  void validateSedekahAmount(double amount) {
    if (amount < 0) {
      throw ValidationException.invalidSedekahAmount(amount);
    }
  }

  /// Validate XP value
  void validateXp(int xp) {
    if (xp < 0) {
      throw ValidationException.invalidXp(xp);
    }
  }

  /// Validate streak value
  void validateStreak(int streak) {
    if (streak < 0) {
      throw ValidationException.invalidStreak(streak);
    }
  }

  /// Validate session year
  void validateYear(int year) {
    final currentYear = DateTime.now().year;
    // Allow years from 2000 to 50 years in the future
    if (year < 2000 || year > currentYear + 50) {
      throw ValidationException.invalidYear(year);
    }
  }

  /// Validate session duration
  void validateDuration(int days) {
    if (days != 29 && days != 30) {
      throw ValidationException.invalidDuration(days);
    }
  }

  /// Validate backdating rule
  /// Records can only be modified if within 2 days of current date
  /// Requirements: 2.8
  void validateBackdating(DateTime recordDate, DateTime currentDate) {
    // Normalize dates to start of day
    final normalizedRecordDate =
        DateTime(recordDate.year, recordDate.month, recordDate.day);
    final normalizedCurrentDate =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    // Calculate difference in days
    final difference =
        normalizedCurrentDate.difference(normalizedRecordDate).inDays;

    // Can modify if difference is 0 (today), 1 (H-1), or 2 (H-2)
    if (difference < 0 || difference > maxBackdatingDays) {
      throw ValidationException.backdatingViolation();
    }
  }

  /// Validate date is within session range
  void validateDateInSession(
      DateTime date, RamadhanSession session) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      session.startDate.year,
      session.startDate.month,
      session.startDate.day,
    );
    final normalizedEnd = DateTime(
      session.endDate.year,
      session.endDate.month,
      session.endDate.day,
    );

    if (normalizedDate.isBefore(normalizedStart) ||
        normalizedDate.isAfter(normalizedEnd)) {
      throw ValidationException.dateOutsideSession();
    }
  }

  /// Validate a complete daily record
  /// Validates all fields in the record
  void validateDailyRecord(DailyRecord record) {
    validateTilawahPages(record.tilawahPages);
    validateSedekahAmount(record.sedekahAmount);
    validateXp(record.xpEarned);
  }

  /// Validate session creation parameters
  void validateSessionCreation({
    required int year,
    required DateTime startDate,
    required int totalDays,
  }) {
    validateYear(year);
    validateDuration(totalDays);

    // Validate start date is not too far in the past or future
    final now = DateTime.now();
    final yearsDifference = (startDate.year - now.year).abs();
    if (yearsDifference > 10) {
      throw ValidationException.invalidDate(
        'Start date must be within 10 years of current date.',
      );
    }
  }

  /// Validate that only one session is active
  /// This should be called after querying active sessions
  void validateSingleActiveSession(List<RamadhanSession> activeSessions) {
    if (activeSessions.length > 1) {
      throw ValidationException(
        message: 'Multiple active sessions found',
        userMessage:
            'System error: Multiple active sessions detected. Please contact support.',
        field: 'session',
      );
    }
  }
}
