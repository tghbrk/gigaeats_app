// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gigaeats_app/main.dart';
// TODO: Restore missing URI import when auth_provider is implemented
// import 'package:gigaeats_app/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('GigaEats app smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    // TODO: Use sharedPreferences when needed
    // final sharedPreferences = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        // TODO: Restore when sharedPreferencesProvider is implemented
        overrides: [
          // sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const GigaEatsApp(),
      ),
    );

    // Verify that the splash screen is shown initially
    expect(find.text('GigaEats'), findsOneWidget);
    expect(find.text('Bulk Food Ordering Made Easy'), findsOneWidget);
  });
}
