import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_fees.g.dart';

/// Enum for transfer fee types
enum TransferFeeType {
  @JsonValue('fixed')
  fixed,
  @JsonValue('percentage')
  percentage,
  @JsonValue('tiered')
  tiered,
}

/// Transfer fees model for fee calculation
@JsonSerializable()
class TransferFees extends Equatable {
  final String id;
  final TransferFeeType feeType;
  final String feeName;
  final String? description;
  final double? fixedAmount;
  final double? percentageRate;
  final double? minimumFee;
  final double? maximumFee;
  final List<Map<String, dynamic>>? tierRanges;
  final String? userTier;
  final String currency;
  final bool isActive;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const TransferFees({
    required this.id,
    required this.feeType,
    required this.feeName,
    this.description,
    this.fixedAmount,
    this.percentageRate,
    this.minimumFee,
    this.maximumFee,
    this.tierRanges,
    this.userTier,
    required this.currency,
    required this.isActive,
    required this.effectiveFrom,
    this.effectiveUntil,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory TransferFees.fromJson(Map<String, dynamic> json) =>
      _$TransferFeesFromJson(json);

  Map<String, dynamic> toJson() => _$TransferFeesToJson(this);

  TransferFees copyWith({
    String? id,
    TransferFeeType? feeType,
    String? feeName,
    String? description,
    double? fixedAmount,
    double? percentageRate,
    double? minimumFee,
    double? maximumFee,
    List<Map<String, dynamic>>? tierRanges,
    String? userTier,
    String? currency,
    bool? isActive,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return TransferFees(
      id: id ?? this.id,
      feeType: feeType ?? this.feeType,
      feeName: feeName ?? this.feeName,
      description: description ?? this.description,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      percentageRate: percentageRate ?? this.percentageRate,
      minimumFee: minimumFee ?? this.minimumFee,
      maximumFee: maximumFee ?? this.maximumFee,
      tierRanges: tierRanges ?? this.tierRanges,
      userTier: userTier ?? this.userTier,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveUntil: effectiveUntil ?? this.effectiveUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        feeType,
        feeName,
        description,
        fixedAmount,
        percentageRate,
        minimumFee,
        maximumFee,
        tierRanges,
        userTier,
        currency,
        isActive,
        effectiveFrom,
        effectiveUntil,
        createdAt,
        updatedAt,
        createdBy,
      ];

  /// Calculate fee for a given amount
  double calculateFee(double amount) {
    double calculatedFee = 0.0;

    switch (feeType) {
      case TransferFeeType.fixed:
        calculatedFee = fixedAmount ?? 0.0;
        break;
      case TransferFeeType.percentage:
        calculatedFee = amount * (percentageRate ?? 0.0);
        break;
      case TransferFeeType.tiered:
        calculatedFee = _calculateTieredFee(amount);
        break;
    }

    // Apply minimum and maximum fee constraints
    if (minimumFee != null && calculatedFee < minimumFee!) {
      calculatedFee = minimumFee!;
    }
    if (maximumFee != null && calculatedFee > maximumFee!) {
      calculatedFee = maximumFee!;
    }

    return calculatedFee;
  }

  double _calculateTieredFee(double amount) {
    if (tierRanges == null || tierRanges!.isEmpty) {
      return 0.0;
    }

    for (final tier in tierRanges!) {
      final min = tier['min'] as double? ?? 0.0;
      final max = tier['max'] as double?;
      final fee = tier['fee'] as double? ?? 0.0;

      if (amount >= min && (max == null || amount <= max)) {
        return fee;
      }
    }

    return 0.0;
  }

  /// Get formatted fee displays
  String get formattedFixedAmount => 
      fixedAmount != null ? 'RM ${fixedAmount!.toStringAsFixed(2)}' : 'N/A';
  
  String get formattedPercentageRate => 
      percentageRate != null ? '${(percentageRate! * 100).toStringAsFixed(2)}%' : 'N/A';
  
  String get formattedMinimumFee => 
      minimumFee != null ? 'RM ${minimumFee!.toStringAsFixed(2)}' : 'N/A';
  
  String get formattedMaximumFee => 
      maximumFee != null ? 'RM ${maximumFee!.toStringAsFixed(2)}' : 'N/A';

  /// Get fee type display name
  String get feeTypeDisplayName {
    switch (feeType) {
      case TransferFeeType.fixed:
        return 'Fixed Fee';
      case TransferFeeType.percentage:
        return 'Percentage Fee';
      case TransferFeeType.tiered:
        return 'Tiered Fee';
    }
  }

  /// Check if fees are currently effective
  bool get isCurrentlyEffective {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(effectiveFrom) &&
        (effectiveUntil == null || now.isBefore(effectiveUntil!));
  }

  /// Create test fees for development
  factory TransferFees.test({
    String? id,
    TransferFeeType? feeType,
    double? fixedAmount,
  }) {
    final now = DateTime.now();
    return TransferFees(
      id: id ?? 'test-fees-id',
      feeType: feeType ?? TransferFeeType.fixed,
      feeName: 'Standard Transfer Fee',
      description: 'Fixed fee for wallet transfers',
      fixedAmount: fixedAmount ?? 1.00,
      currency: 'MYR',
      isActive: true,
      effectiveFrom: now.subtract(const Duration(days: 30)),
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
  }
}

/// Fee breakdown model for displaying fee calculations
@JsonSerializable()
class FeeBreakdown extends Equatable {
  final String name;
  final String type;
  final double amount;

  const FeeBreakdown({
    required this.name,
    required this.type,
    required this.amount,
  });

  factory FeeBreakdown.fromJson(Map<String, dynamic> json) =>
      _$FeeBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$FeeBreakdownToJson(this);

  @override
  List<Object?> get props => [name, type, amount];

  /// Get formatted amount display
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';
}

/// Transfer fee calculation result
@JsonSerializable()
class TransferFeeCalculation extends Equatable {
  final double transferFee;
  final double netAmount;
  final List<FeeBreakdown> feeBreakdown;

  const TransferFeeCalculation({
    required this.transferFee,
    required this.netAmount,
    required this.feeBreakdown,
  });

  factory TransferFeeCalculation.fromJson(Map<String, dynamic> json) =>
      _$TransferFeeCalculationFromJson(json);

  Map<String, dynamic> toJson() => _$TransferFeeCalculationToJson(this);

  @override
  List<Object?> get props => [transferFee, netAmount, feeBreakdown];

  /// Get formatted displays
  String get formattedTransferFee => 'RM ${transferFee.toStringAsFixed(2)}';
  String get formattedNetAmount => 'RM ${netAmount.toStringAsFixed(2)}';

  /// Check if there are any fees
  bool get hasFees => transferFee > 0;

  /// Get total original amount
  double get originalAmount => netAmount + transferFee;
  String get formattedOriginalAmount => 'RM ${originalAmount.toStringAsFixed(2)}';

  /// Create test calculation for development
  factory TransferFeeCalculation.test({
    double? originalAmount,
    double? transferFee,
  }) {
    final amount = originalAmount ?? 100.00;
    final fee = transferFee ?? 1.00;

    return TransferFeeCalculation(
      transferFee: fee,
      netAmount: amount - fee,
      feeBreakdown: [
        FeeBreakdown(
          name: 'Standard Transfer Fee',
          type: 'fixed',
          amount: fee,
        ),
      ],
    );
  }
}

/// Transfer recipient model for recipient validation
@JsonSerializable()
class TransferRecipient extends Equatable {
  final String userId;
  final String walletId;
  final String name;
  final String? email;
  final String? phone;
  final bool isVerified;

  const TransferRecipient({
    required this.userId,
    required this.walletId,
    required this.name,
    this.email,
    this.phone,
    required this.isVerified,
  });

  factory TransferRecipient.fromJson(Map<String, dynamic> json) =>
      _$TransferRecipientFromJson(json);

  Map<String, dynamic> toJson() => _$TransferRecipientToJson(this);

  @override
  List<Object?> get props => [userId, walletId, name, email, phone, isVerified];

  /// Get display identifier (email or phone)
  String get displayIdentifier {
    if (email != null && email!.isNotEmpty) {
      return email!;
    } else if (phone != null && phone!.isNotEmpty) {
      return phone!;
    } else {
      return userId;
    }
  }

  /// Get masked identifier for privacy
  String get maskedIdentifier {
    if (email != null && email!.isNotEmpty) {
      final parts = email!.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        final maskedUsername = username.length > 2 
            ? '${username.substring(0, 2)}***'
            : username;
        return '$maskedUsername@$domain';
      }
    } else if (phone != null && phone!.isNotEmpty) {
      final phone = this.phone!;
      if (phone.length > 4) {
        return '${phone.substring(0, 3)}***${phone.substring(phone.length - 2)}';
      }
    }
    return displayIdentifier;
  }

  /// Create test recipient for development
  factory TransferRecipient.test({
    String? userId,
    String? name,
    String? email,
  }) {
    return TransferRecipient(
      userId: userId ?? 'test-recipient-user-id',
      walletId: 'test-recipient-wallet-id',
      name: name ?? 'Jane Smith',
      email: email ?? 'jane@example.com',
      phone: '+60123456789',
      isVerified: true,
    );
  }
}
