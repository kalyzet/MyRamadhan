import 'package:flutter_test/flutter_test.dart';
import 'package:my_ramadhan/services/date_formatting_service.dart';
import 'package:my_ramadhan/services/localization_service.dart';
import 'dart:math';

/// **Feature: ramadhan-history-localization-fix, Property 3: Month names use translations**
/// **Validates: Requirements 2.5**
/// 
/// Property: For any displayed date, the month names should match the translated 
/// month names from the current language's localization file
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property-Based Tests - Date Formatting Service', () {
    late LocalizationService localizationService;
    late DateFormattingService dateFormattingService;

    setUp(() async {
      localizationService = LocalizationService();
      await localizationService.initialize();
      dateFormattingService = DateFormattingService(localizationService);
    });

    /// **Feature: ramadhan-history-localization-fix, Property 3: Month names use translations**
    /// **Validates: Requirements 2.5**
    test('property: month names use translations', () async {
      // Property: For any displayed date, the month names should match the translated 
      // month names from the current language's localization file
      
      final random = Random(42); // Fixed seed for reproducibility
      const iterations = 100;
      
      // Test with both languages
      for (final languageCode in ['en', 'id']) {
        await localizationService.loadLanguage(languageCode);
        
        for (int i = 0; i < iterations; i++) {
          // Generate random date
          final year = 2020 + random.nextInt(10); // 2020-2029
          final month = 1 + random.nextInt(12); // 1-12
          final day = 1 + random.nextInt(28); // 1-28 (safe for all months)
          final testDate = DateTime(year, month, day);
          
          // Format the date
          final formattedDate = dateFormattingService.formatDate(testDate);
          
          // Get the expected translated month name
          final monthKey = _getMonthKey(month);
          final expectedMonthName = localizationService.translate('date.months.$monthKey');
          
          // Assert: The formatted date should contain the translated month name
          expect(
            formattedDate.contains(expectedMonthName),
            isTrue,
            reason: 'Formatted date "$formattedDate" should contain translated month "$expectedMonthName" '
                'for language "$languageCode" and date $testDate',
          );
          
          // Assert: The formatted date should contain the year
          expect(
            formattedDate.contains(year.toString()),
            isTrue,
            reason: 'Formatted date "$formattedDate" should contain year "$year"',
          );
          
          // Assert: The formatted date should contain the day
          expect(
            formattedDate.contains(day.toString()),
            isTrue,
            reason: 'Formatted date "$formattedDate" should contain day "$day"',
          );
          
          // Assert: The formatted date should not be empty
          expect(
            formattedDate.isNotEmpty,
            isTrue,
            reason: 'Formatted date should never be empty',
          );
          
          // Assert: Language-specific format validation
          if (languageCode == 'id') {
            // Indonesian format: "7 Mei 2026"
            final indonesianPattern = RegExp(r'^\d{1,2} \w+ \d{4}$');
            expect(
              indonesianPattern.hasMatch(formattedDate),
              isTrue,
              reason: 'Indonesian formatted date "$formattedDate" should match pattern "DD Month YYYY"',
            );
          } else {
            // English format: "May 7, 2026"
            final englishPattern = RegExp(r'^\w+ \d{1,2}, \d{4}$');
            expect(
              englishPattern.hasMatch(formattedDate),
              isTrue,
              reason: 'English formatted date "$formattedDate" should match pattern "Month DD, YYYY"',
            );
          }
        }
      }
    });

    test('property: date formatting is consistent for same date', () async {
      // Property: For any given date and language, formatting should be consistent
      // (same date should always produce same formatted string)
      
      final testDate = DateTime(2026, 5, 7);
      
      for (final languageCode in ['en', 'id']) {
        await localizationService.loadLanguage(languageCode);
        
        // Format the same date multiple times
        final results = <String>[];
        for (int i = 0; i < 10; i++) {
          results.add(dateFormattingService.formatDate(testDate));
        }
        
        // Assert: All results should be identical
        final firstResult = results.first;
        for (final result in results) {
          expect(
            result,
            equals(firstResult),
            reason: 'Date formatting should be consistent for same date and language',
          );
        }
      }
    });

    test('property: all months have valid translations', () async {
      // Property: For any month (1-12), there should be a valid translation available
      
      for (final languageCode in ['en', 'id']) {
        await localizationService.loadLanguage(languageCode);
        
        for (int month = 1; month <= 12; month++) {
          final monthKey = _getMonthKey(month);
          final translatedMonth = localizationService.translate('date.months.$monthKey');
          
          // Assert: Translation should not be the key itself (indicating missing translation)
          expect(
            translatedMonth,
            isNot(equals('date.months.$monthKey')),
            reason: 'Month $month should have a valid translation in language "$languageCode"',
          );
          
          // Assert: Translation should not be empty
          expect(
            translatedMonth.isNotEmpty,
            isTrue,
            reason: 'Month translation should not be empty',
          );
        }
      }
    });
  });
}

/// Get the month key for translation lookup
String _getMonthKey(int month) {
  switch (month) {
    case 1:
      return 'january';
    case 2:
      return 'february';
    case 3:
      return 'march';
    case 4:
      return 'april';
    case 5:
      return 'may';
    case 6:
      return 'june';
    case 7:
      return 'july';
    case 8:
      return 'august';
    case 9:
      return 'september';
    case 10:
      return 'october';
    case 11:
      return 'november';
    case 12:
      return 'december';
    default:
      return 'january';
  }
}