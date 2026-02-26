import 'dart:async';
import 'package:flutter/material.dart';

class RealTimeClockWidget extends StatefulWidget {
  final bool showDate;
  final bool showTimezone;
  final TextStyle? timeStyle;
  final TextStyle? dateStyle;
  final DateTime Function()? getCurrentTime; // Injectable for testing

  const RealTimeClockWidget({
    Key? key,
    this.showDate = true,
    this.showTimezone = true,
    this.timeStyle,
    this.dateStyle,
    this.getCurrentTime,
  }) : super(key: key);

  @override
  State<RealTimeClockWidget> createState() => _RealTimeClockWidgetState();
}

class _RealTimeClockWidgetState extends State<RealTimeClockWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  static const List<String> _indonesianDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _indonesianMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

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

  String _formatDate() {
    final dayName = _indonesianDays[_currentTime.weekday - 1];
    final day = _currentTime.day.toString().padLeft(2, '0');
    final monthName = _indonesianMonths[_currentTime.month - 1];
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
                  _formatDate(),
                  key: ValueKey<String>(_formatDate()),
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
