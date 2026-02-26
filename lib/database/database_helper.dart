import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../exceptions/database_exception.dart' as app_exceptions;

/// Database helper class for managing SQLite database operations
/// Implements singleton pattern to ensure single database instance
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  DatabaseHelper._init();

  /// Get database instance, initialize if not exists
  /// Implements retry logic for transient errors
  Future<Database> get database async {
    if (_database != null) return _database!;

    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        _database = await _initDB('myramadhan.db');
        return _database!;
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          throw app_exceptions.DatabaseException.connection(originalError: e);
        }
        // Wait before retrying
        await Future.delayed(_retryDelay);
      }
    }

    throw app_exceptions.DatabaseException.connection(
        originalError: 'Max retries exceeded');
  }

  /// Initialize database with schema
  /// Wraps database operations with error handling
  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        singleInstance: false, // Allow multiple instances for testing
      );
    } catch (e) {
      throw app_exceptions.DatabaseException.connection(originalError: e);
    }
  }

  /// Create all database tables and indexes
  /// Wraps table creation with error handling
  Future<void> _createDB(Database db, int version) async {
    try {
      // Create ramadhan_sessions table
      await db.execute('''
      CREATE TABLE ramadhan_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        total_days INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0
      )
    ''');

      // Create daily_records table with individual prayer columns
      await db.execute('''
      CREATE TABLE daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        fajr_complete INTEGER NOT NULL DEFAULT 0,
        dhuhr_complete INTEGER NOT NULL DEFAULT 0,
        asr_complete INTEGER NOT NULL DEFAULT 0,
        maghrib_complete INTEGER NOT NULL DEFAULT 0,
        isha_complete INTEGER NOT NULL DEFAULT 0,
        puasa_complete INTEGER NOT NULL DEFAULT 0,
        tarawih_complete INTEGER NOT NULL DEFAULT 0,
        tilawah_pages INTEGER NOT NULL DEFAULT 0,
        dzikir_complete INTEGER NOT NULL DEFAULT 0,
        sedekah_amount REAL NOT NULL DEFAULT 0,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        is_perfect_day INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES ramadhan_sessions(id),
        UNIQUE(session_id, date)
      )
    ''');

      // Create user_stats table
      await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL UNIQUE,
        total_xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        prayer_streak INTEGER NOT NULL DEFAULT 0,
        tilawah_streak INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES ramadhan_sessions(id)
      )
    ''');

      // Create achievements table
      await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        unlocked INTEGER NOT NULL DEFAULT 0,
        unlocked_date TEXT,
        icon_name TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES ramadhan_sessions(id)
      )
    ''');

      // Create side_quests table
      await db.execute('''
      CREATE TABLE side_quests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        xp_reward INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES ramadhan_sessions(id)
      )
    ''');

      // Create indexes for performance optimization
      await db.execute('''
      CREATE INDEX idx_daily_records_session_id 
      ON daily_records(session_id)
    ''');

      await db.execute('''
      CREATE INDEX idx_daily_records_date 
      ON daily_records(date)
    ''');

      await db.execute('''
      CREATE INDEX idx_user_stats_session_id 
      ON user_stats(session_id)
    ''');

      await db.execute('''
      CREATE INDEX idx_achievements_session_id 
      ON achievements(session_id)
    ''');

      await db.execute('''
      CREATE INDEX idx_side_quests_session_id 
      ON side_quests(session_id)
    ''');

      await db.execute('''
      CREATE INDEX idx_side_quests_date 
      ON side_quests(date)
    ''');

      await db.execute('''
      CREATE INDEX idx_ramadhan_sessions_is_active 
      ON ramadhan_sessions(is_active)
    ''');
    } catch (e) {
      throw app_exceptions.DatabaseException.general(
        message: 'Failed to create database schema',
        originalError: e,
      );
    }
  }

  /// Close database connection
  /// Wraps close operation with error handling
  Future<void> close() async {
    try {
      final db = await instance.database;
      await db.close();
    } catch (e) {
      throw app_exceptions.DatabaseException.general(
        message: 'Failed to close database',
        originalError: e,
      );
    }
  }

  /// Delete database (useful for testing)
  /// Wraps delete operation with error handling
  Future<void> deleteDB() async {
    try {
      // Close the database first if it's open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Add a small delay to ensure the database is fully closed
      await Future.delayed(const Duration(milliseconds: 50));
      
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'myramadhan.db');
      
      // Try to delete with retries
      int retries = 0;
      while (retries < 3) {
        try {
          await deleteDatabase(path);
          break;
        } catch (e) {
          retries++;
          if (retries >= 3) rethrow;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      throw app_exceptions.DatabaseException.general(
        message: 'Failed to delete database',
        originalError: e,
      );
    }
  }
}
