import 'package:equatable/equatable.dart';

/// Customer wallet specific error types
enum CustomerWalletErrorType {
  networkError,
  authenticationError,
  walletNotFound,
  insufficientBalance,
  transactionFailed,
  serverError,
  unknownError,
}

/// Customer wallet error model with user-friendly messages
class CustomerWalletError extends Equatable {
  final CustomerWalletErrorType type;
  final String message;
  final String userFriendlyMessage;
  final String? technicalDetails;
  final bool isRetryable;
  final DateTime timestamp;

  const CustomerWalletError({
    required this.type,
    required this.message,
    required this.userFriendlyMessage,
    this.technicalDetails,
    required this.isRetryable,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        type,
        message,
        userFriendlyMessage,
        technicalDetails,
        isRetryable,
        timestamp,
      ];

  /// Create error from exception
  factory CustomerWalletError.fromException(Exception exception) {
    final message = exception.toString();
    final timestamp = DateTime.now();

    // Determine error type based on message content
    CustomerWalletErrorType type;
    String userFriendlyMessage;
    bool isRetryable;

    if (message.contains('User not authenticated') || message.contains('auth')) {
      type = CustomerWalletErrorType.authenticationError;
      userFriendlyMessage = 'Please log in again to access your wallet';
      isRetryable = false;
    } else if (message.contains('wallet not found') || message.contains('No wallet found')) {
      type = CustomerWalletErrorType.walletNotFound;
      userFriendlyMessage = 'Your wallet is being set up. Please try again in a moment';
      isRetryable = true;
    } else if (message.contains('insufficient') || message.contains('balance')) {
      type = CustomerWalletErrorType.insufficientBalance;
      userFriendlyMessage = 'Insufficient wallet balance for this transaction';
      isRetryable = false;
    } else if (message.contains('network') || message.contains('connection') || message.contains('timeout')) {
      type = CustomerWalletErrorType.networkError;
      userFriendlyMessage = 'Network connection issue. Please check your internet and try again';
      isRetryable = true;
    } else if (message.contains('server') || message.contains('500') || message.contains('503')) {
      type = CustomerWalletErrorType.serverError;
      userFriendlyMessage = 'Server is temporarily unavailable. Please try again later';
      isRetryable = true;
    } else if (message.contains('transaction') || message.contains('payment')) {
      type = CustomerWalletErrorType.transactionFailed;
      userFriendlyMessage = 'Transaction failed. Please try again or contact support';
      isRetryable = true;
    } else {
      type = CustomerWalletErrorType.unknownError;
      userFriendlyMessage = 'Something went wrong. Please try again';
      isRetryable = true;
    }

    return CustomerWalletError(
      type: type,
      message: message,
      userFriendlyMessage: userFriendlyMessage,
      technicalDetails: message,
      isRetryable: isRetryable,
      timestamp: timestamp,
    );
  }

  /// Create error from string message
  factory CustomerWalletError.fromMessage(String message) {
    return CustomerWalletError.fromException(Exception(message));
  }

  /// Create network error
  factory CustomerWalletError.networkError([String? details]) {
    return CustomerWalletError(
      type: CustomerWalletErrorType.networkError,
      message: 'Network error occurred',
      userFriendlyMessage: 'Network connection issue. Please check your internet and try again',
      technicalDetails: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Create authentication error
  factory CustomerWalletError.authenticationError([String? details]) {
    return CustomerWalletError(
      type: CustomerWalletErrorType.authenticationError,
      message: 'Authentication failed',
      userFriendlyMessage: 'Please log in again to access your wallet',
      technicalDetails: details,
      isRetryable: false,
      timestamp: DateTime.now(),
    );
  }

  /// Create wallet not found error
  factory CustomerWalletError.walletNotFound([String? details]) {
    return CustomerWalletError(
      type: CustomerWalletErrorType.walletNotFound,
      message: 'Wallet not found',
      userFriendlyMessage: 'Your wallet is being set up. Please try again in a moment',
      technicalDetails: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Create insufficient balance error
  factory CustomerWalletError.insufficientBalance(double required, double available) {
    return CustomerWalletError(
      type: CustomerWalletErrorType.insufficientBalance,
      message: 'Insufficient balance',
      userFriendlyMessage: 'Insufficient wallet balance. Required: RM ${required.toStringAsFixed(2)}, Available: RM ${available.toStringAsFixed(2)}',
      technicalDetails: 'Required: $required, Available: $available',
      isRetryable: false,
      timestamp: DateTime.now(),
    );
  }

  /// Create transaction failed error
  factory CustomerWalletError.transactionFailed([String? details]) {
    return CustomerWalletError(
      type: CustomerWalletErrorType.transactionFailed,
      message: 'Transaction failed',
      userFriendlyMessage: 'Transaction failed. Please try again or contact support',
      technicalDetails: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Create server error
  factory CustomerWalletError.serverError([String? details]) {
    return CustomerWalletError(
      type: CustomerWalletErrorType.serverError,
      message: 'Server error',
      userFriendlyMessage: 'Server is temporarily unavailable. Please try again later',
      technicalDetails: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Get icon for error type
  String get iconName {
    switch (type) {
      case CustomerWalletErrorType.networkError:
        return 'wifi_off';
      case CustomerWalletErrorType.authenticationError:
        return 'lock';
      case CustomerWalletErrorType.walletNotFound:
        return 'account_balance_wallet';
      case CustomerWalletErrorType.insufficientBalance:
        return 'money_off';
      case CustomerWalletErrorType.transactionFailed:
        return 'error';
      case CustomerWalletErrorType.serverError:
        return 'cloud_off';
      case CustomerWalletErrorType.unknownError:
        return 'help_outline';
    }
  }

  /// Get suggested action for error
  String get suggestedAction {
    switch (type) {
      case CustomerWalletErrorType.networkError:
        return 'Check your internet connection and try again';
      case CustomerWalletErrorType.authenticationError:
        return 'Please log in again';
      case CustomerWalletErrorType.walletNotFound:
        return 'Wait a moment and try again';
      case CustomerWalletErrorType.insufficientBalance:
        return 'Add funds to your wallet';
      case CustomerWalletErrorType.transactionFailed:
        return 'Try again or contact support';
      case CustomerWalletErrorType.serverError:
        return 'Wait a few minutes and try again';
      case CustomerWalletErrorType.unknownError:
        return 'Try again or contact support if the problem persists';
    }
  }

  /// Check if error occurred recently (within last 5 minutes)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes < 5;
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
