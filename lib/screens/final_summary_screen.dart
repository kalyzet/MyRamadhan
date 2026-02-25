import 'package:flutter/material.dart';
import '../models/ramadhan_session.dart';
import '../models/user_stats.dart';
import '../models/achievement.dart';
import '../models/daily_record.dart';
import '../repositories/daily_record_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/achievement_repository.dart';

/// Final summary screen displayed on day 30 or Eid
/// Shows complete Ramadhan journey statistics and achievements
/// Requirements: 8.1, 8.2, 8.3, 8.4
class FinalSummaryScreen extends StatelessWidget {
  final RamadhanSession session;

  const FinalSummaryScreen({
    super.key,
    required this.session,
  });

  /// Check if the final summary should be displayed
  /// Triggers on day 30 or when Ramadhan is complete
  /// Requirements: 8.1
  static bool shouldDisplay(RamadhanSession session) {
    final today = DateTime.now();
    final daysSinceStart = today.difference(session.startDate).inDays + 1;
    
    // Display if we're on day 30 or beyond, or if we've reached the end date
    return daysSinceStart >= session.totalDays || 
           today.isAfter(session.endDate) ||
           today.isAtSameMomentAs(session.endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark background
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadSummaryData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            );
          }

          final data = snapshot.data!;
          final stats = data['stats'] as UserStats;
          final achievements = data['achievements'] as List<Achievement>;
          final records = data['records'] as List<DailyRecord>;
          final summary = data['summary'] as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with celebration
                _buildHeader(context),
                
                // Final level and XP
                _buildLevelCard(stats),
                
                // Achievements earned
                _buildAchievementsSection(achievements),
                
                // Complete ibadah statistics
                _buildIbadahStatistics(summary),
                
                // Progress comparison
                _buildProgressComparison(summary),
                
                // Motivational message
                _buildMotivationalMessage(summary),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🌙',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ramadhan Complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ramadhan ${session.year}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(UserStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Final Level',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${stats.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${stats.totalXp} Total XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(List<Achievement> achievements) {
    final unlockedAchievements = achievements.where((a) => a.unlocked).toList();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFD97706),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Achievements Earned',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${unlockedAchievements.length} of ${achievements.length} unlocked',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (unlockedAchievements.isEmpty)
            const Text(
              'No achievements unlocked yet. Keep striving!',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: unlockedAchievements.map((achievement) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🏆',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIbadahStatistics(Map<String, dynamic> summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Ibadah Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatItem(
            '🤲',
            'Total Prayers',
            '${summary['totalPrayers']}',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            '🌙',
            'Days Fasted',
            '${summary['daysFasted']}',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            '📖',
            'Quran Pages Read',
            '${summary['totalTilawahPages']}',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            '🕌',
            'Tarawih Completed',
            '${summary['tarawihCompleted']}',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            '📿',
            'Dzikir Sessions',
            '${summary['dzikirCompleted']}',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            '💝',
            'Days with Sedekah',
            '${summary['sedekahDays']}',
            const Color(0xFFD97706),
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            '⭐',
            'Perfect Days',
            '${summary['perfectDays']}',
            const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, Color color) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressComparison(Map<String, dynamic> summary) {
    final startLevel = summary['startLevel'] as int;
    final endLevel = summary['endLevel'] as int;
    final startStreak = summary['startStreak'] as int;
    final endStreak = summary['endStreak'] as int;
    final levelGain = endLevel - startLevel;
    final streakGain = endStreak - startStreak;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Comparison',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildComparisonRow(
            'Level',
            startLevel,
            endLevel,
            levelGain,
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(
            'Longest Streak',
            startStreak,
            endStreak,
            streakGain,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, int start, int end, int delta) {
    final isImprovement = delta > 0;
    final isDecline = delta < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Start value
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$start',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward,
              color: Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            // End value
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$end',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Delta indicator
            if (delta != 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isImprovement
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isImprovement ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isImprovement
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${delta.abs()}',
                      style: TextStyle(
                        color: isImprovement
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage(Map<String, dynamic> summary) {
    final completionPercentage = summary['completionPercentage'] as double;
    final message = _generateMotivationalMessage(completionPercentage);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
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
            Icons.favorite,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Generate motivational message based on performance
  /// Requirements: 8.4
  String _generateMotivationalMessage(double completionPercentage) {
    if (completionPercentage >= 90) {
      return 'Masha Allah! Your dedication this Ramadhan has been truly exceptional. May Allah accept all your efforts and grant you the highest rewards.';
    } else if (completionPercentage >= 70) {
      return 'Alhamdulillah! You\'ve shown great commitment this Ramadhan. Your consistency is inspiring. May Allah continue to guide you on this blessed journey.';
    } else if (completionPercentage >= 50) {
      return 'Well done! You\'ve made meaningful progress this Ramadhan. Every step counts, and Allah sees all your efforts. Keep striving for excellence.';
    } else if (completionPercentage >= 30) {
      return 'You\'ve taken important steps this Ramadhan. Remember, it\'s not about perfection but about sincere effort. May next Ramadhan bring even more growth.';
    } else {
      return 'Every journey begins with a single step. This Ramadhan was a learning experience. May Allah grant you strength and determination for the next one.';
    }
  }

  /// Load all summary data
  /// Requirements: 8.2
  Future<Map<String, dynamic>> _loadSummaryData() async {
    final dailyRecordRepository = DailyRecordRepository();
    final statsRepository = StatsRepository();
    final achievementRepository = AchievementRepository();

    // Load stats
    final stats = await statsRepository.getStatsForSession(session.id!);
    if (stats == null) {
      throw StateError('Stats not found for session');
    }

    // Load achievements
    final achievements = await achievementRepository.getAchievementsForSession(session.id!);

    // Load all records
    final records = await dailyRecordRepository.getRecordsForSession(session.id!);

    // Calculate summary statistics
    int totalPrayers = 0;
    int daysFasted = 0;
    int totalTilawahPages = 0;
    int tarawihCompleted = 0;
    int dzikirCompleted = 0;
    int sedekahDays = 0;
    int perfectDays = 0;
    int completedDays = 0;

    for (final record in records) {
      // Count prayers
      if (record.fajrComplete) totalPrayers++;
      if (record.dhuhrComplete) totalPrayers++;
      if (record.asrComplete) totalPrayers++;
      if (record.maghribComplete) totalPrayers++;
      if (record.ishaComplete) totalPrayers++;

      // Count other ibadah
      if (record.puasaComplete) daysFasted++;
      totalTilawahPages += record.tilawahPages;
      if (record.tarawihComplete) tarawihCompleted++;
      if (record.dzikirComplete) dzikirCompleted++;
      if (record.sedekahAmount > 0) sedekahDays++;
      if (record.isPerfectDay) perfectDays++;
      if (record.xpEarned > 0) completedDays++;
    }

    // Calculate completion percentage
    final completionPercentage = session.totalDays > 0
        ? (completedDays / session.totalDays) * 100
        : 0.0;

    // For progress comparison, we'll use simple start/end values
    // In a real app, you might store initial stats separately
    final startLevel = 1; // Assuming everyone starts at level 1
    final endLevel = stats.level;
    final startStreak = 0; // Assuming everyone starts with 0 streak
    final endStreak = stats.longestStreak;

    return {
      'stats': stats,
      'achievements': achievements,
      'records': records,
      'summary': {
        'totalPrayers': totalPrayers,
        'daysFasted': daysFasted,
        'totalTilawahPages': totalTilawahPages,
        'tarawihCompleted': tarawihCompleted,
        'dzikirCompleted': dzikirCompleted,
        'sedekahDays': sedekahDays,
        'perfectDays': perfectDays,
        'completedDays': completedDays,
        'completionPercentage': completionPercentage,
        'startLevel': startLevel,
        'endLevel': endLevel,
        'startStreak': startStreak,
        'endStreak': endStreak,
      },
    };
  }
}
