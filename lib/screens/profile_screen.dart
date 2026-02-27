import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/ramadhan_session.dart';
import '../repositories/session_repository.dart';
import '../widgets/create_session_dialog.dart';
import 'ramadhan_history_screen.dart';
import '../widgets/skeleton_loader.dart';

/// Profile screen displaying user session information and team credits
/// Requirements: 13.1, 13.2, 13.3
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const ProfileScreenSkeleton();
        }

        final activeSession = appState.activeSession;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Create New Session Button
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const CreateSessionDialog(),
                  );
                  
                  // Session will automatically reload after creation
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session created! Previous session deactivated.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create New Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Session Information
              if (activeSession != null)
                _buildSessionInfoCard(activeSession)
              else
                _buildNoSessionCard(),
              const SizedBox(height: 16),

              // Ramadhan History Link
              _buildHistoryCard(context),
              const SizedBox(height: 16),

              // Language Selection
              _buildLanguageCard(context, appState),
              const SizedBox(height: 16),

              // Kalyzet Team Credits
              _buildTeamCreditsCard(),
              const SizedBox(height: 16),

              // About Section
              _buildAboutCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionInfoCard(RamadhanSession session) {
    final today = DateTime.now();
    final daysSinceStart = today.difference(session.startDate).inDays + 1;
    final currentDay = daysSinceStart.clamp(1, session.totalDays);
    final daysRemaining = session.totalDays - currentDay;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)], // Emerald gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Active Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSessionInfoRow('Year', '${session.year}'),
          const SizedBox(height: 12),
          _buildSessionInfoRow(
            'Duration',
            '${session.totalDays} days',
          ),
          const SizedBox(height: 12),
          _buildSessionInfoRow(
            'Current Day',
            'Day $currentDay of ${session.totalDays}',
          ),
          const SizedBox(height: 12),
          _buildSessionInfoRow(
            'Days Remaining',
            '$daysRemaining days',
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF374151),
          width: 2,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white38,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'No Active Session',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a new Ramadhan session to start tracking your journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RamadhanHistoryScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD97706).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history,
                color: Color(0xFFD97706),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ramadhan History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View all your previous sessions',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, AppState appState) {
    // Get current language from AppState
    final currentLanguage = appState.currentLanguage;

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
          const Row(
            children: [
              Icon(
                Icons.language,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Language / Bahasa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOption(
                  context,
                  appState,
                  'en',
                  'English',
                  '🇬🇧',
                  currentLanguage == 'en',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageOption(
                  context,
                  appState,
                  'id',
                  'Bahasa Indonesia',
                  '🇮🇩',
                  currentLanguage == 'id',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    AppState appState,
    String languageCode,
    String languageName,
    String flag,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () async {
        if (!isSelected) {
          try {
            await appState.changeLanguage(languageCode);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    languageCode == 'en'
                        ? 'Language changed to English'
                        : 'Bahasa diubah ke Bahasa Indonesia',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error changing language: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFF374151),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              languageName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF10B981) : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCreditsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Team Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'icon/creator.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group,
                    size: 60,
                    color: Colors.white38,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Team Name
          const Text(
            'Developed by',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kalyzet Team',
            style: TextStyle(
              color: Color(0xFFD97706), // Gold
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          const Text(
            'Building tools to enhance your spiritual journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'About',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAboutRow('App Name', 'MyRamadhan'),
          const SizedBox(height: 12),
          _buildAboutRow('Version', '1.0.0'),
          const SizedBox(height: 12),
          _buildAboutRow('Platform', 'Flutter'),
          const SizedBox(height: 16),
          const Text(
            'MyRamadhan is a gamified companion app that helps you track your ibadah activities, build consistency through streaks, and reflect on your spiritual journey during Ramadhan.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
