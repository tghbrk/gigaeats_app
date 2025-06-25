import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/features/customers/presentation/screens/customer_addresses_screen.dart';

void main() {
  group('Customer Address Dialog UI Tests', () {
    testWidgets('Add Address Dialog should not overflow on small screens', (WidgetTester tester) async {
      // Set a small screen size to simulate the overflow condition
      await tester.binding.setSurfaceSize(const Size(360, 640)); // Small phone screen
      
      // Create the dialog widget
      final dialog = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddressFormDialog(
                    onSave: (address) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(dialog);
      
      // Tap the button to show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify the dialog is displayed
      expect(find.text('Add Address'), findsOneWidget);
      
      // Verify the City and State fields are present
      expect(find.text('City'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
      
      // Verify the DropdownButtonFormField is present
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      // Check that no RenderFlex overflow errors occur
      // This is implicit - if there were overflow errors, the test would fail
      
      // Verify the dialog has proper width constraints
      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      
      final AlertDialog alertDialog = tester.widget(dialogFinder);
      final SizedBox contentSizedBox = alertDialog.content as SizedBox;
      
      // Verify that the dialog width is responsive
      expect(contentSizedBox.width, isNotNull);
      expect(contentSizedBox.width! > 0, isTrue);
      
      // The dialog width should be responsive - either 90% of screen width or 500px max
      expect(contentSizedBox.width, isA<double>());
      expect(contentSizedBox.width! > 0, isTrue);
    });

    testWidgets('Add Address Dialog should have proper width on larger screens', (WidgetTester tester) async {
      // Set a larger screen size
      await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet screen
      
      // Create the dialog widget
      final dialog = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddressFormDialog(
                    onSave: (address) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(dialog);
      
      // Tap the button to show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify the dialog is displayed
      expect(find.text('Add Address'), findsOneWidget);
      
      // Verify the dialog has proper width constraints for larger screens
      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      
      final AlertDialog alertDialog = tester.widget(dialogFinder);
      final SizedBox contentSizedBox = alertDialog.content as SizedBox;
      
      // For screens wider than 600px, the dialog should be fixed at 500px
      expect(contentSizedBox.width, equals(500.0));
    });

    testWidgets('City and State Row should use Flexible widgets with proper flex ratios', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      final dialog = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddressFormDialog(
                    onSave: (address) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(dialog);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the Row containing City and State fields
      final rowFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Row),
      );
      
      // There should be multiple rows, find the one with Flexible widgets
      final rows = tester.widgetList<Row>(rowFinder);
      
      // Find the row that contains Flexible widgets (City and State row)
      Row? cityStateRow;
      for (final row in rows) {
        final flexibleChildren = row.children.whereType<Flexible>();
        if (flexibleChildren.length == 2) {
          cityStateRow = row;
          break;
        }
      }
      
      expect(cityStateRow, isNotNull);
      
      // Verify the flex ratios
      final flexibleWidgets = cityStateRow!.children.whereType<Flexible>().toList();
      expect(flexibleWidgets.length, equals(2));
      
      // City field should have flex: 2
      expect(flexibleWidgets[0].flex, equals(2));
      
      // State field should have flex: 3 (more space for dropdown)
      expect(flexibleWidgets[1].flex, equals(3));
    });

    testWidgets('State DropdownButtonFormField should be properly configured', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));

      final dialog = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddressFormDialog(
                    onSave: (address) {},
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(dialog);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the DropdownButtonFormField
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      expect(dropdownFinder, findsOneWidget);

      final DropdownButtonFormField<String> dropdown = tester.widget(dropdownFinder);

      // Verify that the dropdown has proper content padding
      expect(dropdown.decoration.contentPadding,
             equals(const EdgeInsets.symmetric(horizontal: 12, vertical: 16)));

      // Verify that the dropdown is present and functional
      expect(dropdown.onChanged, isNotNull);
    });

    testWidgets('Dialog should handle form validation properly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      bool saveCallbackCalled = false;
      
      final dialog = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddressFormDialog(
                    onSave: (address) {
                      saveCallbackCalled = true;
                    },
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(dialog);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to save without filling required fields
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      
      // Should show validation errors
      expect(find.text('Please enter a label'), findsOneWidget);
      expect(find.text('Please enter address'), findsOneWidget);
      expect(find.text('Please enter city'), findsOneWidget);
      expect(find.text('Please enter postal code'), findsOneWidget);

      // Note: State validation might not show immediately if no state is selected by default
      
      // Callback should not be called
      expect(saveCallbackCalled, isFalse);
    });
  });
}
