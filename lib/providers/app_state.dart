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
import '../services/validation_service.dart';
import '../services/localization_service.dart';
import '../services/date_normalizer.dart';
import '../exceptions/database_exception.dart' as app_exceptions;
import '../exceptions/validation_exception.dart';

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
  final ValidationService _validationService;
  final LocalizationService _localizationService;

  // State
  RamadhanSession? _activeSession;
  UserStats? _currentStats;
  DailyRecord? _todayRecord;
  List<Achievement> _achievements = [];
  List<SideQuest> _todaySideQuests = [];
  String _currentLanguage = 'id';

  // Cache for active session to avoid repeated database queries
  // Requirements: 9.3 - Query result caching for active session
  DateTime? _activeSessionCacheTime;
  DateTime? _activeSessionCacheDate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Loading and error state
  bool _isLoading = false;
  String? _errorMessage;

  // Animation callbacks
  void Function(int xpAmount)? onXpGained;
  void Function(int newLevel)? onLevelUp;

  // Getters
  RamadhanSession? get activeSession => _activeSession;
  UserStats? get currentStats => _currentStats;
  DailyRecord? get todayRecord => _todayRecord;
  List<Achievement> get achievements => _achievements;
  List<SideQuest> get todaySideQuests => _todaySideQuests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentLanguage => _currentLanguage;
  LocalizationService get localizationService => _localizationService;

  /// Whether the active session has passed its end date and should be
  /// completed (final summary shown, then session deactivated).
  bool get isSessionExpired {
    final session = _activeSession;
    if (session == null) return false;
    return DateNormalizer.today().isAfter(session.endDate);
  }

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
    ValidationService? validationService,
    LocalizationService? localizationService,
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
            achievementTrackerService ?? AchievementTrackerService(),
        _validationService = validationService ?? ValidationService(),
        _localizationService = localizationService ?? LocalizationService() {
    // Initialize localization on creation
    _initializeLocalization();
  }

  /// Initialize localization service with saved language preference
  Future<void> _initializeLocalization() async {
    try {
      await _localizationService.initialize();
      _currentLanguage = _localizationService.currentLanguage;
      notifyListeners();
    } catch (e) {
      // If initialization fails, default to Indonesian
      _currentLanguage = 'id';
    }
  }

  /// Load the active session and its associated data
  /// Requirements: 1.1
  /// Implements caching to avoid repeated database queries (Requirements: 9.3)
  Future<void> loadActiveSession({bool forceRefresh = false}) async {
    // Check if we have a valid cached session.
    // The cache is also invalidated when the calendar day changes so
    // "today" data (record, side quests) never goes stale across midnight.
    final today = DateNormalizer.today();
    if (!forceRefresh &&
        _activeSession != null &&
        _activeSessionCacheTime != null &&
        _activeSessionCacheDate == today &&
        DateTime.now().difference(_activeSessionCacheTime!) <
            _cacheValidDuration) {
      // Return cached data
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load active session
      _activeSession = await _sessionRepository.getActiveSession();
      _activeSessionCacheTime = DateTime.now();
      _activeSessionCacheDate = today;

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

        // Skip loading "today" data when the session has already ended —
        // there are no valid days left to record or generate quests for.
        if (isSessionExpired) {
          return;
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
    } on app_exceptions.DatabaseException catch (e) {
      _errorMessage = e.userMessage;
      rethrow;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      rethrow;
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
    // Validate inputs
    try {
      _validationService.validateSessionCreation(
        year: year,
        startDate: startDate,
        totalDays: totalDays,
      );
    } on ValidationException catch (e) {
      _errorMessage = e.userMessage;
      rethrow;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create the session
      final session = await _sessionRepository.createSession(
        year: year,
        startDate: startDate,
        totalDays: totalDays,
        currentDayNumber: currentDayNumber,
      );

      // Initialize stats and achievements BEFORE activating, so an active
      // session always has its supporting data. (setActiveSession atomically
      // deactivates all other sessions in a transaction — no separate
      // deactivate pass is needed.)
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

      // Activate this session
      await _sessionRepository.setActiveSession(session.id!);

      // Reload active session data
      await loadActiveSession(forceRefresh: true);

      return session;
    } on app_exceptions.DatabaseException catch (e) {
      _errorMessage = e.userMessage;
      rethrow;
    } catch (e) {
      _errorMessage = 'Failed to create session. Please try again.';
      rethrow;
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
      _errorMessage = 'No active session. Please create a session first.';
      throw StateError('No active session');
    }

    // Validate the record
    try {
      _validationService.validateDailyRecord(record);
      _validationService.validateDateInSession(record.date, _activeSession!);
      _validationService.validateBackdating(record.date, DateTime.now());
    } on ValidationException catch (e) {
      _errorMessage = e.userMessage;
      rethrow;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Store old level for level-up detection
      final oldLevel = _currentStats?.level ?? 1;

      // Fetch the existing record (if any) so XP is applied as a delta —
      // re-saving the same day must not award the full day's XP again.
      final existingRecord = await _dailyRecordRepository.getRecordByDate(
        _activeSession!.id!,
        record.date,
      );

      // Calculate XP for the record
      final xpEarned = _xpCalculatorService.calculateTotalDailyXp(record);
      final previousXp = existingRecord?.xpEarned ?? 0;
      final xpDelta = xpEarned - previousXp;

      // Check if it's a perfect day
      final isPerfectDay = _isPerfectDay(record);

      // Update record with calculated values, keeping any existing id so the
      // save updates the existing row instead of duplicating it
      final updatedRecord = record.copyWith(
        id: record.id ?? existingRecord?.id,
        xpEarned: xpEarned,
        isPerfectDay: isPerfectDay,
      );

      // Save the record
      final savedRecord =
          await _dailyRecordRepository.createOrUpdateRecord(updatedRecord);

      // Recalculate streaks from the full record history so repeated saves
      // and backfilled records cannot corrupt the streak counters.
      final allRecords = await _dailyRecordRepository
          .getRecordsForSession(_activeSession!.id!);
      await _streakTrackerService.recalculateAllStreaks(
        _activeSession!.id!,
        allRecords,
      );

      // Apply only the XP delta to stats
      if (xpDelta != 0) {
        await _statsRepository.addXp(_activeSession!.id!, xpDelta);
      }

      // Reload stats
      _currentStats =
          await _statsRepository.getStatsForSession(_activeSession!.id!);

      // Trigger XP gain animation if XP was earned
      if (xpDelta > 0) {
        onXpGained?.call(xpDelta);
      }

      // Check for level up and trigger animation
      final newLevel = _currentStats?.level ?? 1;
      if (newLevel > oldLevel) {
        onLevelUp?.call(newLevel);
      }

      // Check and unlock achievements
      await _achievementTrackerService.checkAndUnlockAchievements(
        _activeSession!.id!,
        _currentStats!,
        allRecords,
        totalDays: _activeSession!.totalDays,
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
    } on app_exceptions.DatabaseException catch (e) {
      _errorMessage = e.userMessage;
      rethrow;
    } catch (e) {
      _errorMessage = 'Failed to update record. Please try again.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete a side quest and award XP
  /// Requirements: 5.2
  Future<void> completeSideQuest(int questId) async {
    if (_activeSession == null) {
      _errorMessage = 'No active session. Please create a session first.';
      throw StateError('No active session');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the quest
      final quest = _todaySideQuests.firstWhere(
        (q) => q.id == questId,
        orElse: () => throw ArgumentError('Quest not found'),
      );

      // Mark quest as completed. Only award XP if this call actually
      // transitioned the quest to completed (guards double-tap XP farming).
      final wasCompleted = await _sideQuestRepository.completeSideQuest(questId);
      if (!wasCompleted) {
        return;
      }

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
    } on app_exceptions.DatabaseException catch (e) {
      _errorMessage = e.userMessage;
      rethrow;
    } catch (e) {
      _errorMessage = 'Failed to complete quest. Please try again.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete the active session after it has ended.
  /// Deactivates the session, invalidates the cache, and reloads state
  /// so the UI returns to the "create session" flow.
  Future<void> completeActiveSession() async {
    final session = _activeSession;
    if (session == null || session.id == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _sessionRepository.completeSession(session.id!);
      invalidateCache();
      await loadActiveSession(forceRefresh: true);
    } on app_exceptions.DatabaseException catch (e) {
      _errorMessage = e.userMessage;
      rethrow;
    } catch (e) {
      _errorMessage = 'Failed to complete session. Please try again.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Invalidate the active session cache
  /// Call this when session data changes to force a refresh on next load
  /// Requirements: 9.3
  void invalidateCache() {
    _activeSessionCacheTime = null;
    _activeSessionCacheDate = null;
  }

  /// Helper method to check if a day is perfect
  /// Delegates to the shared definition in XpCalculatorService
  bool _isPerfectDay(DailyRecord record) {
    return XpCalculatorService.isPerfectDay(record);
  }

  /// Change the application language
  /// Updates the language in localization service and persists the preference
  /// Requirements: 14.3
  Future<void> changeLanguage(String languageCode) async {
    try {
      // Change language in localization service (this also persists it)
      await _localizationService.changeLanguage(languageCode);

      // Update current language state
      _currentLanguage = languageCode;

      // Notify listeners to rebuild UI with new language
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to change language. Please try again.';
      rethrow;
    }
  }
}
