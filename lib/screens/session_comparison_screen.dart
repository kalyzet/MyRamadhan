import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ramadhan_session.dart';
import '../models/user_stats.dart';
import '../repositories/stats_repository.dart';
import '../repositories/daily_record_repository.dart';
import '../providers/app_state.dart';

/// Session comparison screen for comparing multiple Ramadhan sessions
/// Requirements: 12.2, 12.3
class SessionComparisonScreen extends StatefulWidget {
  final List<RamadhanSession> sessions;

  const SessionComparisonScreen({
    super.key,
    required this.sessions,
  });

  @override
  State<SessionComparisonScreen> createState() =>
      _SessionComparisonScreenState();
}

class _SessionComparisonScreenState extends State<SessionComparisonScreen> {
  final StatsRepository _statsRepository = StatsRepository();
  final DailyRecordRepository _dailyRecordRepository =
      DailyRecordRepository();

  Map<int, UserStats>? _statsMap;
  Map<int, double>? _completionRates;
  bool _isLoading = true;

  /// English fallback translations for when LocalizationService fails
  static const Map<String, String> _englishFallbacks = {
    'session_comparison.title': 'Session Comparison',
    'session_comparison.error_loading': 'Error loading comparison data:',
    'session_comparison.no_sessions': 'No sessions to compare',
    'session_comparison.session_selected': 'Session Selected',
    'session_comparison.sessions_compared': 'Sessions Compared',
    'session_comparison.ramadhan_label': 'Ramadhan',
    'session_comparison.delta_same': 'Same',
    'session_comparison.metrics.level': 'Level',
    'session_comparison.metrics.total_xp': 'Total XP',
    'session_comparison.metrics.longest_streak': 'Longest Streak',
    'session_comparison.metrics.prayer_streak': 'Prayer Streak',
    'session_comparison.metrics.tilawah_streak': 'Tilawah Streak',
    'session_comparison.metrics.completion_rate': 'Completion Rate',
  };

  /// Safely translate a key with fallback to English
  String _safeTranslate(String Function(String)? translate, String key) {
    try {
      if (translate != null) {
        final result = translate(key);
        // If translation returns the key itself, it means translation failed
        if (result != key) {
          return result;
        }
      }
    } catch (e) {
      // Translation failed, fall back to English
    }
    
    // Return English fallback or the key if no fallback exists
    return _englishFallbacks[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statsMap = <int, UserStats>{};
      final completionRates = <int, double>{};

      for (final session in widget.sessions) {
        if (session.id != null) {
          // Load stats
          final stats = await _statsRepository.getStatsForSession(session.id!);
          if (stats != null) {
            statsMap[session.id!] = stats;
          }

          // Calculate completion rate
          final records =
              await _dailyRecordRepository.getRecordsForSession(session.id!);
          final completedDays = records.where((r) => r.xpEarned > 0).length;
          final completionRate = session.totalDays > 0
              ? (completedDays / session.totalDays) * 100
              : 0.0;
          completionRates[session.id!] = completionRate;
        }
      }

      setState(() {
        _statsMap = statsMap;
        _completionRates = completionRates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        // Safely get the localization service from the app state
        String Function(String)? translate;
        try {
          final appState = Provider.of<AppState>(context, listen: false);
          translate = appState.localizationService.translate;
        } catch (localizationError) {
          // LocalizationService is unavailable, translate will remain null
          translate = null;
        }
        
        final errorMessage = _safeTranslate(translate, 'session_comparison.error_loading');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Safely get the translation function
        String Function(String)? translate;
        try {
          translate = appState.localizationService.translate;
        } catch (e) {
          // LocalizationService is unavailable, translate will remain null
          translate = null;
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _safeTranslate(translate, 'session_comparison.title'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF10B981),
                  ),
                )
              : _buildComparisonContent(translate),
        );
      },
    );
  }

  Widget _buildComparisonContent(String Function(String)? translate) {
    if (widget.sessions.isEmpty) {
      return Center(
        child: Text(
          _safeTranslate(translate, 'session_comparison.no_sessions'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    // Sort sessions by year
    final sortedSessions = List<RamadhanSession>.from(widget.sessions);
    sortedSessions.sort((a, b) => a.year.compareTo(b.year));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(translate),
          const SizedBox(height: 20),

          // Comparison metrics
          _buildMetricComparison(_safeTranslate(translate, 'session_comparison.metrics.level'), (stats) => stats.level, translate),
          const SizedBox(height: 16),
          _buildMetricComparison(_safeTranslate(translate, 'session_comparison.metrics.total_xp'), (stats) => stats.totalXp, translate),
          const SizedBox(height: 16),
          _buildMetricComparison(
              _safeTranslate(translate, 'session_comparison.metrics.longest_streak'), (stats) => stats.longestStreak, translate),
          const SizedBox(height: 16),
          _buildMetricComparison(
              _safeTranslate(translate, 'session_comparison.metrics.prayer_streak'), (stats) => stats.prayerStreak, translate),
          const SizedBox(height: 16),
          _buildMetricComparison(
              _safeTranslate(translate, 'session_comparison.metrics.tilawah_streak'), (stats) => stats.tilawahStreak, translate),
          const SizedBox(height: 16),
          _buildCompletionRateComparison(translate),
        ],
      ),
    );
  }

  Widget _buildHeader(String Function(String)? translate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.compare_arrows,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.sessions.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.sessions.length == 1
                ? _safeTranslate(translate, 'session_comparison.session_selected')
                : _safeTranslate(translate, 'session_comparison.sessions_compared'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricComparison(
      String metricName, int Function(UserStats) getValue, String Function(String)? translate) {
    final sortedSessions = List<RamadhanSession>.from(widget.sessions);
    sortedSessions.sort((a, b) => a.year.compareTo(b.year));

    // Calculate values and deltas
    final values = <int, int>{};
    final deltas = <int, MetricDelta>{};

    for (int i = 0; i < sortedSessions.length; i++) {
      final session = sortedSessions[i];
      final stats = _statsMap?[session.id];

      if (stats != null) {
        final value = getValue(stats);
        values[session.id!] = value;

        // Calculate delta from previous session
        if (i > 0) {
          final prevSession = sortedSessions[i - 1];
          final prevStats = _statsMap?[prevSession.id];
          if (prevStats != null) {
            final prevValue = getValue(prevStats);
            final delta = value - prevValue;
            deltas[session.id!] = MetricDelta(
              delta: delta,
              isImprovement: delta > 0,
              isDecline: delta < 0,
              isSame: delta == 0,
            );
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF374151).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metric header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF374151).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              metricName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Session values
          ...sortedSessions.map((session) {
            final value = values[session.id];
            final delta = deltas[session.id];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF374151).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Year
                  Text(
                    '${_safeTranslate(translate, 'session_comparison.ramadhan_label')} ${session.year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  // Value and delta
                  Row(
                    children: [
                      if (delta != null) ...[
                        _buildDeltaIndicator(delta, translate),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        value?.toString() ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompletionRateComparison(String Function(String)? translate) {
    final sortedSessions = List<RamadhanSession>.from(widget.sessions);
    sortedSessions.sort((a, b) => a.year.compareTo(b.year));

    // Calculate deltas
    final deltas = <int, MetricDelta>{};

    for (int i = 0; i < sortedSessions.length; i++) {
      final session = sortedSessions[i];
      final rate = _completionRates?[session.id];

      if (rate != null && i > 0) {
        final prevSession = sortedSessions[i - 1];
        final prevRate = _completionRates?[prevSession.id];
        if (prevRate != null) {
          final delta = rate - prevRate;
          deltas[session.id!] = MetricDelta(
            delta: delta.round(),
            isImprovement: delta > 0,
            isDecline: delta < 0,
            isSame: delta.abs() < 0.5,
          );
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF374151).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metric header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF374151).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              _safeTranslate(translate, 'session_comparison.metrics.completion_rate'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Session values
          ...sortedSessions.map((session) {
            final rate = _completionRates?[session.id];
            final delta = deltas[session.id];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF374151).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Year
                  Text(
                    '${_safeTranslate(translate, 'session_comparison.ramadhan_label')} ${session.year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  // Value and delta
                  Row(
                    children: [
                      if (delta != null) ...[
                        _buildDeltaIndicator(delta, translate),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        rate != null ? '${rate.toStringAsFixed(0)}%' : 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeltaIndicator(MetricDelta delta, String Function(String)? translate) {
    if (delta.isSame) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6B7280),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.remove,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _safeTranslate(translate, 'session_comparison.delta_same'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: delta.isImprovement
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            delta.isImprovement ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            delta.delta.abs().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class to represent metric delta information
class MetricDelta {
  final int delta;
  final bool isImprovement;
  final bool isDecline;
  final bool isSame;

  MetricDelta({
    required this.delta,
    required this.isImprovement,
    required this.isDecline,
    required this.isSame,
  });
}
