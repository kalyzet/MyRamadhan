/// Utility for normalizing DateTime values to midnight of the local day.
///
/// All day-difference calculations in the app must use midnight-normalized
/// dates so that time-of-day components never delay or skew day counting
/// (e.g. a session created at 22:00 advancing to "day 2" only at 22:00).
class DateNormalizer {
  DateNormalizer._();

  /// Returns [dateTime] truncated to midnight of the same local day.
  static DateTime normalize(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Returns today's date normalized to midnight.
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns the whole number of days between two dates, using
  /// midnight-normalized values so DST shifts cannot off-by-one the result.
  static int daysBetween(DateTime from, DateTime to) {
    return normalize(to).difference(normalize(from)).inDays;
  }
}
