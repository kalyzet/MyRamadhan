import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/providers/app_state.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/repositories/daily_record_repository.dart';
import 'package:my_ramadhan/repositories/stats_repository.dart';
import 'package:my_ramadhan/repositories/achievement_repository.dart';
import 'package:my_ramadhan/repositories/side_quest_repository.dart';
import 'package:my_ramadhan/services/xp_calculator_service.dart';
import 'package:my_ramadhan/services/level_calculator_service.dart';
import 'package:my_ramadhan/services/streak_tracker_service.dart';
import 'package:my_ramadhan/services/achievement_tracker_service.dart';
import 'package:my_ramadhan/models/daily_record.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppState Property Tests', () {
    late DatabaseHelper dbHelper;
    late AppState appState;
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
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();

      // Initialize repositories
      sessionRepository = SessionRepository(dbHelper: dbHelper);
      dailyRecordRepository = DailyRecordRepository(dbHelper: dbHelper);
      statsRepository = StatsRepository(dbHelper: dbHelper);
      achievementRepository = AchievementRepository(dbHelper: dbHelper);
      sideQuestRepository = SideQuestRepository(dbHelper: dbHelper);

      // Initialize services
      xpCalculatorService = XpCalculatorService();
      levelCalculatorService = LevelCalculatorService();
      streakTrackerService = StreakTrackerService(
        dailyRecordRepository: dailyRecordRepository,
        statsRepository: statsRepository,
      );
      achievementTrackerService = AchievementTrackerService(
        achievementRepository: achievementRepository,
      );

      // Initialize AppState
      appState = AppState(
        sessionRepository: sessionRepository,
        dailyRecordRepository: dailyRecordRepository,
        statsRepository: statsRepository,
        achievementRepository: achievementRepository,
        sideQuestRepository: sideQuestRepository,
        xpCalculatorService: xpCalculatorService,
        levelCalculatorService: levelCalculatorService,
        streakTrackerService: streakTrackerService,
        achievementTrackerService: achievementTrackerService,
      );
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    // **Feature: my-ramadhan-app, Property 30: Write-then-read consistency**
    // **Validates: Requirements 9.3**
    Glados3<int, int, bool>(
      any.int,
      any.int,
      any.bool,
    ).test(
        'Property 30: For any data write operation (create or update), immediately reading the same data should return the updated values',
        (year, tilawahPages, fajrComplete) async {
      // Generate additional boolean values deterministically
      final puasaComplete = (year + tilawahPages) % 2 == 0;
      final dzikirComplete = (year * tilawahPages) % 2 == 1;
      // Constrain inputs to valid ranges
      if (year < 2020 || year > 2050) return;
      if (tilawahPages < 0 || tilawahPages > 604) return;

      // Create a session first
      final startDate = DateTime(year, 3, 1);
      final session = await appState.createNewSession(
        year: year,
        startDate: startDate,
        totalDays: 30,
      );

      // Verify session was created and is active
      expect(appState.activeSession, isNotNull,
          reason: 'Active session should be set after creation');
      expect(appState.activeSession!.id, equals(session.id),
          reason: 'Active session ID should match created session');
      expect(appState.activeSession!.year, equals(year),
          reason: 'Active session year should match input');

      // Verify stats were initialized
      expect(appState.currentStats, isNotNull,
          reason: 'Stats should be initialized for new session');
      expect(appState.currentStats!.sessionId, equals(session.id!),
          reason: 'Stats should be linked to the session');
      expect(appState.currentStats!.totalXp, equals(0),
          reason: 'Initial XP should be 0');
      expect(appState.currentStats!.level, equals(1),
          reason: 'Initial level should be 1');

      // Create a daily record
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      final record = DailyRecord(
        sessionId: session.id!,
        date: normalizedToday,
        fajrComplete: fajrComplete,
        dhuhrComplete: false,
        asrComplete: false,
        maghribComplete: false,
        ishaComplete: false,
        puasaComplete: puasaComplete,
        tarawihComplete: false,
        tilawahPages: tilawahPages,
        dzikirComplete: dzikirComplete,
        sedekahAmount: 0.0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      // Update the daily record
      await appState.updateDailyRecord(record);

      // Verify the record was saved and can be read back
      expect(appState.todayRecord, isNotNull,
          reason: 'Today\'s record should be set after update');
      expect(appState.todayRecord!.sessionId, equals(session.id!),
          reason: 'Record should be linked to the session');
      expect(appState.todayRecord!.fajrComplete, equals(fajrComplete),
          reason: 'Fajr completion status should match input');
      expect(appState.todayRecord!.puasaComplete, equals(puasaComplete),
          reason: 'Puasa completion status should match input');
      expect(appState.todayRecord!.tilawahPages, equals(tilawahPages),
          reason: 'Tilawah pages should match input');
      expect(appState.todayRecord!.dzikirComplete, equals(dzikirComplete),
          reason: 'Dzikir completion status should match input');

      // Verify XP was calculated and added to stats
      final expectedXp = xpCalculatorService.calculateTotalDailyXp(record);
      expect(appState.currentStats!.totalXp, equals(expectedXp),
          reason: 'Stats XP should match calculated XP from record');

      // Reload the session to verify persistence
      await appState.loadActiveSession();

      // Verify data persists after reload
      expect(appState.activeSession, isNotNull,
          reason: 'Active session should persist after reload');
      expect(appState.activeSession!.id, equals(session.id),
          reason: 'Session ID should persist');
      expect(appState.currentStats, isNotNull,
          reason: 'Stats should persist after reload');
      expect(appState.currentStats!.totalXp, equals(expectedXp),
          reason: 'Stats XP should persist after reload');
      expect(appState.todayRecord, isNotNull,
          reason: 'Today\'s record should persist after reload');
      expect(appState.todayRecord!.fajrComplete, equals(fajrComplete),
          reason: 'Record data should persist after reload');
      expect(appState.todayRecord!.tilawahPages, equals(tilawahPages),
          reason: 'Record tilawah pages should persist after reload');
    });

    test('Write-then-read consistency for side quest completion', () async {
      // Create a session
      final session = await appState.createNewSession(
        year: 2024,
        startDate: DateTime(2024, 3, 1),
        totalDays: 30,
      );

      // Verify side quests were generated
      expect(appState.todaySideQuests.isNotEmpty, isTrue,
          reason: 'Side quests should be generated for new session');

      final initialXp = appState.currentStats!.totalXp;
      final quest = appState.todaySideQuests.first;
      final questXpReward = quest.xpReward;

      // Complete the side quest
      await appState.completeSideQuest(quest.id!);

      // Verify XP was awarded
      expect(appState.currentStats!.totalXp, equals(initialXp + questXpReward),
          reason: 'XP should be awarded for completing side quest');

      // Verify quest is marked as completed
      final completedQuest = appState.todaySideQuests
          .firstWhere((q) => q.id == quest.id);
      expect(completedQuest.completed, isTrue,
          reason: 'Quest should be marked as completed');

      // Reload and verify persistence
      await appState.loadActiveSession();

      expect(appState.currentStats!.totalXp, equals(initialXp + questXpReward),
          reason: 'XP should persist after reload');
      
      final reloadedQuest = appState.todaySideQuests
          .firstWhere((q) => q.id == quest.id);
      expect(reloadedQuest.completed, isTrue,
          reason: 'Quest completion should persist after reload');
    });
  });
}
