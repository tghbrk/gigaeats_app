import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'driver_notification_preferences.g.dart';

@JsonSerializable()
class DriverNotificationPreferences extends Equatable {
  // Order notifications
  final bool orderAssignments;
  final bool statusReminders;
  final bool orderCancellations;
  final bool orderUpdates;

  // Earnings notifications
  final bool earningsUpdates;
  final bool payoutNotifications;
  final bool bonusAlerts;
  final bool commissionUpdates;

  // Performance notifications
  final bool performanceAlerts;
  final bool ratingUpdates;
  final bool targetAchievements;
  final bool deliveryMetrics;

  // Fleet notifications
  final bool fleetAnnouncements;
  final bool systemAnnouncements;
  final bool accountUpdates;
  final bool policyChanges;

  // Location & tracking notifications
  final bool locationReminders;
  final bool routeOptimizations;
  final bool trafficAlerts;
  final bool deliveryZoneUpdates;

  // Customer notifications
  final bool customerMessages;
  final bool customerFeedback;
  final bool specialInstructions;
  final bool contactUpdates;

  // Delivery methods
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;

  const DriverNotificationPreferences({
    // Order notifications - default to true for critical ones
    this.orderAssignments = true,
    this.statusReminders = true,
    this.orderCancellations = true,
    this.orderUpdates = true,

    // Earnings notifications - default to true for financial matters
    this.earningsUpdates = true,
    this.payoutNotifications = true,
    this.bonusAlerts = true,
    this.commissionUpdates = true,

    // Performance notifications - default to true for important ones
    this.performanceAlerts = true,
    this.ratingUpdates = true,
    this.targetAchievements = true,
    this.deliveryMetrics = false,

    // Fleet notifications - default to true for important ones
    this.fleetAnnouncements = true,
    this.systemAnnouncements = true,
    this.accountUpdates = true,
    this.policyChanges = true,

    // Location & tracking notifications - default to false to avoid spam
    this.locationReminders = false,
    this.routeOptimizations = true,
    this.trafficAlerts = true,
    this.deliveryZoneUpdates = false,

    // Customer notifications - default to true for business-critical ones
    this.customerMessages = true,
    this.customerFeedback = false,
    this.specialInstructions = true,
    this.contactUpdates = true,

    // Delivery methods - default to push and email
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
  });

  factory DriverNotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$DriverNotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$DriverNotificationPreferencesToJson(this);

  DriverNotificationPreferences copyWith({
    bool? orderAssignments,
    bool? statusReminders,
    bool? orderCancellations,
    bool? orderUpdates,
    bool? earningsUpdates,
    bool? payoutNotifications,
    bool? bonusAlerts,
    bool? commissionUpdates,
    bool? performanceAlerts,
    bool? ratingUpdates,
    bool? targetAchievements,
    bool? deliveryMetrics,
    bool? fleetAnnouncements,
    bool? systemAnnouncements,
    bool? accountUpdates,
    bool? policyChanges,
    bool? locationReminders,
    bool? routeOptimizations,
    bool? trafficAlerts,
    bool? deliveryZoneUpdates,
    bool? customerMessages,
    bool? customerFeedback,
    bool? specialInstructions,
    bool? contactUpdates,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
  }) {
    return DriverNotificationPreferences(
      orderAssignments: orderAssignments ?? this.orderAssignments,
      statusReminders: statusReminders ?? this.statusReminders,
      orderCancellations: orderCancellations ?? this.orderCancellations,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      earningsUpdates: earningsUpdates ?? this.earningsUpdates,
      payoutNotifications: payoutNotifications ?? this.payoutNotifications,
      bonusAlerts: bonusAlerts ?? this.bonusAlerts,
      commissionUpdates: commissionUpdates ?? this.commissionUpdates,
      performanceAlerts: performanceAlerts ?? this.performanceAlerts,
      ratingUpdates: ratingUpdates ?? this.ratingUpdates,
      targetAchievements: targetAchievements ?? this.targetAchievements,
      deliveryMetrics: deliveryMetrics ?? this.deliveryMetrics,
      fleetAnnouncements: fleetAnnouncements ?? this.fleetAnnouncements,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
      accountUpdates: accountUpdates ?? this.accountUpdates,
      policyChanges: policyChanges ?? this.policyChanges,
      locationReminders: locationReminders ?? this.locationReminders,
      routeOptimizations: routeOptimizations ?? this.routeOptimizations,
      trafficAlerts: trafficAlerts ?? this.trafficAlerts,
      deliveryZoneUpdates: deliveryZoneUpdates ?? this.deliveryZoneUpdates,
      customerMessages: customerMessages ?? this.customerMessages,
      customerFeedback: customerFeedback ?? this.customerFeedback,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      contactUpdates: contactUpdates ?? this.contactUpdates,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
    );
  }

  /// Create from legacy notification preferences format
  factory DriverNotificationPreferences.fromLegacyJson(Map<String, dynamic> json) {
    return DriverNotificationPreferences(
      emailNotifications: json['email'] ?? true,
      pushNotifications: json['push'] ?? true,
      smsNotifications: json['sms'] ?? false,
      // Set reasonable defaults for new categories
      orderAssignments: true,
      statusReminders: true,
      orderCancellations: true,
      orderUpdates: true,
      earningsUpdates: true,
      payoutNotifications: true,
      bonusAlerts: true,
      commissionUpdates: true,
      performanceAlerts: true,
      ratingUpdates: true,
      targetAchievements: true,
      deliveryMetrics: false,
      fleetAnnouncements: true,
      systemAnnouncements: true,
      accountUpdates: true,
      policyChanges: true,
      locationReminders: false,
      routeOptimizations: json['route_alerts'] ?? true,
      trafficAlerts: json['traffic_alerts'] ?? true,
      deliveryZoneUpdates: false,
      customerMessages: true,
      customerFeedback: false,
      specialInstructions: true,
      contactUpdates: true,
    );
  }

  @override
  List<Object?> get props => [
        orderAssignments,
        statusReminders,
        orderCancellations,
        orderUpdates,
        earningsUpdates,
        payoutNotifications,
        bonusAlerts,
        commissionUpdates,
        performanceAlerts,
        ratingUpdates,
        targetAchievements,
        deliveryMetrics,
        fleetAnnouncements,
        systemAnnouncements,
        accountUpdates,
        policyChanges,
        locationReminders,
        routeOptimizations,
        trafficAlerts,
        deliveryZoneUpdates,
        customerMessages,
        customerFeedback,
        specialInstructions,
        contactUpdates,
        emailNotifications,
        pushNotifications,
        smsNotifications,
      ];
}

/// Notification category groupings for UI organization
class DriverNotificationCategory {
  final String title;
  final String description;
  final IconData icon;
  final List<DriverNotificationSetting> settings;

  const DriverNotificationCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.settings,
  });
}

class DriverNotificationSetting {
  final String key;
  final String title;
  final String description;
  final bool Function(DriverNotificationPreferences) getValue;
  final DriverNotificationPreferences Function(DriverNotificationPreferences, bool) setValue;

  const DriverNotificationSetting({
    required this.key,
    required this.title,
    required this.description,
    required this.getValue,
    required this.setValue,
  });
}
