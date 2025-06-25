import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/base_repository.dart';
import '../models/driver_notification_preferences.dart';

/// Provider for driver notification settings repository
final driverNotificationSettingsRepositoryProvider = Provider<DriverNotificationSettingsRepository>((ref) {
  return DriverNotificationSettingsRepository();
});

/// Repository for managing driver notification preferences
/// Uses Supabase functions to interact with user metadata
class DriverNotificationSettingsRepository extends BaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get driver notification preferences
  /// Uses the get_driver_notification_preferences Supabase function
  Future<DriverNotificationPreferences> getDriverNotificationPreferences(String userId) async {
    return executeQuery(() async {
      debugPrint('🔔 DriverNotificationSettingsRepository: Getting preferences for user: $userId');
      
      try {
        // Call the Supabase function to get driver notification preferences
        final response = await _supabase.rpc('get_driver_notification_preferences', params: {
          'p_user_id': userId,
        });

        debugPrint('🔔 DriverNotificationSettingsRepository: Raw response: $response');
        debugPrint('🔔 DriverNotificationSettingsRepository: Response type: ${response.runtimeType}');

        if (response == null) {
          debugPrint('🔔 DriverNotificationSettingsRepository: No preferences found, returning defaults');
          return const DriverNotificationPreferences();
        }

        // Parse the JSONB response - the function returns the preferences directly
        Map<String, dynamic> preferencesJson;

        if (response is List && response.isNotEmpty) {
          // If response is a list (which it should be from the function), get the first element
          final firstElement = response.first as Map<String, dynamic>;
          if (firstElement.containsKey('preferences')) {
            preferencesJson = firstElement['preferences'] as Map<String, dynamic>;
          } else {
            preferencesJson = firstElement;
          }
        } else if (response is Map<String, dynamic>) {
          // If response is already a map
          if (response.containsKey('preferences')) {
            preferencesJson = response['preferences'] as Map<String, dynamic>;
          } else {
            preferencesJson = response;
          }
        } else {
          debugPrint('🔔 DriverNotificationSettingsRepository: Unexpected response format, returning defaults');
          return const DriverNotificationPreferences();
        }

        debugPrint('🔔 DriverNotificationSettingsRepository: Parsed preferences JSON: $preferencesJson');

        // Check if it's the new format or legacy format
        if (preferencesJson.containsKey('orderAssignments')) {
          // New format
          debugPrint('🔔 DriverNotificationSettingsRepository: Using new format preferences');
          return DriverNotificationPreferences.fromJson(preferencesJson);
        } else {
          // Legacy format - convert it
          debugPrint('🔔 DriverNotificationSettingsRepository: Converting legacy format preferences');
          return DriverNotificationPreferences.fromLegacyJson(preferencesJson);
        }
      } catch (e) {
        debugPrint('🔔 DriverNotificationSettingsRepository: Error getting preferences: $e');
        // Return default preferences if there's an error
        return const DriverNotificationPreferences();
      }
    });
  }

  /// Update driver notification preferences
  /// Uses the update_driver_notification_preferences Supabase function
  Future<bool> updateDriverNotificationPreferences(
    String userId,
    DriverNotificationPreferences preferences,
  ) async {
    return executeQuery(() async {
      debugPrint('🔔 DriverNotificationSettingsRepository: Updating preferences for user: $userId');
      
      try {
        final preferencesJson = preferences.toJson();
        debugPrint('🔔 DriverNotificationSettingsRepository: Preferences JSON: $preferencesJson');

        // Call the Supabase function to update driver notification preferences
        final response = await _supabase.rpc('update_driver_notification_preferences', params: {
          'p_user_id': userId,
          'p_preferences': preferencesJson,
        });

        debugPrint('🔔 DriverNotificationSettingsRepository: Update response: $response');

        // The function returns a boolean indicating success
        return response == true;
      } catch (e) {
        debugPrint('🔔 DriverNotificationSettingsRepository: Error updating preferences: $e');
        throw Exception('Failed to update driver notification preferences: $e');
      }
    });
  }

  /// Get driver notification categories for UI organization
  List<DriverNotificationCategory> getDriverNotificationCategories() {
    return [
      DriverNotificationCategory(
        title: 'Order Notifications',
        description: 'Get notified about order assignments and updates',
        icon: Icons.local_shipping,
        settings: [
          DriverNotificationSetting(
            key: 'orderAssignments',
            title: 'Order Assignments',
            description: 'Get notified when you are assigned to a new order',
            getValue: (prefs) => prefs.orderAssignments,
            setValue: (prefs, value) => prefs.copyWith(orderAssignments: value),
          ),
          DriverNotificationSetting(
            key: 'statusReminders',
            title: 'Status Reminders',
            description: 'Reminders to update your delivery status',
            getValue: (prefs) => prefs.statusReminders,
            setValue: (prefs, value) => prefs.copyWith(statusReminders: value),
          ),
          DriverNotificationSetting(
            key: 'orderCancellations',
            title: 'Order Cancellations',
            description: 'Get notified when orders are cancelled',
            getValue: (prefs) => prefs.orderCancellations,
            setValue: (prefs, value) => prefs.copyWith(orderCancellations: value),
          ),
          DriverNotificationSetting(
            key: 'orderUpdates',
            title: 'Order Updates',
            description: 'Get notified about order status changes',
            getValue: (prefs) => prefs.orderUpdates,
            setValue: (prefs, value) => prefs.copyWith(orderUpdates: value),
          ),
        ],
      ),
      DriverNotificationCategory(
        title: 'Earnings & Payments',
        description: 'Stay updated on your earnings and payouts',
        icon: Icons.account_balance_wallet,
        settings: [
          DriverNotificationSetting(
            key: 'earningsUpdates',
            title: 'Earnings Updates',
            description: 'Get notified when your earnings are updated',
            getValue: (prefs) => prefs.earningsUpdates,
            setValue: (prefs, value) => prefs.copyWith(earningsUpdates: value),
          ),
          DriverNotificationSetting(
            key: 'payoutNotifications',
            title: 'Payout Notifications',
            description: 'Get notified when payouts are processed',
            getValue: (prefs) => prefs.payoutNotifications,
            setValue: (prefs, value) => prefs.copyWith(payoutNotifications: value),
          ),
          DriverNotificationSetting(
            key: 'bonusAlerts',
            title: 'Bonus Alerts',
            description: 'Get notified about bonus opportunities',
            getValue: (prefs) => prefs.bonusAlerts,
            setValue: (prefs, value) => prefs.copyWith(bonusAlerts: value),
          ),
          DriverNotificationSetting(
            key: 'commissionUpdates',
            title: 'Commission Updates',
            description: 'Get notified about commission changes',
            getValue: (prefs) => prefs.commissionUpdates,
            setValue: (prefs, value) => prefs.copyWith(commissionUpdates: value),
          ),
        ],
      ),
      DriverNotificationCategory(
        title: 'Performance & Feedback',
        description: 'Track your performance and customer feedback',
        icon: Icons.trending_up,
        settings: [
          DriverNotificationSetting(
            key: 'performanceAlerts',
            title: 'Performance Alerts',
            description: 'Get notified about performance updates',
            getValue: (prefs) => prefs.performanceAlerts,
            setValue: (prefs, value) => prefs.copyWith(performanceAlerts: value),
          ),
          DriverNotificationSetting(
            key: 'ratingUpdates',
            title: 'Rating Updates',
            description: 'Get notified when customers rate your service',
            getValue: (prefs) => prefs.ratingUpdates,
            setValue: (prefs, value) => prefs.copyWith(ratingUpdates: value),
          ),
          DriverNotificationSetting(
            key: 'targetAchievements',
            title: 'Target Achievements',
            description: 'Get notified when you reach delivery targets',
            getValue: (prefs) => prefs.targetAchievements,
            setValue: (prefs, value) => prefs.copyWith(targetAchievements: value),
          ),
          DriverNotificationSetting(
            key: 'deliveryMetrics',
            title: 'Delivery Metrics',
            description: 'Get detailed delivery performance metrics',
            getValue: (prefs) => prefs.deliveryMetrics,
            setValue: (prefs, value) => prefs.copyWith(deliveryMetrics: value),
          ),
        ],
      ),
      DriverNotificationCategory(
        title: 'Fleet & System',
        description: 'Stay informed about fleet announcements and system updates',
        icon: Icons.announcement,
        settings: [
          DriverNotificationSetting(
            key: 'fleetAnnouncements',
            title: 'Fleet Announcements',
            description: 'Get notified about fleet-wide announcements',
            getValue: (prefs) => prefs.fleetAnnouncements,
            setValue: (prefs, value) => prefs.copyWith(fleetAnnouncements: value),
          ),
          DriverNotificationSetting(
            key: 'systemAnnouncements',
            title: 'System Announcements',
            description: 'Get notified about system updates and maintenance',
            getValue: (prefs) => prefs.systemAnnouncements,
            setValue: (prefs, value) => prefs.copyWith(systemAnnouncements: value),
          ),
          DriverNotificationSetting(
            key: 'accountUpdates',
            title: 'Account Updates',
            description: 'Get notified about account-related changes',
            getValue: (prefs) => prefs.accountUpdates,
            setValue: (prefs, value) => prefs.copyWith(accountUpdates: value),
          ),
          DriverNotificationSetting(
            key: 'policyChanges',
            title: 'Policy Changes',
            description: 'Get notified about policy and terms updates',
            getValue: (prefs) => prefs.policyChanges,
            setValue: (prefs, value) => prefs.copyWith(policyChanges: value),
          ),
        ],
      ),
      DriverNotificationCategory(
        title: 'Location & Navigation',
        description: 'Get assistance with routes and traffic updates',
        icon: Icons.navigation,
        settings: [
          DriverNotificationSetting(
            key: 'locationReminders',
            title: 'Location Reminders',
            description: 'Reminders to update your location',
            getValue: (prefs) => prefs.locationReminders,
            setValue: (prefs, value) => prefs.copyWith(locationReminders: value),
          ),
          DriverNotificationSetting(
            key: 'routeOptimizations',
            title: 'Route Optimizations',
            description: 'Get suggestions for better routes',
            getValue: (prefs) => prefs.routeOptimizations,
            setValue: (prefs, value) => prefs.copyWith(routeOptimizations: value),
          ),
          DriverNotificationSetting(
            key: 'trafficAlerts',
            title: 'Traffic Alerts',
            description: 'Get notified about traffic conditions',
            getValue: (prefs) => prefs.trafficAlerts,
            setValue: (prefs, value) => prefs.copyWith(trafficAlerts: value),
          ),
          DriverNotificationSetting(
            key: 'deliveryZoneUpdates',
            title: 'Delivery Zone Updates',
            description: 'Get notified about delivery zone changes',
            getValue: (prefs) => prefs.deliveryZoneUpdates,
            setValue: (prefs, value) => prefs.copyWith(deliveryZoneUpdates: value),
          ),
        ],
      ),
      DriverNotificationCategory(
        title: 'Customer Communication',
        description: 'Stay connected with customers during deliveries',
        icon: Icons.chat,
        settings: [
          DriverNotificationSetting(
            key: 'customerMessages',
            title: 'Customer Messages',
            description: 'Get notified when customers send messages',
            getValue: (prefs) => prefs.customerMessages,
            setValue: (prefs, value) => prefs.copyWith(customerMessages: value),
          ),
          DriverNotificationSetting(
            key: 'customerFeedback',
            title: 'Customer Feedback',
            description: 'Get notified about customer feedback',
            getValue: (prefs) => prefs.customerFeedback,
            setValue: (prefs, value) => prefs.copyWith(customerFeedback: value),
          ),
          DriverNotificationSetting(
            key: 'specialInstructions',
            title: 'Special Instructions',
            description: 'Get notified about special delivery instructions',
            getValue: (prefs) => prefs.specialInstructions,
            setValue: (prefs, value) => prefs.copyWith(specialInstructions: value),
          ),
          DriverNotificationSetting(
            key: 'contactUpdates',
            title: 'Contact Updates',
            description: 'Get notified when customer contact info changes',
            getValue: (prefs) => prefs.contactUpdates,
            setValue: (prefs, value) => prefs.copyWith(contactUpdates: value),
          ),
        ],
      ),
      DriverNotificationCategory(
        title: 'Delivery Methods',
        description: 'Choose how you want to receive notifications',
        icon: Icons.notifications,
        settings: [
          DriverNotificationSetting(
            key: 'emailNotifications',
            title: 'Email Notifications',
            description: 'Receive notifications via email',
            getValue: (prefs) => prefs.emailNotifications,
            setValue: (prefs, value) => prefs.copyWith(emailNotifications: value),
          ),
          DriverNotificationSetting(
            key: 'pushNotifications',
            title: 'Push Notifications',
            description: 'Receive push notifications on your device',
            getValue: (prefs) => prefs.pushNotifications,
            setValue: (prefs, value) => prefs.copyWith(pushNotifications: value),
          ),
          DriverNotificationSetting(
            key: 'smsNotifications',
            title: 'SMS Notifications',
            description: 'Receive notifications via SMS',
            getValue: (prefs) => prefs.smsNotifications,
            setValue: (prefs, value) => prefs.copyWith(smsNotifications: value),
          ),
        ],
      ),
    ];
  }

  /// Validate driver notification preferences
  /// Ensures that critical notifications are not all disabled
  bool validateDriverNotificationPreferences(DriverNotificationPreferences preferences) {
    // Ensure at least one delivery method is enabled
    if (!preferences.emailNotifications &&
        !preferences.pushNotifications &&
        !preferences.smsNotifications) {
      return false;
    }

    // Ensure critical order notifications are enabled
    if (!preferences.orderAssignments && !preferences.orderCancellations) {
      return false;
    }

    return true;
  }

  /// Get default driver notification preferences
  DriverNotificationPreferences getDefaultDriverNotificationPreferences() {
    return const DriverNotificationPreferences();
  }
}
