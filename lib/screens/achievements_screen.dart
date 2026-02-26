import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/achievement.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton_loader.dart';

/// Achievements screen displaying locked and unlocked achievements
/// Requirements: 6.6
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const AchievementsScreenSkeleton();
        }

        if (appState.activeSession == null) {
          return const Center(
            child: Text(
              'No active session. Please create a new Ramadhan session.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }

        final achievements = appState.achievements;

        if (achievements.isEmpty) {
          return const Center(
            child: Text(
              'No achievements available.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Separate locked and unlocked achievements
        final unlockedAchievements =
            achievements.where((a) => a.unlocked).toList();
        final lockedAchievements =
            achievements.where((a) => !a.unlocked).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with progress
              _buildHeader(unlockedAchievements.length, achievements.length),
              const SizedBox(height: 24),

              // Unlocked achievements section
              if (unlockedAchievements.isNotEmpty) ...[
                const Text(
                  'Unlocked',
                  style: TextStyle(
                    color: Color(0xFFD97706), // Gold
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAchievementsGrid(unlockedAchievements, true),
                const SizedBox(height: 24),
              ],

              // Locked achievements section
              if (lockedAchievements.isNotEmpty) ...[
                const Text(
                  'Locked',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAchievementsGrid(lockedAchievements, false),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$unlocked / $total Unlocked',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Complete',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(List<Achievement> achievements, bool unlocked) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index], unlocked);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool unlocked) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFF1F2937) // Dark gray for unlocked
            : const Color(0xFF111827), // Darker gray for locked
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFD97706).withOpacity(0.5) // Gold border
              : const Color(0xFF374151).withOpacity(0.3), // Gray border
          width: 2,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: const Color(0xFFD97706).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            _buildAchievementIcon(achievement.iconName, unlocked),
            const SizedBox(height: 12),

            // Title
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Description or unlock date
            if (unlocked && achievement.unlockedDate != null)
              _buildUnlockDate(achievement.unlockedDate!)
            else
              _buildCriteria(achievement.description, unlocked),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementIcon(String iconName, bool unlocked) {
    // Map icon names to emojis
    String emoji;
    switch (iconName) {
      case 'first_day':
        emoji = '🌙';
        break;
      case 'seven_days':
        emoji = '🔥';
        break;
      case 'quran_100':
        emoji = '📖';
        break;
      case 'master':
        emoji = '👑';
        break;
      case 'prayer_warrior':
        emoji = '🤲';
        break;
      case 'generous':
        emoji = '💝';
        break;
      case 'night_prayer':
        emoji = '🌟';
        break;
      case 'quran_complete':
        emoji = '📚';
        break;
      default:
        emoji = '🏆';
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFFD97706).withOpacity(0.2) // Gold background
            : const Color(0xFF374151).withOpacity(0.3), // Gray background
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 32,
            color: unlocked ? null : Colors.white24,
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockDate(DateTime unlockedDate) {
    final formattedDate = DateFormat('MMM d, y').format(unlockedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.2), // Emerald background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              formattedDate,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteria(String description, bool unlocked) {
    return Text(
      description,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: unlocked ? Colors.white60 : Colors.white24,
        fontSize: 11,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
