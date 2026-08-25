/// Service for calculating user level and progression based on XP
///
/// This is the single source of truth for the level formula and mirrors
/// exactly what StatsRepository.addXp applies:
///
/// The XP cost to advance from level n to level n+1 is n × n × 100.
/// The cumulative XP required to reach level L is therefore
/// sum(i² × 100) for i from 1 to L-1:
///
///   Level 1:      0 XP
///   Level 2:    100 XP
///   Level 3:    500 XP  (+400)
///   Level 4:   1400 XP  (+900)
///   Level 5:   2900 XP  (+1500)
class LevelCalculatorService {
  /// Calculate the current level based on total XP.
  ///
  /// Returns the highest level whose cumulative XP requirement is met.
  int calculateLevel(int totalXp) {
    if (totalXp < 0) {
      throw ArgumentError('Total XP cannot be negative');
    }

    int level = 1;

    // Keep advancing while we can afford the next level's cost
    while (totalXp >= _costForLevel(level)) {
      totalXp -= _costForLevel(level);
      level++;
    }

    return level;
  }

  /// Calculate the cumulative XP required to reach a specific level.
  ///
  /// Level 1 requires 0 XP; reaching level L requires the sum of the costs
  /// of all levels below it.
  int calculateRequiredXpForLevel(int level) {
    if (level < 1) {
      throw ArgumentError('Level must be at least 1');
    }

    var cumulative = 0;
    for (var i = 1; i < level; i++) {
      cumulative += _costForLevel(i);
    }
    return cumulative;
  }

  /// Calculate the progress percentage toward the next level.
  ///
  /// Returns a value between 0.0 and 1.0 representing the progress from
  /// [currentLevel] to the next level.
  double calculateProgressToNextLevel(int totalXp, int currentLevel) {
    if (totalXp < 0) {
      throw ArgumentError('Total XP cannot be negative');
    }
    if (currentLevel < 1) {
      throw ArgumentError('Current level must be at least 1');
    }

    final levelStartXp = calculateRequiredXpForLevel(currentLevel);
    final xpRange = _costForLevel(currentLevel);

    if (xpRange <= 0) {
      return 0.0;
    }

    final progress = (totalXp - levelStartXp) / xpRange;
    return progress.clamp(0.0, 1.0).toDouble();
  }

  /// XP cost to advance from level [level] to [level] + 1
  int _costForLevel(int level) => level * level * 100;
}
