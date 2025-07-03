import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../user_management/data/models/admin_notification_preferences.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../presentation/providers/repository_providers.dart';

// Admin Notification Settings State
class AdminNotificationSettingsState {
  final AdminNotificationPreferences preferences;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const AdminNotificationSettingsState({
    this.preferences = const AdminNotificationPreferences(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  AdminNotificationSettingsState copyWith({
    AdminNotificationPreferences? preferences,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminNotificationSettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Admin Notification Settings Provider
final adminNotificationSettingsProvider = StateNotifierProvider.family<
    AdminNotificationSettingsNotifier,
    AdminNotificationSettingsState,
    String>((ref, adminId) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AdminNotificationSettingsNotifier(userRepository, adminId);
});

class AdminNotificationSettingsNotifier extends StateNotifier<AdminNotificationSettingsState> {
  final UserRepository _userRepository;
  final String _adminId;

  AdminNotificationSettingsNotifier(this._userRepository, this._adminId)
      : super(const AdminNotificationSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _userRepository.getUserProfile(_adminId);
      
      AdminNotificationPreferences preferences;
      if (user != null && user.metadata != null && user.metadata!['notification_preferences'] != null) {
        final notificationPrefs = user.metadata!['notification_preferences'] as Map<String, dynamic>;
        
        // Check if it's the new format or legacy format
        if (notificationPrefs.containsKey('systemAlerts')) {
          // New format
          preferences = AdminNotificationPreferences.fromJson(notificationPrefs);
        } else {
          // Legacy format - convert it
          preferences = AdminNotificationPreferences.fromLegacyJson(notificationPrefs);
        }
      } else {
        // No settings found, use defaults
        preferences = const AdminNotificationPreferences();
      }

      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('AdminNotificationSettings: Error loading settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notification settings: $e',
      );
    }
  }

  Future<void> updatePreferences(AdminNotificationPreferences newPreferences) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      final user = await _userRepository.getUserProfile(_adminId);
      if (user == null) {
        throw Exception('Admin user not found');
      }

      // Update user metadata with new notification preferences
      final updatedMetadata = Map<String, dynamic>.from(user.metadata ?? {});
      updatedMetadata['notification_preferences'] = newPreferences.toJson();

      final updatedUser = user.copyWith(metadata: updatedMetadata);
      await _userRepository.updateUserProfile(updatedUser);

      state = state.copyWith(
        preferences: newPreferences,
        isSaving: false,
        successMessage: 'Notification settings updated successfully',
      );

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(successMessage: null);
        }
      });
    } catch (e) {
      debugPrint('AdminNotificationSettings: Error updating settings: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update notification settings: $e',
      );
    }
  }

  void updateSinglePreference(String key, bool value) {
    final currentPrefs = state.preferences;
    AdminNotificationPreferences newPrefs;

    switch (key) {
      case 'systemAlerts':
        newPrefs = currentPrefs.copyWith(systemAlerts: value);
        break;
      case 'systemMaintenance':
        newPrefs = currentPrefs.copyWith(systemMaintenance: value);
        break;
      case 'systemUpdates':
        newPrefs = currentPrefs.copyWith(systemUpdates: value);
        break;
      case 'securityAlerts':
        newPrefs = currentPrefs.copyWith(securityAlerts: value);
        break;
      case 'newUserRegistrations':
        newPrefs = currentPrefs.copyWith(newUserRegistrations: value);
        break;
      case 'userVerifications':
        newPrefs = currentPrefs.copyWith(userVerifications: value);
        break;
      case 'userSuspensions':
        newPrefs = currentPrefs.copyWith(userSuspensions: value);
        break;
      case 'userReports':
        newPrefs = currentPrefs.copyWith(userReports: value);
        break;
      case 'newVendorApplications':
        newPrefs = currentPrefs.copyWith(newVendorApplications: value);
        break;
      case 'vendorVerifications':
        newPrefs = currentPrefs.copyWith(vendorVerifications: value);
        break;
      case 'vendorSuspensions':
        newPrefs = currentPrefs.copyWith(vendorSuspensions: value);
        break;
      case 'salesAgentApplications':
        newPrefs = currentPrefs.copyWith(salesAgentApplications: value);
        break;
      case 'highValueOrders':
        newPrefs = currentPrefs.copyWith(highValueOrders: value);
        break;
      case 'orderDisputes':
        newPrefs = currentPrefs.copyWith(orderDisputes: value);
        break;
      case 'refundRequests':
        newPrefs = currentPrefs.copyWith(refundRequests: value);
        break;
      case 'paymentIssues':
        newPrefs = currentPrefs.copyWith(paymentIssues: value);
        break;
      case 'revenueAlerts':
        newPrefs = currentPrefs.copyWith(revenueAlerts: value);
        break;
      case 'payoutRequests':
        newPrefs = currentPrefs.copyWith(payoutRequests: value);
        break;
      case 'commissionUpdates':
        newPrefs = currentPrefs.copyWith(commissionUpdates: value);
        break;
      case 'financialReports':
        newPrefs = currentPrefs.copyWith(financialReports: value);
        break;
      case 'complianceViolations':
        newPrefs = currentPrefs.copyWith(complianceViolations: value);
        break;
      case 'auditAlerts':
        newPrefs = currentPrefs.copyWith(auditAlerts: value);
        break;
      case 'regulatoryUpdates':
        newPrefs = currentPrefs.copyWith(regulatoryUpdates: value);
        break;
      case 'policyChanges':
        newPrefs = currentPrefs.copyWith(policyChanges: value);
        break;
      case 'performanceAlerts':
        newPrefs = currentPrefs.copyWith(performanceAlerts: value);
        break;
      case 'analyticsReports':
        newPrefs = currentPrefs.copyWith(analyticsReports: value);
        break;
      case 'kpiUpdates':
        newPrefs = currentPrefs.copyWith(kpiUpdates: value);
        break;
      case 'dashboardAlerts':
        newPrefs = currentPrefs.copyWith(dashboardAlerts: value);
        break;
      case 'campaignUpdates':
        newPrefs = currentPrefs.copyWith(campaignUpdates: value);
        break;
      case 'promotionAlerts':
        newPrefs = currentPrefs.copyWith(promotionAlerts: value);
        break;
      case 'marketingReports':
        newPrefs = currentPrefs.copyWith(marketingReports: value);
        break;
      case 'customerFeedback':
        newPrefs = currentPrefs.copyWith(customerFeedback: value);
        break;
      case 'emailNotifications':
        newPrefs = currentPrefs.copyWith(emailNotifications: value);
        break;
      case 'pushNotifications':
        newPrefs = currentPrefs.copyWith(pushNotifications: value);
        break;
      case 'smsNotifications':
        newPrefs = currentPrefs.copyWith(smsNotifications: value);
        break;
      default:
        return; // Unknown key, do nothing
    }

    // Update state immediately for UI responsiveness
    debugPrint('AdminNotificationSettings: Updating state with new preferences');
    state = state.copyWith(preferences: newPrefs);

    // Save to backend
    debugPrint('AdminNotificationSettings: Saving to backend');
    updatePreferences(newPrefs);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  void refresh() {
    _loadSettings();
  }
}

// Admin Notification categories for UI organization
final adminNotificationCategoriesProvider = Provider<List<AdminNotificationCategory>>((ref) {
  return [
    AdminNotificationCategory(
      title: 'System Notifications',
      description: 'Critical system alerts and updates',
      icon: Icons.computer,
      settings: [
        AdminNotificationSetting(
          key: 'systemAlerts',
          title: 'System Alerts',
          description: 'Critical system alerts and warnings',
          getValue: (prefs) => prefs.systemAlerts,
          setValue: (prefs, value) => prefs.copyWith(systemAlerts: value),
        ),
        AdminNotificationSetting(
          key: 'systemMaintenance',
          title: 'System Maintenance',
          description: 'Scheduled maintenance notifications',
          getValue: (prefs) => prefs.systemMaintenance,
          setValue: (prefs, value) => prefs.copyWith(systemMaintenance: value),
        ),
        AdminNotificationSetting(
          key: 'systemUpdates',
          title: 'System Updates',
          description: 'Platform updates and new features',
          getValue: (prefs) => prefs.systemUpdates,
          setValue: (prefs, value) => prefs.copyWith(systemUpdates: value),
        ),
        AdminNotificationSetting(
          key: 'securityAlerts',
          title: 'Security Alerts',
          description: 'Security incidents and threats',
          getValue: (prefs) => prefs.securityAlerts,
          setValue: (prefs, value) => prefs.copyWith(securityAlerts: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'User Management',
      description: 'User registration and management activities',
      icon: Icons.people,
      settings: [
        AdminNotificationSetting(
          key: 'newUserRegistrations',
          title: 'New User Registrations',
          description: 'New user sign-ups requiring approval',
          getValue: (prefs) => prefs.newUserRegistrations,
          setValue: (prefs, value) => prefs.copyWith(newUserRegistrations: value),
        ),
        AdminNotificationSetting(
          key: 'userVerifications',
          title: 'User Verifications',
          description: 'User verification status changes',
          getValue: (prefs) => prefs.userVerifications,
          setValue: (prefs, value) => prefs.copyWith(userVerifications: value),
        ),
        AdminNotificationSetting(
          key: 'userSuspensions',
          title: 'User Suspensions',
          description: 'User account suspensions and bans',
          getValue: (prefs) => prefs.userSuspensions,
          setValue: (prefs, value) => prefs.copyWith(userSuspensions: value),
        ),
        AdminNotificationSetting(
          key: 'userReports',
          title: 'User Reports',
          description: 'User complaints and reports',
          getValue: (prefs) => prefs.userReports,
          setValue: (prefs, value) => prefs.copyWith(userReports: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'Business Management',
      description: 'Vendor and sales agent management',
      icon: Icons.business,
      settings: [
        AdminNotificationSetting(
          key: 'newVendorApplications',
          title: 'New Vendor Applications',
          description: 'New vendor registration applications',
          getValue: (prefs) => prefs.newVendorApplications,
          setValue: (prefs, value) => prefs.copyWith(newVendorApplications: value),
        ),
        AdminNotificationSetting(
          key: 'vendorVerifications',
          title: 'Vendor Verifications',
          description: 'Vendor verification status updates',
          getValue: (prefs) => prefs.vendorVerifications,
          setValue: (prefs, value) => prefs.copyWith(vendorVerifications: value),
        ),
        AdminNotificationSetting(
          key: 'vendorSuspensions',
          title: 'Vendor Suspensions',
          description: 'Vendor account suspensions',
          getValue: (prefs) => prefs.vendorSuspensions,
          setValue: (prefs, value) => prefs.copyWith(vendorSuspensions: value),
        ),
        AdminNotificationSetting(
          key: 'salesAgentApplications',
          title: 'Sales Agent Applications',
          description: 'New sales agent applications',
          getValue: (prefs) => prefs.salesAgentApplications,
          setValue: (prefs, value) => prefs.copyWith(salesAgentApplications: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'Order Management',
      description: 'High-priority order activities',
      icon: Icons.shopping_cart,
      settings: [
        AdminNotificationSetting(
          key: 'highValueOrders',
          title: 'High Value Orders',
          description: 'Orders above threshold amount',
          getValue: (prefs) => prefs.highValueOrders,
          setValue: (prefs, value) => prefs.copyWith(highValueOrders: value),
        ),
        AdminNotificationSetting(
          key: 'orderDisputes',
          title: 'Order Disputes',
          description: 'Customer and vendor disputes',
          getValue: (prefs) => prefs.orderDisputes,
          setValue: (prefs, value) => prefs.copyWith(orderDisputes: value),
        ),
        AdminNotificationSetting(
          key: 'refundRequests',
          title: 'Refund Requests',
          description: 'Customer refund requests',
          getValue: (prefs) => prefs.refundRequests,
          setValue: (prefs, value) => prefs.copyWith(refundRequests: value),
        ),
        AdminNotificationSetting(
          key: 'paymentIssues',
          title: 'Payment Issues',
          description: 'Payment processing problems',
          getValue: (prefs) => prefs.paymentIssues,
          setValue: (prefs, value) => prefs.copyWith(paymentIssues: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'Financial Management',
      description: 'Revenue and financial activities',
      icon: Icons.monetization_on,
      settings: [
        AdminNotificationSetting(
          key: 'revenueAlerts',
          title: 'Revenue Alerts',
          description: 'Revenue threshold and anomaly alerts',
          getValue: (prefs) => prefs.revenueAlerts,
          setValue: (prefs, value) => prefs.copyWith(revenueAlerts: value),
        ),
        AdminNotificationSetting(
          key: 'payoutRequests',
          title: 'Payout Requests',
          description: 'Vendor and sales agent payout requests',
          getValue: (prefs) => prefs.payoutRequests,
          setValue: (prefs, value) => prefs.copyWith(payoutRequests: value),
        ),
        AdminNotificationSetting(
          key: 'commissionUpdates',
          title: 'Commission Updates',
          description: 'Commission calculation and updates',
          getValue: (prefs) => prefs.commissionUpdates,
          setValue: (prefs, value) => prefs.copyWith(commissionUpdates: value),
        ),
        AdminNotificationSetting(
          key: 'financialReports',
          title: 'Financial Reports',
          description: 'Automated financial reports',
          getValue: (prefs) => prefs.financialReports,
          setValue: (prefs, value) => prefs.copyWith(financialReports: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'Compliance & Audit',
      description: 'Regulatory and compliance matters',
      icon: Icons.gavel,
      settings: [
        AdminNotificationSetting(
          key: 'complianceViolations',
          title: 'Compliance Violations',
          description: 'Policy and compliance violations',
          getValue: (prefs) => prefs.complianceViolations,
          setValue: (prefs, value) => prefs.copyWith(complianceViolations: value),
        ),
        AdminNotificationSetting(
          key: 'auditAlerts',
          title: 'Audit Alerts',
          description: 'Audit findings and recommendations',
          getValue: (prefs) => prefs.auditAlerts,
          setValue: (prefs, value) => prefs.copyWith(auditAlerts: value),
        ),
        AdminNotificationSetting(
          key: 'regulatoryUpdates',
          title: 'Regulatory Updates',
          description: 'New regulations and requirements',
          getValue: (prefs) => prefs.regulatoryUpdates,
          setValue: (prefs, value) => prefs.copyWith(regulatoryUpdates: value),
        ),
        AdminNotificationSetting(
          key: 'policyChanges',
          title: 'Policy Changes',
          description: 'Platform policy updates',
          getValue: (prefs) => prefs.policyChanges,
          setValue: (prefs, value) => prefs.copyWith(policyChanges: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'Performance & Analytics',
      description: 'System performance and analytics',
      icon: Icons.analytics,
      settings: [
        AdminNotificationSetting(
          key: 'performanceAlerts',
          title: 'Performance Alerts',
          description: 'System performance issues',
          getValue: (prefs) => prefs.performanceAlerts,
          setValue: (prefs, value) => prefs.copyWith(performanceAlerts: value),
        ),
        AdminNotificationSetting(
          key: 'analyticsReports',
          title: 'Analytics Reports',
          description: 'Automated analytics reports',
          getValue: (prefs) => prefs.analyticsReports,
          setValue: (prefs, value) => prefs.copyWith(analyticsReports: value),
        ),
        AdminNotificationSetting(
          key: 'kpiUpdates',
          title: 'KPI Updates',
          description: 'Key performance indicator updates',
          getValue: (prefs) => prefs.kpiUpdates,
          setValue: (prefs, value) => prefs.copyWith(kpiUpdates: value),
        ),
        AdminNotificationSetting(
          key: 'dashboardAlerts',
          title: 'Dashboard Alerts',
          description: 'Dashboard anomaly alerts',
          getValue: (prefs) => prefs.dashboardAlerts,
          setValue: (prefs, value) => prefs.copyWith(dashboardAlerts: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'Marketing & Feedback',
      description: 'Marketing campaigns and customer feedback',
      icon: Icons.campaign,
      settings: [
        AdminNotificationSetting(
          key: 'campaignUpdates',
          title: 'Campaign Updates',
          description: 'Marketing campaign performance',
          getValue: (prefs) => prefs.campaignUpdates,
          setValue: (prefs, value) => prefs.copyWith(campaignUpdates: value),
        ),
        AdminNotificationSetting(
          key: 'promotionAlerts',
          title: 'Promotion Alerts',
          description: 'Promotional campaign alerts',
          getValue: (prefs) => prefs.promotionAlerts,
          setValue: (prefs, value) => prefs.copyWith(promotionAlerts: value),
        ),
        AdminNotificationSetting(
          key: 'marketingReports',
          title: 'Marketing Reports',
          description: 'Marketing performance reports',
          getValue: (prefs) => prefs.marketingReports,
          setValue: (prefs, value) => prefs.copyWith(marketingReports: value),
        ),
        AdminNotificationSetting(
          key: 'customerFeedback',
          title: 'Customer Feedback',
          description: 'Customer reviews and feedback',
          getValue: (prefs) => prefs.customerFeedback,
          setValue: (prefs, value) => prefs.copyWith(customerFeedback: value),
        ),
      ],
    ),

    AdminNotificationCategory(
      title: 'Delivery Methods',
      description: 'How you want to receive notifications',
      icon: Icons.notifications_active,
      settings: [
        AdminNotificationSetting(
          key: 'emailNotifications',
          title: 'Email Notifications',
          description: 'Receive notifications via email',
          getValue: (prefs) => prefs.emailNotifications,
          setValue: (prefs, value) => prefs.copyWith(emailNotifications: value),
        ),
        AdminNotificationSetting(
          key: 'pushNotifications',
          title: 'Push Notifications',
          description: 'Receive push notifications on your device',
          getValue: (prefs) => prefs.pushNotifications,
          setValue: (prefs, value) => prefs.copyWith(pushNotifications: value),
        ),
        AdminNotificationSetting(
          key: 'smsNotifications',
          title: 'SMS Notifications',
          description: 'Receive notifications via SMS',
          getValue: (prefs) => prefs.smsNotifications,
          setValue: (prefs, value) => prefs.copyWith(smsNotifications: value),
        ),
      ],
    ),
  ];
});
