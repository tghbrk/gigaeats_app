import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Remove the generated file import for now to fix compilation
// part 'escrow_account.g.dart';

@JsonSerializable()
class EscrowAccount extends Equatable {
  final String id;
  final String orderId;
  final double totalAmount;
  final String currency;
  final EscrowStatus status;
  final EscrowReleaseTrigger releaseTrigger;
  final int holdDurationHours;
  final DateTime? releaseDate;
  final String? releaseReason;
  final String? releasedBy;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EscrowAccount({
    required this.id,
    required this.orderId,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.releaseTrigger,
    required this.holdDurationHours,
    this.releaseDate,
    this.releaseReason,
    this.releasedBy,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EscrowAccount.fromJson(Map<String, dynamic> json) {
    return EscrowAccount(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: EscrowStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => EscrowStatus.pending,
      ),
      releaseTrigger: EscrowReleaseTrigger.values.firstWhere(
        (e) => e.value == json['release_trigger'],
        orElse: () => EscrowReleaseTrigger.orderDelivered,
      ),
      holdDurationHours: json['hold_duration_hours'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'] as String)
          : null,
      releaseReason: json['release_reason'] as String?,
      releasedBy: json['released_by'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'total_amount': totalAmount,
      'currency': currency,
      'status': status.value,
      'release_trigger': releaseTrigger.value,
      'hold_duration_hours': holdDurationHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'release_date': releaseDate?.toIso8601String(),
      'release_reason': releaseReason,
      'released_by': releasedBy,
      'metadata': metadata,
    };
  }

  EscrowAccount copyWith({
    String? id,
    String? orderId,
    double? totalAmount,
    String? currency,
    EscrowStatus? status,
    EscrowReleaseTrigger? releaseTrigger,
    int? holdDurationHours,
    DateTime? releaseDate,
    String? releaseReason,
    String? releasedBy,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EscrowAccount(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      releaseTrigger: releaseTrigger ?? this.releaseTrigger,
      holdDurationHours: holdDurationHours ?? this.holdDurationHours,
      releaseDate: releaseDate ?? this.releaseDate,
      releaseReason: releaseReason ?? this.releaseReason,
      releasedBy: releasedBy ?? this.releasedBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        totalAmount,
        currency,
        status,
        releaseTrigger,
        holdDurationHours,
        releaseDate,
        releaseReason,
        releasedBy,
        metadata,
        createdAt,
        updatedAt,
      ];

  /// Check if escrow is ready for release
  bool get isReadyForRelease {
    switch (status) {
      case EscrowStatus.held:
        return true;
      case EscrowStatus.pending:
      case EscrowStatus.confirmed:
      case EscrowStatus.processing:
      case EscrowStatus.released:
      case EscrowStatus.cancelled:
        return false;
    }
  }

  /// Check if escrow has been released
  bool get isReleased => status == EscrowStatus.released;

  /// Get formatted amount
  String get formattedAmount => '$currency ${totalAmount.toStringAsFixed(2)}';

  /// Get display status
  String get displayStatus => status.displayName;

  /// Get display release trigger
  String get displayReleaseTrigger => releaseTrigger.displayName;
}

enum EscrowStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('processing')
  processing,
  @JsonValue('held')
  held,
  @JsonValue('released')
  released,
  @JsonValue('cancelled')
  cancelled,
}

extension EscrowStatusExtension on EscrowStatus {
  String get displayName {
    switch (this) {
      case EscrowStatus.pending:
        return 'Pending';
      case EscrowStatus.confirmed:
        return 'Confirmed';
      case EscrowStatus.processing:
        return 'Processing';
      case EscrowStatus.held:
        return 'Held';
      case EscrowStatus.released:
        return 'Released';
      case EscrowStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case EscrowStatus.pending:
        return 'pending';
      case EscrowStatus.confirmed:
        return 'confirmed';
      case EscrowStatus.processing:
        return 'processing';
      case EscrowStatus.held:
        return 'held';
      case EscrowStatus.released:
        return 'released';
      case EscrowStatus.cancelled:
        return 'cancelled';
    }
  }

  static EscrowStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return EscrowStatus.pending;
      case 'confirmed':
        return EscrowStatus.confirmed;
      case 'processing':
        return EscrowStatus.processing;
      case 'held':
        return EscrowStatus.held;
      case 'released':
        return EscrowStatus.released;
      case 'cancelled':
        return EscrowStatus.cancelled;
      default:
        throw ArgumentError('Invalid escrow status: $value');
    }
  }
}

enum EscrowReleaseTrigger {
  @JsonValue('order_delivered')
  orderDelivered,
  @JsonValue('manual_release')
  manualRelease,
  @JsonValue('auto_release')
  autoRelease,
}

extension EscrowReleaseTriggerExtension on EscrowReleaseTrigger {
  String get displayName {
    switch (this) {
      case EscrowReleaseTrigger.orderDelivered:
        return 'Order Delivered';
      case EscrowReleaseTrigger.manualRelease:
        return 'Manual Release';
      case EscrowReleaseTrigger.autoRelease:
        return 'Auto Release';
    }
  }

  String get value {
    switch (this) {
      case EscrowReleaseTrigger.orderDelivered:
        return 'order_delivered';
      case EscrowReleaseTrigger.manualRelease:
        return 'manual_release';
      case EscrowReleaseTrigger.autoRelease:
        return 'auto_release';
    }
  }

  static EscrowReleaseTrigger fromString(String value) {
    switch (value.toLowerCase()) {
      case 'order_delivered':
        return EscrowReleaseTrigger.orderDelivered;
      case 'manual_release':
        return EscrowReleaseTrigger.manualRelease;
      case 'auto_release':
        return EscrowReleaseTrigger.autoRelease;
      default:
        throw ArgumentError('Invalid escrow release trigger: $value');
    }
  }
}
