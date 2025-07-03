import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigaeats_app/src/features/orders/presentation/providers/checkout_defaults_provider.dart';
import 'package:gigaeats_app/src/features/orders/presentation/providers/checkout_flow_provider.dart';
import 'package:gigaeats_app/src/features/orders/presentation/providers/checkout_fallback_provider.dart';
import 'package:gigaeats_app/src/features/orders/data/models/customer_delivery_method.dart';
import 'package:gigaeats_app/src/features/user_management/domain/customer_profile.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/data/models/customer_payment_method.dart';

/// Integration test for checkout auto-fetch functionality
void main() {
  group('Checkout Auto-Fetch Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Auto-fetch defaults for delivery method requiring address', (tester) async {
      // Create test address and payment method
      final testAddress = CustomerAddress(
        id: 'test-address-1',
        label: 'Home',
        addressLine1: 'Jalan Test 123',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postalCode: '50000',
        isDefault: true,
      );

      final testPaymentMethod = CustomerPaymentMethod(
        id: 'test-payment-1',
        userId: 'test-user-1',
        stripePaymentMethodId: 'pm_test_1234',
        stripeCustomerId: 'cus_test_1234',
        type: CustomerPaymentMethodType.card,
        cardBrand: CardBrand.visa,
        cardLast4: '1234',
        cardExpMonth: 12,
        cardExpYear: 2025,
        isDefault: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock the providers to return test data
      final mockContainer = ProviderContainer(
        overrides: [
          checkoutDefaultsProvider.overrideWith((ref) {
            return CheckoutDefaults(
              defaultAddress: testAddress,
              defaultPaymentMethod: testPaymentMethod,
              hasAddress: true,
              hasPaymentMethod: true,
            );
          }),
        ],
      );

      // Test checkout defaults provider
      final defaults = mockContainer.read(checkoutDefaultsProvider);
      
      expect(defaults.hasAddress, isTrue);
      expect(defaults.hasPaymentMethod, isTrue);
      expect(defaults.defaultAddress?.label, equals('Home'));
      expect(defaults.defaultPaymentMethod?.displayName, contains('1234'));

      mockContainer.dispose();
    });

    testWidgets('Auto-fetch respects delivery method requirements', (tester) async {
      final mockContainer = ProviderContainer(
        overrides: [
          checkoutDefaultsProvider.overrideWith((ref) {
            return CheckoutDefaults(
              defaultAddress: CustomerAddress(
                id: 'test-address-1',
                label: 'Home',
                addressLine1: 'Jalan Test 123',
                city: 'Kuala Lumpur',
                state: 'Selangor',
                postalCode: '50000',
                isDefault: true,
              ),
              hasAddress: true,
              hasPaymentMethod: false,
            );
          }),
        ],
      );

      // Test with customer pickup (should not require address)
      final checkoutNotifier = mockContainer.read(checkoutFlowProvider.notifier);
      checkoutNotifier.setDeliveryMethod(CustomerDeliveryMethod.customerPickup);
      
      final checkoutState = mockContainer.read(checkoutFlowProvider);
      
      // For customer pickup, address should not be auto-populated
      expect(checkoutState.selectedDeliveryMethod, equals(CustomerDeliveryMethod.customerPickup));
      
      // Test with delivery (should require address)
      checkoutNotifier.setDeliveryMethod(CustomerDeliveryMethod.delivery);
      
      final updatedState = mockContainer.read(checkoutFlowProvider);
      expect(updatedState.selectedDeliveryMethod, equals(CustomerDeliveryMethod.delivery));

      mockContainer.dispose();
    });

    testWidgets('Fallback handling for missing defaults', (tester) async {
      final mockContainer = ProviderContainer(
        overrides: [
          checkoutDefaultsProvider.overrideWith((ref) {
            return const CheckoutDefaults(
              hasAddress: false,
              hasPaymentMethod: false,
              addressError: 'No default address found',
              paymentMethodError: 'No default payment method found',
            );
          }),
          customerHasAddressesProvider.overrideWith((ref) async => false),
          customerHasSavedPaymentMethodsProvider.overrideWith((ref) async => false),
        ],
      );

      // Test fallback analysis
      final fallbackNotifier = mockContainer.read(checkoutFallbackProvider.notifier);
      await fallbackNotifier.analyzeCheckoutState();
      
      final fallbackState = mockContainer.read(checkoutFallbackProvider);
      
      expect(fallbackState.hasBlockingIssues, isTrue);
      expect(fallbackState.activeGuidances.length, greaterThan(0));
      
      // Check for specific fallback scenarios
      final hasAddressGuidance = fallbackState.activeGuidances
          .any((g) => g.scenario == FallbackScenario.noSavedAddresses);
      final hasPaymentGuidance = fallbackState.activeGuidances
          .any((g) => g.scenario == FallbackScenario.noSavedPaymentMethods);
      
      expect(hasAddressGuidance, isTrue);
      expect(hasPaymentGuidance, isTrue);

      mockContainer.dispose();
    });

    testWidgets('Fallback recovery actions work correctly', (tester) async {
      final mockContainer = ProviderContainer(
        overrides: [
          checkoutDefaultsProvider.overrideWith((ref) {
            return const CheckoutDefaults(
              hasAddress: false,
              hasPaymentMethod: false,
            );
          }),
        ],
      );

      final fallbackNotifier = mockContainer.read(checkoutFallbackProvider.notifier);
      await fallbackNotifier.analyzeCheckoutState();
      
      // Test retry action
      final retryResult = await fallbackNotifier.executeFallbackAction(FallbackAction.retry);
      expect(retryResult, isTrue);
      
      // Test continue without defaults action
      final continueResult = await fallbackNotifier.executeFallbackAction(FallbackAction.continueWithoutDefaults);
      expect(continueResult, isTrue);
      
      final updatedState = mockContainer.read(checkoutFallbackProvider);
      expect(updatedState.hasBlockingIssues, isFalse);

      mockContainer.dispose();
    });

    testWidgets('Auto-population works with different payment method types', (tester) async {
      // Test with card payment method
      final cardPaymentMethod = CustomerPaymentMethod(
        id: 'test-card-1',
        userId: 'test-user-1',
        stripePaymentMethodId: 'pm_test_card',
        stripeCustomerId: 'cus_test_1234',
        type: CustomerPaymentMethodType.card,
        cardBrand: CardBrand.visa,
        cardLast4: '1234',
        cardExpMonth: 12,
        cardExpYear: 2025,
        isDefault: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockContainer = ProviderContainer(
        overrides: [
          checkoutDefaultsProvider.overrideWith((ref) {
            return CheckoutDefaults(
              defaultPaymentMethod: cardPaymentMethod,
              hasPaymentMethod: true,
              hasAddress: false,
            );
          }),
        ],
      );

      final defaults = mockContainer.read(checkoutDefaultsProvider);
      expect(defaults.defaultPaymentMethod?.type, equals(CustomerPaymentMethodType.card));

      mockContainer.dispose();

      // Test with digital wallet payment method
      final walletPaymentMethod = CustomerPaymentMethod(
        id: 'test-wallet-1',
        userId: 'test-user-1',
        stripePaymentMethodId: 'pm_test_wallet',
        stripeCustomerId: 'cus_test_1234',
        type: CustomerPaymentMethodType.digitalWallet,
        walletType: 'gigaeats_wallet',
        nickname: 'GigaEats Wallet',
        isDefault: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final walletContainer = ProviderContainer(
        overrides: [
          checkoutDefaultsProvider.overrideWith((ref) {
            return CheckoutDefaults(
              defaultPaymentMethod: walletPaymentMethod,
              hasPaymentMethod: true,
              hasAddress: false,
            );
          }),
        ],
      );

      final walletDefaults = walletContainer.read(checkoutDefaultsProvider);
      expect(walletDefaults.defaultPaymentMethod?.type, equals(CustomerPaymentMethodType.digitalWallet));

      walletContainer.dispose();
    });

    testWidgets('Checkout readiness assessment works correctly', (tester) async {
      final mockContainer = ProviderContainer(
        overrides: [
          customerHasAddressesProvider.overrideWith((ref) async => true),
          customerHasSavedPaymentMethodsProvider.overrideWith((ref) async => true),
        ],
      );

      final readiness = await mockContainer.read(checkoutReadinessProvider.future);
      
      expect(readiness.isReady, isTrue);
      expect(readiness.hasAddresses, isTrue);
      expect(readiness.hasPaymentMethods, isTrue);
      expect(readiness.missingRequirements, isEmpty);

      mockContainer.dispose();

      // Test with missing requirements
      final incompleteContainer = ProviderContainer(
        overrides: [
          customerHasAddressesProvider.overrideWith((ref) async => false),
          customerHasSavedPaymentMethodsProvider.overrideWith((ref) async => true),
        ],
      );

      final incompleteReadiness = await incompleteContainer.read(checkoutReadinessProvider.future);
      
      expect(incompleteReadiness.isReady, isFalse);
      expect(incompleteReadiness.hasAddresses, isFalse);
      expect(incompleteReadiness.hasPaymentMethods, isTrue);
      expect(incompleteReadiness.missingRequirements, contains('delivery address'));

      incompleteContainer.dispose();
    });

    testWidgets('Error handling works correctly', (tester) async {
      final mockContainer = ProviderContainer(
        overrides: [
          checkoutDefaultsProvider.overrideWith((ref) {
            throw Exception('Network error');
          }),
        ],
      );

      final defaults = mockContainer.read(checkoutDefaultsProvider);
      
      expect(defaults.hasErrors, isTrue);
      expect(defaults.addressError, contains('Failed to load address'));
      expect(defaults.paymentMethodError, contains('Failed to load payment method'));

      mockContainer.dispose();
    });
  });
}
