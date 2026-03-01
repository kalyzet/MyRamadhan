import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/database/database_helper.dart';
import '../../lib/providers/app_state.dart';
import '../../lib/screens/profile_screen.dart';
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
      
      // Add a listener to track when notifyListeners is called
      bool listenerCalled = false;
      appState.addListener(() {
        listenerCalled = true;
        print('AppState listener called, current language: ${appState.currentLanguage}');
      });
      
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
      await tester.pump(); // Start the animation
      
      // Give time for async operations
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Debug: Print current language
      print('Current language after tap: ${appState.currentLanguage}');
      print('Localization service language: ${appState.localizationService.currentLanguage}');
      print('Listener was called: $listenerCalled');

      // Check if error SnackBar appeared
      final errorSnackBarFinder = find.byWidgetPredicate(
        (widget) => widget is SnackBar && widget.backgroundColor == Colors.red,
      );
      if (errorSnackBarFinder.evaluate().isNotEmpty) {
        print('ERROR SNACKBAR FOUND!');
      }
      
      // Try to find any SnackBar
      final anySnackBar = find.byType(SnackBar);
      print('SnackBars found: ${anySnackBar.evaluate().length}');

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
  });
}
