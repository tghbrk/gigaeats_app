import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'sales_agent_notification_preferences.g.dart';

@JsonSerializable()
class SalesAgentNotificationPreferences extends Equatable {
  // Order notifications
  final bool newOrders;
  final bool orderStatusChanges;
  final bool orderCancellations;
  final bool orderPayments;

  // Customer notifications
  final bool newCustomers;
  final bool customerUpdates;
  final bool customerMessages;
  final bool customerFeedback;

  // Business notifications
  final bool profileUpdates;
  final bool systemAnnouncements;
  final bool accountUpdates;
  final bool performanceReports;

  // Commission notifications
  final bool commissionUpdates;
  final bool payouts;
  final bool bonusAlerts;
  final bool targetAchievements;

  // Marketing notifications
  final bool promotions;
  final bool featureUpdates;
  final bool salesTips;
  final bool marketingCampaigns;

  // Delivery methods
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;

  const SalesAgentNotificationPreferences({
    // Order notifications - default to true for important ones
    this.newOrders = true,
    this.orderStatusChanges = true,
    this.orderCancellations = true,
    this.orderPayments = true,

    // Customer notifications - default to true for business-critical ones
    this.newCustomers = true,
    this.customerUpdates = true,
    this.customerMessages = true,
    this.customerFeedback = false,

    // Business notifications - default to true for important ones
    this.profileUpdates = true,
    this.systemAnnouncements = true,
    this.accountUpdates = true,
    this.performanceReports = true,

    // Commission notifications - default to true for financial matters
    this.commissionUpdates = true,
    this.payouts = true,
    this.bonusAlerts = true,
    this.targetAchievements = true,

    // Marketing notifications - default to false to avoid spam
    this.promotions = false,
    this.featureUpdates = true,
    this.salesTips = false,
    this.marketingCampaigns = false,

    // Delivery methods - default to push and email
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
  });

  factory SalesAgentNotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$SalesAgentNotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$SalesAgentNotificationPreferencesToJson(this);

  SalesAgentNotificationPreferences copyWith({
    bool? newOrders,
    bool? orderStatusChanges,
    bool? orderCancellations,
    bool? orderPayments,
    bool? newCustomers,
    bool? customerUpdates,
    bool? customerMessages,
    bool? customerFeedback,
    bool? profileUpdates,
    bool? systemAnnouncements,
    bool? accountUpdates,
    bool? performanceReports,
    bool? commissionUpdates,
    bool? payouts,
    bool? bonusAlerts,
    bool? targetAchievements,
    bool? promotions,
    bool? featureUpdates,
    bool? salesTips,
    bool? marketingCampaigns,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
  }) {
    return SalesAgentNotificationPreferences(
      newOrders: newOrders ?? this.newOrders,
      orderStatusChanges: orderStatusChanges ?? this.orderStatusChanges,
      orderCancellations: orderCancellations ?? this.orderCancellations,
      orderPayments: orderPayments ?? this.orderPayments,
      newCustomers: newCustomers ?? this.newCustomers,
      customerUpdates: customerUpdates ?? this.customerUpdates,
      customerMessages: customerMessages ?? this.customerMessages,
      customerFeedback: customerFeedback ?? this.customerFeedback,
      profileUpdates: profileUpdates ?? this.profileUpdates,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
      accountUpdates: accountUpdates ?? this.accountUpdates,
      performanceReports: performanceReports ?? this.performanceReports,
      commissionUpdates: commissionUpdates ?? this.commissionUpdates,
      payouts: payouts ?? this.payouts,
      bonusAlerts: bonusAlerts ?? this.bonusAlerts,
      targetAchievements: targetAchievements ?? this.targetAchievements,
      promotions: promotions ?? this.promotions,
      featureUpdates: featureUpdates ?? this.featureUpdates,
      salesTips: salesTips ?? this.salesTips,
      marketingCampaigns: marketingCampaigns ?? this.marketingCampaigns,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
    );
  }

  /// Create from legacy notification preferences format
  factory SalesAgentNotificationPreferences.fromLegacyJson(Map<String, dynamic> json) {
    return SalesAgentNotificationPreferences(
      emailNotifications: json['email'] ?? true,
      pushNotifications: json['push'] ?? true,
      smsNotifications: json['sms'] ?? false,
      // Set reasonable defaults for new categories
      newOrders: true,
      orderStatusChanges: true,
      orderCancellations: true,
      orderPayments: true,
      newCustomers: true,
      customerUpdates: true,
      customerMessages: true,
      customerFeedback: false,
      profileUpdates: true,
      systemAnnouncements: true,
      accountUpdates: true,
      performanceReports: true,
      commissionUpdates: true,
      payouts: true,
      bonusAlerts: true,
      targetAchievements: true,
      promotions: json['premium_alerts'] ?? false,
      featureUpdates: true,
      salesTips: false,
      marketingCampaigns: false,
    );
  }

  @override
  List<Object?> get props => [
        newOrders,
        orderStatusChanges,
        orderCancellations,
        orderPayments,
        newCustomers,
        customerUpdates,
        customerMessages,
        customerFeedback,
        profileUpdates,
        systemAnnouncements,
        accountUpdates,
        performanceReports,
        commissionUpdates,
        payouts,
        bonusAlerts,
        targetAchievements,
        promotions,
        featureUpdates,
        salesTips,
        marketingCampaigns,
        emailNotifications,
        pushNotifications,
        smsNotifications,
      ];
}

/// Notification category groupings for UI organization
class SalesAgentNotificationCategory {
  final String title;
  final String description;
  final IconData icon;
  final List<SalesAgentNotificationSetting> settings;

  const SalesAgentNotificationCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.settings,
  });
}

class SalesAgentNotificationSetting {
  final String key;
  final String title;
  final String description;
  final bool Function(SalesAgentNotificationPreferences) getValue;
  final SalesAgentNotificationPreferences Function(SalesAgentNotificationPreferences, bool) setValue;

  const SalesAgentNotificationSetting({
    required this.key,
    required this.title,
    required this.description,
    required this.getValue,
    required this.setValue,
  });
}
