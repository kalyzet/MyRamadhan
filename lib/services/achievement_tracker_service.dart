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
  Future<void> checkAndUnlockAchievements(
    int sessionId,
    UserStats stats,
    List<DailyRecord> records,
  ) async {
    // Get all achievements for the session
    final achievements = await _achievementRepository.getAchievementsForSession(sessionId);

    // Check each achievement and unlock if criteria met
    for (final achievement in achievements) {
      // Skip if already unlocked
      if (achievement.unlocked) continue;

      bool shouldUnlock = false;

      // Check based on achievement title (matching the initialized achievements)
      if (achievement.title == 'First Day Completed') {
        shouldUnlock = shouldUnlockFirstDay(records);
      } else if (achievement.title == '7 Day Consistency') {
        shouldUnlock = shouldUnlock7DayStreak(stats);
      } else if (achievement.title == '100 Quran Pages') {
        shouldUnlock = shouldUnlock100Pages(records);
      } else if (achievement.title == 'Ramadhan Master') {
        shouldUnlock = shouldUnlockRamadhanMaster(records);
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

  /// Check if user has completed all 30 days with perfect records
  /// Returns true if there are 30 records and all are perfect days
  bool shouldUnlockRamadhanMaster(List<DailyRecord> records) {
    if (records.length < 30) return false;
    return records.every((record) => record.isPerfectDay);
  }
}
