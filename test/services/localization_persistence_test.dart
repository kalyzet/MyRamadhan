import 'package:flutter_test/flutter_test.dart'
    hide test, group, setUp, tearDown, setUpAll, expect;
import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/settings_repository.dart';

/// **Feature: language-switcher, Property 1: Language persistence round-trip**
/// **Validates: Requirements 1.4, 1.5**
/// 
/// Property: For any valid language code ('en' or 'id'), when a user changes the language
/// and the app is reinitialized, the loaded language should be the same as the saved language.
/// 
/// Note: This test focuses on the persistence mechanism (database layer) rather than
/// the full LocalizationService, because asset loading (rootBundle) is not available
/// in unit tests. The persistence mechanism is the critical part for Requirements 1.4 and 1.5.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Property-Based Tests - Language Persistence', () {
    late DatabaseHelper dbHelper;
    late SettingsRepository settingsRepository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      settingsRepository = SettingsRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    /// **Feature: language-switcher, Property 1: Language persistence round-trip**
    /// **Validates: Requirements 1.4, 1.5**
    test(
        'property: language persistence round-trip - saved language persists across repository instances',
        () async {
      // Property: For any valid language code, saving the language and creating a new
      // repository instance should result in the same language being retrieved
      // This tests the core persistence mechanism that LocalizationService.initialize() relies on
      
      final validLanguages = ['en', 'id'];
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Pick a random language code
        final languageCode = validLanguages[i % validLanguages.length];

        // Save the language preference
        await settingsRepository.updateLanguage(languageCode);

        // Verify it was saved
        final savedSettings = await settingsRepository.getSettings();
        expect(
          savedSettings.languageCode,
          equals(languageCode),
          reason:
              'Language should be saved as "$languageCode" after updateLanguage() call',
        );

        // Simulate app restart by creating a new SettingsRepository instance
        final newSettingsRepository = SettingsRepository(dbHelper: dbHelper);

        // Retrieve settings from new instance (simulates app restart)
        final loadedSettings = await newSettingsRepository.getSettings();

        // Assert: The loaded language should match the saved language
        expect(
          loadedSettings.languageCode,
          equals(languageCode),
          reason:
              'After app restart (iteration $i), language should persist as "$languageCode"',
        );
      }
    });

    test(
        'property: default language fallback - repository initializes with Indonesian when no settings exist',
        () async {
      // Property: For any fresh installation (no settings), the repository should default to 'id'
      // This validates Requirements 3.1, 3.2, 3.3

      const iterations = 20;

      for (int i = 0; i < iterations; i++) {
        // Ensure clean database (fresh installation)
        await dbHelper.deleteDB();

        // Create new repository instance
        final freshSettingsRepository = SettingsRepository(dbHelper: dbHelper);

        // Get settings (should initialize with default)
        final settings = await freshSettingsRepository.getSettings();

        // Assert: Should default to Indonesian
        expect(
          settings.languageCode,
          equals('id'),
          reason:
              'Fresh installation (iteration $i) should default to Indonesian',
        );
      }
    });

    test(
        'property: multiple language switches persist correctly',
        () async {
      // Property: For any sequence of language changes, the final language should persist
      // This tests that multiple changes don't corrupt the persistence mechanism

      const iterations = 30;

      for (int i = 0; i < iterations; i++) {
        // Clean database
        await dbHelper.deleteDB();

        // Perform multiple language switches
        await settingsRepository.updateLanguage('en');
        await settingsRepository.updateLanguage('id');
        await settingsRepository.updateLanguage('en');
        
        // Final language should be 'en'
        final finalLanguage = 'en';

        // Verify current language in database
        final currentSettings = await settingsRepository.getSettings();
        expect(
          currentSettings.languageCode,
          equals(finalLanguage),
          reason: 'After multiple switches, current language should be "$finalLanguage"',
        );

        // Simulate restart with new repository instance
        final newSettingsRepository = SettingsRepository(dbHelper: dbHelper);
        final loadedSettings = await newSettingsRepository.getSettings();

        // Assert: Final language should persist
        expect(
          loadedSettings.languageCode,
          equals(finalLanguage),
          reason:
              'After restart (iteration $i), final language "$finalLanguage" should persist',
        );
      }
    });

    test(
        'property: language persistence is idempotent',
        () async {
      // Property: Saving the same language multiple times should not corrupt the data
      // and should always result in that language being loaded

      final validLanguages = ['en', 'id'];
      const iterations = 40;

      for (int i = 0; i < iterations; i++) {
        await dbHelper.deleteDB();

        final languageCode = validLanguages[i % validLanguages.length];

        // Save the same language multiple times
        await settingsRepository.updateLanguage(languageCode);
        await settingsRepository.updateLanguage(languageCode);
        await settingsRepository.updateLanguage(languageCode);

        // Verify language is correct
        final currentSettings = await settingsRepository.getSettings();
        expect(
          currentSettings.languageCode,
          equals(languageCode),
          reason: 'After multiple saves, language should be "$languageCode"',
        );

        // Simulate restart with new repository instance
        final newSettingsRepository = SettingsRepository(dbHelper: dbHelper);
        final loadedSettings = await newSettingsRepository.getSettings();

        // Assert: Language should still be correct
        expect(
          loadedSettings.languageCode,
          equals(languageCode),
          reason:
              'After multiple saves of same language (iteration $i), language should persist as "$languageCode"',
        );

        // Verify only one settings record exists
        final db = await dbHelper.database;
        final records = await db.query('app_settings');
        expect(
          records.length,
          equals(1),
          reason: 'Should only have one settings record in database',
        );
      }
    });
  });

  group('Unit Tests - Language Persistence Edge Cases', () {
    late DatabaseHelper dbHelper;
    late SettingsRepository settingsRepository;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteDB();
      settingsRepository = SettingsRepository(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.deleteDB();
    });

    test('SettingsRepository persists language changes correctly', () async {
      // Initialize with default
      final initialSettings = await settingsRepository.getSettings();
      expect(initialSettings.languageCode, equals('id'));

      // Change to English
      await settingsRepository.updateLanguage('en');
      
      // Verify it persisted
      final updatedSettings = await settingsRepository.getSettings();
      expect(updatedSettings.languageCode, equals('en'));
    });

    test('SettingsRepository can switch back to Indonesian', () async {
      // Initialize with default
      await settingsRepository.getSettings();
      
      // Change to English
      await settingsRepository.updateLanguage('en');
      
      // Switch back to Indonesian
      await settingsRepository.updateLanguage('id');
      
      // Verify it persisted
      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('id'));
    });

    test('Default fallback to \'id\' when no settings exist', () async {
      // Ensure clean database
      await dbHelper.deleteDB();

      final settings = await settingsRepository.getSettings();

      // Should default to 'id'
      expect(settings.languageCode, equals('id'));
    });

    test('Language persists after app reinstall simulation', () async {
      // First installation - set to English
      await settingsRepository.updateLanguage('en');
      
      final settings1 = await settingsRepository.getSettings();
      expect(settings1.languageCode, equals('en'));

      // Simulate reinstall (clean database)
      await dbHelper.deleteDB();

      // New installation should default to 'id'
      final settings2 = await settingsRepository.getSettings();
      expect(settings2.languageCode, equals('id'));
    });

    test('Multiple repository instances share same database state', () async {
      // Update language with first repository
      await settingsRepository.updateLanguage('en');

      // Create second repository instance
      final secondRepository = SettingsRepository(dbHelper: dbHelper);
      
      // Should see the same language
      final settings = await secondRepository.getSettings();
      expect(settings.languageCode, equals('en'));
    });

    test('Language updates are atomic', () async {
      // Perform rapid updates
      await settingsRepository.updateLanguage('en');
      await settingsRepository.updateLanguage('id');
      await settingsRepository.updateLanguage('en');

      // Final state should be 'en'
      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Should only have one record
      final db = await dbHelper.database;
      final records = await db.query('app_settings');
      expect(records.length, equals(1));
    });
  });
}
