import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_program.g.dart';

/// Referral status
enum ReferralStatus {
  pending,
  completed,
  rewarded,
  expired,
  cancelled,
}

/// Referral program model
@JsonSerializable()
class ReferralProgram extends Equatable {
  final String id;
  final String referrerUserId;
  final String referralCode;
  final String? refereeUserId;
  final String? refereeEmail;
  final String? refereePhone;
  
  // Referral details
  final ReferralStatus status;
  final DateTime referralDate;
  final DateTime? completionDate;
  final DateTime? rewardDate;
  final DateTime? expiresAt;
  
  // Reward details
  final double referrerBonusAmount;
  final double refereeBonusAmount;
  final int? referrerBonusPoints;
  final int? refereeBonusPoints;
  final bool referrerRewarded;
  final bool refereeRewarded;
  
  // Completion requirements
  final double? minimumOrderAmount;
  final int? minimumOrderCount;
  final bool requiresFirstOrder;
  final Map<String, dynamic>? completionCriteria;
  
  // Tracking
  final String? completedOrderId;
  final double? completedOrderAmount;
  final String? campaignId;
  final String? source;
  
  // Metadata
  final Map<String, dynamic>? metadata;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReferralProgram({
    required this.id,
    required this.referrerUserId,
    required this.referralCode,
    this.refereeUserId,
    this.refereeEmail,
    this.refereePhone,
    required this.status,
    required this.referralDate,
    this.completionDate,
    this.rewardDate,
    this.expiresAt,
    required this.referrerBonusAmount,
    required this.refereeBonusAmount,
    this.referrerBonusPoints,
    this.refereeBonusPoints,
    required this.referrerRewarded,
    required this.refereeRewarded,
    this.minimumOrderAmount,
    this.minimumOrderCount,
    required this.requiresFirstOrder,
    this.completionCriteria,
    this.completedOrderId,
    this.completedOrderAmount,
    this.campaignId,
    this.source,
    this.metadata,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferralProgram.fromJson(Map<String, dynamic> json) =>
      _$ReferralProgramFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralProgramToJson(this);

  ReferralProgram copyWith({
    String? id,
    String? referrerUserId,
    String? referralCode,
    String? refereeUserId,
    String? refereeEmail,
    String? refereePhone,
    ReferralStatus? status,
    DateTime? referralDate,
    DateTime? completionDate,
    DateTime? rewardDate,
    DateTime? expiresAt,
    double? referrerBonusAmount,
    double? refereeBonusAmount,
    int? referrerBonusPoints,
    int? refereeBonusPoints,
    bool? referrerRewarded,
    bool? refereeRewarded,
    double? minimumOrderAmount,
    int? minimumOrderCount,
    bool? requiresFirstOrder,
    Map<String, dynamic>? completionCriteria,
    String? completedOrderId,
    double? completedOrderAmount,
    String? campaignId,
    String? source,
    Map<String, dynamic>? metadata,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReferralProgram(
      id: id ?? this.id,
      referrerUserId: referrerUserId ?? this.referrerUserId,
      referralCode: referralCode ?? this.referralCode,
      refereeUserId: refereeUserId ?? this.refereeUserId,
      refereeEmail: refereeEmail ?? this.refereeEmail,
      refereePhone: refereePhone ?? this.refereePhone,
      status: status ?? this.status,
      referralDate: referralDate ?? this.referralDate,
      completionDate: completionDate ?? this.completionDate,
      rewardDate: rewardDate ?? this.rewardDate,
      expiresAt: expiresAt ?? this.expiresAt,
      referrerBonusAmount: referrerBonusAmount ?? this.referrerBonusAmount,
      refereeBonusAmount: refereeBonusAmount ?? this.refereeBonusAmount,
      referrerBonusPoints: referrerBonusPoints ?? this.referrerBonusPoints,
      refereeBonusPoints: refereeBonusPoints ?? this.refereeBonusPoints,
      referrerRewarded: referrerRewarded ?? this.referrerRewarded,
      refereeRewarded: refereeRewarded ?? this.refereeRewarded,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      minimumOrderCount: minimumOrderCount ?? this.minimumOrderCount,
      requiresFirstOrder: requiresFirstOrder ?? this.requiresFirstOrder,
      completionCriteria: completionCriteria ?? this.completionCriteria,
      completedOrderId: completedOrderId ?? this.completedOrderId,
      completedOrderAmount: completedOrderAmount ?? this.completedOrderAmount,
      campaignId: campaignId ?? this.campaignId,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        referrerUserId,
        referralCode,
        refereeUserId,
        refereeEmail,
        refereePhone,
        status,
        referralDate,
        completionDate,
        rewardDate,
        expiresAt,
        referrerBonusAmount,
        refereeBonusAmount,
        referrerBonusPoints,
        refereeBonusPoints,
        referrerRewarded,
        refereeRewarded,
        minimumOrderAmount,
        minimumOrderCount,
        requiresFirstOrder,
        completionCriteria,
        completedOrderId,
        completedOrderAmount,
        campaignId,
        source,
        metadata,
        notes,
        createdAt,
        updatedAt,
      ];

  /// Status display name
  String get statusDisplayName {
    switch (status) {
      case ReferralStatus.pending:
        return 'Pending';
      case ReferralStatus.completed:
        return 'Completed';
      case ReferralStatus.rewarded:
        return 'Rewarded';
      case ReferralStatus.expired:
        return 'Expired';
      case ReferralStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Formatted referrer bonus display
  String get formattedReferrerBonus {
    if (referrerBonusPoints != null && referrerBonusPoints! > 0) {
      return '$referrerBonusPoints pts';
    }
    return 'RM ${referrerBonusAmount.toStringAsFixed(2)}';
  }

  /// Formatted referee bonus display
  String get formattedRefereeBonus {
    if (refereeBonusPoints != null && refereeBonusPoints! > 0) {
      return '$refereeBonusPoints pts';
    }
    return 'RM ${refereeBonusAmount.toStringAsFixed(2)}';
  }

  /// Check if referral is active
  bool get isActive {
    return status == ReferralStatus.pending && !isExpired;
  }

  /// Check if referral is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if referral is completed
  bool get isCompleted {
    return status == ReferralStatus.completed || 
           status == ReferralStatus.rewarded;
  }

  /// Check if both parties have been rewarded
  bool get isBothRewarded {
    return referrerRewarded && refereeRewarded;
  }

  /// Days until expiration
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 0;
    return expiresAt!.difference(now).inDays;
  }

  /// Formatted expiration display
  String? get formattedExpiration {
    if (expiresAt == null) return 'No expiration';
    final days = daysUntilExpiration;
    if (days == null) return null;
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  /// Referee display name
  String get refereeDisplayName {
    if (refereeEmail != null) return refereeEmail!;
    if (refereePhone != null) return refereePhone!;
    if (refereeUserId != null) return 'User ${refereeUserId!.substring(0, 8)}...';
    return 'Pending signup';
  }

  /// Completion progress display
  String get completionProgressDisplay {
    if (isCompleted) return 'Completed';
    if (isExpired) return 'Expired';
    
    final requirements = <String>[];
    if (requiresFirstOrder) {
      requirements.add('First order');
    }
    if (minimumOrderAmount != null) {
      requirements.add('Min RM ${minimumOrderAmount!.toStringAsFixed(2)}');
    }
    if (minimumOrderCount != null && minimumOrderCount! > 1) {
      requirements.add('$minimumOrderCount orders');
    }
    
    if (requirements.isEmpty) return 'Waiting for signup';
    return 'Needs: ${requirements.join(', ')}';
  }

  /// Create test referral program for development
  factory ReferralProgram.test({
    String? id,
    String? referrerUserId,
    ReferralStatus? status,
    bool? hasReferee,
  }) {
    final now = DateTime.now();
    final referralStatus = status ?? ReferralStatus.pending;
    final withReferee = hasReferee ?? false;
    
    return ReferralProgram(
      id: id ?? 'test-referral-id',
      referrerUserId: referrerUserId ?? 'test-referrer-user-id',
      referralCode: 'GIGA2024REF',
      refereeUserId: withReferee ? 'test-referee-user-id' : null,
      refereeEmail: withReferee ? 'referee@example.com' : null,
      status: referralStatus,
      referralDate: now.subtract(const Duration(days: 5)),
      completionDate: referralStatus == ReferralStatus.completed || 
                     referralStatus == ReferralStatus.rewarded
          ? now.subtract(const Duration(days: 2))
          : null,
      rewardDate: referralStatus == ReferralStatus.rewarded
          ? now.subtract(const Duration(days: 1))
          : null,
      expiresAt: now.add(const Duration(days: 30)),
      referrerBonusAmount: 25.00,
      refereeBonusAmount: 15.00,
      referrerBonusPoints: 500,
      refereeBonusPoints: 300,
      referrerRewarded: referralStatus == ReferralStatus.rewarded,
      refereeRewarded: referralStatus == ReferralStatus.rewarded,
      minimumOrderAmount: 20.00,
      minimumOrderCount: 1,
      requiresFirstOrder: true,
      completedOrderId: referralStatus == ReferralStatus.completed || 
                       referralStatus == ReferralStatus.rewarded
          ? 'test-completed-order-id'
          : null,
      completedOrderAmount: referralStatus == ReferralStatus.completed || 
                           referralStatus == ReferralStatus.rewarded
          ? 35.50
          : null,
      campaignId: 'welcome-referral-2024',
      source: 'mobile_app',
      metadata: {
        'campaign_name': 'Welcome Referral Program',
        'referral_link': 'https://gigaeats.com/ref/GIGA2024REF',
      },
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now,
    );
  }
}
