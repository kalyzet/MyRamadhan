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
        final t = appState.localizationService.translate;
        
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
                      SnackBar(
                        content: Text(t('profile.session_created')),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: Text(t('profile.create_new_session')),
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
                _buildSessionInfoCard(context, activeSession)
              else
                _buildNoSessionCard(context),
              const SizedBox(height: 16),

              // Ramadhan History Link
              _buildHistoryCard(context),
              const SizedBox(height: 16),

              // Language Selection
              _buildLanguageCard(context, appState),
              const SizedBox(height: 16),

              // Kalyzet Team Credits
              _buildTeamCreditsCard(context),
              const SizedBox(height: 16),

              // About Section
              _buildAboutCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionInfoCard(BuildContext context, RamadhanSession session) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
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
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                t('profile.active_session'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSessionInfoRow(t('profile.year'), '${session.year}'),
          const SizedBox(height: 12),
          _buildSessionInfoRow(
            t('profile.duration'),
            '${session.totalDays} ${t('create_session.days')}',
          ),
          const SizedBox(height: 12),
          _buildSessionInfoRow(
            t('profile.current_day'),
            '${t('profile.day_of')} $currentDay ${t('home.of')} ${session.totalDays}',
          ),
          const SizedBox(height: 12),
          _buildSessionInfoRow(
            t('profile.days_remaining'),
            '$daysRemaining ${t('create_session.days')}',
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionCard(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
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
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.white38,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            t('profile.no_active_session'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('profile.no_session_message'),
            textAlign: TextAlign.center,
            style: const TextStyle(
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
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('profile.ramadhan_history'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('profile.view_previous_sessions'),
                    style: const TextStyle(
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
    final t = appState.localizationService.translate;
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
          Row(
            children: [
              const Icon(
                Icons.language,
                color: Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                t('profile.language'),
                style: const TextStyle(
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

  Widget _buildTeamCreditsCard(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
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
          Text(
            t('profile.developed_by'),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('profile.kalyzet_team'),
            style: const TextStyle(
              color: Color(0xFFD97706), // Gold
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            t('profile.team_description'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
    return Container(
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
                Icons.info,
                color: Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                t('profile.about'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAboutRow(t('profile.app_name_label'), t('app_name')),
          const SizedBox(height: 12),
          _buildAboutRow(t('profile.version'), '1.0.0'),
          const SizedBox(height: 12),
          _buildAboutRow(t('profile.platform'), 'Flutter'),
          const SizedBox(height: 16),
          Text(
            t('profile.app_description'),
            style: const TextStyle(
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
