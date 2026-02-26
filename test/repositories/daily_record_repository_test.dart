import 'package:flutter_test/flutter_test.dart' hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/daily_record_repository.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/exceptions/validation_exception.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DailyRecordRepository Property Tests', () {
    late DatabaseHelper dbHelper;
    late DailyRecordRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      repository = DailyRecordRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    // **Feature: my-ramadhan-app, Property 8: Backdating validation rule**
    // **Validates: Requirements 2.8**
    Glados<int>(any.int).test(
        'Property 8: For any current date and past record date, modifications should be allowed if and only if the record date is within 2 days before the current date',
        (daysDifference) async {
      // Constrain to reasonable range
      if (daysDifference < -10 || daysDifference > 10) return;

      final currentDate = DateTime(2024, 3, 15);
      final recordDate = currentDate.subtract(Duration(days: daysDifference.abs()));

      final canModify = repository.canModifyRecord(recordDate, currentDate);

      // Should be able to modify if difference is 0, 1, or 2 days
      final expectedCanModify = daysDifference.abs() >= 0 && daysDifference.abs() <= 2;

      expect(canModify, equals(expectedCanModify),
          reason:
              'For $daysDifference days difference, expected canModify=$expectedCanModify but got $canModify');
    });
  });

  group('DailyRecordRepository Validation Tests', () {
    late DatabaseHelper dbHelper;
    late DailyRecordRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      repository = DailyRecordRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    test('createOrUpdateRecord should reject invalid tilawah pages', () async {
      final record = _createTestRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        tilawahPages: 700, // Invalid
      );

      expect(
        () => repository.createOrUpdateRecord(record),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createOrUpdateRecord should reject negative sedekah amount', () async {
      final record = _createTestRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        sedekahAmount: -10.0, // Invalid
      );

      expect(
        () => repository.createOrUpdateRecord(record),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createOrUpdateRecord should reject negative XP', () async {
      final record = _createTestRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        xpEarned: -100, // Invalid
      );

      expect(
        () => repository.createOrUpdateRecord(record),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createOrUpdateRecord should accept valid record', () async {
      final record = _createTestRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        tilawahPages: 10,
        sedekahAmount: 50.0,
        xpEarned: 200,
      );

      final saved = await repository.createOrUpdateRecord(record);
      expect(saved.id, isNotNull);
    });
  });
}

// Helper function to create test records
DailyRecord _createTestRecord({
  required int sessionId,
  required DateTime date,
  int tilawahPages = 0,
  double sedekahAmount = 0,
  int xpEarned = 0,
}) {
  return DailyRecord(
    sessionId: sessionId,
    date: date,
    fajrComplete: false,
    dhuhrComplete: false,
    asrComplete: false,
    maghribComplete: false,
    ishaComplete: false,
    puasaComplete: false,
    tarawihComplete: false,
    tilawahPages: tilawahPages,
    dzikirComplete: false,
    sedekahAmount: sedekahAmount,
    xpEarned: xpEarned,
    isPerfectDay: false,
  );
}
