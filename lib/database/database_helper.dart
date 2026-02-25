import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper class for managing SQLite database operations
/// Implements singleton pattern to ensure single database instance
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance, initialize if not exists
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('myramadhan.db');
    return _database!;
  }

  /// Initialize database with schema
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create all database tables and indexes
  Future<void> _createDB(Database db, int version) async {
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
  }

  /// Close database connection
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  /// Delete database (useful for testing)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'myramadhan.db');
    await deleteDatabase(path);
    _database = null;
  }
}
