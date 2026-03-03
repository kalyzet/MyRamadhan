import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/side_quest.dart';

/// Repository for managing side quests
/// Handles CRUD operations and daily quest generation
/// 
/// Performance optimizations (Requirements: 9.3):
/// - SQLite automatically uses prepared statements for all queries
/// - Indexes on session_id and date columns improve query performance
/// - Batch operations for generating multiple daily quests
class SideQuestRepository {
  final DatabaseHelper _dbHelper;

  SideQuestRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Get side quests for a specific date
  Future<List<SideQuest>> getSideQuestsForDate(
      int sessionId, DateTime date) async {
    final db = await _dbHelper.database;

    // Normalize date to start of day
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final List<Map<String, dynamic>> maps = await db.query(
      'side_quests',
      where: 'session_id = ? AND date = ?',
      whereArgs: [sessionId, normalizedDate.toIso8601String()],
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      return SideQuest.fromMap(maps[i]);
    });
  }

  /// Complete a side quest by marking it as completed
  Future<void> completeSideQuest(int questId) async {
    final db = await _dbHelper.database;

    await db.update(
      'side_quests',
      {'completed': 1},
      where: 'id = ?',
      whereArgs: [questId],
    );
  }

  /// Generate daily side quests for a specific date
  /// Creates 3 random quests from a predefined pool
  Future<void> generateDailySideQuests(int sessionId, DateTime date) async {
    final db = await _dbHelper.database;

    // Normalize date to start of day
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check if quests already exist for this date
    final existing = await getSideQuestsForDate(sessionId, normalizedDate);
    if (existing.isNotEmpty) {
      return; // Quests already generated for this date
    }

    // Define quest pool with translation keys
    final questPool = [
      {
        'title_key': 'side_quests.early_bird.title',
        'description_key': 'side_quests.early_bird.description',
        'xp_reward': 25,
      },
      {
        'title_key': 'side_quests.quran_expert.title',
        'description_key': 'side_quests.quran_expert.description',
        'xp_reward': 30,
      },
      {
        'title_key': 'side_quests.generous_soul.title',
        'description_key': 'side_quests.generous_soul.description',
        'xp_reward': 40,
      },
      {
        'title_key': 'side_quests.community_helper.title',
        'description_key': 'side_quests.community_helper.description',
        'xp_reward': 35,
      },
      {
        'title_key': 'side_quests.dhikr_master.title',
        'description_key': 'side_quests.dhikr_master.description',
        'xp_reward': 20,
      },
      {
        'title_key': 'side_quests.night_warrior.title',
        'description_key': 'side_quests.night_warrior.description',
        'xp_reward': 45,
      },
      {
        'title_key': 'side_quests.dua_specialist.title',
        'description_key': 'side_quests.dua_specialist.description',
        'xp_reward': 25,
      },
      {
        'title_key': 'side_quests.knowledge_seeker.title',
        'description_key': 'side_quests.knowledge_seeker.description',
        'xp_reward': 30,
      },
      {
        'title_key': 'side_quests.family_bond.title',
        'description_key': 'side_quests.family_bond.description',
        'xp_reward': 20,
      },
      {
        'title_key': 'side_quests.patience_training.title',
        'description_key': 'side_quests.patience_training.description',
        'xp_reward': 35,
      },
    ];

    // Select 3 random quests (using date as seed for consistency)
    final seed = normalizedDate.day + normalizedDate.month * 31;
    final selectedIndices = <int>[];
    
    // Simple pseudo-random selection based on date
    for (var i = 0; i < 3 && i < questPool.length; i++) {
      var index = (seed * (i + 1) * 7) % questPool.length;
      while (selectedIndices.contains(index)) {
        index = (index + 1) % questPool.length;
      }
      selectedIndices.add(index);
    }

    // Insert selected quests
    final batch = db.batch();
    for (final index in selectedIndices) {
      final questData = questPool[index];
      final quest = SideQuest(
        sessionId: sessionId,
        date: normalizedDate,
        title: questData['title_key'] as String,
        description: questData['description_key'] as String,
        xpReward: questData['xp_reward'] as int,
        completed: false,
      );
      batch.insert(
        'side_quests',
        quest.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
