import 'dart:convert';
import 'package:flutter/services.dart';
import '../repositories/settings_repository.dart';

/// Service for managing application localization
/// Loads and provides translations for UI text
class LocalizationService {
  String _currentLanguage = 'id';
  Map<String, dynamic> _translations = {};
  final SettingsRepository _settingsRepository;

  LocalizationService({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? SettingsRepository();

  /// Get current language code
  String get currentLanguage => _currentLanguage;

  /// Load language translations from JSON file
  /// Loads the appropriate translation file based on language code
  Future<void> loadLanguage(String languageCode) async {
    try {
      // Load the JSON file from assets
      final String jsonString =
          await rootBundle.loadString('lib/l10n/$languageCode.json');

      // Parse JSON
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      _currentLanguage = languageCode;
    } catch (e) {
      // If loading fails, fall back to Indonesian first, then English
      if (languageCode == 'id') {
        // If Indonesian fails, try English
        try {
          final String jsonString =
              await rootBundle.loadString('lib/l10n/en.json');
          _translations = json.decode(jsonString) as Map<String, dynamic>;
          _currentLanguage = 'en';
        } catch (e) {
          // If both fail, use empty translations with Indonesian as default
          _translations = {};
          _currentLanguage = 'id';
        }
      } else if (languageCode == 'en') {
        // If English fails, try Indonesian
        try {
          final String jsonString =
              await rootBundle.loadString('lib/l10n/id.json');
          _translations = json.decode(jsonString) as Map<String, dynamic>;
          _currentLanguage = 'id';
        } catch (e) {
          // If both fail, use empty translations with Indonesian as default
          _translations = {};
          _currentLanguage = 'id';
        }
      } else {
        // For any other language, fall back to Indonesian
        await loadLanguage('id');
      }
    }
  }

  /// Translate a key to the current language
  /// Supports nested keys using dot notation (e.g., 'home.title')
  /// Returns the key itself if translation is not found
  String translate(String key) {
    try {
      // Split the key by dots for nested access
      final keys = key.split('.');
      dynamic value = _translations;

      // Navigate through nested maps
      for (final k in keys) {
        if (value is Map<String, dynamic> && value.containsKey(k)) {
          value = value[k];
        } else {
          // Key not found, return the key itself
          return key;
        }
      }

      // Return the translated string
      return value.toString();
    } catch (e) {
      // If any error occurs, return the key itself
      return key;
    }
  }

  /// Change language and persist the preference
  /// Updates the language in settings repository and reloads translations
  Future<void> changeLanguage(String languageCode) async {
    try {
      // Validate language code
      if (languageCode != 'en' && languageCode != 'id') {
        throw ArgumentError('Unsupported language code: $languageCode');
      }

      // Load the new language
      await loadLanguage(languageCode);

      // Persist the language preference
      await _settingsRepository.updateLanguage(languageCode);
    } catch (e) {
      rethrow;
    }
  }

  /// Initialize localization service with saved language preference
  /// Loads the language from settings or defaults to Indonesian
  Future<void> initialize() async {
    try {
      // Get saved settings
      final settings = await _settingsRepository.getSettings();

      // Load the saved language
      await loadLanguage(settings.languageCode);
    } catch (e) {
      // If initialization fails, default to Indonesian
      await loadLanguage('id');
    }
  }
}
