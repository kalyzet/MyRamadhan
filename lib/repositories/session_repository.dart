import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/ramadhan_session.dart';

/// Repository for managing Ramadhan sessions
/// Handles CRUD operations and session activation logic
class SessionRepository {
  final DatabaseHelper _dbHelper;

  SessionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Create a new Ramadhan session
  /// Automatically calculates end date based on start date and duration
  /// Supports mid-Ramadhan start with currentDayNumber parameter
  Future<RamadhanSession> createSession({
    required int year,
    required DateTime startDate,
    required int totalDays,
    int? currentDayNumber,
  }) async {
    final db = await _dbHelper.database;

    // Calculate end date
    final endDate = startDate.add(Duration(days: totalDays - 1));

    // Create session object
    final session = RamadhanSession(
      year: year,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      createdAt: DateTime.now(),
      isActive: false, // Will be set to active after deactivating others
    );

    // Insert into database
    final id = await db.insert(
      'ramadhan_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    // Return session with generated id
    return session.copyWith(id: id);
  }

  /// Get the currently active session
  /// Returns null if no session is active
  Future<RamadhanSession?> getActiveSession() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'ramadhan_sessions',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return RamadhanSession.fromMap(maps.first);
  }

  /// Get all sessions ordered by year descending
  Future<List<RamadhanSession>> getAllSessions() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'ramadhan_sessions',
      orderBy: 'year DESC',
    );

    return List.generate(maps.length, (i) {
      return RamadhanSession.fromMap(maps[i]);
    });
  }

  /// Deactivate all sessions
  /// Used before activating a new session to maintain single active session invariant
  Future<void> deactivateAllSessions() async {
    final db = await _dbHelper.database;

    await db.update(
      'ramadhan_sessions',
      {'is_active': 0},
      where: 'is_active = ?',
      whereArgs: [1],
    );
  }

  /// Set a specific session as active
  /// Automatically deactivates all other sessions first
  Future<void> setActiveSession(int sessionId) async {
    final db = await _dbHelper.database;

    // Use transaction to ensure atomicity
    await db.transaction((txn) async {
      // Deactivate all sessions
      await txn.update(
        'ramadhan_sessions',
        {'is_active': 0},
        where: 'is_active = ?',
        whereArgs: [1],
      );

      // Activate the specified session
      await txn.update(
        'ramadhan_sessions',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  }
}
