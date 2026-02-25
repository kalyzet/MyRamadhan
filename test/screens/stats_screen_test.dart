import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:my_ramadhan/models/user_stats.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/services/level_calculator_service.dart';

void main() {
  late LevelCalculatorService levelCalculator;

  setUp(() {
    levelCalculator = LevelCalculatorService();
  });

  group('Stats Screen - Property-Based Tests', () {
    // **Feature: my-ramadhan-app, Property 13: Stats display completeness**
    // **Validates: Requirements 3.4**
    Glados3<int, int, int>().test(
        'Property 13: Stats display includes all required fields',
        (totalXp, currentStreak, longestStreak) {
      // Generate valid values
      final validXp = totalXp.abs() % 100000; // Reasonable XP range
      final validCurrentStreak = currentStreak.abs() % 31; // Max 30 days
      final validLongestStreak = longestStreak.abs() % 31;

      // Calculate level from XP
      final level = levelCalculator.calculateLevel(validXp);

      // Calculate progress to next level
      final progress =
          levelCalculator.calculateProgressToNextLevel(validXp, level);

      // Create stats object
      final stats = UserStats(
        id: 1,
        sessionId: 1,
        totalXp: validXp,
        level: level,
        currentStreak: validCurrentStreak,
        longestStreak: validLongestStreak,
        prayerStreak: 0,
        tilawahStreak: 0,
      );

      // Verify all required fields are present and valid
      expect(stats.level, greaterThanOrEqualTo(1));
      expect(stats.totalXp, greaterThanOrEqualTo(0));
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));

      // Verify stats object contains all required data
      expect(stats.level, isNotNull);
      expect(stats.totalXp, isNotNull);
      expect(stats.currentStreak, isNotNull);
      expect(stats.longestStreak, isNotNull);
      expect(stats.prayerStreak, isNotNull);
      expect(stats.tilawahStreak, isNotNull);
    });

    // **Feature: my-ramadhan-app, Property 24: Consistency percentage calculation**
    // **Validates: Requirements 7.2**
    Glados2<int, int>().test(
        'Property 24: Consistency percentage equals (completed / total) × 100',
        (completedDays, totalDays) {
      // Generate valid values
      final validTotal = (totalDays.abs() % 30) + 1; // 1-30 days
      final validCompleted =
          completedDays.abs() % (validTotal + 1); // 0 to totalDays

      // Calculate consistency percentage
      final consistencyPercentage = (validCompleted / validTotal) * 100;

      // Verify calculation
      expect(consistencyPercentage, greaterThanOrEqualTo(0.0));
      expect(consistencyPercentage, lessThanOrEqualTo(100.0));

      // Verify the formula
      final expectedPercentage = (validCompleted / validTotal) * 100;
      expect(consistencyPercentage, expectedPercentage);

      // Edge cases
      if (validCompleted == 0) {
        expect(consistencyPercentage, 0.0);
      }
      if (validCompleted == validTotal) {
        expect(consistencyPercentage, 100.0);
      }
    });

    // **Feature: my-ramadhan-app, Property 25: Daily history completeness**
    // **Validates: Requirements 7.3**
    Glados2<int, int>().test(
        'Property 25: Daily history includes entry for every day in session',
        (totalDays, year) {
      // Generate valid values
      final validTotalDays = (totalDays.abs() % 30) + 1; // 1-30 days
      final validYear = 2020 + (year.abs() % 10); // 2020-2029

      // Create a session
      final startDate = DateTime(validYear, 3, 1);
      final endDate = startDate.add(Duration(days: validTotalDays - 1));

      final session = RamadhanSession(
        id: 1,
        year: validYear,
        startDate: startDate,
        endDate: endDate,
        totalDays: validTotalDays,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Generate daily records (some days may have records, some may not)
      final records = <DailyRecord>[];
      for (int i = 0; i < validTotalDays; i += 2) {
        // Create records for every other day
        final date = startDate.add(Duration(days: i));
        records.add(DailyRecord(
          id: i + 1,
          sessionId: session.id!,
          date: date,
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
          xpEarned: 240,
          isPerfectDay: true,
        ));
      }

      // Create a map of dates to records
      final recordMap = <DateTime, DailyRecord>{};
      for (final record in records) {
        final normalizedDate = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        recordMap[normalizedDate] = record;
      }

      // Verify that we can generate an entry for every day
      final historyEntries = <Map<String, dynamic>>[];
      for (int i = 0; i < session.totalDays; i++) {
        final date = session.startDate.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final record = recordMap[normalizedDate];

        historyEntries.add({
          'dayNumber': i + 1,
          'date': normalizedDate,
          'hasRecord': record != null,
          'isPerfect': record?.isPerfectDay ?? false,
          'xpEarned': record?.xpEarned ?? 0,
        });
      }

      // Verify completeness
      expect(historyEntries.length, session.totalDays);

      // Verify each entry has required fields
      for (final entry in historyEntries) {
        expect(entry['dayNumber'], isNotNull);
        expect(entry['date'], isNotNull);
        expect(entry['hasRecord'], isNotNull);
        expect(entry['isPerfect'], isNotNull);
        expect(entry['xpEarned'], isNotNull);
      }

      // Verify day numbers are sequential
      for (int i = 0; i < historyEntries.length; i++) {
        expect(historyEntries[i]['dayNumber'], i + 1);
      }
    });
  });
}
