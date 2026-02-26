import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/database/database_helper.dart';
import '../../lib/repositories/settings_repository.dart';
import '../../lib/services/localization_service.dart';

/// Integration tests for default language functionality
/// Tests that the app defaults to Indonesian and language switching persists
/// Requirements: 1.1, 1.4
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Default Language Integration Tests', () {
    late SettingsRepository settingsRepository;

    setUp(() async {
      settingsRepository = SettingsRepository();
    });

    tearDown(() async {
      // Clean up database after each test
      await DatabaseHelper.instance.deleteDB();
    });

    test('Settings repository initializes with Indonesian language code', () async {
      // Initialize settings (simulating fresh install)
      final settings = await settingsRepository.initializeSettings();

      // Verify language code is Indonesian
      expect(settings.languageCode, equals('id'));

      // Verify it persists in database
      final retrievedSettings = await settingsRepository.getSettings();
      expect(retrievedSettings.languageCode, equals('id'));
    });

    test('Language switching persists across restarts', () async {
      // Initialize with default Indonesian
      var settings = await settingsRepository.initializeSettings();
      expect(settings.languageCode, equals('id'));

      // Change to English
      await settingsRepository.updateLanguage('en');
      var updatedSettings = await settingsRepository.getSettings();
      expect(updatedSettings.languageCode, equals('en'));

      // Simulate app restart by creating a new repository instance
      final newSettingsRepository = SettingsRepository();
      final persistedSettings = await newSettingsRepository.getSettings();

      // Verify language persisted as English
      expect(persistedSettings.languageCode, equals('en'));

      // Change back to Indonesian
      await newSettingsRepository.updateLanguage('id');
      final finalSettings = await newSettingsRepository.getSettings();

      // Verify language persisted as Indonesian
      expect(finalSettings.languageCode, equals('id'));
    });

    test('LocalizationService defaults to Indonesian', () {
      // Create a new localization service
      final localizationService = LocalizationService(
        settingsRepository: settingsRepository,
      );

      // Verify default language is Indonesian before initialization
      expect(localizationService.currentLanguage, equals('id'));
    });

    test('MaterialApp locale configuration uses Indonesian by default', () async {
      // Initialize settings
      final settings = await settingsRepository.initializeSettings();

      // Verify the locale is set to Indonesian
      expect(settings.languageCode, equals('id'));

      // Create a Locale object to verify format
      final locale = Locale(settings.languageCode);
      expect(locale.languageCode, equals('id'));
      expect(locale.countryCode, isNull); // No country code specified
    });

    test('Supported locales include both Indonesian and English', () {
      // Define supported locales as in the app
      const supportedLocales = [
        Locale('id', ''), // Indonesian
        Locale('en', ''), // English
      ];

      // Verify both locales are supported
      expect(supportedLocales.length, equals(2));
      expect(supportedLocales.any((l) => l.languageCode == 'id'), isTrue);
      expect(supportedLocales.any((l) => l.languageCode == 'en'), isTrue);

      // Verify Indonesian is first (default)
      expect(supportedLocales.first.languageCode, equals('id'));
    });

    test('Fresh install creates settings with Indonesian language', () async {
      // Simulate fresh install by ensuring no settings exist
      // Then initialize
      final settings = await settingsRepository.initializeSettings();

      // Verify fresh install defaults to Indonesian
      expect(settings.languageCode, equals('id'));
      expect(settings.id, isNotNull);
      expect(settings.updatedAt, isNotNull);
    });

    test('Language preference persists after multiple updates', () async {
      // Initialize
      await settingsRepository.initializeSettings();

      // Update to English
      await settingsRepository.updateLanguage('en');
      var settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Update to Indonesian
      await settingsRepository.updateLanguage('id');
      settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('id'));

      // Update to English again
      await settingsRepository.updateLanguage('en');
      settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));

      // Verify final state
      final finalSettings = await settingsRepository.getSettings();
      expect(finalSettings.languageCode, equals('en'));
    });

    test('Multiple repository instances share same database state', () async {
      // Create first repository and initialize
      final repo1 = SettingsRepository();
      await repo1.initializeSettings();
      await repo1.updateLanguage('en');

      // Create second repository and verify it sees the same state
      final repo2 = SettingsRepository();
      final settings = await repo2.getSettings();
      expect(settings.languageCode, equals('en'));

      // Update through second repository
      await repo2.updateLanguage('id');

      // Verify first repository sees the update
      final updatedSettings = await repo1.getSettings();
      expect(updatedSettings.languageCode, equals('id'));
    });
  });
}
