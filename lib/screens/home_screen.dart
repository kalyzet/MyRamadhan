import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/daily_record.dart';
import '../widgets/create_session_dialog.dart';
import '../widgets/xp_gain_animation.dart';
import '../widgets/error_display.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/real_time_clock_widget.dart';

/// Home screen displaying daily checklist and progress
/// Requirements: 10.3, 11.1
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  OverlayEntry? _xpOverlay;
  OverlayEntry? _levelUpOverlay;

  @override
  void initState() {
    super.initState();
    
    // Set up animation callbacks after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      
      appState.onXpGained = (xpAmount) {
        _showXpGainAnimation(xpAmount);
      };
      
      appState.onLevelUp = (newLevel) {
        _showLevelUpAnimation(newLevel);
      };
    });
  }

  @override
  void dispose() {
    _xpOverlay?.remove();
    _levelUpOverlay?.remove();
    super.dispose();
  }

  void _showXpGainAnimation(int xpAmount) {
    _xpOverlay?.remove();
    
    _xpOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: MediaQuery.of(context).size.width * 0.5 - 60,
        child: XpGainAnimation(
          xpAmount: xpAmount,
          onComplete: () {
            _xpOverlay?.remove();
            _xpOverlay = null;
          },
        ),
      ),
    );
    
    Overlay.of(context).insert(_xpOverlay!);
  }

  void _showLevelUpAnimation(int newLevel) {
    _levelUpOverlay?.remove();
    
    _levelUpOverlay = OverlayEntry(
      builder: (context) => Center(
        child: LevelUpAnimation(
          newLevel: newLevel,
          onComplete: () {
            _levelUpOverlay?.remove();
            _levelUpOverlay = null;
          },
        ),
      ),
    );
    
    Overlay.of(context).insert(_levelUpOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: _overlayKey,
      initialEntries: [
        OverlayEntry(
          builder: (context) => _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final t = appState.localizationService.translate;
        
        // Show error message if present
        if (appState.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorDisplay.showSnackBar(context, appState.errorMessage!);
            appState.clearError();
          });
        }

        if (appState.isLoading) {
          return const HomeScreenSkeleton();
        }

        if (appState.activeSession == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 80,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('home.no_session_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('home.no_session_message'),
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => const CreateSessionDialog(),
                      );
                      
                      // If session was created successfully, reload
                      if (result == true && context.mounted) {
                        // AppState will automatically reload after creation
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(t('home.create_session_button')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final session = appState.activeSession!;
        final stats = appState.currentStats;
        final todayRecord = appState.todayRecord;
        final sideQuests = appState.todaySideQuests;

        // Calculate current Ramadhan day
        final today = DateTime.now();
        final daysSinceStart = today.difference(session.startDate).inDays + 1;
        final currentDay = daysSinceStart.clamp(1, session.totalDays);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Real-time clock widget
              const RealTimeClockWidget(),
              const SizedBox(height: 16),

              // Ramadhan day indicator
              _buildDayIndicator(context, currentDay, session.totalDays),
              const SizedBox(height: 24),

              // XP bar with level and progress
              if (stats != null) _buildXpBar(context, stats),
              const SizedBox(height: 24),

              // Current streak information
              if (stats != null) _buildStreakInfo(context, stats),
              const SizedBox(height: 24),

              // Daily checklist
              _buildDailyChecklist(context, appState, todayRecord),
              const SizedBox(height: 24),

              // Today's side quests
              if (sideQuests.isNotEmpty) _buildSideQuests(context, sideQuests),
            ],
          ),
        );
      },
    );
  }
}

  Widget _buildDayIndicator(BuildContext context, int currentDay, int totalDays) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
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
        children: [
          Text(
            t('home.ramadhan_day'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currentDay',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${t('home.of')} $totalDays',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar(BuildContext context, stats) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Dark gray
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD97706), // Gold
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${t('home.level')} $currentLevel',
                style: const TextStyle(
                  color: Color(0xFFD97706), // Gold
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalXp ${t('home.xp')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
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
              backgroundColor: const Color(0xFF374151),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD97706), // Gold
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$xpInCurrentLevel / $xpRequiredForNextLevel ${t('home.to_level')} ${currentLevel + 1}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakInfo(BuildContext context, stats) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStreakItem(
            '🔥',
            t('home.perfect'),
            stats.currentStreak,
          ),
          _buildStreakItem(
            '🤲',
            t('home.prayer'),
            stats.prayerStreak,
          ),
          _buildStreakItem(
            '📖',
            t('home.tilawah_streak'),
            stats.tilawahStreak,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String emoji, String label, int count) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChecklist(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
  ) {
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
          Text(
            t('home.daily_checklist'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Prayer section
          Text(
            t('home.prayers'),
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildPrayerCheckboxes(context, appState, todayRecord),
          const SizedBox(height: 16),

          // Other ibadah
          Text(
            t('home.other_ibadah'),
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildOtherIbadahCheckboxes(context, appState, todayRecord),
        ],
      ),
    );
  }

  Widget _buildPrayerCheckboxes(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
  ) {
    final t = appState.localizationService.translate;
    
    return Column(
      children: [
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.fajr'),
          todayRecord?.fajrComplete ?? false,
          (value) => _updatePrayer(context, appState, todayRecord, 'fajr', value),
        ),
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.dhuhr'),
          todayRecord?.dhuhrComplete ?? false,
          (value) => _updatePrayer(context, appState, todayRecord, 'dhuhr', value),
        ),
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.asr'),
          todayRecord?.asrComplete ?? false,
          (value) => _updatePrayer(context, appState, todayRecord, 'asr', value),
        ),
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.maghrib'),
          todayRecord?.maghribComplete ?? false,
          (value) => _updatePrayer(context, appState, todayRecord, 'maghrib', value),
        ),
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.isha'),
          todayRecord?.ishaComplete ?? false,
          (value) => _updatePrayer(context, appState, todayRecord, 'isha', value),
        ),
      ],
    );
  }

  Widget _buildOtherIbadahCheckboxes(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
  ) {
    final t = appState.localizationService.translate;
    
    return Column(
      children: [
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.puasa'),
          todayRecord?.puasaComplete ?? false,
          (value) => _updateOtherIbadah(context, appState, todayRecord, 'puasa', value),
        ),
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.tarawih'),
          todayRecord?.tarawihComplete ?? false,
          (value) => _updateOtherIbadah(context, appState, todayRecord, 'tarawih', value),
        ),
        _buildCheckboxTile(
          context,
          appState,
          todayRecord,
          t('home.dzikir'),
          todayRecord?.dzikirComplete ?? false,
          (value) => _updateOtherIbadah(context, appState, todayRecord, 'dzikir', value),
        ),
        const SizedBox(height: 16),
        // Tilawah input
        _buildTilawahInput(context, appState, todayRecord),
        const SizedBox(height: 12),
        // Sedekah input
        _buildSedekahInput(context, appState, todayRecord),
      ],
    );
  }

  Widget _buildTilawahInput(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
  ) {
    final t = appState.localizationService.translate;
    final controller = TextEditingController(
      text: todayRecord?.tilawahPages.toString() ?? '0',
    );

    return Row(
      children: [
        const Icon(
          Icons.menu_book,
          color: Color(0xFF10B981),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t('home.tilawah'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
              hintText: '0',
              hintStyle: const TextStyle(color: Colors.white38),
            ),
            onSubmitted: (value) {
              _updateTilawah(context, appState, todayRecord, value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSedekahInput(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
  ) {
    final t = appState.localizationService.translate;
    final controller = TextEditingController(
      text: todayRecord?.sedekahAmount.toString() ?? '0',
    );

    return Row(
      children: [
        const Icon(
          Icons.volunteer_activism,
          color: Color(0xFFD97706),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t('home.sedekah'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD97706)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD97706)),
              ),
              hintText: '0',
              hintStyle: const TextStyle(color: Colors.white38),
            ),
            onSubmitted: (value) {
              _updateSedekah(context, appState, todayRecord, value);
            },
          ),
        ),
      ],
    );
  }

  void _updateTilawah(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
    String value,
  ) {
    final t = appState.localizationService.translate;
    final session = appState.activeSession;
    if (session == null) return;

    // Validate input
    final pages = int.tryParse(value);
    if (pages == null || pages < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('home.invalid_pages')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Maximum pages in Quran is 604
    if (pages > 604) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('home.max_pages')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Create or update the record
    final record = todayRecord ??
        DailyRecord(
          sessionId: session.id!,
          date: normalizedToday,
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 0,
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: 0,
          isPerfectDay: false,
        );

    final updatedRecord = record.copyWith(tilawahPages: pages);
    appState.updateDailyRecord(updatedRecord);
  }

  void _updateSedekah(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
    String value,
  ) {
    final t = appState.localizationService.translate;
    final session = appState.activeSession;
    if (session == null) return;

    // Validate input
    final amount = double.tryParse(value);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('home.invalid_amount')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Create or update the record
    final record = todayRecord ??
        DailyRecord(
          sessionId: session.id!,
          date: normalizedToday,
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 0,
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: 0,
          isPerfectDay: false,
        );

    final updatedRecord = record.copyWith(sedekahAmount: amount);
    appState.updateDailyRecord(updatedRecord);
  }

  Widget _buildCheckboxTile(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return AnimatedCheckboxTile(
      title: title,
      value: value,
      onChanged: onChanged,
    );
  }

  void _updatePrayer(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
    String prayer,
    bool value,
  ) {
    final session = appState.activeSession;
    if (session == null) return;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Create or update the record
    final record = todayRecord ??
        DailyRecord(
          sessionId: session.id!,
          date: normalizedToday,
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 0,
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: 0,
          isPerfectDay: false,
        );

    DailyRecord updatedRecord;
    switch (prayer) {
      case 'fajr':
        updatedRecord = record.copyWith(fajrComplete: value);
        break;
      case 'dhuhr':
        updatedRecord = record.copyWith(dhuhrComplete: value);
        break;
      case 'asr':
        updatedRecord = record.copyWith(asrComplete: value);
        break;
      case 'maghrib':
        updatedRecord = record.copyWith(maghribComplete: value);
        break;
      case 'isha':
        updatedRecord = record.copyWith(ishaComplete: value);
        break;
      default:
        return;
    }

    appState.updateDailyRecord(updatedRecord);
  }

  void _updateOtherIbadah(
    BuildContext context,
    AppState appState,
    DailyRecord? todayRecord,
    String ibadah,
    bool value,
  ) {
    final session = appState.activeSession;
    if (session == null) return;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Create or update the record
    final record = todayRecord ??
        DailyRecord(
          sessionId: session.id!,
          date: normalizedToday,
          fajrComplete: false,
          dhuhrComplete: false,
          asrComplete: false,
          maghribComplete: false,
          ishaComplete: false,
          puasaComplete: false,
          tarawihComplete: false,
          tilawahPages: 0,
          dzikirComplete: false,
          sedekahAmount: 0,
          xpEarned: 0,
          isPerfectDay: false,
        );

    DailyRecord updatedRecord;
    switch (ibadah) {
      case 'puasa':
        updatedRecord = record.copyWith(puasaComplete: value);
        break;
      case 'tarawih':
        updatedRecord = record.copyWith(tarawihComplete: value);
        break;
      case 'dzikir':
        updatedRecord = record.copyWith(dzikirComplete: value);
        break;
      default:
        return;
    }

    appState.updateDailyRecord(updatedRecord);
  }

  Widget _buildSideQuests(BuildContext context, List sideQuests) {
    final appState = Provider.of<AppState>(context, listen: false);
    final t = appState.localizationService.translate;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD97706).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '⭐',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                t('home.side_quests'),
                style: const TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sideQuests.map((quest) => _buildSideQuestTile(quest)),
        ],
      ),
    );
  }

  Widget _buildSideQuestTile(quest) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final t = appState.localizationService.translate;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: quest.completed
                ? null
                : () async {
                    // Complete the side quest
                    try {
                      await appState.completeSideQuest(quest.id);
                      
                      // Show success message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${t(quest.title)} ${t('home.quest_completed')} +${quest.xpReward} ${t('home.xp')}',
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
                            content: Text('${t('home.error_completing_quest')} $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    quest.completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: quest.completed
                        ? const Color(0xFF10B981)
                        : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(quest.title),
                          style: TextStyle(
                            color: quest.completed
                                ? Colors.white54
                                : Colors.white,
                            fontSize: 14,
                            decoration: quest.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (quest.description.isNotEmpty)
                          Text(
                            t(quest.description),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '+${quest.xpReward} ${t('home.xp')}',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

/// Animated checkbox tile with smooth transitions
/// Requirements: 11.2 (60 FPS animations)
class AnimatedCheckboxTile extends StatefulWidget {
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const AnimatedCheckboxTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  State<AnimatedCheckboxTile> createState() => _AnimatedCheckboxTileState();
}

class _AnimatedCheckboxTileState extends State<AnimatedCheckboxTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(bool? newValue) {
    if (newValue != null) {
      // Trigger animation
      _controller.forward().then((_) {
        _controller.reverse();
      });
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: CheckboxListTile(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        value: widget.value,
        onChanged: _handleTap,
        activeColor: const Color(0xFF10B981), // Emerald
        checkColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
