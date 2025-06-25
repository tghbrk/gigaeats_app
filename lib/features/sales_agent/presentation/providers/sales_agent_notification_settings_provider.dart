import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';

import '../../data/models/sales_agent_notification_preferences.dart';
import '../../data/services/sales_agent_service.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Sales Agent Notification Settings State
class SalesAgentNotificationSettingsState {
  final SalesAgentNotificationPreferences preferences;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const SalesAgentNotificationSettingsState({
    this.preferences = const SalesAgentNotificationPreferences(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  SalesAgentNotificationSettingsState copyWith({
    SalesAgentNotificationPreferences? preferences,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return SalesAgentNotificationSettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Sales Agent Notification Settings Provider
final salesAgentNotificationSettingsProvider = StateNotifierProvider.family<
    SalesAgentNotificationSettingsNotifier,
    SalesAgentNotificationSettingsState,
    String>((ref, salesAgentId) {
  final salesAgentService = ref.watch(salesAgentServiceProvider);
  return SalesAgentNotificationSettingsNotifier(salesAgentService, salesAgentId);
});

class SalesAgentNotificationSettingsNotifier extends StateNotifier<SalesAgentNotificationSettingsState> {
  final SalesAgentService _salesAgentService;
  final String _salesAgentId;

  SalesAgentNotificationSettingsNotifier(this._salesAgentService, this._salesAgentId)
      : super(const SalesAgentNotificationSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final settings = await _salesAgentService.getSalesAgentSettings(_salesAgentId);
      
      SalesAgentNotificationPreferences preferences;
      if (settings != null && settings['notification_preferences'] != null) {
        final notificationPrefs = settings['notification_preferences'] as Map<String, dynamic>;
        
        // Check if it's the new format or legacy format
        if (notificationPrefs.containsKey('newOrders')) {
          // New format
          preferences = SalesAgentNotificationPreferences.fromJson(notificationPrefs);
        } else {
          // Legacy format - convert it
          preferences = SalesAgentNotificationPreferences.fromLegacyJson(notificationPrefs);
        }
      } else {
        // No settings found, use defaults
        preferences = const SalesAgentNotificationPreferences();
      }

      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('SalesAgentNotificationSettings: Error loading settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notification settings: $e',
      );
    }
  }

  Future<void> updatePreferences(SalesAgentNotificationPreferences newPreferences) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      await _salesAgentService.updateSalesAgentSettings(_salesAgentId, {
        'notification_preferences': newPreferences.toJson(),
      });

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
      debugPrint('SalesAgentNotificationSettings: Error updating settings: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update notification settings: $e',
      );
    }
  }

  void updateSinglePreference(String key, bool value) {
    final currentPrefs = state.preferences;
    SalesAgentNotificationPreferences newPrefs;

    switch (key) {
      case 'newOrders':
        newPrefs = currentPrefs.copyWith(newOrders: value);
        break;
      case 'orderStatusChanges':
        newPrefs = currentPrefs.copyWith(orderStatusChanges: value);
        break;
      case 'orderCancellations':
        newPrefs = currentPrefs.copyWith(orderCancellations: value);
        break;
      case 'orderPayments':
        newPrefs = currentPrefs.copyWith(orderPayments: value);
        break;
      case 'newCustomers':
        newPrefs = currentPrefs.copyWith(newCustomers: value);
        break;
      case 'customerUpdates':
        newPrefs = currentPrefs.copyWith(customerUpdates: value);
        break;
      case 'customerMessages':
        newPrefs = currentPrefs.copyWith(customerMessages: value);
        break;
      case 'customerFeedback':
        newPrefs = currentPrefs.copyWith(customerFeedback: value);
        break;
      case 'profileUpdates':
        newPrefs = currentPrefs.copyWith(profileUpdates: value);
        break;
      case 'systemAnnouncements':
        newPrefs = currentPrefs.copyWith(systemAnnouncements: value);
        break;
      case 'accountUpdates':
        newPrefs = currentPrefs.copyWith(accountUpdates: value);
        break;
      case 'performanceReports':
        newPrefs = currentPrefs.copyWith(performanceReports: value);
        break;
      case 'commissionUpdates':
        newPrefs = currentPrefs.copyWith(commissionUpdates: value);
        break;
      case 'payouts':
        newPrefs = currentPrefs.copyWith(payouts: value);
        break;
      case 'bonusAlerts':
        newPrefs = currentPrefs.copyWith(bonusAlerts: value);
        break;
      case 'targetAchievements':
        newPrefs = currentPrefs.copyWith(targetAchievements: value);
        break;
      case 'promotions':
        newPrefs = currentPrefs.copyWith(promotions: value);
        break;
      case 'featureUpdates':
        newPrefs = currentPrefs.copyWith(featureUpdates: value);
        break;
      case 'salesTips':
        newPrefs = currentPrefs.copyWith(salesTips: value);
        break;
      case 'marketingCampaigns':
        newPrefs = currentPrefs.copyWith(marketingCampaigns: value);
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
    debugPrint('SalesAgentNotificationSettings: Updating state with new preferences');
    state = state.copyWith(preferences: newPrefs);

    // Save to backend
    debugPrint('SalesAgentNotificationSettings: Saving to backend');
    updatePreferences(newPrefs);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  void refresh() {
    _loadSettings();
  }
}

// Sales Agent Notification categories for UI organization
final salesAgentNotificationCategoriesProvider = Provider<List<SalesAgentNotificationCategory>>((ref) {
  return [
    SalesAgentNotificationCategory(
      title: 'Order Notifications',
      description: 'Get notified about order activities',
      icon: Icons.shopping_bag,
      settings: [
        SalesAgentNotificationSetting(
          key: 'newOrders',
          title: 'New Orders',
          description: 'Receive notifications when new orders are created',
          getValue: (prefs) => prefs.newOrders,
          setValue: (prefs, value) => prefs.copyWith(newOrders: value),
        ),
        SalesAgentNotificationSetting(
          key: 'orderStatusChanges',
          title: 'Order Status Changes',
          description: 'Get notified when order status changes',
          getValue: (prefs) => prefs.orderStatusChanges,
          setValue: (prefs, value) => prefs.copyWith(orderStatusChanges: value),
        ),
        SalesAgentNotificationSetting(
          key: 'orderCancellations',
          title: 'Order Cancellations',
          description: 'Receive notifications about cancelled orders',
          getValue: (prefs) => prefs.orderCancellations,
          setValue: (prefs, value) => prefs.copyWith(orderCancellations: value),
        ),
        SalesAgentNotificationSetting(
          key: 'orderPayments',
          title: 'Order Payments',
          description: 'Get notified about order payment confirmations',
          getValue: (prefs) => prefs.orderPayments,
          setValue: (prefs, value) => prefs.copyWith(orderPayments: value),
        ),
      ],
    ),

    SalesAgentNotificationCategory(
      title: 'Customer Notifications',
      description: 'Stay updated on customer activities',
      icon: Icons.people,
      settings: [
        SalesAgentNotificationSetting(
          key: 'newCustomers',
          title: 'New Customers',
          description: 'Receive notifications when new customers are added',
          getValue: (prefs) => prefs.newCustomers,
          setValue: (prefs, value) => prefs.copyWith(newCustomers: value),
        ),
        SalesAgentNotificationSetting(
          key: 'customerUpdates',
          title: 'Customer Updates',
          description: 'Get notified about customer profile changes',
          getValue: (prefs) => prefs.customerUpdates,
          setValue: (prefs, value) => prefs.copyWith(customerUpdates: value),
        ),
        SalesAgentNotificationSetting(
          key: 'customerMessages',
          title: 'Customer Messages',
          description: 'Receive notifications for customer messages',
          getValue: (prefs) => prefs.customerMessages,
          setValue: (prefs, value) => prefs.copyWith(customerMessages: value),
        ),
        SalesAgentNotificationSetting(
          key: 'customerFeedback',
          title: 'Customer Feedback',
          description: 'Get notified about customer feedback and reviews',
          getValue: (prefs) => prefs.customerFeedback,
          setValue: (prefs, value) => prefs.copyWith(customerFeedback: value),
        ),
      ],
    ),

    SalesAgentNotificationCategory(
      title: 'Business Notifications',
      description: 'Stay updated on business-related activities',
      icon: Icons.business,
      settings: [
        SalesAgentNotificationSetting(
          key: 'profileUpdates',
          title: 'Profile Updates',
          description: 'Get notified about profile changes and approvals',
          getValue: (prefs) => prefs.profileUpdates,
          setValue: (prefs, value) => prefs.copyWith(profileUpdates: value),
        ),
        SalesAgentNotificationSetting(
          key: 'systemAnnouncements',
          title: 'System Announcements',
          description: 'Receive important system announcements',
          getValue: (prefs) => prefs.systemAnnouncements,
          setValue: (prefs, value) => prefs.copyWith(systemAnnouncements: value),
        ),
        SalesAgentNotificationSetting(
          key: 'accountUpdates',
          title: 'Account Updates',
          description: 'Get notified about account changes',
          getValue: (prefs) => prefs.accountUpdates,
          setValue: (prefs, value) => prefs.copyWith(accountUpdates: value),
        ),
        SalesAgentNotificationSetting(
          key: 'performanceReports',
          title: 'Performance Reports',
          description: 'Receive your performance and analytics reports',
          getValue: (prefs) => prefs.performanceReports,
          setValue: (prefs, value) => prefs.copyWith(performanceReports: value),
        ),
      ],
    ),

    SalesAgentNotificationCategory(
      title: 'Commission Notifications',
      description: 'Financial updates and commission tracking',
      icon: Icons.monetization_on,
      settings: [
        SalesAgentNotificationSetting(
          key: 'commissionUpdates',
          title: 'Commission Updates',
          description: 'Get notified about commission calculations',
          getValue: (prefs) => prefs.commissionUpdates,
          setValue: (prefs, value) => prefs.copyWith(commissionUpdates: value),
        ),
        SalesAgentNotificationSetting(
          key: 'payouts',
          title: 'Payouts',
          description: 'Receive notifications about payout confirmations',
          getValue: (prefs) => prefs.payouts,
          setValue: (prefs, value) => prefs.copyWith(payouts: value),
        ),
        SalesAgentNotificationSetting(
          key: 'bonusAlerts',
          title: 'Bonus Alerts',
          description: 'Get notified about bonus opportunities and achievements',
          getValue: (prefs) => prefs.bonusAlerts,
          setValue: (prefs, value) => prefs.copyWith(bonusAlerts: value),
        ),
        SalesAgentNotificationSetting(
          key: 'targetAchievements',
          title: 'Target Achievements',
          description: 'Receive notifications when you reach sales targets',
          getValue: (prefs) => prefs.targetAchievements,
          setValue: (prefs, value) => prefs.copyWith(targetAchievements: value),
        ),
      ],
    ),

    SalesAgentNotificationCategory(
      title: 'Marketing Notifications',
      description: 'Promotional content and sales tips',
      icon: Icons.campaign,
      settings: [
        SalesAgentNotificationSetting(
          key: 'promotions',
          title: 'Promotions',
          description: 'Special offers and promotional campaigns',
          getValue: (prefs) => prefs.promotions,
          setValue: (prefs, value) => prefs.copyWith(promotions: value),
        ),
        SalesAgentNotificationSetting(
          key: 'featureUpdates',
          title: 'Feature Updates',
          description: 'New features and platform improvements',
          getValue: (prefs) => prefs.featureUpdates,
          setValue: (prefs, value) => prefs.copyWith(featureUpdates: value),
        ),
        SalesAgentNotificationSetting(
          key: 'salesTips',
          title: 'Sales Tips',
          description: 'Helpful tips and best practices for sales',
          getValue: (prefs) => prefs.salesTips,
          setValue: (prefs, value) => prefs.copyWith(salesTips: value),
        ),
        SalesAgentNotificationSetting(
          key: 'marketingCampaigns',
          title: 'Marketing Campaigns',
          description: 'Information about marketing campaigns and materials',
          getValue: (prefs) => prefs.marketingCampaigns,
          setValue: (prefs, value) => prefs.copyWith(marketingCampaigns: value),
        ),
      ],
    ),

    SalesAgentNotificationCategory(
      title: 'Delivery Methods',
      description: 'How you want to receive notifications',
      icon: Icons.notifications_active,
      settings: [
        SalesAgentNotificationSetting(
          key: 'emailNotifications',
          title: 'Email Notifications',
          description: 'Receive notifications via email',
          getValue: (prefs) => prefs.emailNotifications,
          setValue: (prefs, value) => prefs.copyWith(emailNotifications: value),
        ),
        SalesAgentNotificationSetting(
          key: 'pushNotifications',
          title: 'Push Notifications',
          description: 'Receive push notifications on your device',
          getValue: (prefs) => prefs.pushNotifications,
          setValue: (prefs, value) => prefs.copyWith(pushNotifications: value),
        ),
        SalesAgentNotificationSetting(
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

// Current Sales Agent Notification Settings Provider
// This provider gets the notification settings for the currently authenticated sales agent
final currentSalesAgentNotificationSettingsProvider = StateNotifierProvider<SalesAgentNotificationSettingsNotifier, SalesAgentNotificationSettingsState>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = authState.user;
  final salesAgentService = ref.watch(salesAgentServiceProvider);

  if (currentUser == null) {
    // Return a notifier with default state if no user is authenticated
    return SalesAgentNotificationSettingsNotifier(salesAgentService, 'default');
  }

  // Return the notifier for the current user's sales agent ID
  return SalesAgentNotificationSettingsNotifier(salesAgentService, currentUser.id);
});
