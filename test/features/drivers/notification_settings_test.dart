import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/features/drivers/data/models/driver_notification_preferences.dart';

void main() {
  group('Driver Notification Settings Tests', () {

    group('DriverNotificationPreferences Model', () {
      test('should create default preferences with correct values', () {
        const preferences = DriverNotificationPreferences();

        // Order notifications - should default to true for critical ones
        expect(preferences.orderAssignments, true);
        expect(preferences.statusReminders, true);
        expect(preferences.orderCancellations, true);
        expect(preferences.orderUpdates, true);

        // Earnings notifications - should default to true for financial matters
        expect(preferences.earningsUpdates, true);
        expect(preferences.payoutNotifications, true);
        expect(preferences.bonusAlerts, true);
        expect(preferences.commissionUpdates, true);

        // Performance notifications - should default to true for important ones
        expect(preferences.performanceAlerts, true);
        expect(preferences.ratingUpdates, true);
        expect(preferences.targetAchievements, true);
        expect(preferences.deliveryMetrics, false); // Less critical

        // Fleet notifications - should default to true for important ones
        expect(preferences.fleetAnnouncements, true);
        expect(preferences.systemAnnouncements, true);
        expect(preferences.accountUpdates, true);
        expect(preferences.policyChanges, true);

        // Location & tracking notifications - should default to false to avoid spam
        expect(preferences.locationReminders, false);
        expect(preferences.routeOptimizations, true);
        expect(preferences.trafficAlerts, true);
        expect(preferences.deliveryZoneUpdates, false);

        // Customer notifications - should default to true for business-critical ones
        expect(preferences.customerMessages, true);
        expect(preferences.customerFeedback, false);
        expect(preferences.specialInstructions, true);
        expect(preferences.contactUpdates, true);

        // Delivery methods - should default to push and email
        expect(preferences.emailNotifications, true);
        expect(preferences.pushNotifications, true);
        expect(preferences.smsNotifications, false);
      });

      test('should create preferences with custom values', () {
        const preferences = DriverNotificationPreferences(
          orderAssignments: false,
          earningsUpdates: false,
          emailNotifications: false,
          pushNotifications: false,
          smsNotifications: true,
        );

        expect(preferences.orderAssignments, false);
        expect(preferences.earningsUpdates, false);
        expect(preferences.emailNotifications, false);
        expect(preferences.pushNotifications, false);
        expect(preferences.smsNotifications, true);
      });

      test('should support copyWith functionality', () {
        const originalPreferences = DriverNotificationPreferences();
        
        final updatedPreferences = originalPreferences.copyWith(
          orderAssignments: false,
          emailNotifications: false,
        );

        expect(updatedPreferences.orderAssignments, false);
        expect(updatedPreferences.emailNotifications, false);
        // Other values should remain unchanged
        expect(updatedPreferences.statusReminders, true);
        expect(updatedPreferences.pushNotifications, true);
      });

      test('should serialize to and from JSON correctly', () {
        const originalPreferences = DriverNotificationPreferences(
          orderAssignments: false,
          earningsUpdates: true,
          emailNotifications: false,
          pushNotifications: true,
          smsNotifications: true,
        );

        final json = originalPreferences.toJson();
        final deserializedPreferences = DriverNotificationPreferences.fromJson(json);

        expect(deserializedPreferences.orderAssignments, false);
        expect(deserializedPreferences.earningsUpdates, true);
        expect(deserializedPreferences.emailNotifications, false);
        expect(deserializedPreferences.pushNotifications, true);
        expect(deserializedPreferences.smsNotifications, true);
      });

      test('should support legacy JSON format conversion', () {
        final legacyJson = {
          'email': false,
          'push': true,
          'sms': true,
          'route_alerts': false,
          'traffic_alerts': false,
        };

        final preferences = DriverNotificationPreferences.fromLegacyJson(legacyJson);

        expect(preferences.emailNotifications, false);
        expect(preferences.pushNotifications, true);
        expect(preferences.smsNotifications, true);
        expect(preferences.routeOptimizations, false);
        expect(preferences.trafficAlerts, false);
        
        // Should set reasonable defaults for new categories
        expect(preferences.orderAssignments, true);
        expect(preferences.earningsUpdates, true);
        expect(preferences.performanceAlerts, true);
      });
    });

    group('Equatable Implementation', () {
      test('should support equality comparison', () {
        const preferences1 = DriverNotificationPreferences(
          orderAssignments: true,
          emailNotifications: false,
        );

        const preferences2 = DriverNotificationPreferences(
          orderAssignments: true,
          emailNotifications: false,
        );

        const preferences3 = DriverNotificationPreferences(
          orderAssignments: false,
          emailNotifications: false,
        );

        expect(preferences1, equals(preferences2));
        expect(preferences1, isNot(equals(preferences3)));
      });
    });
  });
}
