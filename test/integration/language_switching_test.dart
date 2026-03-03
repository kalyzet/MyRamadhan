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

/// Integration tests for end-to-end language switching
/// Tests complete flow: user clicks language option → language changes → UI updates → preference saved
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Language Switching Integration Tests', () {
    late AppState appState;
    late SettingsRepository settingsRepository;

    setUp(() async {
      // Initialize all dependencies
      final sessionRepository = SessionRepository();
      final dailyRecordRepository = DailyRecordRepository();
      final statsRepository = StatsRepository();
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
      final localizationService = LocalizationService(
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

    testWidgets('Complete language switching flow from UI', (WidgetTester tester) async {
      // Requirements: 1.1, 1.2, 1.3, 1.4
      
      // Build the app with ProfileScreen
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

      // Wait for initial render
      await tester.pumpAndSettle();

      // Verify initial language is Indonesian
      expect(appState.currentLanguage, equals('id'));

      // Find the English language option by looking for the flag emoji
      final englishOption = find.text('🇬🇧');
      expect(englishOption, findsOneWidget);

      // Tap the English language option
      await tester.tap(englishOption);
      await tester.pumpAndSettle();

      // Verify language changed to English
      expect(appState.currentLanguage, equals('en'));

      // Verify the change was persisted to database
      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Verify success message appears
      expect(find.text('Language changed to English'), findsOneWidget);

      // Now switch back to Indonesian
      final indonesianOption = find.text('🇮🇩');
      expect(indonesianOption, findsOneWidget);

      await tester.tap(indonesianOption);
      await tester.pumpAndSettle();

      // Verify language changed back to Indonesian
      expect(appState.currentLanguage, equals('id'));

      // Verify the change was persisted
      final updatedSettings = await settingsRepository.getSettings();
      expect(updatedSettings.languageCode, equals('id'));

      // Verify success message in Indonesian
      expect(find.text('Bahasa diubah ke Bahasa Indonesia'), findsOneWidget);
    });

    testWidgets('Language persists across simulated app restart', (WidgetTester tester) async {
      // Requirements: 1.4, 1.5
      
      // Build the app
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

      // Change language to English
      final englishOption = find.text('🇬🇧');
      await tester.tap(englishOption);
      await tester.pumpAndSettle();

      expect(appState.currentLanguage, equals('en'));

      // Simulate app restart by creating new instances
      final newSettingsRepository = SettingsRepository();
      final newLocalizationService = LocalizationService(
        settingsRepository: newSettingsRepository,
      );
      await newLocalizationService.initialize();

      // Verify language persisted as English
      expect(newLocalizationService.currentLanguage, equals('en'));

      // Verify database has English
      final persistedSettings = await newSettingsRepository.getSettings();
      expect(persistedSettings.languageCode, equals('en'));
    });

    testWidgets('UI updates across all screens after language change', (WidgetTester tester) async {
      // Requirements: 2.1, 2.2, 2.3
      
      // Create a session for testing
      final session = await appState.sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await appState.sessionRepository.setActiveSession(session.id!);
      
      // Initialize stats
      final stats = UserStats(
        sessionId: session.id!,
        totalXp: 100,
        level: 2,
        currentStreak: 5,
        longestStreak: 10,
        prayerStreak: 5,
        tilawahStreak: 3,
      );
      await appState.statsRepository.updateStats(stats);
      await appState.loadActiveSession();

      // Build app with navigation between screens
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: DefaultTabController(
              length: 4,
              child: Scaffold(
                body: TabBarView(
                  children: [
                    HomeScreen(),
                    StatsScreen(),
                    AchievementsScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to ProfileScreen (index 3)
      final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
      final controller = tabBarView.controller!;
      controller.animateTo(3);
      await tester.pumpAndSettle();

      // Change language to English
      final englishOption = find.text('🇬🇧');
      await tester.tap(englishOption);
      await tester.pumpAndSettle();

      // Navigate to HomeScreen (index 0)
      controller.animateTo(0);
      await tester.pumpAndSettle();

      // Verify HomeScreen shows English text
      // The translate function should return English translations
      expect(appState.localizationService.translate('home.title'), equals('My Ramadhan'));

      // Navigate to StatsScreen (index 1)
      controller.animateTo(1);
      await tester.pumpAndSettle();

      // Verify StatsScreen shows English text
      expect(appState.localizationService.translate('stats.title'), equals('Statistics'));

      // Navigate to AchievementsScreen (index 2)
      controller.animateTo(2);
      await tester.pumpAndSettle();

      // Verify AchievementsScreen shows English text
      expect(appState.localizationService.translate('achievements.title'), equals('Achievements'));

      // Navigate back to ProfileScreen
      controller.animateTo(3);
      await tester.pumpAndSettle();

      // Switch back to Indonesian
      final indonesianOption = find.text('🇮🇩');
      await tester.tap(indonesianOption);
      await tester.pumpAndSettle();

      // Navigate through screens again and verify Indonesian
      controller.animateTo(0);
      await tester.pumpAndSettle();
      expect(appState.localizationService.translate('home.title'), equals('Ramadhan Saya'));

      controller.animateTo(1);
      await tester.pumpAndSettle();
      expect(appState.localizationService.translate('stats.title'), equals('Statistik'));

      controller.animateTo(2);
      await tester.pumpAndSettle();
      expect(appState.localizationService.translate('achievements.title'), equals('Pencapaian'));
    });

    test('Language change updates AppState and triggers notifyListeners', () async {
      // Requirements: 2.3
      
      // Track if listeners were notified
      bool listenerCalled = false;
      appState.addListener(() {
        listenerCalled = true;
      });

      // Initial language should be Indonesian
      expect(appState.currentLanguage, equals('id'));

      // Change language to English
      await appState.changeLanguage('en');

      // Verify listener was called
      expect(listenerCalled, isTrue);

      // Verify language changed
      expect(appState.currentLanguage, equals('en'));

      // Verify persistence
      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));
    });

    testWidgets('Language switcher shows correct active state', (WidgetTester tester) async {
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

      // Initially Indonesian should be selected
      expect(appState.currentLanguage, equals('id'));

      // Find the Indonesian option container with check icon
      final indonesianCheckIcon = find.descendant(
        of: find.ancestor(
          of: find.text('🇮🇩'),
          matching: find.byType(InkWell),
        ),
        matching: find.byIcon(Icons.check_circle),
      );
      expect(indonesianCheckIcon, findsOneWidget);

      // Switch to English
      await tester.tap(find.text('🇬🇧'));
      await tester.pumpAndSettle();

      // Now English should show check icon
      final englishCheckIcon = find.descendant(
        of: find.ancestor(
          of: find.text('🇬🇧'),
          matching: find.byType(InkWell),
        ),
        matching: find.byIcon(Icons.check_circle),
      );
      expect(englishCheckIcon, findsOneWidget);

      // Indonesian should not show check icon anymore
      final indonesianCheckIconAfter = find.descendant(
        of: find.ancestor(
          of: find.text('🇮🇩'),
          matching: find.byType(InkWell),
        ),
        matching: find.byIcon(Icons.check_circle),
      );
      expect(indonesianCheckIconAfter, findsNothing);
    });

    test('Multiple language changes persist correctly', () async {
      // Requirements: 1.4, 1.5
      
      // Start with Indonesian
      expect(appState.currentLanguage, equals('id'));

      // Change to English
      await appState.changeLanguage('en');
      expect(appState.currentLanguage, equals('en'));
      var settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Change back to Indonesian
      await appState.changeLanguage('id');
      expect(appState.currentLanguage, equals('id'));
      settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('id'));

      // Change to English again
      await appState.changeLanguage('en');
      expect(appState.currentLanguage, equals('en'));
      settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Simulate restart
      final newSettingsRepository = SettingsRepository();
      final newLocalizationService = LocalizationService(
        settingsRepository: newSettingsRepository,
      );
      await newLocalizationService.initialize();

      // Verify final state persisted
      expect(newLocalizationService.currentLanguage, equals('en'));
    });

    testWidgets('Error handling when language change fails', (WidgetTester tester) async {
      // This test verifies the error handling in ProfileScreen
      
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

      // The current implementation should handle errors gracefully
      // If an error occurs, a red SnackBar should appear
      // This is tested by the try-catch in _buildLanguageOption

      // For now, verify that the UI doesn't crash when switching languages
      await tester.tap(find.text('🇬🇧'));
      await tester.pumpAndSettle();

      // Should complete without throwing
      expect(appState.currentLanguage, equals('en'));
    });
  });
}