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

    // Define default achievements
    final achievements = [
      Achievement(
        sessionId: sessionId,
        title: 'Hari Pertama Selesai',
        description: 'Selesaikan hari pertama Ramadhan Anda',
        unlocked: false,
        iconName: 'first_day',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Konsistensi 7 Hari',
        description: 'Pertahankan streak sempurna selama 7 hari',
        unlocked: false,
        iconName: 'seven_days',
      ),
      Achievement(
        sessionId: sessionId,
        title: '100 Halaman Al-Quran',
        description: 'Baca 100 halaman Al-Quran',
        unlocked: false,
        iconName: 'quran_100',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Master Ramadhan',
        description: 'Selesaikan semua 30 hari dengan catatan sempurna',
        unlocked: false,
        iconName: 'master',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Pejuang Sholat',
        description: 'Selesaikan semua 5 sholat selama 15 hari berturut-turut',
        unlocked: false,
        iconName: 'prayer_warrior',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Hati Dermawan',
        description: 'Berikan sedekah selama 20 hari',
        unlocked: false,
        iconName: 'generous',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Hamba Malam',
        description: 'Selesaikan tarawih selama 25 hari',
        unlocked: false,
        iconName: 'night_prayer',
      ),
      Achievement(
        sessionId: sessionId,
        title: 'Khatam Al-Quran',
        description: 'Baca semua 604 halaman Al-Quran',
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
