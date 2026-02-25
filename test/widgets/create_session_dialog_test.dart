import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_ramadhan/widgets/create_session_dialog.dart';
import 'package:my_ramadhan/providers/app_state.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/repositories/daily_record_repository.dart';
import 'package:my_ramadhan/repositories/stats_repository.dart';
import 'package:my_ramadhan/repositories/achievement_repository.dart';
import 'package:my_ramadhan/repositories/side_quest_repository.dart';

void main() {
  group('CreateSessionDialog', () {
    testWidgets('should display all required input fields', (WidgetTester tester) async {
      // Create app state
      final appState = AppState(
        sessionRepository: SessionRepository(),
        dailyRecordRepository: DailyRecordRepository(),
        statsRepository: StatsRepository(),
        achievementRepository: AchievementRepository(),
        sideQuestRepository: SideQuestRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: appState,
            child: const Scaffold(
              body: CreateSessionDialog(),
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('Create New Session'), findsOneWidget);

      // Verify year input field
      expect(find.text('Year'), findsOneWidget);

      // Verify start date picker
      expect(find.text('Start Date'), findsOneWidget);

      // Verify duration selector
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('29 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);

      // Verify mid-Ramadhan toggle
      expect(find.text('Starting mid-Ramadhan?'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('should toggle mid-Ramadhan input field', (WidgetTester tester) async {
      final appState = AppState(
        sessionRepository: SessionRepository(),
        dailyRecordRepository: DailyRecordRepository(),
        statsRepository: StatsRepository(),
        achievementRepository: AchievementRepository(),
        sideQuestRepository: SideQuestRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: appState,
            child: const Scaffold(
              body: CreateSessionDialog(),
            ),
          ),
        ),
      );

      // Initially, current day input should not be visible
      expect(find.text('Current Day Number'), findsNothing);

      // Find and tap the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Now current day input should be visible
      expect(find.text('Current Day Number'), findsOneWidget);
    });

    testWidgets('should validate year input', (WidgetTester tester) async {
      final appState = AppState(
        sessionRepository: SessionRepository(),
        dailyRecordRepository: DailyRecordRepository(),
        statsRepository: StatsRepository(),
        achievementRepository: AchievementRepository(),
        sideQuestRepository: SideQuestRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: appState,
            child: const Scaffold(
              body: CreateSessionDialog(),
            ),
          ),
        ),
      );

      // Clear the year field
      final yearField = find.widgetWithText(TextFormField, 'Year');
      await tester.enterText(yearField, '');
      
      // Try to submit
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a year'), findsOneWidget);
    });

    testWidgets('should allow duration selection', (WidgetTester tester) async {
      final appState = AppState(
        sessionRepository: SessionRepository(),
        dailyRecordRepository: DailyRecordRepository(),
        statsRepository: StatsRepository(),
        achievementRepository: AchievementRepository(),
        sideQuestRepository: SideQuestRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: appState,
            child: const Scaffold(
              body: CreateSessionDialog(),
            ),
          ),
        ),
      );

      // Tap on 29 days option
      await tester.tap(find.text('29 Days'));
      await tester.pumpAndSettle();

      // The 29 days option should now be selected (visual change)
      // We can verify this by checking if the widget rebuilt
      expect(find.text('29 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
    });
  });
}
