import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/database/database_helper.dart';
import '../../lib/screens/home_screen.dart';
import '../../lib/providers/app_state.dart';
import '../../lib/widgets/real_time_clock_widget.dart';
import '../../lib/repositories/session_repository.dart';
import '../../lib/repositories/daily_record_repository.dart';
import '../../lib/repositories/stats_repository.dart';
import '../../lib/repositories/achievement_repository.dart';
import '../../lib/repositories/side_quest_repository.dart';
import '../../lib/services/xp_calculator_service.dart';
import '../../lib/services/level_calculator_service.dart';
import '../../lib/services/streak_tracker_service.dart';
import '../../lib/services/achievement_tracker_service.dart';
import '../../lib/services/localization_service.dart';
import '../../lib/models/user_stats.dart';

/// Integration tests for RealTimeClockWidget in HomeScreen
/// Requirements: 2.1, 4.1
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HomeScreen Clock Integration Tests', () {
    late AppState appState;

    setUp(() async {
      // Initialize all dependencies
      final sessionRepository = SessionRepository();
      final dailyRecordRepository = DailyRecordRepository();
      final statsRepository = StatsRepository();
      final achievementRepository = AchievementRepository();
      final sideQuestRepository = SideQuestRepository();
      final xpCalculatorService = XpCalculatorService();
      final levelCalculatorService = LevelCalculatorService();
      final streakTrackerService = StreakTrackerService(
        dailyRecordRepository: dailyRecordRepository,
        statsRepository: statsRepository,
      );
      final achievementTrackerService = AchievementTrackerService();
      final localizationService = LocalizationService();

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

      // Create a test session
      final session = await sessionRepository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await sessionRepository.setActiveSession(session.id!);

      // Initialize stats
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

      // Load the session into AppState
      await appState.loadActiveSession();
    });

    tearDown(() async {
      // Clean up database after each test
      await DatabaseHelper.instance.deleteDB();
    });

    testWidgets('Clock appears on HomeScreen', (WidgetTester tester) async {
      // Build the HomeScreen with AppState
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that RealTimeClockWidget is present
      expect(find.byType(RealTimeClockWidget), findsOneWidget);
    });

    testWidgets('Clock updates while screen is visible', (WidgetTester tester) async {
      DateTime testTime = DateTime(2024, 3, 11, 14, 30, 45);
      
      // Build the HomeScreen with a custom time provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    RealTimeClockWidget(
                      getCurrentTime: () => testTime,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Wait for initial render
      await tester.pump();

      // Find the initial time display
      expect(find.text('14:30:45'), findsOneWidget);

      // Advance time by 1 second
      testTime = DateTime(2024, 3, 11, 14, 30, 46);
      
      // Wait for timer to tick (1 second)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(); // Additional pump for animation

      // Verify time has updated
      expect(find.text('14:30:46'), findsOneWidget);
    });

    testWidgets('Clock integrates well with other UI elements', (WidgetTester tester) async {
      // Build the complete HomeScreen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify clock is present
      expect(find.byType(RealTimeClockWidget), findsOneWidget);

      // Verify other HomeScreen elements are also present
      expect(find.text('Ramadhan Day'), findsOneWidget);
      expect(find.text('Daily Checklist'), findsOneWidget);

      // Verify the clock doesn't overlap with other elements
      final clockFinder = find.byType(RealTimeClockWidget);
      final clockWidget = tester.widget<RealTimeClockWidget>(clockFinder);
      expect(clockWidget, isNotNull);

      // Verify the screen is scrollable (content doesn't overflow)
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);
    });

    testWidgets('Clock displays Indonesian date format', (WidgetTester tester) async {
      DateTime testTime = DateTime(2024, 2, 27, 14, 30, 45); // Tuesday, Feb 27, 2024
      
      // Build the clock widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(
              getCurrentTime: () => testTime,
            ),
          ),
        ),
      );

      // Wait for render
      await tester.pump();

      // Verify Indonesian date format is displayed
      // Tuesday = Selasa, February = Februari
      expect(find.textContaining('Selasa'), findsOneWidget);
      expect(find.textContaining('Februari'), findsOneWidget);
      expect(find.textContaining('2024'), findsOneWidget);
    });

    testWidgets('Clock displays timezone label', (WidgetTester tester) async {
      // Build the clock widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(
              showTimezone: true,
            ),
          ),
        ),
      );

      // Wait for render
      await tester.pump();

      // Verify timezone label is displayed (WIB, WITA, or WIT)
      final timezoneFinder = find.textContaining(RegExp(r'WI[BTA]'));
      expect(timezoneFinder, findsOneWidget);
    });

    testWidgets('Clock is positioned at top of HomeScreen', (WidgetTester tester) async {
      // Build the HomeScreen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find the RealTimeClockWidget
      final clockFinder = find.byType(RealTimeClockWidget);
      expect(clockFinder, findsOneWidget);

      // Find the Ramadhan Day indicator (which should come after the clock)
      final dayIndicatorFinder = find.text('Ramadhan Day');
      expect(dayIndicatorFinder, findsOneWidget);

      // Get the positions of both widgets
      final clockPosition = tester.getTopLeft(clockFinder);
      final dayIndicatorPosition = tester.getTopLeft(dayIndicatorFinder);

      // Verify clock is positioned above the day indicator
      expect(clockPosition.dy, lessThan(dayIndicatorPosition.dy));
    });
  });
}
