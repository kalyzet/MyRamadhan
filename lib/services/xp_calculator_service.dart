import '../models/daily_record.dart';

/// Service for calculating XP (Experience Points) based on ibadah activities
class XpCalculatorService {
  // XP constants based on requirements
  static const int xpPerPrayer = 10;
  static const int xpForPuasa = 50;
  static const int xpForTarawih = 30;
  static const int xpPerTilawahPage = 2;
  static const int xpForDzikir = 20;
  static const int xpForSedekah = 30;
  static const int xpForPerfectDayBonus = 50;

  /// Calculate XP for completed prayers (10 XP per prayer)
  /// Requirements: 2.1
  int calculatePrayerXp(int completedPrayers) {
    if (completedPrayers < 0 || completedPrayers > 5) {
      throw ArgumentError('Completed prayers must be between 0 and 5');
    }
    return completedPrayers * xpPerPrayer;
  }

  /// Calculate XP for puasa (50 XP)
  /// Requirements: 2.2
  int calculatePuasaXp() {
    return xpForPuasa;
  }

  /// Calculate XP for tarawih (30 XP)
  /// Requirements: 2.3
  int calculateTarawihXp() {
    return xpForTarawih;
  }

  /// Calculate XP for tilawah (2 XP per page)
  /// Requirements: 2.4
  int calculateTilawahXp(int pages) {
    if (pages < 0) {
      throw ArgumentError('Tilawah pages cannot be negative');
    }
    return pages * xpPerTilawahPage;
  }

  /// Calculate XP for dzikir (20 XP)
  /// Requirements: 2.5
  int calculateDzikirXp() {
    return xpForDzikir;
  }

  /// Calculate XP for sedekah (30 XP)
  /// Requirements: 2.6
  int calculateSedekahXp() {
    return xpForSedekah;
  }

  /// Calculate perfect day bonus (50 XP)
  /// Requirements: 2.7
  int calculatePerfectDayBonus() {
    return xpForPerfectDayBonus;
  }

  /// Calculate total daily XP from a DailyRecord
  /// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7
  int calculateTotalDailyXp(DailyRecord record) {
    int totalXp = 0;

    // Count completed prayers
    int completedPrayers = 0;
    if (record.fajrComplete) completedPrayers++;
    if (record.dhuhrComplete) completedPrayers++;
    if (record.asrComplete) completedPrayers++;
    if (record.maghribComplete) completedPrayers++;
    if (record.ishaComplete) completedPrayers++;

    // Add prayer XP
    totalXp += calculatePrayerXp(completedPrayers);

    // Add puasa XP
    if (record.puasaComplete) {
      totalXp += calculatePuasaXp();
    }

    // Add tarawih XP
    if (record.tarawihComplete) {
      totalXp += calculateTarawihXp();
    }

    // Add tilawah XP
    totalXp += calculateTilawahXp(record.tilawahPages);

    // Add dzikir XP
    if (record.dzikirComplete) {
      totalXp += calculateDzikirXp();
    }

    // Add sedekah XP
    if (record.sedekahAmount > 0) {
      totalXp += calculateSedekahXp();
    }

    // Check for perfect day and add bonus
    if (_isPerfectDay(record)) {
      totalXp += calculatePerfectDayBonus();
    }

    return totalXp;
  }

  /// Helper method to check if a day is perfect
  /// A perfect day requires: all 5 prayers, puasa, tarawih, tilawah > 0, dzikir, sedekah > 0
  bool _isPerfectDay(DailyRecord record) {
    return record.fajrComplete &&
        record.dhuhrComplete &&
        record.asrComplete &&
        record.maghribComplete &&
        record.ishaComplete &&
        record.puasaComplete &&
        record.tarawihComplete &&
        record.tilawahPages > 0 &&
        record.dzikirComplete &&
        record.sedekahAmount > 0;
  }
}
