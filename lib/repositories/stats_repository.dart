import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_stats.dart';

/// Repository for managing user statistics
/// Handles CRUD operations for stats and XP/streak updates
class StatsRepository {
  final DatabaseHelper _dbHelper;

  StatsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Get stats for a specific session
  /// Returns null if no stats exist for the session
  Future<UserStats?> getStatsForSession(int sessionId) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'user_stats',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserStats.fromMap(maps.first);
  }

  /// Update stats for a session
  /// Creates new stats if they don't exist, updates if they do
  Future<UserStats> updateStats(UserStats stats) async {
    final db = await _dbHelper.database;

    if (stats.id == null) {
      // Insert new stats
      final id = await db.insert(
        'user_stats',
        stats.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return stats.copyWith(id: id);
    } else {
      // Update existing stats
      await db.update(
        'user_stats',
        stats.toMap(),
        where: 'id = ?',
        whereArgs: [stats.id],
      );
      return stats;
    }
  }

  /// Add XP to a session's stats
  /// Creates initial stats if they don't exist
  Future<UserStats> addXp(int sessionId, int xpAmount) async {
    final db = await _dbHelper.database;

    // Get current stats or create default
    var stats = await getStatsForSession(sessionId);
    
    if (stats == null) {
      // Create initial stats
      stats = UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
    }

    // Add XP
    final newTotalXp = stats.totalXp + xpAmount;
    
    // Calculate new level (level = sqrt(totalXp / 100))
    // Using the formula: required XP = level * level * 100
    // So level = sqrt(totalXp / 100)
    var newLevel = stats.level;
    while (newLevel * newLevel * 100 <= newTotalXp) {
      newLevel++;
    }
    newLevel--; // Go back one since we went one too far

    // Ensure level is at least 1
    if (newLevel < 1) newLevel = 1;

    // Update stats
    final updatedStats = stats.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
    );

    return await updateStats(updatedStats);
  }

  /// Update streak values for a session
  /// Only updates the streaks that are provided (non-null)
  Future<UserStats> updateStreaks(
    int sessionId, {
    int? currentStreak,
    int? longestStreak,
    int? prayerStreak,
    int? tilawahStreak,
  }) async {
    // Get current stats
    var stats = await getStatsForSession(sessionId);
    
    if (stats == null) {
      // Create initial stats if they don't exist
      stats = UserStats(
        sessionId: sessionId,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
    }

    // Update only the provided streaks
    final updatedStats = stats.copyWith(
      currentStreak: currentStreak ?? stats.currentStreak,
      longestStreak: longestStreak ?? stats.longestStreak,
      prayerStreak: prayerStreak ?? stats.prayerStreak,
      tilawahStreak: tilawahStreak ?? stats.tilawahStreak,
    );

    return await updateStats(updatedStats);
  }
}
