import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'admin_notification_preferences.g.dart';

@JsonSerializable()
class AdminNotificationPreferences extends Equatable {
  // System notifications
  final bool systemAlerts;
  final bool systemMaintenance;
  final bool systemUpdates;
  final bool securityAlerts;

  // User management notifications
  final bool newUserRegistrations;
  final bool userVerifications;
  final bool userSuspensions;
  final bool userReports;

  // Business notifications
  final bool newVendorApplications;
  final bool vendorVerifications;
  final bool vendorSuspensions;
  final bool salesAgentApplications;

  // Order management notifications
  final bool highValueOrders;
  final bool orderDisputes;
  final bool refundRequests;
  final bool paymentIssues;

  // Financial notifications
  final bool revenueAlerts;
  final bool payoutRequests;
  final bool commissionUpdates;
  final bool financialReports;

  // Compliance notifications
  final bool complianceViolations;
  final bool auditAlerts;
  final bool regulatoryUpdates;
  final bool policyChanges;

  // Performance notifications
  final bool performanceAlerts;
  final bool analyticsReports;
  final bool kpiUpdates;
  final bool dashboardAlerts;

  // Marketing notifications
  final bool campaignUpdates;
  final bool promotionAlerts;
  final bool marketingReports;
  final bool customerFeedback;

  // Delivery methods
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;

  const AdminNotificationPreferences({
    // System notifications - default to true for critical ones
    this.systemAlerts = true,
    this.systemMaintenance = true,
    this.systemUpdates = true,
    this.securityAlerts = true,

    // User management notifications - default to true for important ones
    this.newUserRegistrations = true,
    this.userVerifications = true,
    this.userSuspensions = true,
    this.userReports = true,

    // Business notifications - default to true for critical ones
    this.newVendorApplications = true,
    this.vendorVerifications = true,
    this.vendorSuspensions = true,
    this.salesAgentApplications = true,

    // Order management notifications - default to true for high-priority ones
    this.highValueOrders = true,
    this.orderDisputes = true,
    this.refundRequests = true,
    this.paymentIssues = true,

    // Financial notifications - default to true for financial matters
    this.revenueAlerts = true,
    this.payoutRequests = true,
    this.commissionUpdates = true,
    this.financialReports = true,

    // Compliance notifications - default to true for regulatory matters
    this.complianceViolations = true,
    this.auditAlerts = true,
    this.regulatoryUpdates = true,
    this.policyChanges = true,

    // Performance notifications - default to true for monitoring
    this.performanceAlerts = true,
    this.analyticsReports = true,
    this.kpiUpdates = true,
    this.dashboardAlerts = false,

    // Marketing notifications - default to false to avoid spam
    this.campaignUpdates = false,
    this.promotionAlerts = false,
    this.marketingReports = true,
    this.customerFeedback = true,

    // Delivery methods - default to push and email
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
  });

  factory AdminNotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$AdminNotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$AdminNotificationPreferencesToJson(this);

  AdminNotificationPreferences copyWith({
    bool? systemAlerts,
    bool? systemMaintenance,
    bool? systemUpdates,
    bool? securityAlerts,
    bool? newUserRegistrations,
    bool? userVerifications,
    bool? userSuspensions,
    bool? userReports,
    bool? newVendorApplications,
    bool? vendorVerifications,
    bool? vendorSuspensions,
    bool? salesAgentApplications,
    bool? highValueOrders,
    bool? orderDisputes,
    bool? refundRequests,
    bool? paymentIssues,
    bool? revenueAlerts,
    bool? payoutRequests,
    bool? commissionUpdates,
    bool? financialReports,
    bool? complianceViolations,
    bool? auditAlerts,
    bool? regulatoryUpdates,
    bool? policyChanges,
    bool? performanceAlerts,
    bool? analyticsReports,
    bool? kpiUpdates,
    bool? dashboardAlerts,
    bool? campaignUpdates,
    bool? promotionAlerts,
    bool? marketingReports,
    bool? customerFeedback,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
  }) {
    return AdminNotificationPreferences(
      systemAlerts: systemAlerts ?? this.systemAlerts,
      systemMaintenance: systemMaintenance ?? this.systemMaintenance,
      systemUpdates: systemUpdates ?? this.systemUpdates,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      newUserRegistrations: newUserRegistrations ?? this.newUserRegistrations,
      userVerifications: userVerifications ?? this.userVerifications,
      userSuspensions: userSuspensions ?? this.userSuspensions,
      userReports: userReports ?? this.userReports,
      newVendorApplications: newVendorApplications ?? this.newVendorApplications,
      vendorVerifications: vendorVerifications ?? this.vendorVerifications,
      vendorSuspensions: vendorSuspensions ?? this.vendorSuspensions,
      salesAgentApplications: salesAgentApplications ?? this.salesAgentApplications,
      highValueOrders: highValueOrders ?? this.highValueOrders,
      orderDisputes: orderDisputes ?? this.orderDisputes,
      refundRequests: refundRequests ?? this.refundRequests,
      paymentIssues: paymentIssues ?? this.paymentIssues,
      revenueAlerts: revenueAlerts ?? this.revenueAlerts,
      payoutRequests: payoutRequests ?? this.payoutRequests,
      commissionUpdates: commissionUpdates ?? this.commissionUpdates,
      financialReports: financialReports ?? this.financialReports,
      complianceViolations: complianceViolations ?? this.complianceViolations,
      auditAlerts: auditAlerts ?? this.auditAlerts,
      regulatoryUpdates: regulatoryUpdates ?? this.regulatoryUpdates,
      policyChanges: policyChanges ?? this.policyChanges,
      performanceAlerts: performanceAlerts ?? this.performanceAlerts,
      analyticsReports: analyticsReports ?? this.analyticsReports,
      kpiUpdates: kpiUpdates ?? this.kpiUpdates,
      dashboardAlerts: dashboardAlerts ?? this.dashboardAlerts,
      campaignUpdates: campaignUpdates ?? this.campaignUpdates,
      promotionAlerts: promotionAlerts ?? this.promotionAlerts,
      marketingReports: marketingReports ?? this.marketingReports,
      customerFeedback: customerFeedback ?? this.customerFeedback,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
    );
  }

  /// Create from legacy notification preferences format
  factory AdminNotificationPreferences.fromLegacyJson(Map<String, dynamic> json) {
    return AdminNotificationPreferences(
      emailNotifications: json['email'] ?? true,
      pushNotifications: json['push'] ?? true,
      smsNotifications: json['sms'] ?? false,
      // Set reasonable defaults for new categories
      systemAlerts: true,
      systemMaintenance: true,
      systemUpdates: true,
      securityAlerts: true,
      newUserRegistrations: true,
      userVerifications: true,
      userSuspensions: true,
      userReports: true,
      newVendorApplications: true,
      vendorVerifications: true,
      vendorSuspensions: true,
      salesAgentApplications: true,
      highValueOrders: true,
      orderDisputes: true,
      refundRequests: true,
      paymentIssues: true,
      revenueAlerts: true,
      payoutRequests: true,
      commissionUpdates: true,
      financialReports: true,
      complianceViolations: true,
      auditAlerts: true,
      regulatoryUpdates: true,
      policyChanges: true,
      performanceAlerts: true,
      analyticsReports: true,
      kpiUpdates: true,
      dashboardAlerts: false,
      campaignUpdates: json['premium_alerts'] ?? false,
      promotionAlerts: false,
      marketingReports: true,
      customerFeedback: true,
    );
  }

  @override
  List<Object?> get props => [
        systemAlerts,
        systemMaintenance,
        systemUpdates,
        securityAlerts,
        newUserRegistrations,
        userVerifications,
        userSuspensions,
        userReports,
        newVendorApplications,
        vendorVerifications,
        vendorSuspensions,
        salesAgentApplications,
        highValueOrders,
        orderDisputes,
        refundRequests,
        paymentIssues,
        revenueAlerts,
        payoutRequests,
        commissionUpdates,
        financialReports,
        complianceViolations,
        auditAlerts,
        regulatoryUpdates,
        policyChanges,
        performanceAlerts,
        analyticsReports,
        kpiUpdates,
        dashboardAlerts,
        campaignUpdates,
        promotionAlerts,
        marketingReports,
        customerFeedback,
        emailNotifications,
        pushNotifications,
        smsNotifications,
      ];
}

/// Notification category groupings for UI organization
class AdminNotificationCategory {
  final String title;
  final String description;
  final IconData icon;
  final List<AdminNotificationSetting> settings;

  const AdminNotificationCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.settings,
  });
}

class AdminNotificationSetting {
  final String key;
  final String title;
  final String description;
  final bool Function(AdminNotificationPreferences) getValue;
  final AdminNotificationPreferences Function(AdminNotificationPreferences, bool) setValue;

  const AdminNotificationSetting({
    required this.key,
    required this.title,
    required this.description,
    required this.getValue,
    required this.setValue,
  });
}
