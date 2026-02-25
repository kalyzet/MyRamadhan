import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/models/achievement.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/models/user_stats.dart';
import 'package:my_ramadhan/repositories/achievement_repository.dart';
import 'package:my_ramadhan/services/achievement_tracker_service.dart';
import 'package:my_ramadhan/database/database_helper.dart';

void main() {
  late AchievementTrackerService service;
  late AchievementRepository repository;
  late DatabaseHelper dbHelper;

  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Use in-memory database for testing
    dbHelper = DatabaseHelper.instance;
    await dbHelper.database; // Initialize database
    repository = AchievementRepository(dbHelper: dbHelper);
    service = AchievementTrackerService(achievementRepository: repository);
  });

  tearDown(() async {
    await DatabaseHelper.instance.deleteDB();
  });

  group('AchievementTrackerService - Unit Tests', () {
    test('shouldUnlockFirstDay returns true when at least one perfect day exists',
        () {
      final records = [
        DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 5,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 240,
          isPerfectDay: true,
        ),
      ];

      expect(service.shouldUnlockFirstDay(records), true);
    });

    test('shouldUnlockFirstDay returns false when no perfect days exist', () {
      final records = [
        DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: true,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: true,
          tarawihComplete: false,
          tilawahPages: 5,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 110,
          isPerfectDay: false,
        ),
      ];

      expect(service.shouldUnlockFirstDay(records), false);
    });

    test('shouldUnlock7DayStreak returns true when current streak >= 7', () {
      final stats = UserStats(
        sessionId: 1,
        totalXp: 1000,
        level: 3,
        currentStreak: 7,
        longestStreak: 7,
        prayerStreak: 7,
        tilawahStreak: 7,
      );

      expect(service.shouldUnlock7DayStreak(stats), true);
    });

    test('shouldUnlock7DayStreak returns false when current streak < 7', () {
      final stats = UserStats(
        sessionId: 1,
        totalXp: 1000,
        level: 3,
        currentStreak: 6,
        longestStreak: 6,
        prayerStreak: 6,
        tilawahStreak: 6,
      );

      expect(service.shouldUnlock7DayStreak(stats), false);
    });

    test('shouldUnlock100Pages returns true when total pages >= 100', () {
      final records = [
        DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 50,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 340,
          isPerfectDay: true,
        ),
        DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 16),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 50,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 340,
          isPerfectDay: true,
        ),
      ];

      expect(service.shouldUnlock100Pages(records), true);
    });

    test('shouldUnlock100Pages returns false when total pages < 100', () {
      final records = [
        DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 50,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 340,
          isPerfectDay: true,
        ),
      ];

      expect(service.shouldUnlock100Pages(records), false);
    });

    test('shouldUnlockRamadhanMaster returns true when 30 perfect days exist',
        () {
      final records = List.generate(
        30,
        (index) => DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15 + index),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 5,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 240,
          isPerfectDay: true,
        ),
      );

      expect(service.shouldUnlockRamadhanMaster(records), true);
    });

    test('shouldUnlockRamadhanMaster returns false when less than 30 days', () {
      final records = List.generate(
        29,
        (index) => DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15 + index),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 5,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 240,
          isPerfectDay: true,
        ),
      );

      expect(service.shouldUnlockRamadhanMaster(records), false);
    });

    test(
        'shouldUnlockRamadhanMaster returns false when 30 days but not all perfect',
        () {
      final records = List.generate(
        30,
        (index) => DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15 + index),
          fajrComplete: index != 10, // One day incomplete
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 5,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: index != 10 ? 240 : 190,
          isPerfectDay: index != 10,
        ),
      );

      expect(service.shouldUnlockRamadhanMaster(records), false);
    });
  });

  group('AchievementTrackerService - Property-Based Tests', () {
    // **Feature: my-ramadhan-app, Property 21: Achievement unlock with timestamp**
    // **Validates: Requirements 6.1**
    test(
        'Property 21: Achievement unlocked records current timestamp',
        () async {
      // Test with a single session to avoid database locking issues
      final validSessionId = 1;

      // Clean up any existing data for this session
      final db = await dbHelper.database;
      await db.delete('achievements', where: 'session_id = ?', whereArgs: [validSessionId]);
      await db.delete('ramadhan_sessions', where: 'id = ?', whereArgs: [validSessionId]);

      // Create a test session
      await db.insert('ramadhan_sessions', {
        'id': validSessionId,
        'year': 2024,
        'start_date': '2024-03-11',
        'end_date': '2024-04-09',
        'total_days': 30,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      });

      // Initialize achievements for this session
      await repository.initializeAchievements(validSessionId);

      // Get achievements
      final achievements =
          await repository.getAchievementsForSession(validSessionId);

      // Find the "First Day Completed" achievement
      final firstDayAchievement = achievements.firstWhere(
        (a) => a.title == 'First Day Completed',
      );

      // Record the time before unlocking
      final beforeUnlock = DateTime.now();

      // Create a perfect day record to trigger unlock
      final records = [
        DailyRecord(
          sessionId: validSessionId,
          date: DateTime(2024, 3, 15),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 5,
          dzikirComplete: true,
          sedekahAmount: 10.0,
          xpEarned: 240,
          isPerfectDay: true,
        ),
      ];

      final stats = UserStats(
        sessionId: validSessionId,
        totalXp: 240,
        level: 1,
        currentStreak: 1,
        longestStreak: 1,
        prayerStreak: 1,
        tilawahStreak: 1,
      );

      // Check and unlock achievements
      await service.checkAndUnlockAchievements(
        validSessionId,
        stats,
        records,
      );

      // Record the time after unlocking
      final afterUnlock = DateTime.now();

      // Get the updated achievement
      final updatedAchievements =
          await repository.getAchievementsForSession(validSessionId);
      final unlockedAchievement = updatedAchievements.firstWhere(
        (a) => a.title == 'First Day Completed',
      );

      // Verify the achievement is unlocked
      expect(unlockedAchievement.unlocked, true);

      // Verify the unlock date is set and within the time window
      expect(unlockedAchievement.unlockedDate, isNotNull);
      expect(
        unlockedAchievement.unlockedDate!.isAfter(
          beforeUnlock.subtract(Duration(seconds: 2)),
        ),
        true,
      );
      expect(
        unlockedAchievement.unlockedDate!.isBefore(
          afterUnlock.add(Duration(seconds: 2)),
        ),
        true,
      );
    });
  });
}
