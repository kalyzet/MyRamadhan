import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/database/database_helper.dart';
import '../../lib/repositories/session_repository.dart';
import '../../lib/repositories/daily_record_repository.dart';
import '../../lib/repositories/stats_repository.dart';
import '../../lib/repositories/achievement_repository.dart';
import '../../lib/repositories/side_quest_repository.dart';
import '../../lib/models/ramadhan_session.dart';
import '../../lib/models/daily_record.dart';
import '../../lib/models/user_stats.dart';

/// Test offline functionality
/// Verifies app works without internet connection
/// Requirements: 9.2
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Functionality Tests', () {
    late SessionRepository sessionRepository;
    late DailyRecordRepository dailyRecordRepository;
    late StatsRepository statsRepository;
    late AchievementRepository achievementRepository;
    late SideQuestRepository sideQuestRepository;

    setUp(() async {
      // Initialize repositories
      sessionRepository = SessionRepository();
      dailyRecordRepository = DailyRecordRepository();
      statsRepository = StatsRepository();
      achievementRepository = AchievementRepository();
      sideQuestRepository = SideQuestRepository();
    });

    tearDown() async {
      // Clean up database after each test
      await DatabaseHelper.instance.deleteDB();
    };

    test('Session creation works offline', () async {
      // Create a session without network
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      expect(session.id, isNotNull);
      expect(session.year, equals(2024));
      expect(session.totalDays, equals(30));
    });

    test('Daily record creation works offline', () async {
      // Create session first
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Create daily record
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

      final savedRecord = await dailyRecordRepository.createOrUpdateRecord(record);

      expect(savedRecord.id, isNotNull);
      expect(savedRecord.sessionId, equals(session.id));
      expect(savedRecord.fajrComplete, isTrue);
    });

    test('Stats updates work offline', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Create initial stats
      final stats = UserStats(
        sessionId: session.id!,
        totalXp: 100,
        level: 2,
        currentStreak: 5,
        longestStreak: 5,
        prayerStreak: 5,
        tilawahStreak: 5,
      );

      final savedStats = await statsRepository.updateStats(stats);

      expect(savedStats.id, isNotNull);
      expect(savedStats.totalXp, equals(100));
      expect(savedStats.level, equals(2));
    });

    test('Achievement initialization works offline', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Initialize achievements
      await achievementRepository.initializeAchievements(session.id!);

      // Get achievements
      final achievements = await achievementRepository.getAchievementsForSession(session.id!);

      expect(achievements, isNotEmpty);
      expect(achievements.every((a) => a.sessionId == session.id), isTrue);
    });

    test('Side quest generation works offline', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      final date = DateTime(2024, 3, 11);

      // Generate side quests
      await sideQuestRepository.generateDailySideQuests(session.id!, date);

      // Get side quests
      final quests = await sideQuestRepository.getSideQuestsForDate(session.id!, date);

      expect(quests, isNotEmpty);
      expect(quests.every((q) => q.sessionId == session.id), isTrue);
    });

    test('Data persistence works offline', () async {
      // Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Create multiple daily records
      for (int i = 0; i < 5; i++) {
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

        await dailyRecordRepository.createOrUpdateRecord(record);
      }

      // Retrieve all records
      final records = await dailyRecordRepository.getRecordsForSession(session.id!);

      expect(records.length, equals(5));
      expect(records.every((r) => r.sessionId == session.id), isTrue);
    });

    test('Complete workflow works offline', () async {
      // 1. Create session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Set session as active
      await sessionRepository.setActiveSession(session.id!);

      // 2. Initialize stats
      final stats = UserStats(
        sessionId: session.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await statsRepository.updateStats(stats);

      // 3. Initialize achievements
      await achievementRepository.initializeAchievements(session.id!);

      // 4. Create daily record
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
        xpEarned: 180,
        isPerfectDay: true,
      );
      await dailyRecordRepository.createOrUpdateRecord(record);

      // 5. Update stats with XP
      await statsRepository.addXp(session.id!, 180);

      // 6. Generate side quests
      await sideQuestRepository.generateDailySideQuests(
        session.id!,
        DateTime(2024, 3, 11),
      );

      // Verify everything was persisted
      final retrievedSession = await sessionRepository.getActiveSession();
      final retrievedStats = await statsRepository.getStatsForSession(session.id!);
      final retrievedRecords = await dailyRecordRepository.getRecordsForSession(session.id!);
      final retrievedAchievements = await achievementRepository.getAchievementsForSession(session.id!);
      final retrievedQuests = await sideQuestRepository.getSideQuestsForDate(
        session.id!,
        DateTime(2024, 3, 11),
      );

      expect(retrievedSession, isNotNull);
      expect(retrievedStats, isNotNull);
      expect(retrievedStats!.totalXp, equals(180));
      expect(retrievedRecords.length, equals(1));
      expect(retrievedAchievements, isNotEmpty);
      expect(retrievedQuests, isNotEmpty);
    });

    test('Multiple sessions work offline', () async {
      // Create multiple sessions
      final session1 = await sessionRepository.createSession(
        year: 2023,
        startDate: DateTime(2023, 3, 23),
        totalDays: 30,
      );

      final session2 = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Get all sessions
      final sessions = await sessionRepository.getAllSessions();

      expect(sessions.length, greaterThanOrEqualTo(2));
      expect(sessions.any((s) => s.year == 2023), isTrue);
      expect(sessions.any((s) => s.year == 2024), isTrue);
    });

    test('Session switching works offline', () async {
      // Create two sessions
      final session1 = await sessionRepository.createSession(
        year: 2023,
        startDate: DateTime(2023, 3, 23),
        totalDays: 30,
      );

      final session2 = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );

      // Deactivate all and activate session1
      await sessionRepository.deactivateAllSessions();
      await sessionRepository.setActiveSession(session1.id!);

      var activeSession = await sessionRepository.getActiveSession();
      expect(activeSession?.id, equals(session1.id));

      // Switch to session2
      await sessionRepository.deactivateAllSessions();
      await sessionRepository.setActiveSession(session2.id!);

      activeSession = await sessionRepository.getActiveSession();
      expect(activeSession?.id, equals(session2.id));
    });
  });
}
