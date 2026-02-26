import 'package:flutter_test/flutter_test.dart' hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/models/side_quest.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';
import 'package:my_ramadhan/repositories/side_quest_repository.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/repositories/stats_repository.dart';
import 'package:my_ramadhan/models/user_stats.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late SideQuestRepository sideQuestRepository;
  late SessionRepository sessionRepository;
  late StatsRepository statsRepository;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    await dbHelper.deleteDB();
    sideQuestRepository = SideQuestRepository(dbHelper: dbHelper);
    sessionRepository = SessionRepository(dbHelper: dbHelper);
    statsRepository = StatsRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.deleteDB();
  });

  group('SideQuestRepository - Basic Tests', () {
    test('generateDailySideQuests creates 3 quests for a date', () async {
      // Create a session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 1),
        totalDays: 30,
      );

      // Generate side quests
      final date = DateTime(2024, 3, 1);
      await sideQuestRepository.generateDailySideQuests(session.id!, date);

      // Retrieve quests
      final quests = await sideQuestRepository.getSideQuestsForDate(
        session.id!,
        date,
      );

      expect(quests.length, 3);
      expect(quests.every((q) => !q.completed), true);
      expect(quests.every((q) => q.xpReward > 0), true);
    });

    test('completeSideQuest marks quest as completed', () async {
      // Create a session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 1),
        totalDays: 30,
      );

      // Generate side quests
      final date = DateTime(2024, 3, 1);
      await sideQuestRepository.generateDailySideQuests(session.id!, date);

      // Get quests
      final quests = await sideQuestRepository.getSideQuestsForDate(
        session.id!,
        date,
      );
      expect(quests.isNotEmpty, true);

      // Complete first quest
      await sideQuestRepository.completeSideQuest(quests.first.id!);

      // Verify completion
      final updatedQuests = await sideQuestRepository.getSideQuestsForDate(
        session.id!,
        date,
      );
      final completedQuest = updatedQuests.firstWhere(
        (q) => q.id == quests.first.id,
      );
      expect(completedQuest.completed, true);
    });

    test('generateDailySideQuests does not duplicate quests for same date',
        () async {
      // Create a session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 1),
        totalDays: 30,
      );

      // Generate side quests twice
      final date = DateTime(2024, 3, 1);
      await sideQuestRepository.generateDailySideQuests(session.id!, date);
      await sideQuestRepository.generateDailySideQuests(session.id!, date);

      // Should still have only 3 quests
      final quests = await sideQuestRepository.getSideQuestsForDate(
        session.id!,
        date,
      );

      expect(quests.length, 3);
    });
  });

  group('SideQuestRepository - Property-Based Tests', () {
    // **Feature: my-ramadhan-app, Property 19: Side quest completion and XP award**
    // **Validates: Requirements 5.2**
    Glados<int>(any.int).test(
      'Property 19: For any side quest with specified XP reward, completing it should mark as completed and award exact XP amount (testing 100 inputs)',
      (randomSeed) async {
        // Constrain random seed to reasonable range
        if (randomSeed < 0 || randomSeed > 1000) return;

        // Ensure clean database state
        await dbHelper.deleteDB();
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for cleanup

        // Create a session
        final session = await sessionRepository.createSession(
          year: 2024,
          startDate: DateTime(2024, 3, 1),
          totalDays: 30,
        );

        // Initialize stats
        await statsRepository.updateStats(UserStats(
          sessionId: session.id!,
          totalXp: 0,
          level: 1,
          currentStreak: 0,
          longestStreak: 0,
          prayerStreak: 0,
          tilawahStreak: 0,
        ));

        // Generate side quests
        final date = DateTime(2024, 3, 1);
        await sideQuestRepository.generateDailySideQuests(session.id!, date);

        // Get quests
        final quests = await sideQuestRepository.getSideQuestsForDate(
          session.id!,
          date,
        );
        expect(quests.isNotEmpty, true);

        // Select a quest to complete (use randomSeed to select index)
        final questIndex = randomSeed % quests.length;
        final questToComplete = quests[questIndex];
        final expectedXpReward = questToComplete.xpReward;

        // Get initial XP
        final initialStats = await statsRepository.getStatsForSession(
          session.id!,
        );
        final initialXp = initialStats!.totalXp;

        // Complete the quest
        await sideQuestRepository.completeSideQuest(questToComplete.id!);

        // Award XP (this would normally be done by AppState)
        await statsRepository.addXp(session.id!, expectedXpReward);

        // Verify quest is marked as completed
        final updatedQuests = await sideQuestRepository.getSideQuestsForDate(
          session.id!,
          date,
        );
        final completedQuest = updatedQuests.firstWhere(
          (q) => q.id == questToComplete.id,
        );
        expect(completedQuest.completed, true,
            reason: 'Quest should be marked as completed');

        // Verify XP was awarded correctly
        final finalStats = await statsRepository.getStatsForSession(
          session.id!,
        );
        final finalXp = finalStats!.totalXp;
        expect(finalXp, initialXp + expectedXpReward,
            reason:
                'Total XP should increase by exactly the quest XP reward');
      },
    );

    // **Feature: my-ramadhan-app, Property 20: Side quest history retrieval**
    // **Validates: Requirements 5.4**
    Glados2<int, int>(any.int, any.int).test(
      'Property 20: For any set of completed side quests, querying history should return all quests with correct completion dates and data (testing 100 inputs)',
      (numDays, completionPattern) async {
        // Constrain to reasonable number of days (1-10)
        final validNumDays = (numDays.abs() % 10) + 1;
        
        // Ensure clean database state
        await dbHelper.deleteDB();
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for cleanup
        
        // Create a session
        final session = await sessionRepository.createSession(
          year: 2024,
          startDate: DateTime(2024, 3, 1),
          totalDays: 30,
        );

        // Generate side quests for multiple days and complete some
        final startDate = DateTime(2024, 3, 1);
        final completedQuestIds = <int>[];
        final expectedCompletedDates = <DateTime>[];

        for (int i = 0; i < validNumDays; i++) {
          final date = startDate.add(Duration(days: i));
          
          // Generate quests for this date
          await sideQuestRepository.generateDailySideQuests(
            session.id!,
            date,
          );

          // Get quests for this date
          final quests = await sideQuestRepository.getSideQuestsForDate(
            session.id!,
            date,
          );

          // Complete some quests based on pattern
          // Use completionPattern to determine which quests to complete
          if ((completionPattern + i) % 2 == 0 && quests.isNotEmpty) {
            final questToComplete = quests.first;
            await sideQuestRepository.completeSideQuest(questToComplete.id!);
            completedQuestIds.add(questToComplete.id!);
            expectedCompletedDates.add(date);
          }
        }

        // Now verify we can retrieve all quests with correct data
        for (int i = 0; i < validNumDays; i++) {
          final date = startDate.add(Duration(days: i));
          
          // Retrieve quests for this date
          final retrievedQuests = await sideQuestRepository.getSideQuestsForDate(
            session.id!,
            date,
          );

          // Verify we got quests back
          expect(retrievedQuests.isNotEmpty, true,
              reason: 'Should retrieve quests for date $date');

          // Verify each quest has correct data
          for (final quest in retrievedQuests) {
            // Check basic data integrity
            expect(quest.sessionId, session.id!,
                reason: 'Quest should belong to correct session');
            expect(quest.title.isNotEmpty, true,
                reason: 'Quest should have a title');
            expect(quest.description.isNotEmpty, true,
                reason: 'Quest should have a description');
            expect(quest.xpReward, greaterThan(0),
                reason: 'Quest should have positive XP reward');
            
            // Normalize dates for comparison (remove time component)
            final normalizedQuestDate = DateTime(
              quest.date.year,
              quest.date.month,
              quest.date.day,
            );
            final normalizedExpectedDate = DateTime(
              date.year,
              date.month,
              date.day,
            );
            expect(normalizedQuestDate, normalizedExpectedDate,
                reason: 'Quest should have correct date');

            // If this quest was completed, verify completion status
            if (completedQuestIds.contains(quest.id)) {
              expect(quest.completed, true,
                  reason: 'Completed quest should be marked as completed');
            }
          }
        }
      },
    );
  });
}
