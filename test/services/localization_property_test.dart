import 'package:flutter_test/flutter_test.dart';
import 'package:my_ramadhan/services/localization_service.dart';
import 'package:my_ramadhan/repositories/settings_repository.dart';
import 'dart:math';

/// **Feature: language-switcher, Property 3: Translation key fallback**
/// **Validates: Requirements 4.2**
/// 
/// Property: For any translation key that doesn't exist in the localization files,
/// the system should return the key itself as a fallback rather than crashing or showing empty text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property-Based Tests - Localization Service', () {
    late LocalizationService localizationService;

    setUp(() async {
      localizationService = LocalizationService();
      await localizationService.initialize();
    });

    /// **Feature: language-switcher, Property 3: Translation key fallback**
    /// **Validates: Requirements 4.2**
    test('property: translation key fallback - missing keys return the key itself', () async {
      // Property: For any invalid/missing translation key, the system should return the key itself
      // This ensures the app never crashes or shows empty text due to missing translations
      
      final random = Random(42); // Fixed seed for reproducibility
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random invalid keys
        final invalidKey = _generateRandomInvalidKey(random);
        
        // Test with both languages (without changing language to avoid database operations)
        // We'll test with the current language
        final result = localizationService.translate(invalidKey);
        
        // Assert: The result should be the key itself (fallback behavior)
        expect(
          result,
          equals(invalidKey),
          reason: 'For invalid key "$invalidKey", '
              'expected fallback to return the key itself, but got "$result"',
        );
        
        // Assert: Result should not be null or empty
        expect(
          result.isNotEmpty,
          isTrue,
          reason: 'Translation fallback should never return empty string',
        );
      }
    });

    test('property: valid keys never return empty strings', () async {
      // Property: For any valid translation key, the system should return a non-empty translated value
      
      // Test with known valid keys from both language files
      final validKeys = [
        'app_name',
        'home.title',
        'home.no_session_title',
        'home.no_session_message',
        'home.create_session_button',
        'home.ramadhan_day',
        'home.level',
        'home.xp',
        'stats.title',
        'stats.no_session',
        'achievements.title',
        'profile.title',
        'common.loading',
        'common.error',
        'navigation.home',
      ];
      
      for (final key in validKeys) {
        final result = localizationService.translate(key);
        
        // Assert: Result should not be null or empty
        expect(
          result.isNotEmpty,
          isTrue,
          reason: 'Valid key "$key" should return non-empty translation',
        );
      }
    });

    test('property: nested keys fallback correctly', () async {
      // Property: For any nested key structure (e.g., "section.subsection.key"),
      // if the key doesn't exist, it should return the full key path as fallback
      
      final random = Random(42);
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random nested invalid keys
        final depth = random.nextInt(3) + 2; // 2-4 levels deep
        final keyParts = List.generate(depth, (_) => _generateRandomString(random, 5, 10));
        final nestedKey = keyParts.join('.');
        
        final result = localizationService.translate(nestedKey);
        
        // Assert: Should return the full nested key as fallback
        expect(
          result,
          equals(nestedKey),
          reason: 'Nested invalid key "$nestedKey" should return full key path as fallback',
        );
      }
    });

    test('property: special characters in keys are handled safely', () async {
      // Property: For any key containing special characters, the system should handle it gracefully
      // and return the key as fallback without crashing
      
      final specialCharKeys = [
        'key.with.dots',
        'key_with_underscores',
        'key-with-dashes',
        'key with spaces',
        'key@with#special\$characters',
        'key[with]brackets',
        'key{with}braces',
        'key(with)parens',
        'key/with/slashes',
        'key\\with\\backslashes',
        'key|with|pipes',
        'key:with:colons',
        'key;with;semicolons',
        'key,with,commas',
        'key<with>angles',
        'key"with"quotes',
        "key'with'apostrophes",
        'key`with`backticks',
        'key~with~tildes',
        'key!with!exclamations',
        'key?with?questions',
        'key&with&ampersands',
        'key%with%percents',
        'key^with^carets',
        'key*with*asterisks',
        'key+with+plus',
        'key=with=equals',
      ];
      
      for (final key in specialCharKeys) {
        // Act: This should not throw an exception
        final result = localizationService.translate(key);
        
        // Assert: Should return the key as fallback
        expect(
          result,
          equals(key),
          reason: 'Special character key "$key" should be handled gracefully',
        );
        
        // Assert: Should not be null or empty
        expect(
          result.isNotEmpty,
          isTrue,
          reason: 'Translation should never return empty string',
        );
      }
    });

    test('property: empty and whitespace keys are handled', () async {
      // Property: Edge case - empty or whitespace-only keys should be handled gracefully
      
      final edgeCaseKeys = [
        '',
        ' ',
        '  ',
        '\t',
        '\n',
        '   \t\n   ',
      ];
      
      for (final key in edgeCaseKeys) {
        // Act: This should not throw an exception
        final result = localizationService.translate(key);
        
        // Assert: Should return the key as fallback (even if empty)
        expect(
          result,
          equals(key),
          reason: 'Edge case key "$key" should return itself as fallback',
        );
      }
    });
  });
}

/// Generate a random invalid translation key
String _generateRandomInvalidKey(Random random) {
  final length = random.nextInt(20) + 5; // 5-24 characters
  return _generateRandomString(random, length, length);
}

/// Generate a random string of given length range
String _generateRandomString(Random random, int minLength, int maxLength) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
