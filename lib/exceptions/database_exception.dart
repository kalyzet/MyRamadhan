/// Custom exception for database-related errors
/// Provides user-friendly error messages and retry information
class DatabaseException implements Exception {
  final String message;
  final String userMessage;
  final bool isRetryable;
  final dynamic originalError;

  DatabaseException({
    required this.message,
    required this.userMessage,
    this.isRetryable = false,
    this.originalError,
  });

  @override
  String toString() => 'DatabaseException: $message';

  /// Factory for connection errors
  factory DatabaseException.connection({dynamic originalError}) {
    return DatabaseException(
      message: 'Failed to connect to database',
      userMessage: 'Unable to access local storage. Please try again.',
      isRetryable: true,
      originalError: originalError,
    );
  }

  /// Factory for constraint violation errors
  factory DatabaseException.constraint({dynamic originalError}) {
    return DatabaseException(
      message: 'Database constraint violation',
      userMessage: 'This data conflicts with existing records.',
      isRetryable: false,
      originalError: originalError,
    );
  }

  /// Factory for transaction errors
  factory DatabaseException.transaction({dynamic originalError}) {
    return DatabaseException(
      message: 'Database transaction failed',
      userMessage: 'Failed to save changes. Please try again.',
      isRetryable: true,
      originalError: originalError,
    );
  }

  /// Factory for corruption errors
  factory DatabaseException.corruption({dynamic originalError}) {
    return DatabaseException(
      message: 'Database corruption detected',
      userMessage:
          'Local storage is corrupted. Please contact support or reinstall the app.',
      isRetryable: false,
      originalError: originalError,
    );
  }

  /// Factory for general database errors
  factory DatabaseException.general({
    required String message,
    dynamic originalError,
  }) {
    return DatabaseException(
      message: message,
      userMessage: 'An error occurred while accessing data. Please try again.',
      isRetryable: true,
      originalError: originalError,
    );
  }
}
