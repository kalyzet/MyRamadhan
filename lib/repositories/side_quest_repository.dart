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

    // Define quest pool
    final questPool = [
      {
        'title': 'Burung Pagi',
        'description': 'Sholat Subuh dalam 15 menit setelah Adzan',
        'xp_reward': 25,
      },
      {
        'title': 'Ahli Al-Quran',
        'description': 'Baca 5 halaman Al-Quran dengan terjemahan',
        'xp_reward': 30,
      },
      {
        'title': 'Jiwa Dermawan',
        'description': 'Berikan sedekah kepada 3 orang berbeda',
        'xp_reward': 40,
      },
      {
        'title': 'Penolong Komunitas',
        'description': 'Bantu menyiapkan iftar untuk orang lain',
        'xp_reward': 35,
      },
      {
        'title': 'Master Dzikir',
        'description': 'Ucapkan Subhanallah 100 kali',
        'xp_reward': 20,
      },
      {
        'title': 'Pejuang Malam',
        'description': 'Sholat Tahajjud sebelum Subuh',
        'xp_reward': 45,
      },
      {
        'title': 'Spesialis Doa',
        'description': 'Berdoa untuk 10 orang berbeda',
        'xp_reward': 25,
      },
      {
        'title': 'Pencari Ilmu',
        'description': 'Hadiri atau tonton ceramah Islam',
        'xp_reward': 30,
      },
      {
        'title': 'Ikatan Keluarga',
        'description': 'Berbuka puasa bersama keluarga atau teman',
        'xp_reward': 20,
      },
      {
        'title': 'Latihan Kesabaran',
        'description': 'Kendalikan amarah dan berbicara baik sepanjang hari',
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
