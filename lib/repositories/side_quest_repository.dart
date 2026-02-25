import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/side_quest.dart';

/// Repository for managing side quests
/// Handles CRUD operations and daily quest generation
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

    // Define quest pool
    final questPool = [
      {
        'title': 'Early Bird',
        'description': 'Pray Fajr within 15 minutes of Adhan',
        'xp_reward': 25,
      },
      {
        'title': 'Quran Scholar',
        'description': 'Read 5 pages of Quran with translation',
        'xp_reward': 30,
      },
      {
        'title': 'Generous Soul',
        'description': 'Give sedekah to 3 different people',
        'xp_reward': 40,
      },
      {
        'title': 'Community Helper',
        'description': 'Help prepare iftar for others',
        'xp_reward': 35,
      },
      {
        'title': 'Dhikr Master',
        'description': 'Recite Subhanallah 100 times',
        'xp_reward': 20,
      },
      {
        'title': 'Night Warrior',
        'description': 'Pray Tahajjud before Fajr',
        'xp_reward': 45,
      },
      {
        'title': 'Dua Specialist',
        'description': 'Make dua for 10 different people',
        'xp_reward': 25,
      },
      {
        'title': 'Knowledge Seeker',
        'description': 'Attend or watch an Islamic lecture',
        'xp_reward': 30,
      },
      {
        'title': 'Family Bond',
        'description': 'Break fast with family or friends',
        'xp_reward': 20,
      },
      {
        'title': 'Patience Practice',
        'description': 'Control anger and speak kindly all day',
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
        title: questData['title'] as String,
        description: questData['description'] as String,
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
