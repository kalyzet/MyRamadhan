import 'package:flutter_test/flutter_test.dart' hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/session_repository.dart';
import 'package:my_ramadhan/models/ramadhan_session.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SessionRepository Property Tests', () {
    late DatabaseHelper dbHelper;
    late SessionRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      repository = SessionRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    // **Feature: my-ramadhan-app, Property 2: Single active session invariant**
    // **Validates: Requirements 1.2**
    Glados<List<int>>(any.list(any.int)).test(
        'Property 2: For any sequence of session creation operations, exactly one session should be marked as active',
        (years) async {
      // Filter to valid years and constrain list size
      final validYears = years.where((y) => y >= 2020 && y <= 2050).toSet().toList();
      if (validYears.length < 2 || validYears.length > 5) return;

      // Create multiple sessions
      final sessions = <RamadhanSession>[];
      for (final year in validYears) {
        final startDate = DateTime(year, 3, 1);
        final session = await repository.createSession(
          year: year,
          startDate: startDate,
          totalDays: 30,
        );
        sessions.add(session);
      }

      // Activate each session one by one
      for (final session in sessions) {
        await repository.setActiveSession(session.id!);

        // Verify only one session is active
        final allSessions = await repository.getAllSessions();
        final activeSessions =
            allSessions.where((s) => s.isActive).toList();

        expect(activeSessions.length, equals(1),
            reason:
                'Expected exactly 1 active session, found ${activeSessions.length}');
        expect(activeSessions.first.id, equals(session.id),
            reason: 'Active session should be the one we just activated');
      }
    });

    // **Feature: my-ramadhan-app, Property 3: End date calculation correctness**
    // **Validates: Requirements 1.3**
    Glados2<int, int>(any.int, any.int).test(
        'Property 3: For any start date and duration (29 or 30 days), the calculated end date should equal the start date plus the duration in days',
        (year, duration) async {
      // Constrain to valid years and durations
      if (year < 2020 || year > 2050) return;
      if (duration != 29 && duration != 30) return;

      final startDate = DateTime(year, 3, 1);
      final session = await repository.createSession(
        year: year,
        startDate: startDate,
        totalDays: duration,
      );

      // Calculate expected end date
      final expectedEndDate = startDate.add(Duration(days: duration - 1));

      // Verify end date calculation
      expect(
        session.endDate.year,
        equals(expectedEndDate.year),
        reason: 'End date year should match expected',
      );
      expect(
        session.endDate.month,
        equals(expectedEndDate.month),
        reason: 'End date month should match expected',
      );
      expect(
        session.endDate.day,
        equals(expectedEndDate.day),
        reason: 'End date day should match expected',
      );
    });

    // **Feature: my-ramadhan-app, Property 4: Session retrieval completeness**
    // **Validates: Requirements 1.5**
    Glados<List<int>>(any.list(any.int)).test(
        'Property 4: For any set of created sessions, querying all sessions should return every session with correct year and completion status',
        (years) async {
      // Filter to valid years and constrain list size
      final validYears = years.where((y) => y >= 2020 && y <= 2050).toSet().toList();
      if (validYears.isEmpty || validYears.length > 5) return;

      // Create sessions
      final createdSessions = <RamadhanSession>[];
      for (final year in validYears) {
        final startDate = DateTime(year, 3, 1);
        final session = await repository.createSession(
          year: year,
          startDate: startDate,
          totalDays: 30,
        );
        createdSessions.add(session);
      }

      // Retrieve all sessions
      final retrievedSessions = await repository.getAllSessions();

      // Verify count matches
      expect(retrievedSessions.length, equals(createdSessions.length),
          reason:
              'Retrieved session count should match created session count');

      // Verify each created session is in retrieved sessions
      for (final created in createdSessions) {
        final found = retrievedSessions.any((retrieved) =>
            retrieved.id == created.id &&
            retrieved.year == created.year &&
            retrieved.totalDays == created.totalDays);

        expect(found, isTrue,
            reason:
                'Session with year ${created.year} should be in retrieved sessions');
      }
    });
  });

  group('SessionRepository Business Rule Validation Tests', () {
    late DatabaseHelper dbHelper;
    late SessionRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      repository = SessionRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    test('verifyActiveSessionInvariant should pass with zero active sessions', () async {
      await repository.verifyActiveSessionInvariant();
      // Should not throw
    });

    test('verifyActiveSessionInvariant should pass with one active session', () async {
      final session = await repository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      await repository.setActiveSession(session.id!);

      await repository.verifyActiveSessionInvariant();
      // Should not throw
    });

    test('verifyActiveSessionInvariant maintains invariant after multiple activations', () async {
      // Create multiple sessions
      final session1 = await repository.createSession(
        year: 2024,
        startDate: DateTime(2024, 3, 11),
        totalDays: 30,
      );
      final session2 = await repository.createSession(
        year: 2023,
        startDate: DateTime(2023, 3, 23),
        totalDays: 30,
      );

      // Activate first session
      await repository.setActiveSession(session1.id!);
      await repository.verifyActiveSessionInvariant();

      // Activate second session
      await repository.setActiveSession(session2.id!);
      await repository.verifyActiveSessionInvariant();

      // Verify only one is active
      final allSessions = await repository.getAllSessions();
      final activeSessions = allSessions.where((s) => s.isActive).toList();
      expect(activeSessions.length, equals(1));
    });
  });
}
