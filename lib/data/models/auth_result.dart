import 'user.dart';

/// Result wrapper for authentication operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? errorCode;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  /// Create a successful result
  factory AuthResult.success(User? user) {
    return AuthResult._(
      isSuccess: true,
      user: user,
    );
  }

  /// Create a failure result
  factory AuthResult.failure(String message, [String? code]) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  /// Check if the result is a failure
  bool get isFailure => !isSuccess;

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult.success(user: ${user?.email})';
    } else {
      return 'AuthResult.failure(message: $errorMessage, code: $errorCode)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AuthResult &&
      other.isSuccess == isSuccess &&
      other.user == user &&
      other.errorMessage == errorMessage &&
      other.errorCode == errorCode;
  }

  @override
  int get hashCode {
    return isSuccess.hashCode ^
      user.hashCode ^
      errorMessage.hashCode ^
      errorCode.hashCode;
  }
}
