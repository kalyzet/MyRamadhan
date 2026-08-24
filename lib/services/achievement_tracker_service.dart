import '../models/achievement.dart';
import '../models/daily_record.dart';
import '../models/user_stats.dart';
import '../repositories/achievement_repository.dart';

/// Service for tracking and unlocking achievements
/// Checks achievement criteria and unlocks achievements when conditions are met
class AchievementTrackerService {
  final AchievementRepository _achievementRepository;

  AchievementTrackerService({
    AchievementRepository? achievementRepository,
  }) : _achievementRepository = achievementRepository ?? AchievementRepository();

  /// Check all achievement criteria and unlock achievements that meet their conditions
  /// This method should be called after daily records are updated
  ///
  /// Achievements are matched by [Achievement.iconName], which is a stable
  /// non-localized identifier. Titles are translation keys and must never be
  /// used for matching.
  Future<void> checkAndUnlockAchievements(
    int sessionId,
    UserStats stats,
    List<DailyRecord> records, {
    int totalDays = 30,
  }) async {
    // Get all achievements for the session
    final achievements = await _achievementRepository.getAchievementsForSession(sessionId);

    // Check each achievement and unlock if criteria met
    for (final achievement in achievements) {
      // Skip if already unlocked
      if (achievement.unlocked) continue;

      bool shouldUnlock = false;

      // Check based on the stable iconName identifier
      if (achievement.iconName == 'first_day') {
        shouldUnlock = shouldUnlockFirstDay(records);
      } else if (achievement.iconName == 'seven_days') {
        shouldUnlock = shouldUnlock7DayStreak(stats);
      } else if (achievement.iconName == 'quran_100') {
        shouldUnlock = shouldUnlock100Pages(records);
      } else if (achievement.iconName == 'master') {
        shouldUnlock = shouldUnlockRamadhanMaster(records, totalDays);
      } else if (achievement.iconName == 'prayer_warrior') {
        shouldUnlock = shouldUnlockPrayerWarrior(stats);
      } else if (achievement.iconName == 'generous') {
        shouldUnlock = shouldUnlockGenerous(records);
      } else if (achievement.iconName == 'night_prayer') {
        shouldUnlock = shouldUnlockNightPrayer(records);
      } else if (achievement.iconName == 'quran_complete') {
        shouldUnlock = shouldUnlockQuranComplete(records);
      }

      // Unlock the achievement if criteria met
      if (shouldUnlock && achievement.id != null) {
        await _achievementRepository.unlockAchievement(achievement.id!);
      }
    }
  }

  /// Check if user has completed their first day
  /// Returns true if there is at least one perfect day in the records
  bool shouldUnlockFirstDay(List<DailyRecord> records) {
    return records.any((record) => record.isPerfectDay);
  }

  /// Check if user has maintained a 7-day perfect streak
  /// Returns true if current streak is >= 7
  bool shouldUnlock7DayStreak(UserStats stats) {
    return stats.currentStreak >= 7;
  }

  /// Check if user has read 100 Quran pages
  /// Returns true if total tilawah pages across all records >= 100
  bool shouldUnlock100Pages(List<DailyRecord> records) {
    final totalPages = records.fold<int>(
      0,
      (sum, record) => sum + record.tilawahPages,
    );
    return totalPages >= 100;
  }

  /// Check if user has completed all session days with perfect records
  /// Returns true if there are at least [totalDays] records and all are perfect days
  bool shouldUnlockRamadhanMaster(List<DailyRecord> records, int totalDays) {
    if (records.length < totalDays) return false;
    return records.every((record) => record.isPerfectDay);
  }

  /// Check if user has maintained a 7-day prayer streak
  /// Returns true if the current prayer streak is >= 7
  bool shouldUnlockPrayerWarrior(UserStats stats) {
    return stats.prayerStreak >= 7;
  }

  /// Check if user has given sedekah on at least 15 different days
  bool shouldUnlockGenerous(List<DailyRecord> records) {
    final generousDays = records.where((record) => record.sedekahAmount > 0);
    return generousDays.length >= 15;
  }

  /// Check if user has completed tarawih on at least 20 days
  bool shouldUnlockNightPrayer(List<DailyRecord> records) {
    final tarawihDays = records.where((record) => record.tarawihComplete);
    return tarawihDays.length >= 20;
  }

  /// Check if user has read the equivalent of a full Quran (604 pages)
  bool shouldUnlockQuranComplete(List<DailyRecord> records) {
    final totalPages = records.fold<int>(
      0,
      (sum, record) => sum + record.tilawahPages,
    );
    return totalPages >= 604;
  }
}
