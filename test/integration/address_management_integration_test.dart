import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/user_management/presentation/screens/customer/customer_addresses_screen.dart';
import 'package:gigaeats_app/src/features/user_management/presentation/screens/customer/customer_address_selection_screen.dart';
import 'package:gigaeats_app/src/features/user_management/presentation/widgets/address_form_dialog.dart';
import 'package:gigaeats_app/src/features/user_management/presentation/providers/customer_address_provider.dart';
import 'package:gigaeats_app/src/features/user_management/domain/customer_profile.dart';
import 'package:gigaeats_app/src/features/user_management/data/repositories/customer_profile_repository.dart';

// Mock repository for testing
class MockCustomerProfileRepository implements CustomerProfileRepository {
  @override
  Future<CustomerProfile?> getCurrentProfile() async => null;

  @override
  Future<CustomerProfile> createProfile(CustomerProfile profile) async => profile;

  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async => profile;

  @override
  Future<CustomerProfile> addAddress(CustomerAddress address) async {
    // Return a mock profile with the address
    return CustomerProfile(
      id: 'mock-id',
      userId: 'mock-user-id',
      fullName: 'Mock User',
      addresses: [address],
      loyaltyPoints: 0,
      totalOrders: 0,
      totalSpent: 0.0,
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<CustomerProfile> updateAddress(CustomerAddress address) async {
    return CustomerProfile(
      id: 'mock-id',
      userId: 'mock-user-id',
      fullName: 'Mock User',
      addresses: [address],
      loyaltyPoints: 0,
      totalOrders: 0,
      totalSpent: 0.0,
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> deleteAddress(String addressId) async {}

  @override
  Future<CustomerProfile> setDefaultAddress(String addressId) async {
    return CustomerProfile(
      id: 'mock-id',
      userId: 'mock-user-id',
      fullName: 'Mock User',
      addresses: [],
      loyaltyPoints: 0,
      totalOrders: 0,
      totalSpent: 0.0,
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Add other required methods with default implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Address Management Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('CustomerAddressesScreen should display empty state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const CustomerAddressesScreen(),
          ),
        ),
      );

      // Should show empty state
      expect(find.text('No addresses found'), findsOneWidget);
      expect(find.text('Add your first delivery address'), findsOneWidget);
      expect(find.byIcon(Icons.add_location), findsOneWidget);
    });

    testWidgets('AddressFormDialog should validate Malaysian address fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const AddressFormDialog(),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify form fields are present
      expect(find.text('Add New Address'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5)); // label, address1, address2, city, postcode
      expect(find.byType(DropdownButtonFormField), findsOneWidget); // state dropdown

      // Test validation - try to save empty form
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Address label is required'), findsOneWidget);
      expect(find.text('Address is required'), findsOneWidget);
      expect(find.text('City is required'), findsOneWidget);
      expect(find.text('Postcode is required'), findsOneWidget);
      expect(find.text('State is required'), findsOneWidget);
    });

    testWidgets('AddressFormDialog should accept valid Malaysian address', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const AddressFormDialog(),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in valid Malaysian address
      await tester.enterText(find.byKey(const Key('address_label_field')), 'Home');
      await tester.enterText(find.byKey(const Key('address_line_1_field')), 'No. 123, Jalan Bukit Bintang');
      await tester.enterText(find.byKey(const Key('address_line_2_field')), 'Taman Desa');
      await tester.enterText(find.byKey(const Key('city_field')), 'Kuala Lumpur');
      await tester.enterText(find.byKey(const Key('postcode_field')), '50450');

      // Select state
      await tester.tap(find.byKey(const Key('state_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selangor').last);
      await tester.pumpAndSettle();

      // Save the address
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();

      // Dialog should close (no validation errors)
      expect(find.text('Add New Address'), findsNothing);
    });

    testWidgets('CustomerAddressSelectionScreen should show address list', (WidgetTester tester) async {
      // Create mock addresses
      final mockAddresses = [
        const CustomerAddress(
          id: '1',
          label: 'Home',
          addressLine1: 'No. 123, Jalan Bukit Bintang',
          city: 'Kuala Lumpur',
          state: 'Selangor',
          postalCode: '50450',
          isDefault: true,
        ),
        const CustomerAddress(
          id: '2',
          label: 'Office',
          addressLine1: 'Level 10, Menara ABC',
          city: 'Petaling Jaya',
          state: 'Selangor',
          postalCode: '47800',
          isDefault: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerAddressesProvider.overrideWith((ref) {
              final mockRepository = MockCustomerProfileRepository();
              final notifier = CustomerAddressesNotifier(mockRepository, ref);
              notifier.state = CustomerAddressesState(
                addresses: mockAddresses,
                isLoading: false,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: CustomerAddressSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show address list
      expect(find.text('Select Delivery Address'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget); // Default indicator
      expect(find.byIcon(Icons.check_circle), findsNothing); // No selection initially

      // Tap on an address to select it
      await tester.tap(find.text('Office'));
      await tester.pumpAndSettle();

      // Should show selection indicator
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Should enable the bottom button
      expect(find.text('Use This Address'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Address validation should reject invalid postal codes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const AddressFormDialog(),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in address with invalid postcode
      await tester.enterText(find.byKey(const Key('address_label_field')), 'Test');
      await tester.enterText(find.byKey(const Key('address_line_1_field')), 'Test Address');
      await tester.enterText(find.byKey(const Key('city_field')), 'Test City');
      await tester.enterText(find.byKey(const Key('postcode_field')), '1234'); // Invalid: only 4 digits

      // Select state
      await tester.tap(find.byKey(const Key('state_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selangor').last);
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();

      // Should show postcode validation error
      expect(find.text('Postcode must be exactly 5 digits'), findsOneWidget);
    });

    testWidgets('Address validation should reject invalid city names', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const AddressFormDialog(),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in address with invalid city (contains numbers)
      await tester.enterText(find.byKey(const Key('address_label_field')), 'Test');
      await tester.enterText(find.byKey(const Key('address_line_1_field')), 'Test Address');
      await tester.enterText(find.byKey(const Key('city_field')), 'City123'); // Invalid: contains numbers
      await tester.enterText(find.byKey(const Key('postcode_field')), '50450');

      // Select state
      await tester.tap(find.byKey(const Key('state_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selangor').last);
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();

      // Should show city validation error
      expect(find.text('City name can only contain letters, spaces, and hyphens'), findsOneWidget);
    });

    testWidgets('State dropdown should contain all Malaysian states', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const AddressFormDialog(),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Open state dropdown
      await tester.tap(find.byKey(const Key('state_dropdown')));
      await tester.pumpAndSettle();

      // Check for key Malaysian states
      expect(find.text('Selangor'), findsOneWidget);
      expect(find.text('Kuala Lumpur'), findsOneWidget);
      expect(find.text('Johor'), findsOneWidget);
      expect(find.text('Penang'), findsOneWidget);
      expect(find.text('Sabah'), findsOneWidget);
      expect(find.text('Sarawak'), findsOneWidget);
      expect(find.text('Putrajaya'), findsOneWidget);
      expect(find.text('Labuan'), findsOneWidget);
    });
  });
}
