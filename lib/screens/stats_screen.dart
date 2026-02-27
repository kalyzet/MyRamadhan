import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/daily_record.dart';
import '../repositories/daily_record_repository.dart';
import '../repositories/session_repository.dart';
import '../widgets/skeleton_loader.dart';

/// Stats screen displaying user statistics and progress
/// Requirements: 7.1, 7.2, 7.3
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const StatsScreenSkeleton();
        }

        if (appState.activeSession == null) {
          return const Center(
            child: Text(
              'Tidak ada sesi aktif. Silakan buat sesi Ramadhan baru.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }

        final session = appState.activeSession!;
        final stats = appState.currentStats;

        if (stats == null) {
          return const Center(
            child: Text(
              'Tidak ada statistik tersedia.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total XP and Level
              _buildXpLevelCard(stats),
              const SizedBox(height: 16),

              // Streak Information
              _buildStreaksCard(stats),
              const SizedBox(height: 16),

              // Statistics Summary
              _buildStatsSummaryCard(session, stats),
              const SizedBox(height: 16),

              // Daily History Calendar
              _buildDailyHistorySection(session),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXpLevelCard(stats) {
    final currentLevel = stats.level;
    final totalXp = stats.totalXp;

    // Calculate XP for current level
    int xpForCurrentLevel = 0;
    for (int i = 1; i < currentLevel; i++) {
      xpForCurrentLevel += i * i * 100;
    }

    final xpInCurrentLevel = totalXp - xpForCurrentLevel;
    final xpRequiredForNextLevel = currentLevel * currentLevel * 100;
    final progress = xpInCurrentLevel / xpRequiredForNextLevel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)], // Emerald gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Level Saat Ini',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentLevel',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total XP',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '$totalXp',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD97706), // Gold
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$xpInCurrentLevel / $xpRequiredForNextLevel XP ke Level ${currentLevel + 1}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksCard(stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Streak Saat Ini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakItem(
                '🔥',
                'Sempurna',
                stats.currentStreak,
                'hari',
              ),
              _buildStreakItem(
                '🤲',
                'Sholat',
                stats.prayerStreak,
                'hari',
              ),
              _buildStreakItem(
                '📖',
                'Tilawah',
                stats.tilawahStreak,
                'hari',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Streak Terpanjang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${stats.longestStreak} hari',
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String emoji, String label, int count, String unit) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummaryCard(session, stats) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateStatsSummary(session.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            ),
          );
        }

        final summary = snapshot.data!;
        final totalTilawahPages = summary['totalTilawahPages'] as int;
        final consistencyPercentage = summary['consistencyPercentage'] as double;
        final completedDays = summary['completedDays'] as int;
        final totalDays = session.totalDays;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Statistik',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildStatRow(
                Icons.menu_book,
                'Total Halaman Tilawah',
                '$totalTilawahPages',
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.check_circle,
                'Konsistensi',
                '${consistencyPercentage.toStringAsFixed(1)}%',
                const Color(0xFFD97706),
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.calendar_today,
                'Hari Selesai',
                '$completedDays / $totalDays',
                const Color(0xFF10B981),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyHistorySection(session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Harian',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<DailyRecord>>(
            future: _loadDailyRecords(session.id!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                  ),
                );
              }

              final records = snapshot.data!;
              return _buildCalendarGrid(session, records);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(session, List<DailyRecord> records) {
    // Create a map of dates to records for quick lookup
    final recordMap = <DateTime, DailyRecord>{};
    for (final record in records) {
      final normalizedDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      recordMap[normalizedDate] = record;
    }

    // Generate all days in the session
    final days = <Widget>[];
    for (int i = 0; i < session.totalDays; i++) {
      final date = session.startDate.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final record = recordMap[normalizedDate];

      days.add(_buildDayCell(i + 1, record));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days,
    );
  }

  Widget _buildDayCell(int dayNumber, DailyRecord? record) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    if (record == null) {
      // No record - gray
      backgroundColor = const Color(0xFF374151);
      textColor = Colors.white38;
    } else if (record.isPerfectDay) {
      // Perfect day - gold
      backgroundColor = const Color(0xFFD97706);
      textColor = Colors.white;
      icon = Icons.star;
    } else if (record.xpEarned > 0) {
      // Some progress - emerald
      backgroundColor = const Color(0xFF10B981);
      textColor = Colors.white;
      icon = Icons.check;
    } else {
      // Record exists but no XP - gray
      backgroundColor = const Color(0xFF374151);
      textColor = Colors.white38;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (icon != null)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                icon,
                size: 12,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _calculateStatsSummary(int sessionId) async {
    // Import repository directly
    final dailyRecordRepository = DailyRecordRepository();

    // Get all records for the session
    final records = await dailyRecordRepository.getRecordsForSession(sessionId);

    // Calculate total tilawah pages
    int totalTilawahPages = 0;
    int completedDays = 0;

    for (final record in records) {
      totalTilawahPages += record.tilawahPages;
      if (record.xpEarned > 0) {
        completedDays++;
      }
    }

    // Get session repository to get total days
    final sessionRepository = SessionRepository();
    final session = await sessionRepository.getActiveSession();
    final totalDays = session?.totalDays ?? 30;
    final consistencyPercentage = totalDays > 0 ? (completedDays / totalDays) * 100 : 0.0;

    return {
      'totalTilawahPages': totalTilawahPages,
      'consistencyPercentage': consistencyPercentage,
      'completedDays': completedDays,
    };
  }

  Future<List<DailyRecord>> _loadDailyRecords(int sessionId) async {
    final dailyRecordRepository = DailyRecordRepository();
    return await dailyRecordRepository.getRecordsForSession(sessionId);
  }
}
