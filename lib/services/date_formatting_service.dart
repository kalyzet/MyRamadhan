import '../services/localization_service.dart';

/// Service for formatting dates based on current locale
/// Uses translated month names from localization files
class DateFormattingService {
  final LocalizationService _localizationService;

  DateFormattingService(this._localizationService);

  /// Format a date using the current locale
  /// Returns date in format "MMM d, y" with translated month names
  /// Example: "May 7, 2026" (English) or "7 Mei 2026" (Indonesian)
  String formatDate(DateTime date) {
    final monthKey = _getMonthKey(date.month);
    final translatedMonth = _localizationService.translate('date.months.$monthKey');
    
    // Use Indonesian format (day month year) for Indonesian, English format for English
    if (_localizationService.currentLanguage == 'id') {
      return '${date.day} $translatedMonth ${date.year}';
    } else {
      return '$translatedMonth ${date.day}, ${date.year}';
    }
  }

  /// Get the month key for translation lookup
  String _getMonthKey(int month) {
    switch (month) {
      case 1:
        return 'january';
      case 2:
        return 'february';
      case 3:
        return 'march';
      case 4:
        return 'april';
      case 5:
        return 'may';
      case 6:
        return 'june';
      case 7:
        return 'july';
      case 8:
        return 'august';
      case 9:
        return 'september';
      case 10:
        return 'october';
      case 11:
        return 'november';
      case 12:
        return 'december';
      default:
        return 'january';
    }
  }
}