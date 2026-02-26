import 'package:flutter_test/flutter_test.dart';
import 'package:my_ramadhan/services/validation_service.dart';
import 'package:my_ramadhan/exceptions/validation_exception.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';
import 'package:my_ramadhan/models/daily_record.dart';

void main() {
  late ValidationService validationService;

  setUp(() {
    validationService = ValidationService();
  });

  group('Input Validation Tests', () {
    group('validateTilawahPages', () {
      test('should accept valid page count (0)', () {
        expect(() => validationService.validateTilawahPages(0), returnsNormally);
      });

      test('should accept valid page count (604)', () {
        expect(() => validationService.validateTilawahPages(604), returnsNormally);
      });

      test('should accept valid page count (300)', () {
        expect(() => validationService.validateTilawahPages(300), returnsNormally);
      });

      test('should reject negative page count', () {
        expect(
          () => validationService.validateTilawahPages(-1),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject page count exceeding 604', () {
        expect(
          () => validationService.validateTilawahPages(605),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateSedekahAmount', () {
      test('should accept zero amount', () {
        expect(() => validationService.validateSedekahAmount(0), returnsNormally);
      });

      test('should accept positive amount', () {
        expect(() => validationService.validateSedekahAmount(100.50), returnsNormally);
      });

      test('should reject negative amount', () {
        expect(
          () => validationService.validateSedekahAmount(-1.0),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateDateInSession', () {
      test('should accept date within session range', () {
        final session = RamadhanSession(
          id: 1,
          year: 2024,
          startDate: DateTime(2024, 3, 11),
          endDate: DateTime(2024, 4, 9),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        expect(
          () => validationService.validateDateInSession(
            DateTime(2024, 3, 15),
            session,
          ),
          returnsNormally,
        );
      });

      test('should accept start date', () {
        final session = RamadhanSession(
          id: 1,
          year: 2024,
          startDate: DateTime(2024, 3, 11),
          endDate: DateTime(2024, 4, 9),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        expect(
          () => validationService.validateDateInSession(
            DateTime(2024, 3, 11),
            session,
          ),
          returnsNormally,
        );
      });

      test('should accept end date', () {
        final session = RamadhanSession(
          id: 1,
          year: 2024,
          startDate: DateTime(2024, 3, 11),
          endDate: DateTime(2024, 4, 9),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        expect(
          () => validationService.validateDateInSession(
            DateTime(2024, 4, 9),
            session,
          ),
          returnsNormally,
        );
      });

      test('should reject date before session start', () {
        final session = RamadhanSession(
          id: 1,
          year: 2024,
          startDate: DateTime(2024, 3, 11),
          endDate: DateTime(2024, 4, 9),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        expect(
          () => validationService.validateDateInSession(
            DateTime(2024, 3, 10),
            session,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject date after session end', () {
        final session = RamadhanSession(
          id: 1,
          year: 2024,
          startDate: DateTime(2024, 3, 11),
          endDate: DateTime(2024, 4, 9),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        expect(
          () => validationService.validateDateInSession(
            DateTime(2024, 4, 10),
            session,
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });

  group('Business Rule Validation Tests', () {
    group('validateBackdating', () {
      test('should allow modification of today\'s record', () {
        final today = DateTime.now();
        expect(
          () => validationService.validateBackdating(today, today),
          returnsNormally,
        );
      });

      test('should allow modification of H-1 record', () {
        final today = DateTime(2024, 3, 15);
        final yesterday = DateTime(2024, 3, 14);
        expect(
          () => validationService.validateBackdating(yesterday, today),
          returnsNormally,
        );
      });

      test('should allow modification of H-2 record', () {
        final today = DateTime(2024, 3, 15);
        final twoDaysAgo = DateTime(2024, 3, 13);
        expect(
          () => validationService.validateBackdating(twoDaysAgo, today),
          returnsNormally,
        );
      });

      test('should reject modification of H-3 record', () {
        final today = DateTime(2024, 3, 15);
        final threeDaysAgo = DateTime(2024, 3, 12);
        expect(
          () => validationService.validateBackdating(threeDaysAgo, today),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject modification of future record', () {
        final today = DateTime(2024, 3, 15);
        final tomorrow = DateTime(2024, 3, 16);
        expect(
          () => validationService.validateBackdating(tomorrow, today),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateSessionCreation', () {
      test('should accept valid session parameters', () {
        expect(
          () => validationService.validateSessionCreation(
            year: 2024,
            startDate: DateTime(2024, 3, 11),
            totalDays: 30,
          ),
          returnsNormally,
        );
      });

      test('should accept 29-day duration', () {
        expect(
          () => validationService.validateSessionCreation(
            year: 2024,
            startDate: DateTime(2024, 3, 11),
            totalDays: 29,
          ),
          returnsNormally,
        );
      });

      test('should reject invalid duration (28 days)', () {
        expect(
          () => validationService.validateSessionCreation(
            year: 2024,
            startDate: DateTime(2024, 3, 11),
            totalDays: 28,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject invalid duration (31 days)', () {
        expect(
          () => validationService.validateSessionCreation(
            year: 2024,
            startDate: DateTime(2024, 3, 11),
            totalDays: 31,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject year too far in past', () {
        expect(
          () => validationService.validateSessionCreation(
            year: 1999,
            startDate: DateTime(1999, 3, 11),
            totalDays: 30,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject year too far in future', () {
        final currentYear = DateTime.now().year;
        expect(
          () => validationService.validateSessionCreation(
            year: currentYear + 51,
            startDate: DateTime(currentYear + 51, 3, 11),
            totalDays: 30,
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateDailyRecord', () {
      test('should accept valid daily record', () {
        final record = DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: true,
          dhuhrComplete: true,
          asrComplete: true,
          maghribComplete: true,
          ishaComplete: true,
          puasaComplete: true,
          tarawihComplete: true,
          tilawahPages: 10,
          dzikirComplete: true,
          sedekahAmount: 50.0,
          xpEarned: 200,
          isPerfectDay: true,
        );

        expect(
          () => validationService.validateDailyRecord(record),
          returnsNormally,
        );
      });

      test('should reject record with invalid tilawah pages', () {
        final record = DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 700, // Invalid
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: 0,
          isPerfectDay: false,
        );

        expect(
          () => validationService.validateDailyRecord(record),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject record with negative sedekah amount', () {
        final record = DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 0,
          dzikirComplete: false,
          sedekahAmount: -10.0, // Invalid
          xpEarned: 0,
          isPerfectDay: false,
        );

        expect(
          () => validationService.validateDailyRecord(record),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should reject record with negative XP', () {
        final record = DailyRecord(
          sessionId: 1,
          date: DateTime(2024, 3, 15),
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 0,
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: -100, // Invalid
          isPerfectDay: false,
        );

        expect(
          () => validationService.validateDailyRecord(record),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateSingleActiveSession', () {
      test('should accept zero active sessions', () {
        expect(
          () => validationService.validateSingleActiveSession([]),
          returnsNormally,
        );
      });

      test('should accept one active session', () {
        final session = RamadhanSession(
          id: 1,
          year: 2024,
          startDate: DateTime(2024, 3, 11),
          endDate: DateTime(2024, 4, 9),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        expect(
          () => validationService.validateSingleActiveSession([session]),
          returnsNormally,
        );
      });

      test('should reject multiple active sessions', () {
        final session1 = RamadhanSession(
          id: 1,
          year: 2024,
          startDate: DateTime(2024, 3, 11),
          endDate: DateTime(2024, 4, 9),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        final session2 = RamadhanSession(
          id: 2,
          year: 2023,
          startDate: DateTime(2023, 3, 23),
          endDate: DateTime(2023, 4, 21),
          totalDays: 30,
          createdAt: DateTime.now(),
          isActive: true,
        );

        expect(
          () => validationService.validateSingleActiveSession([session1, session2]),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}
