import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/achievement.dart';

/// Repository for managing achievements
/// Handles CRUD operations and achievement unlocking
/// 
/// Performance optimizations (Requirements: 9.3):
/// - SQLite automatically uses prepared statements for all queries
/// - Index on session_id column improves query performance
/// - Batch operations for initializing multiple achievements
class AchievementRepository {
  final DatabaseHelper _dbHelper;

  AchievementRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Get all achievements for a session
  Future<List<Achievement>> getAchievementsForSession(int sessionId) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      return Achievement.fromMap(maps[i]);
    });
  }

  /// Unlock an achievement by setting unlocked flag and recording unlock date
  Future<void> unlockAchievement(int achievementId) async {
    final db = await _dbHelper.database;

    await db.update(
      'achievements',
      {
        'unlocked': 1,
        'unlocked_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [achievementId],
    );
  }

  /// Initialize default achievements for a new session
  /// Creates the standard set of achievements that users can unlock
  Future<void> initializeAchievements(int sessionId) async {
    final db = await _dbHelper.database;

    // Define default achievements with translation keys
    final achievements = [
      Achievement(
        sessionId: sessionId,
        title: 'achievements.first_day.title',
        description: 'achievements.first_day.description',
        unlocked: false,
        iconName: 'first_day',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'achievements.seven_days.title',
        description: 'achievements.seven_days.description',
        unlocked: false,
        iconName: 'seven_days',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'achievements.quran_100.title',
        description: 'achievements.quran_100.description',
        unlocked: false,
        iconName: 'quran_100',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'achievements.master.title',
        description: 'achievements.master.description',
        unlocked: false,
        iconName: 'master',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'achievements.prayer_warrior.title',
        description: 'achievements.prayer_warrior.description',
        unlocked: false,
        iconName: 'prayer_warrior',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'achievements.generous.title',
        description: 'achievements.generous.description',
        unlocked: false,
        iconName: 'generous',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'achievements.night_prayer.title',
        description: 'achievements.night_prayer.description',
        unlocked: false,
        iconName: 'night_prayer',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'achievements.quran_complete.title',
        description: 'achievements.quran_complete.description',
        unlocked: false,
        iconName: 'quran_complete',
      ),
    ];

    // Insert all achievements
    final batch = db.batch();
    for (final achievement in achievements) {
      batch.insert(
        'achievements',
        achievement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
