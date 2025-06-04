import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'vendor_notification_preferences.g.dart';

@JsonSerializable()
class VendorNotificationPreferences extends Equatable {
  // Order notifications
  final bool newOrders;
  final bool orderStatusChanges;
  final bool orderCancellations;
  final bool orderPayments;

  // Business notifications
  final bool profileUpdates;
  final bool menuApprovals;
  final bool systemAnnouncements;
  final bool accountUpdates;

  // Marketing notifications
  final bool promotions;
  final bool featureUpdates;
  final bool businessTips;
  final bool marketingCampaigns;

  // Payment notifications
  final bool earnings;
  final bool payouts;
  final bool transactionAlerts;
  final bool paymentFailures;

  // Delivery methods
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;

  const VendorNotificationPreferences({
    // Order notifications - default to true for important ones
    this.newOrders = true,
    this.orderStatusChanges = true,
    this.orderCancellations = true,
    this.orderPayments = true,

    // Business notifications - default to true for important ones
    this.profileUpdates = true,
    this.menuApprovals = true,
    this.systemAnnouncements = true,
    this.accountUpdates = true,

    // Marketing notifications - default to false to avoid spam
    this.promotions = false,
    this.featureUpdates = true,
    this.businessTips = false,
    this.marketingCampaigns = false,

    // Payment notifications - default to true for financial matters
    this.earnings = true,
    this.payouts = true,
    this.transactionAlerts = true,
    this.paymentFailures = true,

    // Delivery methods - default to push and email
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
  });

  factory VendorNotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$VendorNotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$VendorNotificationPreferencesToJson(this);

  VendorNotificationPreferences copyWith({
    bool? newOrders,
    bool? orderStatusChanges,
    bool? orderCancellations,
    bool? orderPayments,
    bool? profileUpdates,
    bool? menuApprovals,
    bool? systemAnnouncements,
    bool? accountUpdates,
    bool? promotions,
    bool? featureUpdates,
    bool? businessTips,
    bool? marketingCampaigns,
    bool? earnings,
    bool? payouts,
    bool? transactionAlerts,
    bool? paymentFailures,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
  }) {
    return VendorNotificationPreferences(
      newOrders: newOrders ?? this.newOrders,
      orderStatusChanges: orderStatusChanges ?? this.orderStatusChanges,
      orderCancellations: orderCancellations ?? this.orderCancellations,
      orderPayments: orderPayments ?? this.orderPayments,
      profileUpdates: profileUpdates ?? this.profileUpdates,
      menuApprovals: menuApprovals ?? this.menuApprovals,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
      accountUpdates: accountUpdates ?? this.accountUpdates,
      promotions: promotions ?? this.promotions,
      featureUpdates: featureUpdates ?? this.featureUpdates,
      businessTips: businessTips ?? this.businessTips,
      marketingCampaigns: marketingCampaigns ?? this.marketingCampaigns,
      earnings: earnings ?? this.earnings,
      payouts: payouts ?? this.payouts,
      transactionAlerts: transactionAlerts ?? this.transactionAlerts,
      paymentFailures: paymentFailures ?? this.paymentFailures,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
    );
  }

  /// Create from legacy notification preferences format
  factory VendorNotificationPreferences.fromLegacyJson(Map<String, dynamic> json) {
    return VendorNotificationPreferences(
      emailNotifications: json['email'] ?? true,
      pushNotifications: json['push'] ?? true,
      smsNotifications: json['sms'] ?? false,
      // Set reasonable defaults for new categories
      newOrders: true,
      orderStatusChanges: true,
      orderCancellations: true,
      orderPayments: true,
      profileUpdates: true,
      menuApprovals: true,
      systemAnnouncements: true,
      accountUpdates: true,
      promotions: json['premium_alerts'] ?? false,
      featureUpdates: true,
      businessTips: false,
      marketingCampaigns: false,
      earnings: true,
      payouts: true,
      transactionAlerts: true,
      paymentFailures: true,
    );
  }

  @override
  List<Object?> get props => [
        newOrders,
        orderStatusChanges,
        orderCancellations,
        orderPayments,
        profileUpdates,
        menuApprovals,
        systemAnnouncements,
        accountUpdates,
        promotions,
        featureUpdates,
        businessTips,
        marketingCampaigns,
        earnings,
        payouts,
        transactionAlerts,
        paymentFailures,
        emailNotifications,
        pushNotifications,
        smsNotifications,
      ];
}

/// Notification category groupings for UI organization
class NotificationCategory {
  final String title;
  final String description;
  final IconData icon;
  final List<NotificationSetting> settings;

  const NotificationCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.settings,
  });
}

class NotificationSetting {
  final String key;
  final String title;
  final String description;
  final bool Function(VendorNotificationPreferences) getValue;
  final VendorNotificationPreferences Function(VendorNotificationPreferences, bool) setValue;

  const NotificationSetting({
    required this.key,
    required this.title,
    required this.description,
    required this.getValue,
    required this.setValue,
  });
}
