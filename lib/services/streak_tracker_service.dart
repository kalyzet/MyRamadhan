import '../models/daily_record.dart';
import '../models/user_stats.dart';
import '../repositories/daily_record_repository.dart';
import '../repositories/stats_repository.dart';

/// Service for tracking and calculating streaks
/// Handles perfect day streaks, prayer streaks, and tilawah streaks
class StreakTrackerService {
  final DailyRecordRepository _dailyRecordRepository;
  final StatsRepository _statsRepository;

  StreakTrackerService({
    required DailyRecordRepository dailyRecordRepository,
    required StatsRepository statsRepository,
  })  : _dailyRecordRepository = dailyRecordRepository,
        _statsRepository = statsRepository;

  /// Check if a daily record represents a perfect day
  /// A perfect day requires all main quest objectives to be completed:
  /// - All 5 prayers (Fajr, Dhuhr, Asr, Maghrib, Isha)
  /// - Puasa (fasting)
  /// - Tarawih
  /// - Tilawah (at least 1 page)
  /// - Dzikir
  /// - Sedekah (any amount > 0)
  bool isPerfectDay(DailyRecord record) {
    return record.fajrComplete &&
        record.dhuhrComplete &&
        record.asrComplete &&
        record.maghribComplete &&
        record.ishaComplete &&
        record.puasaComplete &&
        record.tarawihComplete &&
        record.tilawahPages > 0 &&
        record.dzikirComplete &&
        record.sedekahAmount > 0;
  }

  /// Check if all prayers are complete in a daily record
  bool hasPrayerComplete(DailyRecord record) {
    return record.fajrComplete &&
        record.dhuhrComplete &&
        record.asrComplete &&
        record.maghribComplete &&
        record.ishaComplete;
  }

  /// Check if tilawah is complete in a daily record
  /// Tilawah is considered complete if at least 1 page was read
  bool hasTilawahComplete(DailyRecord record) {
    return record.tilawahPages > 0;
  }

  /// Update streaks for a new record
  /// This method calculates streaks incrementally based on the previous day's record
  Future<void> updateStreaksForNewRecord(
    int sessionId,
    DailyRecord newRecord,
    DailyRecord? previousDayRecord,
  ) async {
    // Get current stats
    var stats = await _statsRepository.getStatsForSession(sessionId);
    
    if (stats == null) {
      // Create initial stats if they don't exist
      stats = UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
    }

    // Calculate new perfect streak
    int newCurrentStreak;
    if (isPerfectDay(newRecord)) {
      // If previous day was also perfect, increment streak
      if (previousDayRecord != null && isPerfectDay(previousDayRecord)) {
        newCurrentStreak = stats.currentStreak + 1;
      } else {
        // Start new streak
        newCurrentStreak = 1;
      }
    } else {
      // Perfect day streak broken
      newCurrentStreak = 0;
    }

    // Calculate new prayer streak
    int newPrayerStreak;
    if (hasPrayerComplete(newRecord)) {
      // If previous day also had complete prayers, increment streak
      if (previousDayRecord != null && hasPrayerComplete(previousDayRecord)) {
        newPrayerStreak = stats.prayerStreak + 1;
      } else {
        // Start new streak
        newPrayerStreak = 1;
      }
    } else {
      // Prayer streak broken
      newPrayerStreak = 0;
    }

    // Calculate new tilawah streak
    int newTilawahStreak;
    if (hasTilawahComplete(newRecord)) {
      // If previous day also had tilawah, increment streak
      if (previousDayRecord != null && hasTilawahComplete(previousDayRecord)) {
        newTilawahStreak = stats.tilawahStreak + 1;
      } else {
        // Start new streak
        newTilawahStreak = 1;
      }
    } else {
      // Tilawah streak broken
      newTilawahStreak = 0;
    }

    // Update longest streak if current streak exceeds it
    int newLongestStreak = stats.longestStreak;
    if (newCurrentStreak > newLongestStreak) {
      newLongestStreak = newCurrentStreak;
    }

    // Update stats in database
    await _statsRepository.updateStreaks(
      sessionId,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      prayerStreak: newPrayerStreak,
      tilawahStreak: newTilawahStreak,
    );
  }

  /// Recalculate all streaks from scratch based on all records
  /// This is used when backdating occurs and streaks need to be recalculated
  Future<void> recalculateAllStreaks(
    int sessionId,
    List<DailyRecord> records,
  ) async {
    // Sort records by date to ensure correct order
    final sortedRecords = List<DailyRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Initialize streak counters
    int currentStreak = 0;
    int longestStreak = 0;
    int prayerStreak = 0;
    int tilawahStreak = 0;

    // Track previous day's date to detect gaps
    DateTime? previousDate;

    for (final record in sortedRecords) {
      // Check if there's a gap in dates (more than 1 day)
      bool hasGap = false;
      if (previousDate != null) {
        final daysDifference = record.date.difference(previousDate).inDays;
        if (daysDifference > 1) {
          hasGap = true;
        }
      }

      // Calculate perfect streak
      if (isPerfectDay(record)) {
        if (hasGap) {
          // Gap detected, reset streak
          currentStreak = 1;
        } else {
          // Continue or start streak
          currentStreak++;
        }
        
        // Update longest streak if needed
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        // Perfect day streak broken
        currentStreak = 0;
      }

      // Calculate prayer streak
      if (hasPrayerComplete(record)) {
        if (hasGap) {
          // Gap detected, reset streak
          prayerStreak = 1;
        } else {
          // Continue or start streak
          prayerStreak++;
        }
      } else {
        // Prayer streak broken
        prayerStreak = 0;
      }

      // Calculate tilawah streak
      if (hasTilawahComplete(record)) {
        if (hasGap) {
          // Gap detected, reset streak
          tilawahStreak = 1;
        } else {
          // Continue or start streak
          tilawahStreak++;
        }
      } else {
        // Tilawah streak broken
        tilawahStreak = 0;
      }

      previousDate = record.date;
    }

    // Update stats in database with final calculated values
    await _statsRepository.updateStreaks(
      sessionId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      prayerStreak: prayerStreak,
      tilawahStreak: tilawahStreak,
    );
  }
}
