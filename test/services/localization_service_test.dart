import 'package:flutter_test/flutter_test.dart' hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/services/localization_service.dart';
import 'package:my_ramadhan/repositories/settings_repository.dart';
import 'package:my_ramadhan/database/database_helper.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalizationService', () {
    test('should initialize with default English language', () async {
      // **Feature: my-ramadhan-app, Property 39: Default language initialization**
      // **Validates: Requirements 14.1**
      
      // Use in-memory database to avoid file locking issues on Windows
      final dbHelper = DatabaseHelper.inMemory();
      
      // Ensure database is initialized by accessing it
      await dbHelper.database;

      final settingsRepository = SettingsRepository(dbHelper: dbHelper);
      final localizationService =
          LocalizationService(settingsRepository: settingsRepository);

      await localizationService.initialize();

      expect(localizationService.currentLanguage, equals('en'));

      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      await dbHelper.close();
    });

    test('should persist language preference after change', () async {
      // **Feature: my-ramadhan-app, Property 37: Language preference persistence**
      // **Validates: Requirements 14.4**
      
      // Use in-memory database to avoid file locking issues on Windows
      final dbHelper = DatabaseHelper.inMemory();
      
      // Ensure database is initialized by accessing it
      await dbHelper.database;

      final settingsRepository = SettingsRepository(dbHelper: dbHelper);
      
      // First, verify initial state is English
      final initialSettings = await settingsRepository.getSettings();
      expect(initialSettings.languageCode, equals('en'));
      
      // Change language to Indonesian
      await settingsRepository.updateLanguage('id');

      // Verify the change was persisted
      final updatedSettings = await settingsRepository.getSettings();
      expect(updatedSettings.languageCode, equals('id'));
      
      // Create a new repository instance to verify persistence across instances
      final newSettingsRepository = SettingsRepository(dbHelper: dbHelper);
      final persistedSettings = await newSettingsRepository.getSettings();
      expect(persistedSettings.languageCode, equals('id'));

      await dbHelper.close();
    });
  });
}
