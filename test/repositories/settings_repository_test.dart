import 'package:flutter_test/flutter_test.dart' hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/settings_repository.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SettingsRepository Property Tests', () {
    late DatabaseHelper dbHelper;
    late SettingsRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      repository = SettingsRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    // **Feature: indonesian-default-realtime-clock, Property 1: Default language initialization**
    // **Validates: Requirements 1.2**
    test(
        'Property 1: For any fresh installation without existing settings, initializing settings should result in language code being \'id\'',
        () async {
      // Test multiple fresh installations
      for (int i = 0; i < 10; i++) {
        // Ensure database is clean (fresh installation state)
        await dbHelper.deleteDB();
        
        // Create new repository instance
        final testRepository = SettingsRepository(dbHelper: dbHelper);

        // Initialize settings
        final settings = await testRepository.initializeSettings();

        // Verify language code is 'id'
        expect(settings.languageCode, equals('id'),
            reason: 'Default language code should be \'id\' for fresh installation (iteration $i)');

        // Verify it persists in database
        final retrievedSettings = await testRepository.getSettings();
        expect(retrievedSettings.languageCode, equals('id'),
            reason: 'Retrieved settings should also have \'id\' as language code (iteration $i)');
      }
    });
  });

  group('SettingsRepository Unit Tests', () {
    late DatabaseHelper dbHelper;
    late SettingsRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      repository = SettingsRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    test('initializeSettings returns \'id\' as default language', () async {
      final settings = await repository.initializeSettings();
      
      expect(settings.languageCode, equals('id'));
    });

    test('getSettings returns initialized settings with \'id\' when no settings exist', () async {
      final settings = await repository.getSettings();
      
      expect(settings.languageCode, equals('id'));
    });

    test('updateLanguage persists language preference', () async {
      // Initialize with default
      await repository.getSettings();
      
      // Update to English
      await repository.updateLanguage('en');
      
      // Verify it persisted
      final settings = await repository.getSettings();
      expect(settings.languageCode, equals('en'));
    });

    test('updateLanguage can switch back to Indonesian', () async {
      // Initialize with default
      await repository.getSettings();
      
      // Update to English
      await repository.updateLanguage('en');
      
      // Switch back to Indonesian
      await repository.updateLanguage('id');
      
      // Verify it persisted
      final settings = await repository.getSettings();
      expect(settings.languageCode, equals('id'));
    });
  });
}
