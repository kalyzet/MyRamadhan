import 'package:flutter_test/flutter_test.dart' hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/repositories/stats_repository.dart';
import 'package:my_ramadhan/repositories/daily_record_repository.dart';
import 'package:my_ramadhan/repositories/settings_repository.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';
import 'package:my_ramadhan/models/user_stats.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/services/localization_service.dart';
import 'package:my_ramadhan/providers/app_state.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Profile Screen Property Tests', () {
    late DatabaseHelper dbHelper;
    late SessionRepository sessionRepository;
    late StatsRepository statsRepository;
    late DailyRecordRepository dailyRecordRepository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      sessionRepository = SessionRepository(dbHelper: dbHelper);
      statsRepository = StatsRepository(dbHelper: dbHelper);
      dailyRecordRepository = DailyRecordRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    // **Feature: my-ramadhan-app, Property 34: Historical session retrieval completeness**
    // **Validates: Requirements 12.1**
    Glados<List<int>>(any.list(any.int)).test(
        'Property 34: For any set of created sessions, viewing Ramadhan history should return all sessions with their key statistics (year, total XP, level, completion rate)',
        (years) async {
      // Filter to valid years and constrain list size
      final validYears = years.where((y) => y >= 2020 && y <= 2050).toSet().toList();
      if (validYears.isEmpty || validYears.length > 5) return;

      // Create sessions with stats and records
      final createdSessions = <RamadhanSession>[];
      final expectedStats = <int, UserStats>{};
      final expectedCompletionRates = <int, double>{};

      for (final year in validYears) {
        final startDate = DateTime(year, 3, 1);
        final session = await sessionRepository.createSession(
          year: year,
          startDate: startDate,
          totalDays: 30,
        );
        createdSessions.add(session);

        // Create stats for the session
        final stats = UserStats(
          sessionId: session.id!,
          totalXp: year % 1000, // Use year as seed for XP
          level: (year % 10) + 1, // Level between 1-10
          currentStreak: 0,
          longestStreak: year % 15, // Longest streak based on year
          prayerStreak: 0,
          tilawahStreak: 0,
        );
        await statsRepository.updateStats(stats);
        expectedStats[session.id!] = stats;

        // Create some daily records to calculate completion rate
        final completedDays = year % 20; // 0-19 completed days
        for (int i = 0; i < completedDays; i++) {
          final recordDate = startDate.add(Duration(days: i));
          final record = DailyRecord(
            sessionId: session.id!,
            date: recordDate,
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

        // Calculate expected completion rate
        final completionRate = (completedDays / session.totalDays) * 100;
        expectedCompletionRates[session.id!] = completionRate;
      }

      // Retrieve all sessions (simulating history view)
      final retrievedSessions = await sessionRepository.getAllSessions();

      // Verify all sessions are retrieved
      expect(retrievedSessions.length, equals(createdSessions.length),
          reason: 'All created sessions should be retrieved');

      // Verify each session has correct data
      for (final created in createdSessions) {
        final retrieved = retrievedSessions.firstWhere(
          (s) => s.id == created.id,
          orElse: () => throw Exception('Session ${created.id} not found'),
        );

        // Verify year
        expect(retrieved.year, equals(created.year),
            reason: 'Session year should match');

        // Verify stats are retrievable
        final stats = await statsRepository.getStatsForSession(created.id!);
        final expectedStat = expectedStats[created.id!]!;
        
        expect(stats, isNotNull,
            reason: 'Stats should exist for session ${created.year}');
        expect(stats!.totalXp, equals(expectedStat.totalXp),
            reason: 'Total XP should match for session ${created.year}');
        expect(stats.level, equals(expectedStat.level),
            reason: 'Level should match for session ${created.year}');
        expect(stats.longestStreak, equals(expectedStat.longestStreak),
            reason: 'Longest streak should match for session ${created.year}');

        // Verify completion rate is calculable
        final records = await dailyRecordRepository.getRecordsForSession(created.id!);
        final completedDays = records.where((r) => r.xpEarned > 0).length;
        final actualCompletionRate = (completedDays / created.totalDays) * 100;
        final expectedRate = expectedCompletionRates[created.id!]!;

        expect(actualCompletionRate, equals(expectedRate),
            reason: 'Completion rate should be calculable for session ${created.year}');
      }
    });

    // **Feature: language-switcher, Property 2: Language change updates all UI text**
    // **Validates: Requirements 1.2, 1.3, 2.1, 2.2, 2.3**
    test(
        'Property 2: For any valid language code, when the language is changed, AppState notifies listeners to trigger UI rebuild',
        () async {
      const iterations = 100;
      final languageCodes = ['en', 'id'];

      for (int i = 0; i < iterations; i++) {
        // Alternate between language codes
        final languageCode = languageCodes[i % languageCodes.length];

        // Create fresh instances for each iteration
        final settingsRepo = SettingsRepository(dbHelper: dbHelper);
        final localizationService = LocalizationService(
          settingsRepository: settingsRepo,
        );
        
        // Initialize with default language
        await localizationService.initialize();

        final appState = AppState(
          sessionRepository: sessionRepository,
          dailyRecordRepository: dailyRecordRepository,
          statsRepository: statsRepository,
          localizationService: localizationService,
        );

        // Wait for initialization to complete
        await Future.delayed(Duration(milliseconds: 10));

        // Track if notifyListeners was called AFTER initialization
        var listenerCallCount = 0;
        appState.addListener(() {
          listenerCallCount++;
        });

        // Get initial language
        final initialLanguage = appState.currentLanguage;

        // Change language
        await appState.changeLanguage(languageCode);

        // Verify language was updated in AppState
        expect(appState.currentLanguage, equals(languageCode),
            reason: 'Iteration $i: AppState currentLanguage should be updated to $languageCode');

        // Verify notifyListeners was called (triggers UI rebuild)
        expect(listenerCallCount, greaterThan(0),
            reason: 'Iteration $i: notifyListeners should be called at least once to trigger UI rebuild');

        // Verify translations are available
        final testKey = 'app_name';
        final translation = appState.localizationService.translate(testKey);
        expect(translation, isNotEmpty,
            reason: 'Iteration $i: Translations should be available');

        // Test that changing to the same language still works
        listenerCallCount = 0;
        await appState.changeLanguage(languageCode);
        expect(listenerCallCount, greaterThan(0),
            reason: 'Iteration $i: notifyListeners should be called even when changing to same language');
      }
    });

    test('ProfileScreen language switcher displays current language correctly',
        () async {
      // Create AppState with localization service
      final settingsRepo = SettingsRepository(dbHelper: dbHelper);
      final localizationService = LocalizationService(
        settingsRepository: settingsRepo,
      );
      await localizationService.initialize();

      final appState = AppState(
        sessionRepository: sessionRepository,
        dailyRecordRepository: dailyRecordRepository,
        statsRepository: statsRepository,
        localizationService: localizationService,
      );

      // Wait for initialization
      await Future.delayed(Duration(milliseconds: 10));

      // Verify initial language is 'id' (default)
      expect(appState.currentLanguage, equals('id'),
          reason: 'Default language should be Indonesian');

      // Change to English
      await appState.changeLanguage('en');
      expect(appState.currentLanguage, equals('en'),
          reason: 'Language should be updated to English');

      // Change back to Indonesian
      await appState.changeLanguage('id');
      expect(appState.currentLanguage, equals('id'),
          reason: 'Language should be updated back to Indonesian');
    });

    test('ProfileScreen language switcher handles errors gracefully', () async {
      // Create AppState with localization service
      final settingsRepo = SettingsRepository(dbHelper: dbHelper);
      final localizationService = LocalizationService(
        settingsRepository: settingsRepo,
      );
      await localizationService.initialize();

      final appState = AppState(
        sessionRepository: sessionRepository,
        dailyRecordRepository: dailyRecordRepository,
        statsRepository: statsRepository,
        localizationService: localizationService,
      );

      // Wait for initialization
      await Future.delayed(Duration(milliseconds: 10));

      // Try to change to invalid language code
      try {
        await appState.changeLanguage('invalid');
        fail('Should throw ArgumentError for invalid language code');
      } catch (e) {
        expect(e, isA<ArgumentError>(),
            reason: 'Should throw ArgumentError for invalid language code');
      }

      // Verify language remains unchanged after error
      expect(appState.currentLanguage, equals('id'),
          reason: 'Language should remain unchanged after error');
    });
  });
}
