import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:my_ramadhan/services/level_calculator_service.dart';

void main() {
  late LevelCalculatorService service;

  setUp(() {
    service = LevelCalculatorService();
  });

  group('LevelCalculatorService - Unit Tests', () {
    test('calculateLevel returns 1 for 0 XP', () {
      expect(service.calculateLevel(0), 1);
    });

    test('calculateLevel returns 1 for XP below level 2 threshold', () {
      // Level 2 requires 2*2*100 = 400 XP
      expect(service.calculateLevel(100), 1);
      expect(service.calculateLevel(399), 1);
    });

    test('calculateLevel returns 2 when reaching level 2 threshold', () {
      // Level 2 requires 400 XP
      expect(service.calculateLevel(400), 2);
      expect(service.calculateLevel(500), 2);
    });

    test('calculateLevel returns correct level for higher XP', () {
      // Level 3 requires 3*3*100 = 900 XP
      expect(service.calculateLevel(900), 3);
      // Level 4 requires 4*4*100 = 1600 XP
      expect(service.calculateLevel(1600), 4);
      // Level 5 requires 5*5*100 = 2500 XP
      expect(service.calculateLevel(2500), 5);
    });

    test('calculateLevel throws for negative XP', () {
      expect(() => service.calculateLevel(-1), throwsArgumentError);
    });

    test('calculateRequiredXpForLevel returns correct values', () {
      expect(service.calculateRequiredXpForLevel(1), 100);
      expect(service.calculateRequiredXpForLevel(2), 400);
      expect(service.calculateRequiredXpForLevel(3), 900);
      expect(service.calculateRequiredXpForLevel(4), 1600);
      expect(service.calculateRequiredXpForLevel(5), 2500);
      expect(service.calculateRequiredXpForLevel(10), 10000);
    });

    test('calculateRequiredXpForLevel throws for level < 1', () {
      expect(() => service.calculateRequiredXpForLevel(0), throwsArgumentError);
      expect(() => service.calculateRequiredXpForLevel(-1), throwsArgumentError);
    });

    test('calculateProgressToNextLevel returns 0.0 at level start', () {
      // At level 1 with 100 XP (exactly at level 1 threshold)
      expect(service.calculateProgressToNextLevel(100, 1), 0.0);
    });

    test('calculateProgressToNextLevel returns correct progress mid-level', () {
      // Level 1 requires 100 XP, Level 2 requires 400 XP
      // Range is 300 XP (400 - 100)
      // At 250 XP: progress = (250 - 100) / 300 = 150 / 300 = 0.5
      expect(service.calculateProgressToNextLevel(250, 1), closeTo(0.5, 0.01));
    });

    test('calculateProgressToNextLevel returns 1.0 at next level threshold', () {
      // At 400 XP (level 2 threshold) while still at level 1
      expect(service.calculateProgressToNextLevel(400, 1), 1.0);
    });

    test('calculateProgressToNextLevel throws for negative XP', () {
      expect(() => service.calculateProgressToNextLevel(-1, 1),
          throwsArgumentError);
    });

    test('calculateProgressToNextLevel throws for level < 1', () {
      expect(() => service.calculateProgressToNextLevel(100, 0),
          throwsArgumentError);
    });
  });

  group('LevelCalculatorService - Property-Based Tests', () {
    // **Feature: my-ramadhan-app, Property 11: Level-up threshold detection**
    // **Validates: Requirements 3.2**
    Glados<int>().test(
        'Property 11: Level increments when XP reaches required threshold',
        (xp) {
      // Generate valid XP values (non-negative, reasonable range)
      final validXp = xp.abs() % 100000;

      final level = service.calculateLevel(validXp);
      final requiredXpForNextLevel =
          service.calculateRequiredXpForLevel(level + 1);

      // The user's XP should be < required XP for next level
      // This ensures the level calculation is correct
      expect(validXp < requiredXpForNextLevel, isTrue,
          reason:
              'XP $validXp should be < required XP $requiredXpForNextLevel for level ${level + 1}');

      // For levels > 1, verify XP is >= required XP for current level
      // Level 1 is special: it starts at 0 XP (not 100 XP)
      if (level > 1) {
        final requiredXpForCurrentLevel =
            service.calculateRequiredXpForLevel(level);
        expect(validXp >= requiredXpForCurrentLevel, isTrue,
            reason:
                'XP $validXp should be >= required XP $requiredXpForCurrentLevel for level $level');
      } else {
        // Level 1 starts at 0 XP
        expect(validXp >= 0, isTrue);
      }
    });

    // **Feature: my-ramadhan-app, Property 12: Required XP formula correctness**
    // **Validates: Requirements 3.3**
    Glados<int>().test('Property 12: Required XP equals level × level × 100',
        (level) {
      // Generate valid level values (1 to 100)
      final validLevel = (level.abs() % 100) + 1;

      final requiredXp = service.calculateRequiredXpForLevel(validLevel);
      final expectedXp = validLevel * validLevel * 100;

      expect(requiredXp, expectedXp,
          reason:
              'Required XP for level $validLevel should be $expectedXp but got $requiredXp');
    });
  });
}
