import 'package:flutter/foundation.dart';
import '../models/ramadhan_session.dart';
import '../models/daily_record.dart';
import '../models/user_stats.dart';
import '../models/achievement.dart';
import '../models/side_quest.dart';
import '../repositories/session_repository.dart';
import '../repositories/daily_record_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/side_quest_repository.dart';
import '../services/xp_calculator_service.dart';
import '../services/level_calculator_service.dart';
import '../services/streak_tracker_service.dart';
import '../services/achievement_tracker_service.dart';

/// AppState provider class for managing application state
/// Implements state management layer with Provider pattern
/// Requirements: 1.1, 1.4, 2.1, 5.2
class AppState extends ChangeNotifier {
  // Repositories
  final SessionRepository _sessionRepository;
  final DailyRecordRepository _dailyRecordRepository;
  final StatsRepository _statsRepository;
  final AchievementRepository _achievementRepository;
  final SideQuestRepository _sideQuestRepository;

  // Services
  final XpCalculatorService _xpCalculatorService;
  final LevelCalculatorService _levelCalculatorService;
  final StreakTrackerService _streakTrackerService;
  final AchievementTrackerService _achievementTrackerService;

  // State
  RamadhanSession? _activeSession;
  UserStats? _currentStats;
  DailyRecord? _todayRecord;
  List<Achievement> _achievements = [];
  List<SideQuest> _todaySideQuests = [];

  // Loading state
  bool _isLoading = false;

  // Getters
  RamadhanSession? get activeSession => _activeSession;
  UserStats? get currentStats => _currentStats;
  DailyRecord? get todayRecord => _todayRecord;
  List<Achievement> get achievements => _achievements;
  List<SideQuest> get todaySideQuests => _todaySideQuests;
  bool get isLoading => _isLoading;

  AppState({
    SessionRepository? sessionRepository,
    DailyRecordRepository? dailyRecordRepository,
    StatsRepository? statsRepository,
    AchievementRepository? achievementRepository,
    SideQuestRepository? sideQuestRepository,
    XpCalculatorService? xpCalculatorService,
    LevelCalculatorService? levelCalculatorService,
    StreakTrackerService? streakTrackerService,
    AchievementTrackerService? achievementTrackerService,
  })  : _sessionRepository = sessionRepository ?? SessionRepository(),
        _dailyRecordRepository =
            dailyRecordRepository ?? DailyRecordRepository(),
        _statsRepository = statsRepository ?? StatsRepository(),
        _achievementRepository =
            achievementRepository ?? AchievementRepository(),
        _sideQuestRepository = sideQuestRepository ?? SideQuestRepository(),
        _xpCalculatorService = xpCalculatorService ?? XpCalculatorService(),
        _levelCalculatorService =
            levelCalculatorService ?? LevelCalculatorService(),
        _streakTrackerService = streakTrackerService ??
            StreakTrackerService(
              dailyRecordRepository:
                  dailyRecordRepository ?? DailyRecordRepository(),
              statsRepository: statsRepository ?? StatsRepository(),
            ),
        _achievementTrackerService =
            achievementTrackerService ?? AchievementTrackerService();

  /// Load the active session and its associated data
  /// Requirements: 1.1
  Future<void> loadActiveSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load active session
      _activeSession = await _sessionRepository.getActiveSession();

      if (_activeSession != null) {
        // Load stats for active session
        _currentStats =
            await _statsRepository.getStatsForSession(_activeSession!.id!);

        // If stats don't exist, create initial stats
        if (_currentStats == null) {
          _currentStats = UserStats(
            sessionId: _activeSession!.id!,
            totalXp: 0,
            level: 1,
            currentStreak: 0,
            longestStreak: 0,
            prayerStreak: 0,
            tilawahStreak: 0,
          );
          _currentStats = await _statsRepository.updateStats(_currentStats!);
        }

        // Load today's record
        final today = DateTime.now();
        _todayRecord = await _dailyRecordRepository.getRecordByDate(
          _activeSession!.id!,
          today,
        );

        // Load achievements
        _achievements = await _achievementRepository
            .getAchievementsForSession(_activeSession!.id!);

        // Load today's side quests
        _todaySideQuests = await _sideQuestRepository.getSideQuestsForDate(
          _activeSession!.id!,
          today,
        );

        // Generate side quests if they don't exist
        if (_todaySideQuests.isEmpty) {
          await _sideQuestRepository.generateDailySideQuests(
            _activeSession!.id!,
            today,
          );
          _todaySideQuests = await _sideQuestRepository.getSideQuestsForDate(
            _activeSession!.id!,
            today,
          );
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new Ramadhan session with mid-Ramadhan support
  /// Requirements: 1.1, 1.4
  Future<RamadhanSession> createNewSession({
    required int year,
    required DateTime startDate,
    required int totalDays,
    int? currentDayNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create the session
      final session = await _sessionRepository.createSession(
        year: year,
        startDate: startDate,
        totalDays: totalDays,
        currentDayNumber: currentDayNumber,
      );

      // Deactivate all other sessions and activate this one
      await _sessionRepository.deactivateAllSessions();
      await _sessionRepository.setActiveSession(session.id!);

      // Initialize stats for the new session
      final initialStats = UserStats(
        sessionId: session.id!,
        totalXp: 0,
        level: 1,
        currentStreak: 0,
        longestStreak: 0,
        prayerStreak: 0,
        tilawahStreak: 0,
      );
      await _statsRepository.updateStats(initialStats);

      // Initialize achievements for the new session
      await _achievementRepository.initializeAchievements(session.id!);

      // Reload active session data
      await loadActiveSession();

      return session;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a daily record with new data
  /// Calculates XP, updates streaks, and checks achievements
  /// Requirements: 2.1
  Future<void> updateDailyRecord(DailyRecord record) async {
    if (_activeSession == null) {
      throw StateError('No active session');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Calculate XP for the record
      final xpEarned = _xpCalculatorService.calculateTotalDailyXp(record);

      // Check if it's a perfect day
      final isPerfectDay = _isPerfectDay(record);

      // Update record with calculated values
      final updatedRecord = record.copyWith(
        xpEarned: xpEarned,
        isPerfectDay: isPerfectDay,
      );

      // Save the record
      final savedRecord =
          await _dailyRecordRepository.createOrUpdateRecord(updatedRecord);

      // Get previous day's record for streak calculation
      final previousDay = record.date.subtract(const Duration(days: 1));
      final previousDayRecord = await _dailyRecordRepository.getRecordByDate(
        _activeSession!.id!,
        previousDay,
      );

      // Update streaks
      await _streakTrackerService.updateStreaksForNewRecord(
        _activeSession!.id!,
        savedRecord,
        previousDayRecord,
      );

      // Add XP to stats
      await _statsRepository.addXp(_activeSession!.id!, xpEarned);

      // Reload stats
      _currentStats =
          await _statsRepository.getStatsForSession(_activeSession!.id!);

      // Check and unlock achievements
      final allRecords = await _dailyRecordRepository
          .getRecordsForSession(_activeSession!.id!);
      await _achievementTrackerService.checkAndUnlockAchievements(
        _activeSession!.id!,
        _currentStats!,
        allRecords,
      );

      // Reload achievements
      _achievements = await _achievementRepository
          .getAchievementsForSession(_activeSession!.id!);

      // Update today's record if this is today
      final today = DateTime.now();
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);

      if (recordDate == todayDate) {
        _todayRecord = savedRecord;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete a side quest and award XP
  /// Requirements: 5.2
  Future<void> completeSideQuest(int questId) async {
    if (_activeSession == null) {
      throw StateError('No active session');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Find the quest
      final quest = _todaySideQuests.firstWhere(
        (q) => q.id == questId,
        orElse: () => throw ArgumentError('Quest not found'),
      );

      // Mark quest as completed
      await _sideQuestRepository.completeSideQuest(questId);

      // Award XP
      await _statsRepository.addXp(_activeSession!.id!, quest.xpReward);

      // Reload stats
      _currentStats =
          await _statsRepository.getStatsForSession(_activeSession!.id!);

      // Reload side quests
      final today = DateTime.now();
      _todaySideQuests = await _sideQuestRepository.getSideQuestsForDate(
        _activeSession!.id!,
        today,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
