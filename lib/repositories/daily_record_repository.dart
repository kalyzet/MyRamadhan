import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/daily_record.dart';

/// Repository for managing daily records
/// Handles CRUD operations and backdating validation
class DailyRecordRepository {
  final DatabaseHelper _dbHelper;

  DailyRecordRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Create or update a daily record
  /// Uses REPLACE conflict algorithm to handle updates
  Future<DailyRecord> createOrUpdateRecord(DailyRecord record) async {
    final db = await _dbHelper.database;

    final id = await db.insert(
      'daily_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // If record had no id, return with new id
    if (record.id == null) {
      return record.copyWith(id: id);
    }

    // Otherwise return the record as-is
    return record;
  }

  /// Get a daily record for a specific date and session
  Future<DailyRecord?> getRecordByDate(int sessionId, DateTime date) async {
    final db = await _dbHelper.database;

    // Normalize date to start of day for comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_records',
      where: 'session_id = ? AND date = ?',
      whereArgs: [sessionId, normalizedDate.toIso8601String()],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return DailyRecord.fromMap(maps.first);
  }

  /// Get all records for a session, ordered by date ascending
  Future<List<DailyRecord>> getRecordsForSession(int sessionId) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) {
      return DailyRecord.fromMap(maps[i]);
    });
  }

  /// Check if a record can be modified based on backdating rules
  /// Records can only be modified if they are within 2 days of current date
  /// (H-1 and H-2, where H is current day)
  bool canModifyRecord(DateTime recordDate, DateTime currentDate) {
    // Normalize dates to start of day
    final normalizedRecordDate =
        DateTime(recordDate.year, recordDate.month, recordDate.day);
    final normalizedCurrentDate =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    // Calculate difference in days
    final difference =
        normalizedCurrentDate.difference(normalizedRecordDate).inDays;

    // Can modify if difference is 0 (today), 1 (H-1), or 2 (H-2)
    return difference >= 0 && difference <= 2;
  }

  /// Recalculate streaks from a specific date forward
  /// This is called when a past record is modified
  /// Note: Actual streak calculation logic is in StreakTrackerService
  /// This method is a placeholder for future implementation
  Future<void> recalculateStreaksFromDate(
      int sessionId, DateTime fromDate) async {
    // This will be implemented when StreakTrackerService is created
    // For now, this is a placeholder that does nothing
    // The actual implementation will:
    // 1. Get all records from fromDate onwards
    // 2. Recalculate streaks based on consecutive completions
    // 3. Update user_stats table with new streak values
  }
}
