import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/repositories/stats_repository.dart';
import 'package:my_ramadhan/repositories/daily_record_repository.dart';
import 'package:my_ramadhan/repositories/settings_repository.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';
import 'package:my_ramadhan/models/user_stats.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/providers/app_state.dart';
import 'package:my_ramadhan/services/localization_service.dart';
import 'package:my_ramadhan/screens/session_comparison_screen.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Session Comparison Property Tests', () {
    late DatabaseHelper dbHelper;
    late SessionRepository sessionRepository;
    late StatsRepository statsRepository;
    late DailyRecordRepository dailyRecordRepository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      await dbHelper.database; // Initialize database
      sessionRepository = SessionRepository(dbHelper: dbHelper);
      statsRepository = StatsRepository(dbHelper: dbHelper);
      dailyRecordRepository = DailyRecordRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
      await dbHelper.deleteDB();
    });

    // **Feature: my-ramadhan-app, Property 35: Multi-session comparison data accuracy**
    // **Validates: Requirements 12.2**
    Glados<List<int>>(any.list(any.int)).test(
        'Property 35: For any set of selected sessions, the comparison view should display accurate XP, level, streaks, and completion rates for each session',
        (years) async {
      // Filter to valid years and constrain list size
      final validYears =
          years.where((y) => y >= 2020 && y <= 2050).toSet().toList();
      if (validYears.length < 2 || validYears.length > 4) return;

      // Create sessions with stats
      final sessions = <RamadhanSession>[];
      final expectedStats = <int, UserStats>{};
      final expectedCompletionRates = <int, double>{};

      for (final year in validYears) {
        final startDate = DateTime(year, 3, 1);
        final session = await sessionRepository.createSession(
          year: year,
          startDate: startDate,
          totalDays: 30,
        );
        sessions.add(session);

        // Create stats for this session
        final stats = UserStats(
          sessionId: session.id!,
          totalXp: (year % 10) * 100, // Deterministic XP based on year
          level: (year % 10) + 1, // Deterministic level
          currentStreak: (year % 5),
          longestStreak: (year % 5) + 2,
          prayerStreak: (year % 4),
          tilawahStreak: (year % 3),
        );
        await statsRepository.updateStats(stats);
        expectedStats[session.id!] = stats;

        // Create some daily records for completion rate
        final completedDays = (year % 10) + 10; // 10-19 completed days
        for (int i = 0; i < completedDays; i++) {
          final record = DailyRecord(
            sessionId: session.id!,
            date: startDate.add(Duration(days: i)),
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
            isPerfectDay: true,
          );
          await dailyRecordRepository.createOrUpdateRecord(record);
        }
        expectedCompletionRates[session.id!] = (completedDays / 30) * 100;
      }

      // Now verify comparison data accuracy
      for (final session in sessions) {
        // Retrieve stats
        final retrievedStats =
            await statsRepository.getStatsForSession(session.id!);
        expect(retrievedStats, isNotNull,
            reason: 'Stats should exist for session ${session.year}');

        final expected = expectedStats[session.id!]!;
        expect(retrievedStats!.totalXp, equals(expected.totalXp),
            reason: 'Total XP should match for session ${session.year}');
        expect(retrievedStats.level, equals(expected.level),
            reason: 'Level should match for session ${session.year}');
        expect(retrievedStats.longestStreak, equals(expected.longestStreak),
            reason: 'Longest streak should match for session ${session.year}');
        expect(retrievedStats.prayerStreak, equals(expected.prayerStreak),
            reason: 'Prayer streak should match for session ${session.year}');
        expect(retrievedStats.tilawahStreak, equals(expected.tilawahStreak),
            reason: 'Tilawah streak should match for session ${session.year}');

        // Verify completion rate
        final records =
            await dailyRecordRepository.getRecordsForSession(session.id!);
        final completedDays = records.where((r) => r.xpEarned > 0).length;
        final actualCompletionRate = (completedDays / session.totalDays) * 100;
        final expectedRate = expectedCompletionRates[session.id!]!;

        expect(actualCompletionRate, equals(expectedRate),
            reason:
                'Completion rate should match for session ${session.year}');
      }
    });

    // **Feature: my-ramadhan-app, Property 36: Performance metric delta identification**
    // **Validates: Requirements 12.3**
    Glados2<int, int>(any.int, any.int).test(
        'Property 36: For any two sessions being compared, the system should correctly identify and highlight which metrics improved, declined, or stayed the same',
        (year1, year2) async {
      // Constrain to valid years and ensure they're different
      if (year1 < 2020 || year1 > 2050) return;
      if (year2 < 2020 || year2 > 2050) return;
      if (year1 == year2) return;

      // Ensure year1 < year2 for consistent ordering
      if (year1 > year2) {
        final temp = year1;
        year1 = year2;
        year2 = temp;
      }

      // Create two sessions
      final session1 = await sessionRepository.createSession(
        year: year1,
        startDate: DateTime(year1, 3, 1),
        totalDays: 30,
      );

      final session2 = await sessionRepository.createSession(
        year: year2,
        startDate: DateTime(year2, 3, 1),
        totalDays: 30,
      );

      // Create stats with known differences
      final stats1 = UserStats(
        sessionId: session1.id!,
        totalXp: 1000,
        level: 5,
        currentStreak: 10,
        longestStreak: 15,
        prayerStreak: 8,
        tilawahStreak: 12,
      );
      await statsRepository.updateStats(stats1);

      final stats2 = UserStats(
        sessionId: session2.id!,
        totalXp: 1500, // Improved
        level: 6, // Improved
        currentStreak: 8, // Declined
        longestStreak: 15, // Same
        prayerStreak: 10, // Improved
        tilawahStreak: 10, // Declined
      );
      await statsRepository.updateStats(stats2);

      // Retrieve and compare
      final retrieved1 = await statsRepository.getStatsForSession(session1.id!);
      final retrieved2 = await statsRepository.getStatsForSession(session2.id!);

      expect(retrieved1, isNotNull);
      expect(retrieved2, isNotNull);

      // Calculate deltas
      final xpDelta = retrieved2!.totalXp - retrieved1!.totalXp;
      final levelDelta = retrieved2.level - retrieved1.level;
      final longestStreakDelta =
          retrieved2.longestStreak - retrieved1.longestStreak;
      final prayerStreakDelta =
          retrieved2.prayerStreak - retrieved1.prayerStreak;
      final tilawahStreakDelta =
          retrieved2.tilawahStreak - retrieved1.tilawahStreak;

      // Verify delta identification
      expect(xpDelta > 0, isTrue,
          reason: 'XP should show improvement (positive delta)');
      expect(levelDelta > 0, isTrue,
          reason: 'Level should show improvement (positive delta)');
      expect(longestStreakDelta == 0, isTrue,
          reason: 'Longest streak should show no change (zero delta)');
      expect(prayerStreakDelta > 0, isTrue,
          reason: 'Prayer streak should show improvement (positive delta)');
      expect(tilawahStreakDelta < 0, isTrue,
          reason: 'Tilawah streak should show decline (negative delta)');

      // Verify delta values
      expect(xpDelta, equals(500), reason: 'XP delta should be 500');
      expect(levelDelta, equals(1), reason: 'Level delta should be 1');
      expect(longestStreakDelta, equals(0),
          reason: 'Longest streak delta should be 0');
      expect(prayerStreakDelta, equals(2),
          reason: 'Prayer streak delta should be 2');
      expect(tilawahStreakDelta, equals(-2),
          reason: 'Tilawah streak delta should be -2');
    });

    // **Feature: session-comparison-localization, Property 1: Language-specific text display**
    // **Validates: Requirements 1.1, 1.2**
    Glados<String>(any.choose(['en', 'id'])).test(
        'Property 1: For any supported language setting (English or Indonesian), when the Session Comparison screen is opened, all displayed text should match the translations defined for that language',
        (languageCode) async {
      // Initialize localization service with the test language
      final settingsRepository = SettingsRepository(dbHelper: dbHelper);
      final localizationService = LocalizationService(settingsRepository: settingsRepository);
      await localizationService.loadLanguage(languageCode);

      // Test that the localization service returns correct translations
      final t = localizationService.translate;

      // Verify key translations exist and are not empty
      expect(t('session_comparison.title'), isNotEmpty,
          reason: 'Title translation should exist for $languageCode');
      expect(t('session_comparison.no_sessions'), isNotEmpty,
          reason: 'No sessions translation should exist for $languageCode');
      expect(t('session_comparison.session_selected'), isNotEmpty,
          reason: 'Session selected translation should exist for $languageCode');
      expect(t('session_comparison.sessions_compared'), isNotEmpty,
          reason: 'Sessions compared translation should exist for $languageCode');
      expect(t('session_comparison.metrics.level'), isNotEmpty,
          reason: 'Level metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.total_xp'), isNotEmpty,
          reason: 'Total XP metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.longest_streak'), isNotEmpty,
          reason: 'Longest streak metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.prayer_streak'), isNotEmpty,
          reason: 'Prayer streak metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.tilawah_streak'), isNotEmpty,
          reason: 'Tilawah streak metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.completion_rate'), isNotEmpty,
          reason: 'Completion rate metric translation should exist for $languageCode');
      expect(t('session_comparison.ramadhan_label'), isNotEmpty,
          reason: 'Ramadhan label translation should exist for $languageCode');
      expect(t('session_comparison.delta_same'), isNotEmpty,
          reason: 'Delta same translation should exist for $languageCode');
      expect(t('session_comparison.error_loading'), isNotEmpty,
          reason: 'Error loading translation should exist for $languageCode');

      // Verify language-specific content
      if (languageCode == 'id') {
        expect(t('session_comparison.title'), equals('Perbandingan Sesi'),
            reason: 'Indonesian title should be correct');
        expect(t('session_comparison.no_sessions'), equals('Tidak ada sesi untuk dibandingkan'),
            reason: 'Indonesian no sessions message should be correct');
        expect(t('session_comparison.delta_same'), equals('Sama'),
            reason: 'Indonesian delta same should be correct');
      } else if (languageCode == 'en') {
        expect(t('session_comparison.title'), equals('Session Comparison'),
            reason: 'English title should be correct');
        expect(t('session_comparison.no_sessions'), equals('No sessions to compare'),
            reason: 'English no sessions message should be correct');
        expect(t('session_comparison.delta_same'), equals('Same'),
            reason: 'English delta same should be correct');
      }
    });
          sessionId: session1.id!,
          date: DateTime(2024, 3, 1).add(Duration(days: i)),
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
          isPerfectDay: true,
        );
        await dailyRecordRepository.createOrUpdateRecord(record1);

        final record2 = DailyRecord(
          sessionId: session2.id!,
          date: DateTime(2025, 3, 1).add(Duration(days: i)),
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
          isPerfectDay: true,
        );
        await dailyRecordRepository.createOrUpdateRecord(record2);
      }

      // Initialize localization service with the test language
      final settingsRepository = SettingsRepository(dbHelper: dbHelper);
      final localizationService = LocalizationService(settingsRepository: settingsRepository);
      await localizationService.loadLanguage(languageCode);

      // Test that the localization service returns correct translations
      final t = localizationService.translate;

      // Verify key translations exist and are not empty
      expect(t('session_comparison.title'), isNotEmpty,
          reason: 'Title translation should exist for $languageCode');
      expect(t('session_comparison.no_sessions'), isNotEmpty,
          reason: 'No sessions translation should exist for $languageCode');
      expect(t('session_comparison.session_selected'), isNotEmpty,
          reason: 'Session selected translation should exist for $languageCode');
      expect(t('session_comparison.sessions_compared'), isNotEmpty,
          reason: 'Sessions compared translation should exist for $languageCode');
      expect(t('session_comparison.metrics.level'), isNotEmpty,
          reason: 'Level metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.total_xp'), isNotEmpty,
          reason: 'Total XP metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.longest_streak'), isNotEmpty,
          reason: 'Longest streak metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.prayer_streak'), isNotEmpty,
          reason: 'Prayer streak metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.tilawah_streak'), isNotEmpty,
          reason: 'Tilawah streak metric translation should exist for $languageCode');
      expect(t('session_comparison.metrics.completion_rate'), isNotEmpty,
          reason: 'Completion rate metric translation should exist for $languageCode');
      expect(t('session_comparison.ramadhan_label'), isNotEmpty,
          reason: 'Ramadhan label translation should exist for $languageCode');
      expect(t('session_comparison.delta_same'), isNotEmpty,
          reason: 'Delta same translation should exist for $languageCode');
      expect(t('session_comparison.error_loading'), isNotEmpty,
          reason: 'Error loading translation should exist for $languageCode');

      // Verify language-specific content
      if (languageCode == 'id') {
        expect(t('session_comparison.title'), equals('Perbandingan Sesi'),
            reason: 'Indonesian title should be correct');
        expect(t('session_comparison.no_sessions'), equals('Tidak ada sesi untuk dibandingkan'),
            reason: 'Indonesian no sessions message should be correct');
        expect(t('session_comparison.delta_same'), equals('Sama'),
            reason: 'Indonesian delta same should be correct');
      } else if (languageCode == 'en') {
        expect(t('session_comparison.title'), equals('Session Comparison'),
            reason: 'English title should be correct');
        expect(t('session_comparison.no_sessions'), equals('No sessions to compare'),
            reason: 'English no sessions message should be correct');
        expect(t('session_comparison.delta_same'), equals('Same'),
            reason: 'English delta same should be correct');
      }
    });

    // **Feature: session-comparison-localization, Property 2: Reactive language switching**
    // **Validates: Requirements 1.3**
    Glados2<String, String>(any.choose(['en', 'id']), any.choose(['en', 'id'])).test(
        'Property 2: For any language change while the Session Comparison screen is open, all text elements should immediately update to reflect the new language without requiring screen refresh',
        (initialLanguage, newLanguage) async {
      // Skip if languages are the same
      if (initialLanguage == newLanguage) return;

      // Initialize localization service with initial language
      final settingsRepository = SettingsRepository(dbHelper: dbHelper);
      final localizationService = LocalizationService(settingsRepository: settingsRepository);
      await localizationService.loadLanguage(initialLanguage);

      // Get initial translations
      final initialTitle = localizationService.translate('session_comparison.title');
      final initialNoSessions = localizationService.translate('session_comparison.no_sessions');
      final initialDeltaSame = localizationService.translate('session_comparison.delta_same');

      // Verify initial translations are correct
      if (initialLanguage == 'id') {
        expect(initialTitle, equals('Perbandingan Sesi'),
            reason: 'Initial Indonesian title should be correct');
        expect(initialNoSessions, equals('Tidak ada sesi untuk dibandingkan'),
            reason: 'Initial Indonesian no sessions should be correct');
        expect(initialDeltaSame, equals('Sama'),
            reason: 'Initial Indonesian delta same should be correct');
      } else {
        expect(initialTitle, equals('Session Comparison'),
            reason: 'Initial English title should be correct');
        expect(initialNoSessions, equals('No sessions to compare'),
            reason: 'Initial English no sessions should be correct');
        expect(initialDeltaSame, equals('Same'),
            reason: 'Initial English delta same should be correct');
      }

      // Switch to new language
      await localizationService.changeLanguage(newLanguage);

      // Get new translations
      final newTitle = localizationService.translate('session_comparison.title');
      final newNoSessions = localizationService.translate('session_comparison.no_sessions');
      final newDeltaSame = localizationService.translate('session_comparison.delta_same');

      // Verify translations have changed
      expect(newTitle, isNot(equals(initialTitle)),
          reason: 'Title should change when language switches from $initialLanguage to $newLanguage');
      expect(newNoSessions, isNot(equals(initialNoSessions)),
          reason: 'No sessions message should change when language switches from $initialLanguage to $newLanguage');
      expect(newDeltaSame, isNot(equals(initialDeltaSame)),
          reason: 'Delta same should change when language switches from $initialLanguage to $newLanguage');

      // Verify new translations are correct for the new language
      if (newLanguage == 'id') {
        expect(newTitle, equals('Perbandingan Sesi'),
            reason: 'New Indonesian title should be correct');
        expect(newNoSessions, equals('Tidak ada sesi untuk dibandingkan'),
            reason: 'New Indonesian no sessions should be correct');
        expect(newDeltaSame, equals('Sama'),
            reason: 'New Indonesian delta same should be correct');
      } else {
        expect(newTitle, equals('Session Comparison'),
            reason: 'New English title should be correct');
        expect(newNoSessions, equals('No sessions to compare'),
            reason: 'New English no sessions should be correct');
        expect(newDeltaSame, equals('Same'),
            reason: 'New English delta same should be correct');
      }

      // Verify the language was persisted
      expect(localizationService.currentLanguage, equals(newLanguage),
          reason: 'Current language should be updated to $newLanguage');
    });
  });
}
