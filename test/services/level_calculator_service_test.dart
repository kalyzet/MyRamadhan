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
      // Cost of level 1 -> 2 is 1*1*100 = 100 XP
      expect(service.calculateLevel(50), 1);
      expect(service.calculateLevel(99), 1);
    });

    test('calculateLevel returns 2 when reaching level 2 threshold', () {
      expect(service.calculateLevel(100), 2);
      // Cumulative to reach level 3 is 100 + 400 = 500
      expect(service.calculateLevel(499), 2);
    });

    test('calculateLevel returns correct level for higher XP', () {
      // Cumulative: L3 = 500, L4 = 1400, L5 = 3000
      expect(service.calculateLevel(500), 3);
      expect(service.calculateLevel(1399), 3);
      expect(service.calculateLevel(1400), 4);
      expect(service.calculateLevel(2999), 4);
      expect(service.calculateLevel(3000), 5);
    });

    test('calculateLevel throws for negative XP', () {
      expect(() => service.calculateLevel(-1), throwsArgumentError);
    });

    test('calculateRequiredXpForLevel returns cumulative values', () {
      // C(L) = sum(i² × 100) for i = 1..L-1
      expect(service.calculateRequiredXpForLevel(1), 0);
      expect(service.calculateRequiredXpForLevel(2), 100);
      expect(service.calculateRequiredXpForLevel(3), 500);
      expect(service.calculateRequiredXpForLevel(4), 1400);
      expect(service.calculateRequiredXpForLevel(5), 3000);
      // sum i=1..9 of i² = 285 → 28500
      expect(service.calculateRequiredXpForLevel(10), 28500);
    });

    test('calculateRequiredXpForLevel throws for level < 1', () {
      expect(() => service.calculateRequiredXpForLevel(0), throwsArgumentError);
      expect(() => service.calculateRequiredXpForLevel(-1), throwsArgumentError);
    });

    test('calculateProgressToNextLevel returns 0.0 at level start', () {
      // Level 1 starts at 0 XP
      expect(service.calculateProgressToNextLevel(0, 1), 0.0);
    });

    test('calculateProgressToNextLevel returns correct progress mid-level', () {
      // Level 1 spans 0..100 XP; at 50 XP progress = 0.5
      expect(service.calculateProgressToNextLevel(50, 1), closeTo(0.5, 0.01));
    });

    test('calculateProgressToNextLevel returns 1.0 at next level threshold', () {
      // At 100 XP the user has fully paid level 1's cost
      expect(service.calculateProgressToNextLevel(100, 1), 1.0);
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

    // **Feature: my-ramadhan-app, Property 12: Cumulative required XP correctness**
    // **Validates: Requirements 3.3**
    Glados<int>().test(
        'Property 12: Required XP equals sum of i² × 100 below the level',
        (level) {
      // Generate valid level values (1 to 100)
      final validLevel = (level.abs() % 100) + 1;

      final requiredXp = service.calculateRequiredXpForLevel(validLevel);
      var expectedXp = 0;
      for (var i = 1; i < validLevel; i++) {
        expectedXp += i * i * 100;
      }

      expect(requiredXp, expectedXp,
          reason:
              'Cumulative XP for level $validLevel should be $expectedXp but got $requiredXp');
    });
  });
}
