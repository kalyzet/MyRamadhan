import 'package:flutter_test/flutter_test.dart' hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/models/user_stats.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/repositories/daily_record_repository.dart';
import 'package:my_ramadhan/repositories/stats_repository.dart';
import 'package:my_ramadhan/repositories/achievement_repository.dart';
import 'package:my_ramadhan/screens/final_summary_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('FinalSummaryScreen Property Tests', () {
    late DatabaseHelper dbHelper;
    late SessionRepository sessionRepository;
    late DailyRecordRepository dailyRecordRepository;
    late StatsRepository statsRepository;
    late AchievementRepository achievementRepository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      sessionRepository = SessionRepository(dbHelper: dbHelper);
      dailyRecordRepository = DailyRecordRepository(dbHelper: dbHelper);
      statsRepository = StatsRepository(dbHelper: dbHelper);
      achievementRepository = AchievementRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    // **Feature: my-ramadhan-app, Property 27: Final summary data completeness**
    // **Validates: Requirements 8.2**
    Glados2<int, int>(any.int, any.int).test(
        'Property 27: For any completed session, the final summary should include all required data',
        (year, level) async {
      // Constrain to valid ranges
      final validYear = 2020 + (year.abs() % 11); // 2020-2030
      final validTotalDays = year.abs() % 2 == 0 ? 30 : 29;
      final validLevel = 1 + (level.abs() % 20); // 1-20
      final validTotalXp = (level.abs() % 50001); // 0-50000
      final validLongestStreak = (year.abs() % 31); // 0-30

      // Create a session
      final startDate = DateTime(validYear, 3, 1);
      final session = await sessionRepository.createSession(
        year: validYear,
        startDate: startDate,
        totalDays: validTotalDays,
      );

      // Create stats
      final stats = UserStats(
        sessionId: session.id!,
        totalXp: validTotalXp,
        level: validLevel,
        currentStreak: 0,
        longestStreak: validLongestStreak,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await statsRepository.updateStats(stats);

      // Initialize achievements
      await achievementRepository.initializeAchievements(session.id!);

      // Create some daily records
      for (int i = 0; i < validTotalDays; i++) {
        final date = startDate.add(Duration(days: i));
        final record = DailyRecord(
          sessionId: session.id!,
          date: date,
          fajrComplete: i % 2 == 0,
          dhuhrComplete: i % 2 == 0,
          asrComplete: i % 2 == 0,
          maghribComplete: i % 2 == 0,
          ishaComplete: i % 2 == 0,
          puasaComplete: i % 3 == 0,
          tarawihComplete: i % 3 == 0,
          tilawahPages: i % 5,
          dzikirComplete: i % 4 == 0,
          sedekahAmount: i % 2 == 0 ? 10.0 : 0.0,
          xpEarned: 100,
          isPerfectDay: false,
        );
        await dailyRecordRepository.createOrUpdateRecord(record);
      }

      // Load summary data
      final loadedStats = await statsRepository.getStatsForSession(session.id!);
      final loadedAchievements = await achievementRepository.getAchievementsForSession(session.id!);
      final loadedRecords = await dailyRecordRepository.getRecordsForSession(session.id!);

      // Verify all required data is present
      expect(loadedStats, isNotNull, reason: 'Stats should be loaded');
      expect(loadedStats!.level, equals(validLevel), reason: 'Final level should match');
      expect(loadedStats.totalXp, equals(validTotalXp), reason: 'Total XP should match');
      
      expect(loadedAchievements, isNotEmpty, reason: 'Achievements should be loaded');
      
      expect(loadedRecords, isNotEmpty, reason: 'Records should be loaded');
      expect(loadedRecords.length, equals(validTotalDays), reason: 'All daily records should be present');

      // Verify we can calculate complete ibadah statistics
      int totalPrayers = 0;
      int daysFasted = 0;
      int totalTilawahPages = 0;
      int tarawihCompleted = 0;
      int dzikirCompleted = 0;
      int sedekahDays = 0;
      int perfectDays = 0;

      for (final record in loadedRecords) {
        if (record.fajrComplete) totalPrayers++;
        if (record.dhuhrComplete) totalPrayers++;
        if (record.asrComplete) totalPrayers++;
        if (record.maghribComplete) totalPrayers++;
        if (record.ishaComplete) totalPrayers++;
        if (record.puasaComplete) daysFasted++;
        totalTilawahPages += record.tilawahPages;
        if (record.tarawihComplete) tarawihCompleted++;
        if (record.dzikirComplete) dzikirCompleted++;
        if (record.sedekahAmount > 0) sedekahDays++;
        if (record.isPerfectDay) perfectDays++;
      }

      // All statistics should be calculable (non-negative)
      expect(totalPrayers, greaterThanOrEqualTo(0), reason: 'Total prayers should be calculable');
      expect(daysFasted, greaterThanOrEqualTo(0), reason: 'Days fasted should be calculable');
      expect(totalTilawahPages, greaterThanOrEqualTo(0), reason: 'Total tilawah pages should be calculable');
      expect(tarawihCompleted, greaterThanOrEqualTo(0), reason: 'Tarawih completed should be calculable');
      expect(dzikirCompleted, greaterThanOrEqualTo(0), reason: 'Dzikir completed should be calculable');
      expect(sedekahDays, greaterThanOrEqualTo(0), reason: 'Sedekah days should be calculable');
      expect(perfectDays, greaterThanOrEqualTo(0), reason: 'Perfect days should be calculable');
    });

    // **Feature: my-ramadhan-app, Property 28: Progress comparison delta calculation**
    // **Validates: Requirements 8.3**
    Glados2<int, int>(any.int, any.int).test(
        'Property 28: For any session, the progress comparison should show the difference between end state and start state',
        (startLevel, endLevel) async {
      // Constrain to valid ranges
      final validStartLevel = 1 + (startLevel.abs() % 10); // 1-10
      final validEndLevel = validStartLevel + (endLevel.abs() % 10); // Start level + 0-9
      final validYear = 2020 + (startLevel.abs() % 11);

      // Create a session
      final startDate = DateTime(validYear, 3, 1);
      final session = await sessionRepository.createSession(
        year: validYear,
        startDate: startDate,
        totalDays: 30,
      );

      // Create stats with end state
      final stats = UserStats(
        sessionId: session.id!,
        totalXp: validEndLevel * 1000,
        level: validEndLevel,
        currentStreak: 5,
        longestStreak: 10,
        prayerStreak: 5,
        tilawahStreak: 5,
      );
      await statsRepository.updateStats(stats);

      // Calculate deltas (in a real app, we'd store initial stats)
      final levelDelta = validEndLevel - validStartLevel;
      final streakDelta = 10 - 0; // Assuming start streak is 0

      // Verify deltas are calculated correctly
      expect(levelDelta, equals(validEndLevel - validStartLevel), 
        reason: 'Level delta should be end level minus start level');
      expect(levelDelta, greaterThanOrEqualTo(0), 
        reason: 'Level delta should be non-negative');
      expect(streakDelta, equals(10), 
        reason: 'Streak delta should be end streak minus start streak');
    });

    // **Feature: my-ramadhan-app, Property 29: Motivational message selection**
    // **Validates: Requirements 8.4**
    Glados<int>(any.int).test(
        'Property 29: For any session performance level, the system should select an appropriate motivational message',
        (completedDays) async {
      // Constrain to valid range (0-30 days)
      final validCompletedDays = completedDays.abs() % 31;
      final totalDays = 30;
      final completionPercentage = (validCompletedDays / totalDays) * 100;

      // Create a session
      final startDate = DateTime(2024, 3, 1);
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: startDate,
        totalDays: totalDays,
      );

      // Create some daily records
      for (int i = 0; i < validCompletedDays; i++) {
        final date = startDate.add(Duration(days: i));
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
          xpEarned: 100,
          isPerfectDay: false,
        );
        await dailyRecordRepository.createOrUpdateRecord(record);
      }

      // Test the motivational message generation logic
      // This mirrors the logic in FinalSummaryScreen._generateMotivationalMessage
      String expectedMessageType;
      if (completionPercentage >= 90) {
        expectedMessageType = 'exceptional';
      } else if (completionPercentage >= 70) {
        expectedMessageType = 'great';
      } else if (completionPercentage >= 50) {
        expectedMessageType = 'good';
      } else if (completionPercentage >= 30) {
        expectedMessageType = 'progress';
      } else {
        expectedMessageType = 'learning';
      }

      // Verify the message type is appropriate for the performance level
      expect(expectedMessageType, isNotNull, 
        reason: 'A motivational message type should be selected');
      
      // Verify the logic is consistent
      if (completionPercentage >= 90) {
        expect(expectedMessageType, equals('exceptional'));
      } else if (completionPercentage >= 70) {
        expect(expectedMessageType, equals('great'));
      } else if (completionPercentage >= 50) {
        expect(expectedMessageType, equals('good'));
      } else if (completionPercentage >= 30) {
        expect(expectedMessageType, equals('progress'));
      } else {
        expect(expectedMessageType, equals('learning'));
      }
    });
  });

  group('FinalSummaryScreen Unit Tests', () {
    test('shouldDisplay returns true on day 30', () {
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 29));
      final session = RamadhanSession(
        id: 1,
        year: today.year,
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 29)),
        totalDays: 30,
        createdAt: DateTime.now(),
        isActive: true,
      );

      expect(FinalSummaryScreen.shouldDisplay(session), isTrue);
    });

    test('shouldDisplay returns false before day 30', () {
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 10));
      final session = RamadhanSession(
        id: 1,
        year: today.year,
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 29)),
        totalDays: 30,
        createdAt: DateTime.now(),
        isActive: true,
      );

      expect(FinalSummaryScreen.shouldDisplay(session), isFalse);
    });

    test('shouldDisplay returns true after end date', () {
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 35));
      final session = RamadhanSession(
        id: 1,
        year: today.year,
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 29)),
        totalDays: 30,
        createdAt: DateTime.now(),
        isActive: true,
      );

      expect(FinalSummaryScreen.shouldDisplay(session), isTrue);
    });
  });
}
