import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/achievement.dart';

/// Repository for managing achievements
/// Handles CRUD operations and achievement unlocking
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

    // Define default achievements
    final achievements = [
      Achievement(
        sessionId: sessionId,
        title: 'First Day Completed',
        description: 'Complete your first day of Ramadhan',
        unlocked: false,
        iconName: 'first_day',
      ),
      Achievement(
        sessionId: sessionId,
        title: '7 Day Consistency',
        description: 'Maintain a 7-day perfect streak',
        unlocked: false,
        iconName: 'seven_days',
      ),
      Achievement(
        sessionId: sessionId,
        title: '100 Quran Pages',
        description: 'Read 100 pages of the Quran',
        unlocked: false,
        iconName: 'quran_100',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Ramadhan Master',
        description: 'Complete all 30 days with perfect records',
        unlocked: false,
        iconName: 'master',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Prayer Warrior',
        description: 'Complete all 5 prayers for 15 consecutive days',
        unlocked: false,
        iconName: 'prayer_warrior',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Generous Heart',
        description: 'Give sedekah for 20 days',
        unlocked: false,
        iconName: 'generous',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Night Worshipper',
        description: 'Complete tarawih for 25 days',
        unlocked: false,
        iconName: 'night_prayer',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Quran Completion',
        description: 'Read all 604 pages of the Quran',
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
