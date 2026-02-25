import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/repositories/achievement_repository.dart';
import 'package:my_ramadhan/models/achievement.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Achievements Screen Property Tests', () {
    late DatabaseHelper dbHelper;
    late SessionRepository sessionRepository;
    late AchievementRepository achievementRepository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      sessionRepository = SessionRepository(dbHelper: dbHelper);
      achievementRepository = AchievementRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    // **Feature: my-ramadhan-app, Property 22: Achievement display completeness**
    // **Validates: Requirements 6.6**
    Glados<int>(any.int).test(
        'Property 22: For any session, viewing achievements should return all achievements (both locked and unlocked) with their criteria and unlock status',
        (year) async {
      // Constrain to valid years
      if (year < 2020 || year > 2050) return;

      // Create a session
      final startDate = DateTime(year, 3, 1);
      final session = await sessionRepository.createSession(
        year: year,
        startDate: startDate,
        totalDays: 30,
      );

      // Initialize achievements for the session
      await achievementRepository.initializeAchievements(session.id!);

      // Get all achievements
      final achievements =
          await achievementRepository.getAchievementsForSession(session.id!);

      // Verify achievements exist
      expect(achievements.isNotEmpty, isTrue,
          reason: 'Achievements should be initialized for the session');

      // Verify all achievements have required fields
      for (final achievement in achievements) {
        // Verify session ID matches
        expect(achievement.sessionId, equals(session.id),
            reason: 'Achievement should belong to the correct session');

        // Verify title is not empty
        expect(achievement.title.isNotEmpty, isTrue,
            reason: 'Achievement title should not be empty');

        // Verify description (criteria) is not empty
        expect(achievement.description.isNotEmpty, isTrue,
            reason: 'Achievement description/criteria should not be empty');

        // Verify icon name is not empty
        expect(achievement.iconName.isNotEmpty, isTrue,
            reason: 'Achievement icon name should not be empty');

        // Verify unlock status is a boolean
        expect(achievement.unlocked, isA<bool>(),
            reason: 'Achievement unlocked status should be a boolean');

        // If unlocked, verify unlock date exists
        if (achievement.unlocked) {
          expect(achievement.unlockedDate, isNotNull,
              reason: 'Unlocked achievement should have an unlock date');
        }
      }

      // Verify both locked and unlocked achievements can be retrieved
      // Initially all should be locked
      final lockedAchievements =
          achievements.where((a) => !a.unlocked).toList();
      expect(lockedAchievements.length, equals(achievements.length),
          reason: 'Initially all achievements should be locked');

      // Unlock one achievement
      if (achievements.isNotEmpty) {
        await achievementRepository.unlockAchievement(achievements.first.id!);

        // Retrieve achievements again
        final updatedAchievements =
            await achievementRepository.getAchievementsForSession(session.id!);

        // Verify we still get all achievements
        expect(updatedAchievements.length, equals(achievements.length),
            reason:
                'Should still retrieve all achievements after unlocking one');

        // Verify one is now unlocked
        final unlockedAchievements =
            updatedAchievements.where((a) => a.unlocked).toList();
        expect(unlockedAchievements.length, equals(1),
            reason: 'Exactly one achievement should be unlocked');

        // Verify the unlocked achievement has all required fields
        final unlockedAchievement = unlockedAchievements.first;
        expect(unlockedAchievement.title.isNotEmpty, isTrue,
            reason: 'Unlocked achievement should have a title');
        expect(unlockedAchievement.description.isNotEmpty, isTrue,
            reason: 'Unlocked achievement should have criteria/description');
        expect(unlockedAchievement.unlockedDate, isNotNull,
            reason: 'Unlocked achievement should have an unlock date');
        expect(unlockedAchievement.iconName.isNotEmpty, isTrue,
            reason: 'Unlocked achievement should have an icon name');
      }
    });
  });
}
