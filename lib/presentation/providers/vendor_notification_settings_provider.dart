import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../data/models/vendor_notification_preferences.dart';
import '../../data/services/vendor_service.dart';
import 'vendor_provider.dart';

// Vendor Notification Settings State
class VendorNotificationSettingsState {
  final VendorNotificationPreferences preferences;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const VendorNotificationSettingsState({
    required this.preferences,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  VendorNotificationSettingsState copyWith({
    VendorNotificationPreferences? preferences,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return VendorNotificationSettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Vendor Notification Settings Notifier
class VendorNotificationSettingsNotifier extends StateNotifier<VendorNotificationSettingsState> {
  final VendorService _vendorService;
  final String _vendorId;

  VendorNotificationSettingsNotifier(this._vendorService, this._vendorId)
      : super(VendorNotificationSettingsState(
          preferences: const VendorNotificationPreferences(),
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final settings = await _vendorService.getVendorSettings(_vendorId);
      
      VendorNotificationPreferences preferences;
      if (settings != null && settings['notification_preferences'] != null) {
        final notificationPrefs = settings['notification_preferences'] as Map<String, dynamic>;
        
        // Check if it's the new format or legacy format
        if (notificationPrefs.containsKey('newOrders')) {
          // New format
          preferences = VendorNotificationPreferences.fromJson(notificationPrefs);
        } else {
          // Legacy format - convert it
          preferences = VendorNotificationPreferences.fromLegacyJson(notificationPrefs);
        }
      } else {
        // No settings found, use defaults
        preferences = const VendorNotificationPreferences();
      }

      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notification settings: $e',
      );
    }
  }

  Future<void> updatePreferences(VendorNotificationPreferences newPreferences) async {
    debugPrint('VendorNotificationSettings: Starting updatePreferences for vendor $_vendorId');
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      final settingsData = {
        'notification_preferences': newPreferences.toJson(),
      };
      debugPrint('VendorNotificationSettings: Settings data: $settingsData');

      await _vendorService.updateVendorSettings(_vendorId, settingsData);
      debugPrint('VendorNotificationSettings: Successfully updated vendor settings');

      state = state.copyWith(
        preferences: newPreferences,
        isSaving: false,
        successMessage: 'Notification settings updated successfully!',
      );

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(successMessage: null);
        }
      });
    } catch (e) {
      debugPrint('VendorNotificationSettings: Error updating preferences: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update notification settings: $e',
      );
    }
  }

  void updateSinglePreference(String key, bool value) {
    debugPrint('VendorNotificationSettings: Updating $key to $value');
    final currentPrefs = state.preferences;
    VendorNotificationPreferences newPrefs;

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
      case 'profileUpdates':
        newPrefs = currentPrefs.copyWith(profileUpdates: value);
        break;
      case 'menuApprovals':
        newPrefs = currentPrefs.copyWith(menuApprovals: value);
        break;
      case 'systemAnnouncements':
        newPrefs = currentPrefs.copyWith(systemAnnouncements: value);
        break;
      case 'accountUpdates':
        newPrefs = currentPrefs.copyWith(accountUpdates: value);
        break;
      case 'promotions':
        newPrefs = currentPrefs.copyWith(promotions: value);
        break;
      case 'featureUpdates':
        newPrefs = currentPrefs.copyWith(featureUpdates: value);
        break;
      case 'businessTips':
        newPrefs = currentPrefs.copyWith(businessTips: value);
        break;
      case 'marketingCampaigns':
        newPrefs = currentPrefs.copyWith(marketingCampaigns: value);
        break;
      case 'earnings':
        newPrefs = currentPrefs.copyWith(earnings: value);
        break;
      case 'payouts':
        newPrefs = currentPrefs.copyWith(payouts: value);
        break;
      case 'transactionAlerts':
        newPrefs = currentPrefs.copyWith(transactionAlerts: value);
        break;
      case 'paymentFailures':
        newPrefs = currentPrefs.copyWith(paymentFailures: value);
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
    debugPrint('VendorNotificationSettings: Updating state with new preferences');
    state = state.copyWith(preferences: newPrefs);

    // Save to backend
    debugPrint('VendorNotificationSettings: Saving to backend');
    updatePreferences(newPrefs);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  void refresh() {
    _loadSettings();
  }
}

// Provider for vendor notification settings
final vendorNotificationSettingsProvider = StateNotifierProvider.family<
    VendorNotificationSettingsNotifier,
    VendorNotificationSettingsState,
    String>((ref, vendorId) {
  final vendorService = ref.watch(vendorServiceProvider);
  return VendorNotificationSettingsNotifier(vendorService, vendorId);
});

// Notification categories for UI organization
final notificationCategoriesProvider = Provider<List<NotificationCategory>>((ref) {
  return [
    NotificationCategory(
      title: 'Order Notifications',
      description: 'Get notified about order activities',
      icon: Icons.shopping_bag,
      settings: [
        NotificationSetting(
          key: 'newOrders',
          title: 'New Orders',
          description: 'Receive notifications when new orders are placed',
          getValue: (prefs) => prefs.newOrders,
          setValue: (prefs, value) => prefs.copyWith(newOrders: value),
        ),
        NotificationSetting(
          key: 'orderStatusChanges',
          title: 'Order Status Changes',
          description: 'Get notified when order status is updated',
          getValue: (prefs) => prefs.orderStatusChanges,
          setValue: (prefs, value) => prefs.copyWith(orderStatusChanges: value),
        ),
        NotificationSetting(
          key: 'orderCancellations',
          title: 'Order Cancellations',
          description: 'Receive alerts when orders are cancelled',
          getValue: (prefs) => prefs.orderCancellations,
          setValue: (prefs, value) => prefs.copyWith(orderCancellations: value),
        ),
        NotificationSetting(
          key: 'orderPayments',
          title: 'Order Payments',
          description: 'Get notified about payment confirmations',
          getValue: (prefs) => prefs.orderPayments,
          setValue: (prefs, value) => prefs.copyWith(orderPayments: value),
        ),
      ],
    ),
    NotificationCategory(
      title: 'Business Notifications',
      description: 'Stay updated on business-related activities',
      icon: Icons.business,
      settings: [
        NotificationSetting(
          key: 'profileUpdates',
          title: 'Profile Updates',
          description: 'Get notified about profile changes and approvals',
          getValue: (prefs) => prefs.profileUpdates,
          setValue: (prefs, value) => prefs.copyWith(profileUpdates: value),
        ),
        NotificationSetting(
          key: 'menuApprovals',
          title: 'Menu Approvals',
          description: 'Receive notifications about menu item approvals',
          getValue: (prefs) => prefs.menuApprovals,
          setValue: (prefs, value) => prefs.copyWith(menuApprovals: value),
        ),
        NotificationSetting(
          key: 'systemAnnouncements',
          title: 'System Announcements',
          description: 'Important platform updates and announcements',
          getValue: (prefs) => prefs.systemAnnouncements,
          setValue: (prefs, value) => prefs.copyWith(systemAnnouncements: value),
        ),
        NotificationSetting(
          key: 'accountUpdates',
          title: 'Account Updates',
          description: 'Changes to your account status or settings',
          getValue: (prefs) => prefs.accountUpdates,
          setValue: (prefs, value) => prefs.copyWith(accountUpdates: value),
        ),
      ],
    ),
    NotificationCategory(
      title: 'Marketing Notifications',
      description: 'Promotional content and business tips',
      icon: Icons.campaign,
      settings: [
        NotificationSetting(
          key: 'promotions',
          title: 'Promotions',
          description: 'Special offers and promotional campaigns',
          getValue: (prefs) => prefs.promotions,
          setValue: (prefs, value) => prefs.copyWith(promotions: value),
        ),
        NotificationSetting(
          key: 'featureUpdates',
          title: 'Feature Updates',
          description: 'New features and platform improvements',
          getValue: (prefs) => prefs.featureUpdates,
          setValue: (prefs, value) => prefs.copyWith(featureUpdates: value),
        ),
        NotificationSetting(
          key: 'businessTips',
          title: 'Business Tips',
          description: 'Tips to grow your business and increase sales',
          getValue: (prefs) => prefs.businessTips,
          setValue: (prefs, value) => prefs.copyWith(businessTips: value),
        ),
        NotificationSetting(
          key: 'marketingCampaigns',
          title: 'Marketing Campaigns',
          description: 'Participate in platform-wide marketing campaigns',
          getValue: (prefs) => prefs.marketingCampaigns,
          setValue: (prefs, value) => prefs.copyWith(marketingCampaigns: value),
        ),
      ],
    ),
    NotificationCategory(
      title: 'Payment Notifications',
      description: 'Financial transactions and earnings',
      icon: Icons.payment,
      settings: [
        NotificationSetting(
          key: 'earnings',
          title: 'Earnings',
          description: 'Daily and weekly earnings summaries',
          getValue: (prefs) => prefs.earnings,
          setValue: (prefs, value) => prefs.copyWith(earnings: value),
        ),
        NotificationSetting(
          key: 'payouts',
          title: 'Payouts',
          description: 'Payout confirmations and schedules',
          getValue: (prefs) => prefs.payouts,
          setValue: (prefs, value) => prefs.copyWith(payouts: value),
        ),
        NotificationSetting(
          key: 'transactionAlerts',
          title: 'Transaction Alerts',
          description: 'Important transaction notifications',
          getValue: (prefs) => prefs.transactionAlerts,
          setValue: (prefs, value) => prefs.copyWith(transactionAlerts: value),
        ),
        NotificationSetting(
          key: 'paymentFailures',
          title: 'Payment Failures',
          description: 'Alerts about failed payments or issues',
          getValue: (prefs) => prefs.paymentFailures,
          setValue: (prefs, value) => prefs.copyWith(paymentFailures: value),
        ),
      ],
    ),
    NotificationCategory(
      title: 'Delivery Methods',
      description: 'How you want to receive notifications',
      icon: Icons.notifications_active,
      settings: [
        NotificationSetting(
          key: 'emailNotifications',
          title: 'Email Notifications',
          description: 'Receive notifications via email',
          getValue: (prefs) => prefs.emailNotifications,
          setValue: (prefs, value) => prefs.copyWith(emailNotifications: value),
        ),
        NotificationSetting(
          key: 'pushNotifications',
          title: 'Push Notifications',
          description: 'Receive push notifications on your device',
          getValue: (prefs) => prefs.pushNotifications,
          setValue: (prefs, value) => prefs.copyWith(pushNotifications: value),
        ),
        NotificationSetting(
          key: 'smsNotifications',
          title: 'SMS Notifications',
          description: 'Receive notifications via SMS (charges may apply)',
          getValue: (prefs) => prefs.smsNotifications,
          setValue: (prefs, value) => prefs.copyWith(smsNotifications: value),
        ),
      ],
    ),
  ];
});
