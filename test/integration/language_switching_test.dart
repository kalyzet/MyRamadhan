import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_ramadhan/database/database_helper.dart';
import 'package:my_ramadhan/repositories/settings_repository.dart';
import 'package:my_ramadhan/services/localization_service.dart';

/// Integration tests for end-to-end language switching at the service level.
///
/// These complement language_switching_minimal_test.dart (mocked
/// translations + widget tests) by exercising the real LocalizationService,
/// SettingsRepository, and l10n JSON assets against a real database.
///
/// Widget-level fake-async tests are deliberately avoided here: real async
/// work (sqflite FFI I/O, rootBundle asset loading) cannot complete inside a
/// testWidgets FakeAsync zone without runAsync wrappers, and the real-time
/// clock widget prevents pumpAndSettle from ever settling.
///
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3
void main() {
  // Required so rootBundle can load l10n JSON assets in plain tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Language Switching Integration Tests', () {
    late SettingsRepository settingsRepository;
    late LocalizationService localizationService;

    setUp(() async {
      await DatabaseHelper.instance.deleteDB();
      settingsRepository = SettingsRepository();
      localizationService = LocalizationService(
        settingsRepository: settingsRepository,
      );
      await localizationService.initialize();
    });

    tearDown(() async {
      await DatabaseHelper.instance.deleteDB();
    });

    test('changeLanguage updates translations and persists preference',
        () async {
      // Starts in Indonesian on a fresh install
      expect(localizationService.currentLanguage, equals('id'));

      await localizationService.changeLanguage('en');

      expect(localizationService.currentLanguage, equals('en'));
      expect(localizationService.translate('navigation.home'),
          equals('Home'));

      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('en'));
    });

    test('switching back and forth always reloads correct translations',
        () async {
      for (var i = 0; i < 3; i++) {
        await localizationService.changeLanguage('en');
        expect(localizationService.translate('navigation.stats'), equals('Stats'));
        expect(localizationService.translate('navigation.achievements'),
            equals('Achievements'));

        await localizationService.changeLanguage('id');
        expect(localizationService.translate('navigation.stats'),
            equals('Statistik'));
        expect(localizationService.translate('navigation.achievements'),
            equals('Pencapaian'));
      }

      final settings = await settingsRepository.getSettings();
      expect(settings.languageCode, equals('id'));
    });

    test('language preference survives a simulated app restart', () async {
      await localizationService.changeLanguage('en');

      // Simulate restart with brand new instances
      final restartedLocalization = LocalizationService(
        settingsRepository: SettingsRepository(),
      );
      await restartedLocalization.initialize();

      expect(restartedLocalization.currentLanguage, equals('en'));
      expect(restartedLocalization.translate('navigation.profile'),
          equals('Profile'));
    });

    test('all screens have non-empty translations in every supported language',
        () async {
      const sections = [
        'app_name',
        'home.title',
        'home.no_session_title',
        'home.create_session_button',
        'stats.title',
        'stats.no_session',
        'achievements.title',
        'profile.title',
        'profile.language',
        'history.title',
        'comparison.title',
        'final_summary.title',
        'create_session.title',
        'common.loading',
        'navigation.home',
        'navigation.stats',
        'navigation.achievements',
        'navigation.profile',
        'side_quests.early_bird.title',
        'session_comparison.title',
      ];

      for (final languageCode in ['en', 'id']) {
        await localizationService.loadLanguage(languageCode);
        for (final key in sections) {
          expect(
            localizationService.translate(key),
            isNot(equals(key)),
            reason:
                '$languageCode is missing a translation for "$key"',
          );
        }
      }
    });

    test('changeLanguage rejects unsupported language codes', () async {
      expect(
        () => localizationService.changeLanguage('fr'),
        throwsArgumentError,
      );

      // Language must remain unchanged after the failed switch
      expect(localizationService.currentLanguage, equals('id'));
    });
  });
}
