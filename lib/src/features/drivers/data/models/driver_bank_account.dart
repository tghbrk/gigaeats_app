import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_bank_account.freezed.dart';
part 'driver_bank_account.g.dart';

/// Model for driver bank account
@freezed
class DriverBankAccount with _$DriverBankAccount {
  const factory DriverBankAccount({
    required String id,
    required String driverId,
    required String userId,
    required String bankName,
    String? bankCode,
    required String accountNumber,
    required String accountHolderName,
    String? accountType,
    required String verificationStatus,
    String? verificationMethod,
    String? verificationReference,
    int? verificationAttempts,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? lastUsedAt,
    required bool isPrimary,
    required bool isActive,
    Map<String, dynamic>? encryptedDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _DriverBankAccount;

  factory DriverBankAccount.fromJson(Map<String, dynamic> json) =>
      _$DriverBankAccountFromJson(json);
}

/// Extension for bank account verification status
extension DriverBankAccountStatus on DriverBankAccount {
  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isFailed => verificationStatus == 'failed';
  bool get isExpired => verificationStatus == 'expired';
  
  String get statusDisplayName {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending Verification';
      case 'failed':
        return 'Verification Failed';
      case 'expired':
        return 'Verification Expired';
      default:
        return verificationStatus;
    }
  }
  
  String get accountTypeDisplayName {
    switch (accountType) {
      case 'savings':
        return 'Savings Account';
      case 'current':
        return 'Current Account';
      default:
        return accountType ?? 'Unknown';
    }
  }
}
