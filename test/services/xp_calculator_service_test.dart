import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:my_ramadhan/models/daily_record.dart';
import 'package:my_ramadhan/services/xp_calculator_service.dart';

void main() {
  late XpCalculatorService service;

  setUp(() {
    service = XpCalculatorService();
  });

  group('XpCalculatorService - Unit Tests', () {
    test('calculatePrayerXp returns correct XP for valid prayer counts', () {
      expect(service.calculatePrayerXp(0), 0);
      expect(service.calculatePrayerXp(1), 10);
      expect(service.calculatePrayerXp(2), 20);
      expect(service.calculatePrayerXp(3), 30);
      expect(service.calculatePrayerXp(4), 40);
      expect(service.calculatePrayerXp(5), 50);
    });

    test('calculatePrayerXp throws for invalid prayer counts', () {
      expect(() => service.calculatePrayerXp(-1), throwsArgumentError);
      expect(() => service.calculatePrayerXp(6), throwsArgumentError);
    });

    test('calculatePuasaXp returns 50 XP', () {
      expect(service.calculatePuasaXp(), 50);
    });

    test('calculateTarawihXp returns 30 XP', () {
      expect(service.calculateTarawihXp(), 30);
    });

    test('calculateTilawahXp returns correct XP for pages', () {
      expect(service.calculateTilawahXp(0), 0);
      expect(service.calculateTilawahXp(1), 2);
      expect(service.calculateTilawahXp(10), 20);
      expect(service.calculateTilawahXp(100), 200);
    });

    test('calculateTilawahXp throws for negative pages', () {
      expect(() => service.calculateTilawahXp(-1), throwsArgumentError);
    });

    test('calculateDzikirXp returns 20 XP', () {
      expect(service.calculateDzikirXp(), 20);
    });

    test('calculateSedekahXp returns 30 XP', () {
      expect(service.calculateSedekahXp(), 30);
    });

    test('calculatePerfectDayBonus returns 50 XP', () {
      expect(service.calculatePerfectDayBonus(), 50);
    });

    test('calculateTotalDailyXp calculates correct total without perfect day', () {
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: true,
        dhuhrComplete: true,
        asrComplete: false,
        maghribComplete: false,
        ishaComplete: false,
        puasaComplete: true,
        tarawihComplete: false,
        tilawahPages: 5,
        dzikirComplete: true,
        sedekahAmount: 10.0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      // 2 prayers (20) + puasa (50) + tilawah 5 pages (10) + dzikir (20) + sedekah (30) = 130
      expect(service.calculateTotalDailyXp(record), 130);
    });

    test('calculateTotalDailyXp includes perfect day bonus', () {
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: true,
        dhuhrComplete: true,
        asrComplete: true,
        maghribComplete: true,
        ishaComplete: true,
        puasaComplete: true,
        tarawihComplete: true,
        tilawahPages: 5,
        dzikirComplete: true,
        sedekahAmount: 10.0,
        xpEarned: 0,
        isPerfectDay: false,
      );

      // 5 prayers (50) + puasa (50) + tarawih (30) + tilawah 5 pages (10) + dzikir (20) + sedekah (30) + perfect bonus (50) = 240
      expect(service.calculateTotalDailyXp(record), 240);
    });
  });

  group('XpCalculatorService - Property-Based Tests', () {
    // **Feature: my-ramadhan-app, Property 5: Prayer XP calculation consistency**
    // **Validates: Requirements 2.1**
    Glados<int>().test('Property 5: Prayer XP equals prayer count × 10',
        (prayerCount) {
      // Generate valid prayer counts (0-5)
      final validPrayerCount = prayerCount.abs() % 6;
      final xp = service.calculatePrayerXp(validPrayerCount);
      expect(xp, validPrayerCount * 10);
    });

    // **Feature: my-ramadhan-app, Property 6: Tilawah XP calculation linearity**
    // **Validates: Requirements 2.4**
    Glados<int>().test('Property 6: Tilawah XP equals pages × 2', (pages) {
      // Generate valid page counts (non-negative)
      final validPages = pages.abs() % 605; // Max 604 pages in Quran
      final xp = service.calculateTilawahXp(validPages);
      expect(xp, validPages * 2);
    });

    // **Feature: my-ramadhan-app, Property 7: Perfect day bonus detection**
    // **Validates: Requirements 2.7**
    Glados2<int, double>().test(
        'Property 7: Perfect day awards bonus when all objectives complete',
        (tilawahPages, sedekahAmount) {
      // Generate valid values
      final validPages = tilawahPages.abs() % 605;
      final validSedekah = sedekahAmount.abs();

      // Create a record with all objectives complete
      final perfectRecord = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: true,
        dhuhrComplete: true,
        asrComplete: true,
        maghribComplete: true,
        ishaComplete: true,
        puasaComplete: true,
        tarawihComplete: true,
        tilawahPages: validPages > 0 ? validPages : 1, // Ensure > 0
        dzikirComplete: true,
        sedekahAmount: validSedekah > 0 ? validSedekah : 1.0, // Ensure > 0
        xpEarned: 0,
        isPerfectDay: false,
      );

      final totalXp = service.calculateTotalDailyXp(perfectRecord);

      // Calculate expected XP
      final expectedBaseXp = 50 + // 5 prayers
          50 + // puasa
          30 + // tarawih
          (perfectRecord.tilawahPages * 2) + // tilawah
          20 + // dzikir
          30; // sedekah
      final expectedTotal = expectedBaseXp + 50; // perfect day bonus

      expect(totalXp, expectedTotal);
    });

    // **Feature: my-ramadhan-app, Property 10: XP accumulation additivity**
    // **Validates: Requirements 3.1**
    Glados2<int, double>().test(
        'Property 10: Total XP equals sum of individual XP components',
        (tilawahPages, sedekahAmount) {
      // Generate valid values
      final validPages = tilawahPages.abs() % 605;
      final validSedekah = sedekahAmount.abs();

      // Create a record with random completions (fixed prayers for simplicity)
      final record = DailyRecord(
        sessionId: 1,
        date: DateTime(2024, 3, 15),
        fajrComplete: true,
        dhuhrComplete: true,
        asrComplete: false,
        maghribComplete: false,
        ishaComplete: false,
        puasaComplete: true,
        tarawihComplete: false,
        tilawahPages: validPages,
        dzikirComplete: true,
        sedekahAmount: validSedekah,
        xpEarned: 0,
        isPerfectDay: false,
      );

      final totalXp = service.calculateTotalDailyXp(record);

      // Calculate expected XP by summing components
      int expectedXp = 0;
      expectedXp += 2 * 10; // 2 prayers complete
      expectedXp += 50; // puasa
      expectedXp += validPages * 2; // tilawah
      expectedXp += 20; // dzikir
      if (validSedekah > 0) expectedXp += 30; // sedekah

      // No perfect day bonus since not all prayers complete
      expect(totalXp, expectedXp);
    });
  });
}
