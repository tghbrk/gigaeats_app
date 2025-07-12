import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/widgets/navigation_app_selector.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/navigation_app_service.dart';

void main() {
  group('NavigationAppSelector Widget Tests', () {
    late List<NavigationApp> mockApps;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      
      mockApps = [
        const NavigationApp(
          id: 'google_maps',
          name: 'Google Maps',
          iconAsset: 'assets/icons/google_maps.png',
          isInstalled: true,
          supportedFeatures: ['traffic', 'avoid_tolls'],
        ),
        const NavigationApp(
          id: 'waze',
          name: 'Waze',
          iconAsset: 'assets/icons/waze.png',
          isInstalled: true,
          supportedFeatures: ['traffic', 'real_time_updates'],
        ),
        const NavigationApp(
          id: 'in_app',
          name: 'In-App Navigation',
          iconAsset: 'assets/icons/in_app_nav.png',
          isInstalled: true,
          isDefault: true,
          supportedFeatures: ['basic_navigation'],
        ),
        const NavigationApp(
          id: 'here_maps',
          name: 'HERE WeGo',
          iconAsset: 'assets/icons/here_maps.png',
          isInstalled: false,
          supportedFeatures: ['offline_maps'],
        ),
      ];
    });

    Widget createTestWidget({
      String? selectedAppId,
      required ValueChanged<String> onAppSelected,
      bool showInstallPrompt = true,
      bool showDescription = true,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NavigationAppSelector(
              availableApps: mockApps,
              selectedAppId: selectedAppId,
              onAppSelected: onAppSelected,
              showInstallPrompt: showInstallPrompt,
              showDescription: showDescription,
            ),
          ),
        ),
      );
    }

    testWidgets('displays all available navigation apps', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) {},
      ));

      // Verify all apps are displayed
      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.text('Waze'), findsOneWidget);
      expect(find.text('In-App Navigation'), findsOneWidget);
      expect(find.text('HERE WeGo'), findsOneWidget);

      // Verify installed status
      expect(find.text('Installed'), findsNWidgets(3)); // Google Maps, Waze, In-App
      expect(find.text('Not installed'), findsOneWidget); // HERE WeGo
    });

    testWidgets('shows selected app with check icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedAppId: 'google_maps',
        onAppSelected: (appId) {},
      ));

      // Verify check icon is shown for selected app
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls onAppSelected when app is tapped', (WidgetTester tester) async {
      String? selectedApp;
      
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) => selectedApp = appId,
      ));

      // Tap on Waze
      await tester.tap(find.text('Waze'));
      await tester.pump();

      expect(selectedApp, equals('waze'));
    });

    testWidgets('does not allow selection of uninstalled apps', (WidgetTester tester) async {
      String? selectedApp;
      
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) => selectedApp = appId,
      ));

      // Try to tap on HERE WeGo (not installed)
      await tester.tap(find.text('HERE WeGo'));
      await tester.pump();

      // Should not be selected
      expect(selectedApp, isNull);
    });

    testWidgets('shows install prompt when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) {},
        showInstallPrompt: true,
      ));

      expect(find.text('Install additional navigation apps for more options'), findsOneWidget);
    });

    testWidgets('hides install prompt when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) {},
        showInstallPrompt: false,
      ));

      expect(find.text('Install additional navigation apps for more options'), findsNothing);
    });

    testWidgets('shows description when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) {},
        showDescription: true,
      ));

      expect(find.text('Your selection will be saved for future deliveries. You can change it anytime.'), findsOneWidget);
    });

    testWidgets('hides description when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) {},
        showDescription: false,
      ));

      expect(find.text('Your selection will be saved for future deliveries. You can change it anytime.'), findsNothing);
    });

    testWidgets('displays correct header information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) {},
      ));

      expect(find.text('Navigation App'), findsOneWidget);
      expect(find.text('Choose your preferred navigation app'), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('shows download icon for uninstalled apps', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) {},
      ));

      // Find the HERE WeGo tile and verify it has a download icon
      final hereMapsTile = find.ancestor(
        of: find.text('HERE WeGo'),
        matching: find.byType(Container),
      ).first;
      
      expect(find.descendant(
        of: hereMapsTile,
        matching: find.byIcon(Icons.download),
      ), findsOneWidget);
    });

    testWidgets('loads saved preference on initialization', (WidgetTester tester) async {
      // Set up mock preference
      SharedPreferences.setMockInitialValues({
        'preferred_navigation_app': 'waze',
      });

      String? selectedApp;
      
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) => selectedApp = appId,
      ));

      // Wait for async initialization
      await tester.pumpAndSettle();

      // Verify Waze is selected by default
      expect(selectedApp, equals('waze'));
    });

    testWidgets('defaults to in-app navigation when no preference saved', (WidgetTester tester) async {
      String? selectedApp;
      
      await tester.pumpWidget(createTestWidget(
        onAppSelected: (appId) => selectedApp = appId,
      ));

      // Wait for async initialization
      await tester.pumpAndSettle();

      // Should default to in-app navigation
      expect(selectedApp, equals('in_app'));
    });
  });

  group('NavigationAppSelector Integration Tests', () {
    testWidgets('saves preference when app is selected', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NavigationAppSelector(
              availableApps: [
                const NavigationApp(
                  id: 'google_maps',
                  name: 'Google Maps',
                  iconAsset: 'assets/icons/google_maps.png',
                  isInstalled: true,
                ),
              ],
              onAppSelected: (appId) {},
            ),
          ),
        ),
      ));

      // Tap on Google Maps
      await tester.tap(find.text('Google Maps'));
      await tester.pumpAndSettle();

      // Verify preference is saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('preferred_navigation_app'), equals('google_maps'));
    });
  });
}
