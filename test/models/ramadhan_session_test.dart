import 'package:test/test.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';
import 'dart:math';

void main() {
  group('RamadhanSession Model Tests', () {
    // **Feature: my-ramadhan-app, Property 1: Session data persistence round-trip**
    // **Validates: Requirements 1.1**
    test(
      'Property 1: Session data persistence round-trip - '
      'For any valid session data, creating a session and then querying it '
      'should return the same data with all fields intact',
      () {
        final random = Random();
        
        // Run 100 iterations with random data
        for (int i = 0; i < 100; i++) {
          // Generate random session data
          final year = 2020 + random.nextInt(11); // 2020-2030
          final totalDays = 29 + random.nextInt(2); // 29 or 30
          final startDayOffset = random.nextInt(10); // 0-9
          final createdDaysAgo = 1 + random.nextInt(30); // 1-30
          final isActive = random.nextBool();
          final id = 1 + random.nextInt(1000); // 1-1000

          final startDate = DateTime(year, 3, 1 + startDayOffset);
          final endDate = startDate.add(Duration(days: totalDays));
          final createdAt = startDate.subtract(Duration(days: createdDaysAgo));

          final session = RamadhanSession(
            id: id,
            year: year,
            startDate: startDate,
            endDate: endDate,
            totalDays: totalDays,
            createdAt: createdAt,
            isActive: isActive,
          );

          // Serialize to map
          final map = session.toMap();

          // Deserialize from map
          final deserializedSession = RamadhanSession.fromMap(map);

          // Verify all fields match
          expect(deserializedSession.id, equals(session.id),
              reason: 'Iteration $i: id mismatch');
          expect(deserializedSession.year, equals(session.year),
              reason: 'Iteration $i: year mismatch');
          expect(deserializedSession.startDate, equals(session.startDate),
              reason: 'Iteration $i: startDate mismatch');
          expect(deserializedSession.endDate, equals(session.endDate),
              reason: 'Iteration $i: endDate mismatch');
          expect(deserializedSession.totalDays, equals(session.totalDays),
              reason: 'Iteration $i: totalDays mismatch');
          expect(deserializedSession.createdAt, equals(session.createdAt),
              reason: 'Iteration $i: createdAt mismatch');
          expect(deserializedSession.isActive, equals(session.isActive),
              reason: 'Iteration $i: isActive mismatch');
        }
      },
    );

    test('toMap converts RamadhanSession to Map correctly', () {
      final session = RamadhanSession(
        id: 1,
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        endDate: DateTime(2024, 4, 9),
        totalDays: 30,
        createdAt: DateTime(2024, 3, 1),
        isActive: true,
      );

      final map = session.toMap();

      expect(map['id'], equals(1));
      expect(map['year'], equals(2024));
      expect(map['start_date'], equals('2024-03-11T00:00:00.000'));
      expect(map['end_date'], equals('2024-04-09T00:00:00.000'));
      expect(map['total_days'], equals(30));
      expect(map['created_at'], equals('2024-03-01T00:00:00.000'));
      expect(map['is_active'], equals(1));
    });

    test('fromMap creates RamadhanSession from Map correctly', () {
      final map = {
        'id': 1,
        'year': 2024,
        'start_date': '2024-03-11T00:00:00.000',
        'end_date': '2024-04-09T00:00:00.000',
        'total_days': 30,
        'created_at': '2024-03-01T00:00:00.000',
        'is_active': 1,
      };

      final session = RamadhanSession.fromMap(map);

      expect(session.id, equals(1));
      expect(session.year, equals(2024));
      expect(session.startDate, equals(DateTime(2024, 3, 11)));
      expect(session.endDate, equals(DateTime(2024, 4, 9)));
      expect(session.totalDays, equals(30));
      expect(session.createdAt, equals(DateTime(2024, 3, 1)));
      expect(session.isActive, equals(true));
    });

    test('copyWith creates a new instance with updated fields', () {
      final session = RamadhanSession(
        id: 1,
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        endDate: DateTime(2024, 4, 9),
        totalDays: 30,
        createdAt: DateTime(2024, 3, 1),
        isActive: true,
      );

      final updatedSession = session.copyWith(isActive: false);

      expect(updatedSession.id, equals(1));
      expect(updatedSession.year, equals(2024));
      expect(updatedSession.isActive, equals(false));
    });

    test('equality operator works correctly', () {
      final session1 = RamadhanSession(
        id: 1,
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        endDate: DateTime(2024, 4, 9),
        totalDays: 30,
        createdAt: DateTime(2024, 3, 1),
        isActive: true,
      );

      final session2 = RamadhanSession(
        id: 1,
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        endDate: DateTime(2024, 4, 9),
        totalDays: 30,
        createdAt: DateTime(2024, 3, 1),
        isActive: true,
      );

      expect(session1, equals(session2));
    });
  });
}
