import 'package:flutter/material.dart';
import '../models/ramadhan_session.dart';
import '../models/user_stats.dart';
import '../models/daily_record.dart';
import '../repositories/session_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/daily_record_repository.dart';
import 'session_comparison_screen.dart';
import 'package:intl/intl.dart';

/// Ramadhan History screen displaying all previous sessions
/// Requirements: 12.1
class RamadhanHistoryScreen extends StatefulWidget {
  const RamadhanHistoryScreen({super.key});

  @override
  State<RamadhanHistoryScreen> createState() => _RamadhanHistoryScreenState();
}

class _RamadhanHistoryScreenState extends State<RamadhanHistoryScreen> {
  final SessionRepository _sessionRepository = SessionRepository();
  final StatsRepository _statsRepository = StatsRepository();
  final DailyRecordRepository _dailyRecordRepository = DailyRecordRepository();

  List<RamadhanSession>? _sessions;
  Map<int, UserStats>? _statsMap;
  Map<int, double>? _completionRates;
  bool _isLoading = true;
  Set<int> _selectedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all sessions
      final sessions = await _sessionRepository.getAllSessions();

      // Load stats and completion rates for each session
      final statsMap = <int, UserStats>{};
      final completionRates = <int, double>{};

      for (final session in sessions) {
        if (session.id != null) {
          // Load stats
          final stats = await _statsRepository.getStatsForSession(session.id!);
          if (stats != null) {
            statsMap[session.id!] = stats;
          }

          // Calculate completion rate
          final records = await _dailyRecordRepository.getRecordsForSession(session.id!);
          final completedDays = records.where((r) => r.xpEarned > 0).length;
          final completionRate = session.totalDays > 0
              ? (completedDays / session.totalDays) * 100
              : 0.0;
          completionRates[session.id!] = completionRate;
        }
      }

      setState(() {
        _sessions = sessions;
        _statsMap = statsMap;
        _completionRates = completionRates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Ramadhan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedSessionIds.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows, color: Colors.white),
              onPressed: _navigateToComparison,
              tooltip: 'Bandingkan Sesi',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : _buildHistoryContent(),
    );
  }

  void _navigateToComparison() {
    final selectedSessions = _sessions!
        .where((s) => _selectedSessionIds.contains(s.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionComparisonScreen(
          sessions: selectedSessions,
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_sessions == null || _sessions!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.white38,
            ),
            SizedBox(height: 16),
            Text(
              'Belum Ada Sesi Ramadhan',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Buat sesi pertama Anda untuk mulai melacak',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Sort sessions by year (most recent first)
    final sortedSessions = List<RamadhanSession>.from(_sessions!);
    sortedSessions.sort((a, b) => b.year.compareTo(a.year));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(sortedSessions.length),
          const SizedBox(height: 20),

          // Selection hint
          if (_selectedSessionIds.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ketuk sesi untuk memilihnya untuk perbandingan',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedSessionIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD97706).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedSessionIds.length} sesi dipilih',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSessionIds.clear();
                      });
                    },
                    child: const Text(
                      'Bersihkan',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Sessions list
          ...sortedSessions.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSessionCard(session),
              )),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalSessions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309)], // Gold gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            '$totalSessions',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            totalSessions == 1 ? 'Sesi Ramadhan' : 'Sesi Ramadhan',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(RamadhanSession session) {
    final stats = _statsMap?[session.id];
    final completionRate = _completionRates?[session.id] ?? 0.0;
    final dateFormat = DateFormat('MMM d, y');
    final isSelected = _selectedSessionIds.contains(session.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSessionIds.remove(session.id);
          } else {
            _selectedSessionIds.add(session.id!);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD97706)
                : session.isActive
                    ? const Color(0xFF10B981).withOpacity(0.5)
                    : const Color(0xFF374151).withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with year and active badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD97706).withOpacity(0.1)
                    : session.isActive
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF374151).withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.calendar_month,
                        color: isSelected
                            ? const Color(0xFFD97706)
                            : const Color(0xFFD97706),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ramadhan ${session.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (session.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Session details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range
                  Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        color: Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${dateFormat.format(session.startDate)} - ${dateFormat.format(session.endDate)}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats grid
                  if (stats != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Level',
                            '${stats.level}',
                            Icons.trending_up,
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'Total XP',
                            '${stats.totalXp}',
                            Icons.stars,
                            const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Streak Terpanjang',
                            '${stats.longestStreak}',
                            Icons.local_fire_department,
                            const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'Penyelesaian',
                            '${completionRate.toStringAsFixed(0)}%',
                            Icons.check_circle,
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const Center(
                      child: Text(
                        'Tidak ada statistik tersedia',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
