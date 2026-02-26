import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/database/database_helper.dart';
import '../../lib/repositories/session_repository.dart';
import '../../lib/repositories/daily_record_repository.dart';
import '../../lib/repositories/stats_repository.dart';
import '../../lib/repositories/achievement_repository.dart';
import '../../lib/repositories/side_quest_repository.dart';
import '../../lib/services/xp_calculator_service.dart';
import '../../lib/services/level_calculator_service.dart';
import '../../lib/services/streak_tracker_service.dart';
import '../../lib/services/achievement_tracker_service.dart';
import '../../lib/models/ramadhan_session.dart';
import '../../lib/models/daily_record.dart';
import '../../lib/models/user_stats.dart';

/// Integration tests for complete workflows
/// Tests end-to-end user journeys
/// Requirements: All
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Complete Workflow Integration Tests', () {
    late SessionRepository sessionRepository;
    late DailyRecordRepository dailyRecordRepository;
    late StatsRepository statsRepository;
    late AchievementRepository achievementRepository;
    late SideQuestRepository sideQuestRepository;
    late XpCalculatorService xpCalculatorService;
    late LevelCalculatorService levelCalculatorService;
    late StreakTrackerService streakTrackerService;
    late AchievementTrackerService achievementTrackerService;

    setUp(() async {
      // Initialize repositories
      sessionRepository = SessionRepository();
      dailyRecordRepository = DailyRecordRepository();
      statsRepository = StatsRepository();
      achievementRepository = AchievementRepository();
      sideQuestRepository = SideQuestRepository();

      // Initialize services
      xpCalculatorService = XpCalculatorService();
      levelCalculatorService = LevelCalculatorService();
      streakTrackerService = StreakTrackerService(
        dailyRecordRepository: dailyRecordRepository,
        statsRepository: statsRepository,
      );
      achievementTrackerService = AchievementTrackerService();
    });

    tearDown(() async {
      // Clean up database after each test
      await DatabaseHelper.instance.deleteDB();
    });

    test('Complete day recording flow', () async {
      // 1. Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await sessionRepository.setActiveSession(session.id!);

      // 2. Initialize stats
      var stats = UserStats(
        sessionId: session.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      stats = await statsRepository.updateStats(stats);

      // 3. Initialize achievements
      await achievementRepository.initializeAchievements(session.id!);

      // 4. Record a complete day
      final record = DailyRecord(
        sessionId: session.id!,
        date: DateTime(2024, 3, 11),
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
        xpEarned: 0,
        isPerfectDay: false,
      );

      // 5. Calculate XP
      final xpEarned = xpCalculatorService.calculateTotalDailyXp(record);
      // 50 (prayers) + 50 (puasa) + 30 (tarawih) + 10 (tilawah 5 pages) + 20 (dzikir) + 30 (sedekah) + 50 (perfect day bonus) = 240
      expect(xpEarned, equals(240));

      // 6. Save record with XP
      final savedRecord = await dailyRecordRepository.createOrUpdateRecord(
        record.copyWith(xpEarned: xpEarned, isPerfectDay: true),
      );

      // 7. Update stats with XP
      await statsRepository.addXp(session.id!, xpEarned);

      // 8. Update streaks
      await streakTrackerService.updateStreaksForNewRecord(
        session.id!,
        savedRecord,
        null, // No previous day
      );

      // 9. Check achievements
      final allRecords = await dailyRecordRepository.getRecordsForSession(session.id!);
      final updatedStats = await statsRepository.getStatsForSession(session.id!);
      await achievementTrackerService.checkAndUnlockAchievements(
        session.id!,
        updatedStats!,
        allRecords,
      );

      // Verify final state
      final finalStats = await statsRepository.getStatsForSession(session.id!);
      expect(finalStats!.totalXp, equals(240));
      expect(finalStats.currentStreak, equals(1));
      expect(finalStats.prayerStreak, equals(1));
      expect(finalStats.tilawahStreak, equals(1));

      final achievements = await achievementRepository.getAchievementsForSession(session.id!);
      final firstDayAchievement = achievements.firstWhere(
        (a) => a.title == 'First Day Completed',
      );
      expect(firstDayAchievement.unlocked, isTrue);
    });

    test('Multi-day journey with streaks', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await sessionRepository.setActiveSession(session.id!);

      // Initialize stats
      var stats = UserStats(
        sessionId: session.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await statsRepository.updateStats(stats);

      // Initialize achievements
      await achievementRepository.initializeAchievements(session.id!);

      // Record 7 consecutive perfect days
      for (int i = 0; i < 7; i++) {
        final date = DateTime(2024, 3, 11 + i);
        final record = DailyRecord(
          sessionId: session.id!,
          date: date,
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
          xpEarned: 0,
          isPerfectDay: false,
        );

        final xpEarned = xpCalculatorService.calculateTotalDailyXp(record);
        final savedRecord = await dailyRecordRepository.createOrUpdateRecord(
          record.copyWith(xpEarned: xpEarned, isPerfectDay: true),
        );

        await statsRepository.addXp(session.id!, xpEarned);

        // Get previous day's record for streak calculation
        final previousDay = date.subtract(const Duration(days: 1));
        final previousRecord = await dailyRecordRepository.getRecordByDate(
          session.id!,
          previousDay,
        );

        await streakTrackerService.updateStreaksForNewRecord(
          session.id!,
          savedRecord,
          previousRecord,
        );
      }

      // Check achievements
      final allRecords = await dailyRecordRepository.getRecordsForSession(session.id!);
      final updatedStats = await statsRepository.getStatsForSession(session.id!);
      await achievementTrackerService.checkAndUnlockAchievements(
        session.id!,
        updatedStats!,
        allRecords,
      );

      // Verify streaks
      final finalStats = await statsRepository.getStatsForSession(session.id!);
      expect(finalStats!.currentStreak, equals(7));
      expect(finalStats.longestStreak, equals(7));
      expect(finalStats.prayerStreak, equals(7));
      expect(finalStats.tilawahStreak, equals(7));
      expect(finalStats.totalXp, equals(240 * 7)); // 7 days of 240 XP each

      // Verify 7-day streak achievement
      final achievements = await achievementRepository.getAchievementsForSession(session.id!);
      final sevenDayAchievement = achievements.firstWhere(
        (a) => a.title == '7 Day Consistency',
      );
      expect(sevenDayAchievement.unlocked, isTrue);
    });

    test('Backdating and recalculation', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await sessionRepository.setActiveSession(session.id!);

      // Initialize stats
      var stats = UserStats(
        sessionId: session.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await statsRepository.updateStats(stats);

      // Record day 1 (perfect)
      final day1 = DailyRecord(
        sessionId: session.id!,
        date: DateTime(2024, 3, 11),
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
      );
      await dailyRecordRepository.createOrUpdateRecord(day1);

      // Record day 3 (perfect) - skipping day 2
      final day3 = DailyRecord(
        sessionId: session.id!,
        date: DateTime(2024, 3, 13),
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
      );
      await dailyRecordRepository.createOrUpdateRecord(day3);

      // Calculate streaks without day 2
      await streakTrackerService.recalculateAllStreaks(
        session.id!,
        await dailyRecordRepository.getRecordsForSession(session.id!),
      );

      var currentStats = await statsRepository.getStatsForSession(session.id!);
      expect(currentStats!.currentStreak, equals(1)); // Streak broken

      // Now backdate day 2 (perfect)
      final day2 = DailyRecord(
        sessionId: session.id!,
        date: DateTime(2024, 3, 12),
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
      );
      await dailyRecordRepository.createOrUpdateRecord(day2);

      // Recalculate streaks with day 2 filled in
      await streakTrackerService.recalculateAllStreaks(
        session.id!,
        await dailyRecordRepository.getRecordsForSession(session.id!),
      );

      // Verify streak is now continuous
      currentStats = await statsRepository.getStatsForSession(session.id!);
      expect(currentStats!.currentStreak, equals(3)); // Streak restored
      expect(currentStats.prayerStreak, equals(3));
      expect(currentStats.tilawahStreak, equals(3));
    });

    test('Session switching', () async {
      // Create first session (2023)
      final session2023 = await sessionRepository.createSession(
        year: 2023,
        startDate: DateTime(2023, 3, 23),
        totalDays: 30,
      );
      await sessionRepository.setActiveSession(session2023.id!);

      // Initialize stats for 2023
      var stats2023 = UserStats(
        sessionId: session2023.id!,
        totalXp: 500,
        level: 3,
        currentStreak: 10,
        longestStreak: 10,
        prayerStreak: 10,
        tilawahStreak: 10,
      );
      await statsRepository.updateStats(stats2023);

      // Create some records for 2023
      for (int i = 0; i < 5; i++) {
        final record = DailyRecord(
          sessionId: session2023.id!,
          date: DateTime(2023, 3, 23 + i),
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
        );
        await dailyRecordRepository.createOrUpdateRecord(record);
      }

      // Create second session (2024)
      final session2024 = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Switch to 2024 session
      await sessionRepository.deactivateAllSessions();
      await sessionRepository.setActiveSession(session2024.id!);

      // Initialize stats for 2024
      var stats2024 = UserStats(
        sessionId: session2024.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await statsRepository.updateStats(stats2024);

      // Create some records for 2024
      for (int i = 0; i < 3; i++) {
        final record = DailyRecord(
          sessionId: session2024.id!,
          date: DateTime(2024, 3, 11 + i),
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
        );
        await dailyRecordRepository.createOrUpdateRecord(record);
      }

      // Verify active session is 2024
      final activeSession = await sessionRepository.getActiveSession();
      expect(activeSession!.year, equals(2024));

      // Verify 2024 stats
      final current2024Stats = await statsRepository.getStatsForSession(session2024.id!);
      expect(current2024Stats, isNotNull);

      // Verify 2024 records
      final records2024 = await dailyRecordRepository.getRecordsForSession(session2024.id!);
      expect(records2024.length, equals(3));

      // Verify 2023 data is still intact
      final records2023 = await dailyRecordRepository.getRecordsForSession(session2023.id!);
      expect(records2023.length, equals(5));

      final current2023Stats = await statsRepository.getStatsForSession(session2023.id!);
      expect(current2023Stats!.totalXp, equals(500));
      expect(current2023Stats.level, equals(3));

      // Verify data isolation - 2024 records don't appear in 2023
      expect(records2024.every((r) => r.sessionId == session2024.id), isTrue);
      expect(records2023.every((r) => r.sessionId == session2023.id), isTrue);
    });

    test('Level progression through XP accumulation', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await sessionRepository.setActiveSession(session.id!);

      // Initialize stats
      var stats = UserStats(
        sessionId: session.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await statsRepository.updateStats(stats);

      // Record multiple days to accumulate XP
      int totalXp = 0;
      for (int i = 0; i < 10; i++) {
        final record = DailyRecord(
          sessionId: session.id!,
          date: DateTime(2024, 3, 11 + i),
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
          xpEarned: 0,
          isPerfectDay: false,
        );

        final xpEarned = xpCalculatorService.calculateTotalDailyXp(record);
        totalXp += xpEarned;

        await dailyRecordRepository.createOrUpdateRecord(
          record.copyWith(xpEarned: xpEarned, isPerfectDay: true),
        );

        await statsRepository.addXp(session.id!, xpEarned);
      }

      // Verify level progression
      final finalStats = await statsRepository.getStatsForSession(session.id!);
      expect(finalStats!.totalXp, equals(totalXp));

      // Calculate expected level
      final expectedLevel = levelCalculatorService.calculateLevel(totalXp);
      expect(finalStats.level, equals(expectedLevel));

      // With 10 days of 180 XP each = 1800 XP
      // Level 1 requires 100 XP (1*1*100)
      // Level 2 requires 400 XP (2*2*100)
      // Level 3 requires 900 XP (3*3*100)
      // Level 4 requires 1600 XP (4*4*100)
      // Level 5 requires 2500 XP (5*5*100)
      // So 1800 XP should be level 4
      expect(finalStats.level, greaterThanOrEqualTo(4));
    });

    test('Achievement unlocking through progress', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await sessionRepository.setActiveSession(session.id!);

      // Initialize stats
      var stats = UserStats(
        sessionId: session.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await statsRepository.updateStats(stats);

      // Initialize achievements
      await achievementRepository.initializeAchievements(session.id!);

      // Record days to unlock various achievements
      int totalTilawahPages = 0;

      for (int i = 0; i < 30; i++) {
        final record = DailyRecord(
          sessionId: session.id!,
          date: DateTime(2024, 3, 11 + i),
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
          xpEarned: 180,
          isPerfectDay: true,
        );

        totalTilawahPages += 5;

        await dailyRecordRepository.createOrUpdateRecord(record);
        await statsRepository.addXp(session.id!, 240);

        // Update streaks
        final previousDay = record.date.subtract(const Duration(days: 1));
        final previousRecord = await dailyRecordRepository.getRecordByDate(
          session.id!,
          previousDay,
        );

        await streakTrackerService.updateStreaksForNewRecord(
          session.id!,
          record,
          previousRecord,
        );
      }

      // Check achievements
      final allRecords = await dailyRecordRepository.getRecordsForSession(session.id!);
      final updatedStats = await statsRepository.getStatsForSession(session.id!);
      await achievementTrackerService.checkAndUnlockAchievements(
        session.id!,
        updatedStats!,
        allRecords,
      );

      // Verify achievements
      final achievements = await achievementRepository.getAchievementsForSession(session.id!);

      // First Day achievement
      final firstDay = achievements.firstWhere((a) => a.title == 'First Day Completed');
      expect(firstDay.unlocked, isTrue);

      // 7 Day Consistency achievement
      final sevenDay = achievements.firstWhere((a) => a.title == '7 Day Consistency');
      expect(sevenDay.unlocked, isTrue);

      // 100 Quran Pages achievement (30 days * 5 pages = 150 pages)
      final quran100 = achievements.firstWhere((a) => a.title == '100 Quran Pages');
      expect(quran100.unlocked, isTrue);

      // Ramadhan Master achievement (all 30 days perfect)
      final master = achievements.firstWhere((a) => a.title == 'Ramadhan Master');
      expect(master.unlocked, isTrue);
    });
  });
}
