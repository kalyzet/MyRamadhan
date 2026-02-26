import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ramadhan/widgets/real_time_clock_widget.dart';

void main() {
  group('RealTimeClockWidget Property Tests', () {
    testWidgets(
      'Property 2: Clock update consistency - '
      'For any clock widget instance, after waiting for at least 1 second, '
      'the displayed time should be different from the initial time',
      (WidgetTester tester) async {
        // **Feature: indonesian-default-realtime-clock, Property 2: Clock update consistency**
        // **Validates: Requirements 2.2**

        // Create a controllable time source using a class to hold mutable state
        final testClock = _TestClock(DateTime(2026, 2, 27, 14, 30, 45));
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RealTimeClockWidget(
                getCurrentTime: () => testClock.now(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get initial time text
        final textFinders = find.byType(Text);
        expect(textFinders, findsWidgets);
        
        final initialTimeText = tester.widget<Text>(textFinders.first).data;
        expect(initialTimeText, equals('14:30:45'));

        // Advance the test time by 1 second
        testClock.advance(const Duration(seconds: 1));

        // Trigger the timer by advancing fake async time
        await tester.pump(const Duration(seconds: 1));
        
        // Allow AnimatedSwitcher animation to complete
        await tester.pumpAndSettle();

        // Get updated time text - need to find it again after rebuild
        final updatedTextFinders = find.byType(Text);
        final updatedTimeText = tester.widget<Text>(updatedTextFinders.first).data;

        // Verify time has changed
        expect(updatedTimeText, isNot(equals(initialTimeText)),
            reason: 'Time should update after 1 second');
        expect(updatedTimeText, equals('14:30:46'),
            reason: 'Time should be 1 second later');
      },
    );

    testWidgets(
      'Property 3: Offline time accuracy - '
      'For any clock widget running without network connection, '
      'the displayed time should match the device system time within 1 second tolerance',
      (WidgetTester tester) async {
        // **Feature: indonesian-default-realtime-clock, Property 3: Offline time accuracy**
        // **Validates: Requirements 2.3**

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RealTimeClockWidget(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get the displayed time
        final textFinders = find.byType(Text);
        final displayedTimeText = tester.widget<Text>(textFinders.first).data!;

        // Parse the displayed time (format: HH:mm:ss)
        final timeParts = displayedTimeText.split(':');
        expect(timeParts.length, 3, reason: 'Time should be in HH:mm:ss format');

        final displayedHour = int.parse(timeParts[0]);
        final displayedMinute = int.parse(timeParts[1]);
        final displayedSecond = int.parse(timeParts[2]);

        // Get actual system time
        final systemTime = DateTime.now();

        // Verify displayed time matches system time within 1 second tolerance
        expect(displayedHour, equals(systemTime.hour),
            reason: 'Hour should match system time');
        expect(displayedMinute, equals(systemTime.minute),
            reason: 'Minute should match system time');
        
        // Second might differ by 1 due to timing
        expect((displayedSecond - systemTime.second).abs(), lessThanOrEqualTo(1),
            reason: 'Second should match system time within 1 second tolerance');
      },
    );

    testWidgets(
      'Property 4: Time format validation - '
      'For any displayed time string, it should match the pattern HH:mm:ss '
      'where HH is 00-23, mm is 00-59, and ss is 00-59',
      (WidgetTester tester) async {
        // **Feature: indonesian-default-realtime-clock, Property 4: Time format validation**
        // **Validates: Requirements 2.4**

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RealTimeClockWidget(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get the displayed time
        final textFinders = find.byType(Text);
        final displayedTimeText = tester.widget<Text>(textFinders.first).data!;

        // Verify format matches HH:mm:ss pattern
        final timeRegex = RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$');
        expect(timeRegex.hasMatch(displayedTimeText), isTrue,
            reason: 'Time should match HH:mm:ss format with valid ranges');

        // Parse and verify ranges
        final timeParts = displayedTimeText.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = int.parse(timeParts[2]);

        expect(hour, inInclusiveRange(0, 23),
            reason: 'Hour should be between 00 and 23');
        expect(minute, inInclusiveRange(0, 59),
            reason: 'Minute should be between 00 and 59');
        expect(second, inInclusiveRange(0, 59),
            reason: 'Second should be between 00 and 59');
      },
    );

    testWidgets(
      'Property 5: Indonesian date format - '
      'For any displayed date string in Indonesian, it should contain '
      'a valid day name in Indonesian and a valid month name in Indonesian',
      (WidgetTester tester) async {
        // **Feature: indonesian-default-realtime-clock, Property 5: Indonesian date format**
        // **Validates: Requirements 2.5**

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RealTimeClockWidget(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get all text widgets
        final textFinders = find.byType(Text);
        expect(textFinders, findsAtLeastNWidgets(2),
            reason: 'Should have at least time and date text widgets');
        
        // Find the date text by looking for one that contains Indonesian day/month names
        String? displayedDateText;
        for (int i = 0; i < tester.widgetList<Text>(textFinders).length; i++) {
          final text = tester.widget<Text>(textFinders.at(i)).data;
          if (text != null && text.contains(',')) {
            displayedDateText = text;
            break;
          }
        }

        expect(displayedDateText, isNotNull,
            reason: 'Should find a date text widget');

        // Valid Indonesian day names
        const validDays = [
          'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
        ];

        // Valid Indonesian month names
        const validMonths = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];

        // Check if date contains a valid Indonesian day name
        final containsValidDay = validDays.any((day) => displayedDateText!.contains(day));
        expect(containsValidDay, isTrue,
            reason: 'Date should contain a valid Indonesian day name');

        // Check if date contains a valid Indonesian month name
        final containsValidMonth = validMonths.any((month) => displayedDateText!.contains(month));
        expect(containsValidMonth, isTrue,
            reason: 'Date should contain a valid Indonesian month name');

        // Verify format: "Hari, DD Bulan YYYY"
        final dateRegex = RegExp(r'^[A-Za-z]+, \d{2} [A-Za-z]+ \d{4}$');
        expect(dateRegex.hasMatch(displayedDateText!), isTrue,
            reason: 'Date should match format "Hari, DD Bulan YYYY"');
      },
    );

    testWidgets(
      'Property 6: Timer cleanup - '
      'For any clock widget that is disposed, its timer should be cancelled '
      'and not continue executing',
      (WidgetTester tester) async {
        // **Feature: indonesian-default-realtime-clock, Property 6: Timer cleanup**
        // **Validates: Requirements 4.2**

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RealTimeClockWidget(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify widget is rendered
        expect(find.byType(RealTimeClockWidget), findsOneWidget);

        // Remove the widget by replacing it with an empty container
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox.shrink(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify widget is no longer in the tree
        expect(find.byType(RealTimeClockWidget), findsNothing);

        // Advance time to ensure timer would have fired if not cancelled
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        // If we get here without errors, the timer was properly cancelled
        // (If timer wasn't cancelled, setState would be called on disposed widget causing error)
        expect(true, isTrue, reason: 'Timer should be cancelled on dispose');
      },
    );
  });

  group('RealTimeClockWidget Unit Tests', () {
    testWidgets('Widget renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(RealTimeClockWidget), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('Time format matches expected pattern', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinders = find.byType(Text);
      final timeText = tester.widget<Text>(textFinders.first).data!;

      // Verify HH:mm:ss format
      expect(timeText, matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
    });

    testWidgets('Date contains Indonesian day and month names', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinders = find.byType(Text);
      
      // Find date text
      String? dateText;
      for (int i = 0; i < tester.widgetList<Text>(textFinders).length; i++) {
        final text = tester.widget<Text>(textFinders.at(i)).data;
        if (text != null && text.contains(',')) {
          dateText = text;
          break;
        }
      }

      expect(dateText, isNotNull);

      const validDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const validMonths = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];

      final hasDay = validDays.any((day) => dateText!.contains(day));
      final hasMonth = validMonths.any((month) => dateText!.contains(month));

      expect(hasDay, isTrue);
      expect(hasMonth, isTrue);
    });

    testWidgets('Timer is cancelled on dispose', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dispose the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Advance time - if timer wasn't cancelled, this would cause an error
      await tester.pump(const Duration(seconds: 2));
      
      // Test passes if no error is thrown
      expect(find.byType(RealTimeClockWidget), findsNothing);
    });

    testWidgets('Widget shows timezone when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(showTimezone: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find text containing timezone (WIB, WITA, or WIT)
      final timezoneRegex = RegExp(r'WI[BTA]');
      final textFinders = find.byType(Text);
      
      bool foundTimezone = false;
      for (int i = 0; i < tester.widgetList<Text>(textFinders).length; i++) {
        final text = tester.widget<Text>(textFinders.at(i)).data;
        if (text != null && timezoneRegex.hasMatch(text)) {
          foundTimezone = true;
          break;
        }
      }

      expect(foundTimezone, isTrue);
    });

    testWidgets('Widget hides date when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealTimeClockWidget(showDate: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinders = find.byType(Text);
      
      // Should only have time text, not date text
      bool foundDate = false;
      for (int i = 0; i < tester.widgetList<Text>(textFinders).length; i++) {
        final text = tester.widget<Text>(textFinders.at(i)).data;
        if (text != null && text.contains(',')) {
          foundDate = true;
          break;
        }
      }

      expect(foundDate, isFalse);
    });
  });
}

// Helper class for testing with controllable time
class _TestClock {
  DateTime _currentTime;

  _TestClock(this._currentTime);

  DateTime now() => _currentTime;

  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }
}
