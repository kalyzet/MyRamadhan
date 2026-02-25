/// Service for calculating user level and progression based on XP
/// Requirements: 3.2, 3.3
class LevelCalculatorService {
  /// Calculate the current level based on total XP
  /// Requirements: 3.2
  /// 
  /// The level is determined by finding the highest level where
  /// the user has accumulated enough XP to reach it.
  /// Formula: required XP for level n = n × n × 100
  int calculateLevel(int totalXp) {
    if (totalXp < 0) {
      throw ArgumentError('Total XP cannot be negative');
    }

    // Start at level 1 (minimum level)
    int level = 1;

    // Keep incrementing level while user has enough XP for the next level
    while (totalXp >= calculateRequiredXpForLevel(level + 1)) {
      level++;
    }

    return level;
  }

  /// Calculate the required XP to reach a specific level
  /// Requirements: 3.3
  /// 
  /// Formula: required XP = level × level × 100
  int calculateRequiredXpForLevel(int level) {
    if (level < 1) {
      throw ArgumentError('Level must be at least 1');
    }

    return level * level * 100;
  }

  /// Calculate the progress percentage toward the next level
  /// Requirements: 3.3
  /// 
  /// Returns a value between 0.0 and 1.0 representing the progress
  /// from current level to next level
  double calculateProgressToNextLevel(int totalXp, int currentLevel) {
    if (totalXp < 0) {
      throw ArgumentError('Total XP cannot be negative');
    }
    if (currentLevel < 1) {
      throw ArgumentError('Current level must be at least 1');
    }

    // XP required for current level
    int currentLevelXp = calculateRequiredXpForLevel(currentLevel);
    
    // XP required for next level
    int nextLevelXp = calculateRequiredXpForLevel(currentLevel + 1);
    
    // XP needed to progress from current to next level
    int xpRange = nextLevelXp - currentLevelXp;
    
    // XP the user has accumulated beyond current level
    int xpProgress = totalXp - currentLevelXp;
    
    // Calculate progress as a percentage (0.0 to 1.0)
    if (xpRange <= 0) {
      return 0.0;
    }
    
    double progress = xpProgress / xpRange;
    
    // Clamp between 0.0 and 1.0
    return progress.clamp(0.0, 1.0);
  }
}
