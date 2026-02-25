import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/models/user_stats.dart';
import 'package:my_ramadhan/repositories/daily_record_repository.dart';
import 'package:my_ramadhan/repositories/stats_repository.dart';
import 'package:my_ramadhan/services/streak_tracker_service.dart';
import 'package:my_ramadhan/database/database_helper.dart';

void main() {
  late StreakTrackerService service;
  late DailyRecordRepository dailyRecordRepo;
  late StatsRepository statsRepo;
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
    
    dailyRecordRepo = DailyRecordRepository(dbHelper: dbHelper);
    statsRepo = StatsRepository(dbHelper: dbHelper);
    service = StreakTrackerService(
      dailyRecordRepository: dailyRecordRepo,
      statsRepository: statsRepo,
    );
  });

  tearDown(() async {
    // Clean up database after each test
    await dbHelper.deleteDB();
  });

  group('StreakTrackerService - Helper Methods', () {
    test('isPerfectDay returns true when all objectives complete', () {
      final record = DailyRecord(
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
        xpEarned: 0,
        isPerfectDay: false,
      );

      expect(service.isPerfectDay(record), true);
    });

    test('isPerfectDay returns false when any objective incomplete', () {
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: true,
        dhuhrComplete: true,
        asrComplete: true,
        maghribComplete: true,
        ishaComplete: false, // Missing Isha
        puasaComplete: true,
        tarawihComplete: true,
        tilawahPages: 5,
        dzikirComplete: true,
        sedekahAmount: 10.0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      expect(service.isPerfectDay(record), false);
    });

    test('hasPrayerComplete returns true when all 5 prayers complete', () {
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: true,
        dhuhrComplete: true,
        asrComplete: true,
        maghribComplete: true,
        ishaComplete: true,
        puasaComplete: false,
        tarawihComplete: false,
        tilawahPages: 0,
        dzikirComplete: false,
        sedekahAmount: 0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      expect(service.hasPrayerComplete(record), true);
    });

    test('hasPrayerComplete returns false when any prayer incomplete', () {
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: true,
        dhuhrComplete: true,
        asrComplete: false, // Missing Asr
        maghribComplete: true,
        ishaComplete: true,
        puasaComplete: false,
        tarawihComplete: false,
        tilawahPages: 0,
        dzikirComplete: false,
        sedekahAmount: 0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      expect(service.hasPrayerComplete(record), false);
    });

    test('hasTilawahComplete returns true when pages > 0', () {
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: false,
        dhuhrComplete: false,
        asrComplete: false,
        maghribComplete: false,
        ishaComplete: false,
        puasaComplete: false,
        tarawihComplete: false,
        tilawahPages: 1,
        dzikirComplete: false,
        sedekahAmount: 0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      expect(service.hasTilawahComplete(record), true);
    });

    test('hasTilawahComplete returns false when pages = 0', () {
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: false,
        dhuhrComplete: false,
        asrComplete: false,
        maghribComplete: false,
        ishaComplete: false,
        puasaComplete: false,
        tarawihComplete: false,
        tilawahPages: 0,
        dzikirComplete: false,
        sedekahAmount: 0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      expect(service.hasTilawahComplete(record), false);
    });
  });

  group('StreakTrackerService - Property-Based Tests', () {
    // **Feature: my-ramadhan-app, Property 14: Perfect streak increment logic**
    // **Validates: Requirements 4.1**
    test(
        'Property 14: Perfect streak equals count of consecutive perfect days',
        () async {
      final numDays = 5;
      final sessionId = 1;

      // Create initial stats
      await statsRepo.updateStats(UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      ));

      // Create consecutive perfect day records
      final records = <DailyRecord>[];
      for (int i = 0; i < numDays; i++) {
        final record = DailyRecord(
          sessionId: sessionId,
          date: DateTime(2024, 3, 15 + i),
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
        records.add(record);
      }

      // Recalculate streaks based on all records
      await service.recalculateAllStreaks(sessionId, records);

      // Get updated stats
      final stats = await statsRepo.getStatsForSession(sessionId);

      // Current streak should equal the number of consecutive perfect days
      expect(stats!.currentStreak, numDays);
    });

    // **Feature: my-ramadhan-app, Property 15: Prayer streak increment logic**
    // **Validates: Requirements 4.2**
    test(
        'Property 15: Prayer streak equals count of consecutive days with complete prayers',
        () async {
      final numDays = 7;
      final sessionId = 2;

      // Create initial stats
      await statsRepo.updateStats(UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      ));

      // Create consecutive records with complete prayers
      final records = <DailyRecord>[];
      for (int i = 0; i < numDays; i++) {
        final record = DailyRecord(
          sessionId: sessionId,
          date: DateTime(2024, 3, 15 + i),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: false, // Not perfect day
          tarawihComplete: false,
          tilawahPages: 0,
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: 0,
          isPerfectDay: false,
        );
        records.add(record);
      }

      // Recalculate streaks
      await service.recalculateAllStreaks(sessionId, records);

      // Get updated stats
      final stats = await statsRepo.getStatsForSession(sessionId);

      // Prayer streak should equal the number of consecutive days with complete prayers
      expect(stats!.prayerStreak, numDays);
    });

    // **Feature: my-ramadhan-app, Property 16: Tilawah streak increment logic**
    // **Validates: Requirements 4.3**
    test(
        'Property 16: Tilawah streak equals count of consecutive days with tilawah',
        () async {
      final numDays = 10;
      final sessionId = 3;

      // Create initial stats
      await statsRepo.updateStats(UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      ));

      // Create consecutive records with tilawah
      final records = <DailyRecord>[];
      for (int i = 0; i < numDays; i++) {
        final record = DailyRecord(
          sessionId: sessionId,
          date: DateTime(2024, 3, 15 + i),
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 5, // Has tilawah
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: 0,
          isPerfectDay: false,
        );
        records.add(record);
      }

      // Recalculate streaks
      await service.recalculateAllStreaks(sessionId, records);

      // Get updated stats
      final stats = await statsRepo.getStatsForSession(sessionId);

      // Tilawah streak should equal the number of consecutive days with tilawah
      expect(stats!.tilawahStreak, numDays);
    });

    // **Feature: my-ramadhan-app, Property 17: Streak reset on miss**
    // **Validates: Requirements 4.4**
    test(
        'Property 17: Streak resets to 0 when activity is missed',
        () async {
      final numDays = 7;
      final missDay = 3;
      final sessionId = 4;

      // Create initial stats
      await statsRepo.updateStats(UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      ));

      // Create records with a miss in the middle
      final records = <DailyRecord>[];
      for (int i = 0; i < numDays; i++) {
        final isPerfect = i != missDay; // Miss on missDay
        final record = DailyRecord(
          sessionId: sessionId,
          date: DateTime(2024, 3, 15 + i),
          fajrComplete: isPerfect,
          dhuhrComplete: isPerfect,
          asrComplete: isPerfect,
          maghribComplete: isPerfect,
          ishaComplete: isPerfect,
          puasaComplete: isPerfect,
          tarawihComplete: isPerfect,
          tilawahPages: isPerfect ? 5 : 0,
          dzikirComplete: isPerfect,
          sedekahAmount: isPerfect ? 10.0 : 0,
          xpEarned: 0,
          isPerfectDay: false,
        );
        records.add(record);
      }

      // Recalculate streaks
      await service.recalculateAllStreaks(sessionId, records);

      // Get updated stats
      final stats = await statsRepo.getStatsForSession(sessionId);

      // Current streak should be the days after the miss
      final expectedStreak = numDays - missDay - 1;
      expect(stats!.currentStreak, expectedStreak);
    });

    // **Feature: my-ramadhan-app, Property 18: Longest streak invariant**
    // **Validates: Requirements 4.5**
    test(
        'Property 18: Longest streak >= current streak always',
        () async {
      final firstStreak = 5;
      final secondStreak = 3;
      final sessionId = 5;

      // Create initial stats
      await statsRepo.updateStats(UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      ));

      // Create first streak
      final records = <DailyRecord>[];
      for (int i = 0; i < firstStreak; i++) {
        records.add(DailyRecord(
          sessionId: sessionId,
          date: DateTime(2024, 3, 15 + i),
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
        ));
      }

      // Add a break day
      records.add(DailyRecord(
        sessionId: sessionId,
        date: DateTime(2024, 3, 15 + firstStreak),
        fajrComplete: false,
        dhuhrComplete: false,
        asrComplete: false,
        maghribComplete: false,
        ishaComplete: false,
        puasaComplete: false,
        tarawihComplete: false,
        tilawahPages: 0,
        dzikirComplete: false,
        sedekahAmount: 0,
        xpEarned: 0,
        isPerfectDay: false,
      ));

      // Create second streak
      for (int i = 0; i < secondStreak; i++) {
        records.add(DailyRecord(
          sessionId: sessionId,
          date: DateTime(2024, 3, 15 + firstStreak + 1 + i),
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
        ));
      }

      // Recalculate streaks
      await service.recalculateAllStreaks(sessionId, records);

      // Get updated stats
      final stats = await statsRepo.getStatsForSession(sessionId);

      // Longest streak should be >= current streak
      expect(stats!.longestStreak >= stats.currentStreak, true);

      // Longest streak should equal the maximum of the two streaks
      final expectedLongest = firstStreak > secondStreak ? firstStreak : secondStreak;
      expect(stats.longestStreak, expectedLongest);
    });

    // **Feature: my-ramadhan-app, Property 9: Streak recalculation correctness**
    // **Validates: Requirements 2.9**
    test(
        'Property 9: Modifying past record recalculates streaks correctly',
        () async {
      final numDays = 7;
      final dayToModify = 3;
      final sessionId = 6;

      // Create initial stats
      await statsRepo.updateStats(UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      ));

      // Create records with a gap (incomplete day)
      final records = <DailyRecord>[];
      for (int i = 0; i < numDays; i++) {
        final isComplete = i != dayToModify; // Gap at dayToModify
        records.add(DailyRecord(
          sessionId: sessionId,
          date: DateTime(2024, 3, 15 + i),
          fajrComplete: isComplete,
          dhuhrComplete: isComplete,
          asrComplete: isComplete,
          maghribComplete: isComplete,
          ishaComplete: isComplete,
          puasaComplete: isComplete,
          tarawihComplete: isComplete,
          tilawahPages: isComplete ? 5 : 0,
          dzikirComplete: isComplete,
          sedekahAmount: isComplete ? 10.0 : 0,
          xpEarned: 0,
          isPerfectDay: false,
        ));
      }

      // Calculate initial streaks
      await service.recalculateAllStreaks(sessionId, records);
      final initialStats = await statsRepo.getStatsForSession(sessionId);

      // Now "modify" the incomplete day to be complete
      records[dayToModify] = records[dayToModify].copyWith(
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
      );

      // Recalculate streaks after modification
      await service.recalculateAllStreaks(sessionId, records);
      final updatedStats = await statsRepo.getStatsForSession(sessionId);

      // After filling the gap, current streak should be all days
      expect(updatedStats!.currentStreak, numDays);

      // Longest streak should also be updated
      expect(updatedStats.longestStreak >= initialStats!.longestStreak, true);
    });
  });
}
