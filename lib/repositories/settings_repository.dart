import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../exceptions/database_exception.dart' as app_exceptions;

/// Repository for managing application settings
class SettingsRepository {
  final DatabaseHelper _dbHelper;

  SettingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Get current application settings
  /// Returns the first settings record, or creates default if none exists
  Future<AppSettings> getSettings() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'app_settings',
        limit: 1,
      );

      if (maps.isEmpty) {
        // Initialize default settings if none exist
        return await initializeSettings();
      }

      return AppSettings.fromMap(maps.first);
    } catch (e) {
      throw app_exceptions.DatabaseException.general(
        message: 'Failed to get settings',
        originalError: e,
      );
    }
  }

  /// Update the language preference
  /// Updates the first settings record or creates one if none exists
  Future<void> updateLanguage(String languageCode) async {
    try {
      final db = await _dbHelper.database;

      // Check if settings exist
      final List<Map<String, dynamic>> existing = await db.query(
        'app_settings',
        limit: 1,
      );

      final updatedAt = DateTime.now().toIso8601String();

      if (existing.isEmpty) {
        // Create new settings record
        await db.insert('app_settings', {
          'language_code': languageCode,
          'updated_at': updatedAt,
        });
      } else {
        // Update existing settings
        await db.update(
          'app_settings',
          {
            'language_code': languageCode,
            'updated_at': updatedAt,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    } catch (e) {
      throw app_exceptions.DatabaseException.general(
        message: 'Failed to update language',
        originalError: e,
      );
    }
  }

  /// Initialize default settings with English as default language
  /// Creates a new settings record with 'en' as the language code
  Future<AppSettings> initializeSettings() async {
    try {
      final db = await _dbHelper.database;

      final now = DateTime.now();
      final id = await db.insert('app_settings', {
        'language_code': 'en',
        'updated_at': now.toIso8601String(),
      });

      return AppSettings(
        id: id,
        languageCode: 'en',
        updatedAt: now,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException.general(
        message: 'Failed to initialize settings',
        originalError: e,
      );
    }
  }
}
