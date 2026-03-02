import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../providers/app_state.dart';

class RealTimeClockWidget extends StatefulWidget {
  final bool showDate;
  final bool showTimezone;
  final TextStyle? timeStyle;
  final TextStyle? dateStyle;
  final DateTime Function()? getCurrentTime; // Injectable for testing
  final LocalizationService? localizationService; // Injectable for testing

  const RealTimeClockWidget({
    Key? key,
    this.showDate = true,
    this.showTimezone = true,
    this.timeStyle,
    this.dateStyle,
    this.getCurrentTime,
    this.localizationService,
  }) : super(key: key);

  @override
  State<RealTimeClockWidget> createState() => _RealTimeClockWidgetState();
}

class _RealTimeClockWidgetState extends State<RealTimeClockWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = _getTime();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTime);
  }

  DateTime _getTime() {
    return widget.getCurrentTime?.call() ?? DateTime.now();
  }

  void _updateTime(Timer timer) {
    setState(() {
      _currentTime = _getTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime() {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    final second = _currentTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _formatDate(LocalizationService localizationService) {
    final t = localizationService.translate;
    
    // Map weekday numbers to translation keys
    final dayKeys = [
      'date.days.monday',    // 1
      'date.days.tuesday',   // 2
      'date.days.wednesday', // 3
      'date.days.thursday',  // 4
      'date.days.friday',    // 5
      'date.days.saturday',  // 6
      'date.days.sunday',    // 7
    ];
    
    // Map month numbers to translation keys
    final monthKeys = [
      'date.months.january',   // 1
      'date.months.february',  // 2
      'date.months.march',     // 3
      'date.months.april',     // 4
      'date.months.may',       // 5
      'date.months.june',      // 6
      'date.months.july',      // 7
      'date.months.august',    // 8
      'date.months.september', // 9
      'date.months.october',   // 10
      'date.months.november',  // 11
      'date.months.december',  // 12
    ];
    
    final dayName = t(dayKeys[_currentTime.weekday - 1]);
    final day = _currentTime.day.toString().padLeft(2, '0');
    final monthName = t(monthKeys[_currentTime.month - 1]);
    final year = _currentTime.year;
    
    return '$dayName, $day $monthName $year';
  }

  String _getTimezone() {
    final offset = _currentTime.timeZoneOffset;
    if (offset.inHours == 7) return 'WIB';
    if (offset.inHours == 8) return 'WITA';
    if (offset.inHours == 9) return 'WIT';
    return 'WIB'; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    // If localizationService is provided directly (for testing), use it without Consumer
    if (widget.localizationService != null) {
      return _buildWidget(context, widget.localizationService!);
    }
    
    // Otherwise, use Consumer to get localizationService from AppState
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return _buildWidget(context, appState.localizationService);
      },
    );
  }

  Widget _buildWidget(BuildContext context, LocalizationService localizationService) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive font sizes
    final timeFontSize = screenWidth < 360 ? 28.0 : 34.0;
    final dateFontSize = screenWidth < 360 ? 13.0 : 15.0;
    final timezoneFontSize = screenWidth < 360 ? 11.0 : 13.0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time with timezone
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    _formatTime(),
                    key: ValueKey<String>(_formatTime()),
                    style: widget.timeStyle ??
                        TextStyle(
                          fontSize: timeFontSize,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                  ),
                ),
                if (widget.showTimezone) ...[
                  const SizedBox(width: 8),
                  Text(
                    _getTimezone(),
                    style: TextStyle(
                      fontSize: timezoneFontSize,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
            // Date
            if (widget.showDate) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: Text(
                  _formatDate(localizationService),
                  key: ValueKey<String>(_formatDate(localizationService)),
                  style: widget.dateStyle ??
                      TextStyle(
                        fontSize: dateFontSize,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
