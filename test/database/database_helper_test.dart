import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.deleteDB();
  });

  group('DatabaseHelper', () {
    test('should create database with all tables', () async {
      final db = await DatabaseHelper.instance.database;

      // Verify all tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('ramadhan_sessions'));
      expect(tableNames, contains('daily_records'));
      expect(tableNames, contains('user_stats'));
      expect(tableNames, contains('achievements'));
      expect(tableNames, contains('side_quests'));
    });

    test('should create ramadhan_sessions table with correct schema', () async {
      final db = await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        "PRAGMA table_info(ramadhan_sessions)",
      );

      final columnNames = result.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('year'));
      expect(columnNames, contains('start_date'));
      expect(columnNames, contains('end_date'));
      expect(columnNames, contains('total_days'));
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('is_active'));
    });

    test('should create daily_records table with individual prayer columns',
        () async {
      final db = await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        "PRAGMA table_info(daily_records)",
      );

      final columnNames = result.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('session_id'));
      expect(columnNames, contains('date'));
      expect(columnNames, contains('fajr_complete'));
      expect(columnNames, contains('dhuhr_complete'));
      expect(columnNames, contains('asr_complete'));
      expect(columnNames, contains('maghrib_complete'));
      expect(columnNames, contains('isha_complete'));
      expect(columnNames, contains('puasa_complete'));
      expect(columnNames, contains('tarawih_complete'));
      expect(columnNames, contains('tilawah_pages'));
      expect(columnNames, contains('dzikir_complete'));
      expect(columnNames, contains('sedekah_amount'));
      expect(columnNames, contains('xp_earned'));
      expect(columnNames, contains('is_perfect_day'));
    });

    test('should create user_stats table with correct schema', () async {
      final db = await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        "PRAGMA table_info(user_stats)",
      );

      final columnNames = result.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('session_id'));
      expect(columnNames, contains('total_xp'));
      expect(columnNames, contains('level'));
      expect(columnNames, contains('current_streak'));
      expect(columnNames, contains('longest_streak'));
      expect(columnNames, contains('prayer_streak'));
      expect(columnNames, contains('tilawah_streak'));
    });

    test('should create achievements table with correct schema', () async {
      final db = await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        "PRAGMA table_info(achievements)",
      );

      final columnNames = result.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('session_id'));
      expect(columnNames, contains('title'));
      expect(columnNames, contains('description'));
      expect(columnNames, contains('unlocked'));
      expect(columnNames, contains('unlocked_date'));
      expect(columnNames, contains('icon_name'));
    });

    test('should create side_quests table with correct schema', () async {
      final db = await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        "PRAGMA table_info(side_quests)",
      );

      final columnNames = result.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('session_id'));
      expect(columnNames, contains('date'));
      expect(columnNames, contains('title'));
      expect(columnNames, contains('description'));
      expect(columnNames, contains('xp_reward'));
      expect(columnNames, contains('completed'));
    });

    test('should create indexes for session_id and date columns', () async {
      final db = await DatabaseHelper.instance.database;

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' ORDER BY name",
      );

      final indexNames = indexes.map((i) => i['name'] as String).toList();

      expect(indexNames, contains('idx_daily_records_session_id'));
      expect(indexNames, contains('idx_daily_records_date'));
      expect(indexNames, contains('idx_user_stats_session_id'));
      expect(indexNames, contains('idx_achievements_session_id'));
      expect(indexNames, contains('idx_side_quests_session_id'));
      expect(indexNames, contains('idx_side_quests_date'));
      expect(indexNames, contains('idx_ramadhan_sessions_is_active'));
    });

    test('should enforce unique constraint on session_id and date', () async {
      final db = await DatabaseHelper.instance.database;

      // Insert a session first
      final sessionId = await db.insert('ramadhan_sessions', {
        'year': 2024,
        'start_date': '2024-03-11',
        'end_date': '2024-04-09',
        'total_days': 30,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      });

      // Insert first daily record
      await db.insert('daily_records', {
        'session_id': sessionId,
        'date': '2024-03-11',
        'fajr_complete': 1,
      });

      // Try to insert duplicate - should throw
      expect(
        () async => await db.insert('daily_records', {
          'session_id': sessionId,
          'date': '2024-03-11',
          'dhuhr_complete': 1,
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('should enforce unique constraint on user_stats session_id',
        () async {
      final db = await DatabaseHelper.instance.database;

      // Insert a session first
      final sessionId = await db.insert('ramadhan_sessions', {
        'year': 2024,
        'start_date': '2024-03-11',
        'end_date': '2024-04-09',
        'total_days': 30,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      });

      // Insert first user_stats
      await db.insert('user_stats', {
        'session_id': sessionId,
        'total_xp': 100,
        'level': 1,
      });

      // Try to insert duplicate - should throw
      expect(
        () async => await db.insert('user_stats', {
          'session_id': sessionId,
          'total_xp': 200,
          'level': 2,
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}
