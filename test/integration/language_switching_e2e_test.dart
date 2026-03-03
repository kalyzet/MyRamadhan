import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/database/database_helper.dart';
import '../../lib/providers/app_state.dart';
import '../../lib/screens/profile_screen.dart';
import '../../lib/screens/home_screen.dart';
import '../../lib/screens/stats_screen.dart';
import '../../lib/screens/achievements_screen.dart';
import '../../lib/repositories/session_repository.dart';
import '../../lib/repositories/daily_record_repository.dart';
import '../../lib/repositories/stats_repository.dart';
import '../../lib/repositories/achievement_repository.dart';
import '../../lib/repositories/side_quest_repository.dart';
import '../../lib/repositories/settings_repository.dart';
import '../../lib/services/xp_calculator_service.dart';
import '../../lib/services/level_calculator_service.dart';
import '../../lib/services/streak_tracker_service.dart';
import '../../lib/services/achievement_tracker_service.dart';
import '../../lib/services/localization_service.dart';
import '../../lib/models/user_stats.dart';
import '../../lib/models/ramadhan_session.dart';

/// End-to-end integration tests for language switching
/// Tests complete flow: user clicks language option → language changes → UI updates → preference saved
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Language Switching End-to-End Tests', () {
    late AppState appState;
    late SettingsRepository settingsRepository;
    late LocalizationService localizationService;
    late SessionRepository sessionRepository;
    late StatsRepository statsRepository;

    setUp(() async {
      // Initialize all dependencies
      sessionRepository = SessionRepository();
      final dailyRecordRepository = DailyRecordRepository();
      statsRepository = StatsRepository();
      final achievementRepository = AchievementRepository();
      final sideQuestRepository = SideQuestRepository();
      settingsRepository = SettingsRepository();
      final xpCalculatorService = XpCalculatorService();
      final levelCalculatorService = LevelCalculatorService();
      final streakTrackerService = StreakTrackerService(
        dailyRecordRepository: dailyRecordRepository,
        statsRepository: statsRepository,
      );
      final achievementTrackerService = AchievementTrackerService();
      localizationService = LocalizationService(
        settingsRepository: settingsRepository,
      );

      // Initialize localization service
      await localizationService.initialize();

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
        localizationService: localizationService,
      );

      // Wait for AppState to initialize localization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      // Clean up database after each test
      await DatabaseHelper.instance.deleteDB();
    });

    test('Language change through AppState updates localization service', () async {
      // Requirements: 1.2, 1.3, 2.3
      
      // Initial language should be Indonesian
      expect(appState.localizationService.currentLanguage, equals('id'));

      // Change language through AppState
      await appState.changeLanguage('en');

      // Verify localization service updated
      expect(appState.localizationService.currentLanguage, equals('en'));

      // Verify translations work in English
      final translation = appState.localizationService.translate('home.title');
      expect(translation, equals('Home'));
    });

    test('Language preference persists across app restarts', () async {
      // Requirements: 1.4, 1.5
      
      // Change language to English
      await appState.changeLanguage('en');

      // Verify it persisted to database
      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Simulate app restart by creating new instances
      final newSettingsRepository = SettingsRepository();
      final newLocalizationService = LocalizationService(
        settingsRepository: newSettingsRepository,
      );
      await newLocalizationService.initialize();

      // Verify language persisted as English
      expect(newLocalizationService.currentLanguage, equals('en'));
    });

    test('Multiple language changes persist correctly', () async {
      // Requirements: 1.4, 1.5
      
      // Start with Indonesian
      expect(appState.localizationService.currentLanguage, equals('id'));

      // Change to English
      await appState.changeLanguage('en');
      expect(appState.localizationService.currentLanguage, equals('en'));
      var settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Change back to Indonesian
      await appState.changeLanguage('id');
      expect(appState.localizationService.currentLanguage, equals('id'));
      settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('id'));

      // Change to English again
      await appState.changeLanguage('en');
      expect(appState.localizationService.currentLanguage, equals('en'));
      settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Simulate restart and verify final state
      final newSettingsRepository = SettingsRepository();
      final newLocalizationService = LocalizationService(
        settingsRepository: newSettingsRepository,
      );
      await newLocalizationService.initialize();
      expect(newLocalizationService.currentLanguage, equals('en'));
    });

    test('Translations update correctly after language change', () async {
      // Requirements: 2.1, 2.2
      
      // Get Indonesian translation
      var homeTitle = appState.localizationService.translate('home.title');
      expect(homeTitle, equals('Beranda'));

      // Change to English
      await appState.changeLanguage('en');

      // Get English translation
      homeTitle = appState.localizationService.translate('home.title');
      expect(homeTitle, equals('Home'));

      // Verify other translations also work
      final statsTitle = appState.localizationService.translate('stats.title');
      expect(statsTitle, equals('Stats'));

      final achievementsTitle = appState.localizationService.translate('achievements.title');
      expect(achievementsTitle, equals('Achievements'));
    });

    testWidgets('ProfileScreen displays language switcher UI', (WidgetTester tester) async {
      // Requirements: 1.1
      
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify language options are displayed
      expect(find.text('🇮🇩'), findsOneWidget);
      expect(find.text('🇬🇧'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Verify check icon appears for current language (Indonesian)
      final checkIcons = find.byIcon(Icons.check_circle);
      expect(checkIcons, findsOneWidget);
    });

    test('AppState notifies listeners when language changes', () async {
      // Requirements: 2.3
      
      // Track if listeners were notified
      bool listenerCalled = false;
      appState.addListener(() {
        listenerCalled = true;
      });

      // Change language
      await appState.changeLanguage('en');

      // Verify listener was called
      expect(listenerCalled, isTrue);
    });

    test('Default language is Indonesian on fresh install', () async {
      // Requirements: 3.1, 3.2, 3.3
      
      // Create fresh instances
      final freshSettingsRepository = SettingsRepository();
      final freshLocalizationService = LocalizationService(
        settingsRepository: freshSettingsRepository,
      );

      // Initialize (simulating fresh install)
      await freshLocalizationService.initialize();

      // Verify default is Indonesian
      expect(freshLocalizationService.currentLanguage, equals('id'));

      // Verify database has Indonesian
      final settings = await freshSettingsRepository.getSettings();
      expect(settings.languageCode, equals('id'));
    });
  });
}
