import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'notification_preferences.g.dart';

/// Notification preferences model for customer wallet
@JsonSerializable()
class NotificationPreference extends Equatable {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'notification_type')
  final NotificationType type;
  @JsonKey(name: 'is_enabled')
  final bool isEnabled;
  @JsonKey(name: 'delivery_method')
  final NotificationDeliveryMethod deliveryMethod;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const NotificationPreference({
    required this.id,
    required this.customerId,
    required this.type,
    required this.isEnabled,
    required this.deliveryMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferenceToJson(this);

  NotificationPreference copyWith({
    String? id,
    String? customerId,
    NotificationType? type,
    bool? isEnabled,
    NotificationDeliveryMethod? deliveryMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        type,
        isEnabled,
        deliveryMethod,
        createdAt,
        updatedAt,
      ];
}

/// Notification type enum
enum NotificationType {
  @JsonValue('transaction_completed')
  transactionCompleted,
  @JsonValue('payment_received')
  paymentReceived,
  @JsonValue('payment_failed')
  paymentFailed,
  @JsonValue('low_balance')
  lowBalance,
  @JsonValue('wallet_topup')
  walletTopup,
  @JsonValue('transfer_received')
  transferReceived,
  @JsonValue('transfer_sent')
  transferSent,
  @JsonValue('security_alert')
  securityAlert,
  @JsonValue('promotional')
  promotional,
  @JsonValue('system_maintenance')
  systemMaintenance,
}

/// Notification delivery method enum
enum NotificationDeliveryMethod {
  @JsonValue('push')
  push,
  @JsonValue('email')
  email,
  @JsonValue('sms')
  sms,
  @JsonValue('in_app')
  inApp,
}

/// Extension for NotificationType
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.transactionCompleted:
        return 'Transaction Completed';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.paymentFailed:
        return 'Payment Failed';
      case NotificationType.lowBalance:
        return 'Low Balance Alert';
      case NotificationType.walletTopup:
        return 'Wallet Top-up';
      case NotificationType.transferReceived:
        return 'Transfer Received';
      case NotificationType.transferSent:
        return 'Transfer Sent';
      case NotificationType.securityAlert:
        return 'Security Alert';
      case NotificationType.promotional:
        return 'Promotional';
      case NotificationType.systemMaintenance:
        return 'System Maintenance';
    }
  }

  String get description {
    switch (this) {
      case NotificationType.transactionCompleted:
        return 'Get notified when transactions are completed';
      case NotificationType.paymentReceived:
        return 'Get notified when payments are received';
      case NotificationType.paymentFailed:
        return 'Get notified when payments fail';
      case NotificationType.lowBalance:
        return 'Get notified when wallet balance is low';
      case NotificationType.walletTopup:
        return 'Get notified when wallet is topped up';
      case NotificationType.transferReceived:
        return 'Get notified when money is transferred to your wallet';
      case NotificationType.transferSent:
        return 'Get notified when you send money';
      case NotificationType.securityAlert:
        return 'Get notified about security-related activities';
      case NotificationType.promotional:
        return 'Get notified about promotions and offers';
      case NotificationType.systemMaintenance:
        return 'Get notified about system maintenance';
    }
  }

  bool get isImportant {
    switch (this) {
      case NotificationType.securityAlert:
      case NotificationType.paymentFailed:
      case NotificationType.lowBalance:
        return true;
      default:
        return false;
    }
  }
}

/// Extension for NotificationDeliveryMethod
extension NotificationDeliveryMethodExtension on NotificationDeliveryMethod {
  String get displayName {
    switch (this) {
      case NotificationDeliveryMethod.push:
        return 'Push Notification';
      case NotificationDeliveryMethod.email:
        return 'Email';
      case NotificationDeliveryMethod.sms:
        return 'SMS';
      case NotificationDeliveryMethod.inApp:
        return 'In-App';
    }
  }
}
