import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
// TODO: Restore unused import when Supabase functionality is implemented
// import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Restore when customer providers and widgets are implemented
// import '../../../../customers/presentation/providers/customer_cart_provider.dart';
// import '../../../../customers/presentation/providers/customer_profile_provider.dart';
// import '../../../../customers/presentation/providers/customer_order_provider.dart';
// import '../../../../customers/presentation/widgets/schedule_time_picker.dart';
import '../../../../orders/presentation/providers/customer/customer_cart_provider.dart';
import '../../../../orders/presentation/providers/customer/customer_order_provider.dart';
import '../../../../orders/presentation/providers/enhanced_cart_provider.dart';
import '../../../../orders/data/models/customer_delivery_method.dart';
import '../../../../user_management/presentation/providers/customer_address_provider.dart' as address_provider;
import '../../../../orders/presentation/providers/checkout_defaults_provider.dart';
import '../../../../orders/presentation/providers/checkout_fallback_provider.dart';
import '../../../../orders/presentation/widgets/checkout_fallback_widget.dart';
import '../../../../orders/presentation/widgets/enhanced_delivery_method_picker.dart';
import '../../../../marketplace_wallet/data/models/customer_payment_method.dart';
import '../../../../marketplace_wallet/presentation/providers/customer_payment_methods_provider.dart';
import '../../../../user_management/domain/customer_profile.dart';

import '../../../../../shared/widgets/custom_button.dart';

class CustomerCheckoutScreen extends ConsumerStatefulWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  ConsumerState<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends ConsumerState<CustomerCheckoutScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  bool _isAutoPopulating = false;
  bool _hasAutoPopulated = false;
  final TextEditingController _promoCodeController = TextEditingController();
  double _discount = 0.0;
  stripe.CardFieldInputDetails? _cardDetails;
  final TextEditingController _orderNotesController = TextEditingController();

  // Saved payment method state
  CustomerPaymentMethod? _savedPaymentMethod;
  bool _useSavedPaymentMethod = false;

  @override
  void initState() {
    super.initState();
    // Auto-populate defaults and analyze fallback scenarios when checkout screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckout();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to re-trigger auto-population after hot restart
    // and watch for checkout defaults changes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndRetriggerAutoPopulation();
      await _handleCheckoutDefaultsChange();
    });
  }

  /// Check if auto-population should be re-triggered (e.g., after hot restart)
  Future<void> _checkAndRetriggerAutoPopulation() async {
    final cartState = ref.read(customerCartProvider);

    // Ensure provider synchronization first
    await _ensureProviderSynchronization();

    // If delivery method requires address but no address is selected, re-trigger auto-population
    if (cartState.deliveryMethod.requiresDriver &&
        cartState.selectedAddress == null &&
        !_isAutoPopulating &&
        !cartState.isAutoPopulating) {

      debugPrint('🔄 [CHECKOUT-SCREEN] Re-triggering auto-population after state change');

      // Reset auto-population flags to allow re-population
      setState(() {
        _hasAutoPopulated = false;
      });
      ref.read(customerCartProvider.notifier).resetAutoPopulationState();

      // Trigger auto-population
      await _autoPopulateCheckoutDefaults();
    }
  }

  /// Ensure all providers are properly synchronized after hot restart
  Future<void> _ensureProviderSynchronization() async {
    try {
      debugPrint('🔄 [CHECKOUT-SCREEN] Ensuring provider synchronization');

      final cartState = ref.read(customerCartProvider);

      // Sync address to enhanced cart if present
      if (cartState.selectedAddress != null) {
        await _syncAddressToEnhancedCart(cartState.selectedAddress!);
      }

      // Sync payment method to enhanced cart if present
      if (cartState.selectedPaymentMethod != null) {
        await _syncPaymentMethodToEnhancedCart(cartState.selectedPaymentMethod!);
      }

      // Sync delivery method to enhanced cart
      try {
        await ref.read(enhancedCartProvider.notifier).setDeliveryMethod(cartState.deliveryMethod);
        debugPrint('🔄 [CHECKOUT-SCREEN] Synced delivery method to enhanced cart provider');
      } catch (e) {
        debugPrint('⚠️ [CHECKOUT-SCREEN] Failed to sync delivery method to enhanced cart: $e');
      }

      debugPrint('✅ [CHECKOUT-SCREEN] Provider synchronization completed');

    } catch (e) {
      debugPrint('❌ [CHECKOUT-SCREEN] Error during provider synchronization: $e');
    }
  }

  /// Initialize checkout with auto-population and fallback analysis
  Future<void> _initializeCheckout() async {
    debugPrint('🚀 [CHECKOUT-SCREEN] Starting checkout initialization');

    // Ensure provider synchronization first
    await _ensureProviderSynchronization();

    // Initialize payment method from cart state if available
    final cartState = ref.read(customerCartProvider);
    if (cartState.selectedPaymentMethod != null) {
      setState(() {
        _selectedPaymentMethod = cartState.selectedPaymentMethod!;
      });
    }

    // Complete auto-population before allowing validation to run
    await _autoPopulateCheckoutDefaults();

    // Validate provider state consistency
    await _validateProviderStateConsistency();

    // Add a small delay to ensure all state updates are processed
    await Future.delayed(const Duration(milliseconds: 100));

    // Analyze fallback scenarios after auto-population
    ref.read(checkoutFallbackProvider.notifier).analyzeCheckoutState();

    debugPrint('✅ [CHECKOUT-SCREEN] Checkout initialization completed');
  }

  /// Validate that all providers have consistent state
  Future<void> _validateProviderStateConsistency() async {
    try {
      debugPrint('🔍 [CHECKOUT-SCREEN] Validating provider state consistency');

      final cartState = ref.read(customerCartProvider);

      // Check if enhanced cart provider exists and is accessible
      try {
        final enhancedCartState = ref.read(enhancedCartProvider);

        // Log state comparison for debugging
        debugPrint('🔍 [CHECKOUT-SCREEN] Cart address: ${cartState.selectedAddress?.label ?? 'None'}');
        debugPrint('🔍 [CHECKOUT-SCREEN] Enhanced cart address: ${enhancedCartState.selectedAddress?.label ?? 'None'}');
        debugPrint('🔍 [CHECKOUT-SCREEN] Cart delivery method: ${cartState.deliveryMethod.value}');
        debugPrint('🔍 [CHECKOUT-SCREEN] Enhanced cart delivery method: ${enhancedCartState.deliveryMethod.value}');

      } catch (e) {
        debugPrint('⚠️ [CHECKOUT-SCREEN] Enhanced cart provider not accessible: $e');
      }

      debugPrint('✅ [CHECKOUT-SCREEN] Provider state validation completed');

    } catch (e) {
      debugPrint('❌ [CHECKOUT-SCREEN] Error during provider state validation: $e');
    }
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  /// Sync address to enhanced cart provider with resilient error handling
  Future<void> _syncAddressToEnhancedCart(CustomerAddress address) async {
    try {
      ref.read(enhancedCartProvider.notifier).setDeliveryAddress(address);
      debugPrint('🔄 [CHECKOUT-SCREEN] Synced address to enhanced cart provider');
    } catch (e) {
      // Handle SharedPreferences initialization errors gracefully
      if (e.toString().contains('SharedPreferences must be initialized') ||
          e.toString().contains('UnimplementedError')) {
        debugPrint('⚠️ [CHECKOUT-SCREEN] Enhanced cart address sync skipped - SharedPreferences not initialized');
      } else {
        debugPrint('⚠️ [CHECKOUT-SCREEN] Could not sync address to enhanced cart: $e');
      }
    }
  }

  /// Sync payment method to enhanced cart provider with resilient error handling
  Future<void> _syncPaymentMethodToEnhancedCart(String paymentMethod) async {
    try {
      ref.read(enhancedCartProvider.notifier).setPaymentMethod(paymentMethod);
      debugPrint('🔄 [CHECKOUT-SCREEN] Synced payment method to enhanced cart provider');
    } catch (e) {
      // Handle SharedPreferences initialization errors gracefully
      if (e.toString().contains('SharedPreferences must be initialized') ||
          e.toString().contains('UnimplementedError')) {
        debugPrint('⚠️ [CHECKOUT-SCREEN] Enhanced cart payment sync skipped - SharedPreferences not initialized');
      } else {
        debugPrint('⚠️ [CHECKOUT-SCREEN] Could not sync payment method to enhanced cart: $e');
      }
    }
  }

  /// Auto-populate checkout defaults (address and payment method)
  Future<void> _autoPopulateCheckoutDefaults() async {
    final cartState = ref.read(customerCartProvider);

    // Check if auto-population should be skipped
    if (_isAutoPopulating || cartState.isAutoPopulating) {
      debugPrint('🔄 [CHECKOUT-SCREEN] Auto-population already in progress');
      return; // Prevent multiple auto-population attempts
    }

    // Allow re-population if address is missing even if previously auto-populated
    final shouldAutoPopulate = !_hasAutoPopulated ||
        !cartState.hasAutoPopulated ||
        (cartState.deliveryMethod.requiresDriver && cartState.selectedAddress == null);

    if (!shouldAutoPopulate) {
      debugPrint('🔄 [CHECKOUT-SCREEN] Auto-population not needed - already completed and address present');
      return;
    }

    debugPrint('🚀 [CHECKOUT-SCREEN] Starting auto-population of checkout defaults');
    setState(() {
      _isAutoPopulating = true;
    });

    // Set auto-populating state in cart provider
    ref.read(customerCartProvider.notifier).setAutoPopulatingState(true);

    try {
      debugPrint('🛒 [CHECKOUT-SCREEN] Current cart state - Address: ${cartState.selectedAddress?.label ?? 'None'}, Payment: ${cartState.selectedPaymentMethod ?? 'None'}');
      debugPrint('🚚 [CHECKOUT-SCREEN] Current delivery method: ${cartState.deliveryMethod.value} (requires driver: ${cartState.deliveryMethod.requiresDriver})');

      // Fetch checkout defaults (now synchronous)
      final defaults = ref.read(checkoutDefaultsProvider);
      debugPrint('📦 [CHECKOUT-SCREEN] Fetched defaults - Address: ${defaults.hasAddress}, Payment: ${defaults.hasPaymentMethod}');

      // Auto-populate default address if available and delivery method requires it
      if (defaults.hasAddress &&
          defaults.defaultAddress != null &&
          cartState.selectedAddress == null &&
          cartState.deliveryMethod.requiresDriver) {

        debugPrint('🏠 [CHECKOUT-SCREEN] Auto-populating address: ${defaults.defaultAddress!.label}');

        // Update primary cart provider first
        ref.read(customerCartProvider.notifier).setDeliveryAddress(defaults.defaultAddress!);

        // Sync to enhanced cart provider with resilient error handling
        await _syncAddressToEnhancedCart(defaults.defaultAddress!);

        debugPrint('✅ [CHECKOUT-SCREEN] Auto-populated address: ${defaults.defaultAddress!.label}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using default address: ${defaults.defaultAddress!.label}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Change',
                textColor: Colors.white,
                onPressed: () => _changeDeliveryAddress(),
              ),
            ),
          );
        }
      }

      // Auto-populate default payment method if available
      debugPrint('🔍 [CHECKOUT-SCREEN] Checking payment method auto-population - hasPaymentMethod: ${defaults.hasPaymentMethod}, defaultPaymentMethod: ${defaults.defaultPaymentMethod?.displayName ?? 'null'}');

      // First, check the async state of payment methods for debugging
      final paymentMethodsAsync = ref.read(customerPaymentMethodsProvider);
      debugPrint('🔍 [CHECKOUT-SCREEN] Payment methods async state: ${paymentMethodsAsync.runtimeType}');

      paymentMethodsAsync.when(
        data: (methods) => debugPrint('📊 [CHECKOUT-SCREEN] Payment methods data available: ${methods.length} methods'),
        loading: () => debugPrint('🔄 [CHECKOUT-SCREEN] Payment methods still loading'),
        error: (error, stack) => debugPrint('❌ [CHECKOUT-SCREEN] Payment methods error: $error'),
      );

      if (defaults.hasPaymentMethod && defaults.defaultPaymentMethod != null) {
        // Check if payment method is already set to avoid overriding user selection
        if (_selectedPaymentMethod != 'card' || _savedPaymentMethod == null) {
          String paymentMethodValue;
          switch (defaults.defaultPaymentMethod!.type) {
            case CustomerPaymentMethodType.card:
              paymentMethodValue = 'card';
              break;
            case CustomerPaymentMethodType.digitalWallet:
              paymentMethodValue = 'wallet';
              break;
            case CustomerPaymentMethodType.bankAccount:
              paymentMethodValue = 'fpx';
              break;
          }

          debugPrint('💳 [CHECKOUT-SCREEN] Auto-populating payment method: ${defaults.defaultPaymentMethod!.displayName} -> $paymentMethodValue');

          setState(() {
            _selectedPaymentMethod = paymentMethodValue;
            _savedPaymentMethod = defaults.defaultPaymentMethod;
            _useSavedPaymentMethod = true; // Auto-select saved payment method
          });

          // Sync payment method to cart provider
          ref.read(customerCartProvider.notifier).setPaymentMethod(paymentMethodValue);

          // Sync to enhanced cart provider with resilient error handling
          await _syncPaymentMethodToEnhancedCart(paymentMethodValue);

          debugPrint('✅ [CHECKOUT-SCREEN] Auto-populated payment method: ${defaults.defaultPaymentMethod!.displayName} ($paymentMethodValue)');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Using default payment: ${defaults.defaultPaymentMethod!.displayName}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Change',
                  textColor: Colors.white,
                  onPressed: () => _showPaymentMethodSelection(),
                ),
              ),
            );
          }
        } else {
          debugPrint('ℹ️ [CHECKOUT-SCREEN] Payment method already set, skipping auto-population');
        }
      } else {
        debugPrint('⚠️ [CHECKOUT-SCREEN] No default payment method available for auto-population');
        debugPrint('🔍 [CHECKOUT-SCREEN] hasPaymentMethod: ${defaults.hasPaymentMethod}, defaultPaymentMethod: ${defaults.defaultPaymentMethod}');

        if (defaults.paymentMethodError != null) {
          debugPrint('❌ [CHECKOUT-SCREEN] Payment method error: ${defaults.paymentMethodError}');
        }

        // If payment methods are still loading, note this for debugging
        // The new _handleCheckoutDefaultsChange method will handle auto-population when they load
        if (paymentMethodsAsync.isLoading) {
          debugPrint('🔄 [CHECKOUT-SCREEN] Payment methods still loading, _handleCheckoutDefaultsChange will handle auto-population when they finish loading');
        }
      }

      // Load addresses if not already loaded (for fallback)
      final addressesState = ref.read(address_provider.customerAddressesProvider);
      if (addressesState.addresses.isEmpty && !addressesState.isLoading) {
        ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();
      }

      setState(() {
        _hasAutoPopulated = true;
      });

      debugPrint('🎉 [CHECKOUT-SCREEN] Auto-population completed successfully');

    } catch (e) {
      debugPrint('❌ [CHECKOUT-SCREEN] Error auto-populating defaults: $e');
      // Continue with manual selection if auto-population fails
    } finally {
      setState(() {
        _isAutoPopulating = false;
      });

      // Mark auto-population as completed in cart provider
      ref.read(customerCartProvider.notifier).markAutoPopulationCompleted();

      // Force a rebuild to ensure UI reflects the updated state
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Handle checkout defaults changes from build method (reactive to provider changes)
  void _handleCheckoutDefaultsChangeFromBuild(CheckoutDefaults checkoutDefaults) {
    try {
      debugPrint('🔍 [CHECKOUT-SCREEN-REACTIVE] Checking checkout defaults for changes from build');
      debugPrint('🔍 [CHECKOUT-SCREEN-REACTIVE] Current defaults: hasPaymentMethod=${checkoutDefaults.hasPaymentMethod}, defaultPaymentMethod=${checkoutDefaults.defaultPaymentMethod?.displayName ?? 'null'}');
      debugPrint('🔍 [CHECKOUT-SCREEN-REACTIVE] Current state: _savedPaymentMethod=${_savedPaymentMethod?.displayName ?? 'null'}, _useSavedPaymentMethod=$_useSavedPaymentMethod, _selectedPaymentMethod=$_selectedPaymentMethod');

      // Check if payment methods just became available and we haven't auto-populated yet
      if (checkoutDefaults.hasPaymentMethod &&
          checkoutDefaults.defaultPaymentMethod != null &&
          _savedPaymentMethod == null &&
          !_useSavedPaymentMethod) {

        debugPrint('🔄 [CHECKOUT-SCREEN-REACTIVE] Payment methods now available, triggering auto-population');
        debugPrint('🔄 [CHECKOUT-SCREEN-REACTIVE] Auto-populating with payment method: ${checkoutDefaults.defaultPaymentMethod!.displayName}');

        // Auto-populate the saved payment method
        setState(() {
          _savedPaymentMethod = checkoutDefaults.defaultPaymentMethod;
          _useSavedPaymentMethod = true;
          _selectedPaymentMethod = 'card'; // Ensure card is selected
        });

        debugPrint('🔄 [CHECKOUT-SCREEN-REACTIVE] State updated - _savedPaymentMethod=${_savedPaymentMethod?.displayName}, _useSavedPaymentMethod=$_useSavedPaymentMethod, _selectedPaymentMethod=$_selectedPaymentMethod');

        // Update cart provider
        ref.read(customerCartProvider.notifier).setPaymentMethod('card');
        debugPrint('🔄 [CHECKOUT-SCREEN-REACTIVE] Updated cart provider with payment method: card');

        // Sync to enhanced cart provider
        _syncPaymentMethodToEnhancedCart('card');

        debugPrint('✅ [CHECKOUT-SCREEN-REACTIVE] Auto-populated payment method: ${checkoutDefaults.defaultPaymentMethod!.displayName}');

        // Show success message
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Using default payment: ${checkoutDefaults.defaultPaymentMethod!.displayName}'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } else {
        debugPrint('🔍 [CHECKOUT-SCREEN-REACTIVE] No auto-population needed - conditions not met');
        if (!checkoutDefaults.hasPaymentMethod) {
          debugPrint('  - No payment method available');
        }
        if (checkoutDefaults.defaultPaymentMethod == null) {
          debugPrint('  - Default payment method is null');
        }
        if (_savedPaymentMethod != null) {
          debugPrint('  - Saved payment method already set: ${_savedPaymentMethod!.displayName}');
        }
        if (_useSavedPaymentMethod) {
          debugPrint('  - Already using saved payment method');
        }
      }
    } catch (e) {
      debugPrint('❌ [CHECKOUT-SCREEN-REACTIVE] Error handling checkout defaults change: $e');
    }
  }

  /// Handle checkout defaults changes and re-trigger auto-population if needed
  Future<void> _handleCheckoutDefaultsChange() async {
    try {
      debugPrint('🔍 [CHECKOUT-SCREEN] Checking checkout defaults for changes');

      final defaults = ref.read(checkoutDefaultsProvider);
      debugPrint('🔍 [CHECKOUT-SCREEN] Current defaults: hasPaymentMethod=${defaults.hasPaymentMethod}, defaultPaymentMethod=${defaults.defaultPaymentMethod?.displayName ?? 'null'}');
      debugPrint('🔍 [CHECKOUT-SCREEN] Current state: _savedPaymentMethod=${_savedPaymentMethod?.displayName ?? 'null'}, _useSavedPaymentMethod=$_useSavedPaymentMethod, _selectedPaymentMethod=$_selectedPaymentMethod');

      // Check if payment methods just became available and we haven't auto-populated yet
      if (defaults.hasPaymentMethod &&
          defaults.defaultPaymentMethod != null &&
          _savedPaymentMethod == null &&
          !_useSavedPaymentMethod) {

        debugPrint('🔄 [CHECKOUT-SCREEN] Payment methods now available, triggering auto-population');
        debugPrint('🔄 [CHECKOUT-SCREEN] Auto-populating with payment method: ${defaults.defaultPaymentMethod!.displayName}');

        // Auto-populate the saved payment method
        setState(() {
          _savedPaymentMethod = defaults.defaultPaymentMethod;
          _useSavedPaymentMethod = true;
          _selectedPaymentMethod = 'card'; // Ensure card is selected
        });

        debugPrint('🔄 [CHECKOUT-SCREEN] State updated - _savedPaymentMethod=${_savedPaymentMethod?.displayName}, _useSavedPaymentMethod=$_useSavedPaymentMethod, _selectedPaymentMethod=$_selectedPaymentMethod');

        // Update cart provider
        ref.read(customerCartProvider.notifier).setPaymentMethod('card');
        debugPrint('🔄 [CHECKOUT-SCREEN] Updated cart provider with payment method: card');

        // Sync to enhanced cart provider
        await _syncPaymentMethodToEnhancedCart('card');

        debugPrint('✅ [CHECKOUT-SCREEN] Auto-populated payment method: ${defaults.defaultPaymentMethod!.displayName}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using default payment: ${defaults.defaultPaymentMethod!.displayName}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('🔍 [CHECKOUT-SCREEN] No auto-population needed - conditions not met');
        if (!defaults.hasPaymentMethod) {
          debugPrint('  - No payment method available');
        }
        if (defaults.defaultPaymentMethod == null) {
          debugPrint('  - Default payment method is null');
        }
        if (_savedPaymentMethod != null) {
          debugPrint('  - Saved payment method already set: ${_savedPaymentMethod!.displayName}');
        }
        if (_useSavedPaymentMethod) {
          debugPrint('  - Already using saved payment method');
        }
      }
    } catch (e) {
      debugPrint('❌ [CHECKOUT-SCREEN] Error handling checkout defaults change: $e');
    }
  }

  /// Manually trigger auto-population (for refresh button)
  Future<void> _refreshDefaults() async {
    setState(() {
      _hasAutoPopulated = false;
      _savedPaymentMethod = null;
      _useSavedPaymentMethod = false;
    });
    // Reset auto-population state in cart provider
    ref.read(customerCartProvider.notifier).resetAutoPopulationState();
    await _autoPopulateCheckoutDefaults();
  }

  /// Handle delivery method changes and auto-populate address if needed
  Future<void> _handleDeliveryMethodChange(CustomerDeliveryMethod newMethod) async {
    debugPrint('🚚 [CHECKOUT-SCREEN] Delivery method changed to: ${newMethod.value}');

    final previousMethod = ref.read(customerCartProvider).deliveryMethod;

    // Update cart provider
    ref.read(customerCartProvider.notifier).setDeliveryMethod(newMethod);

    // Handle address logic based on delivery method requirements
    if (newMethod.requiresDriver) {
      // New method requires address - auto-populate if needed
      final cartState = ref.read(customerCartProvider);
      if (cartState.selectedAddress == null) {
        debugPrint('🔄 [CHECKOUT-SCREEN] Auto-populating address for delivery method change');

        try {
          final defaults = ref.read(checkoutDefaultsProvider);
          if (defaults.hasAddress && defaults.defaultAddress != null) {
            ref.read(customerCartProvider.notifier).setDeliveryAddress(defaults.defaultAddress!);
            await _syncAddressToEnhancedCart(defaults.defaultAddress!);
            debugPrint('✅ [CHECKOUT-SCREEN] Auto-populated address for delivery method change');
          } else {
            debugPrint('⚠️ [CHECKOUT-SCREEN] No default address available for auto-population');
          }
        } catch (e) {
          debugPrint('❌ [CHECKOUT-SCREEN] Error auto-populating address for delivery method change: $e');
        }
      }
    } else if (previousMethod.requiresDriver && !newMethod.requiresDriver) {
      // Switched from address-required to address-not-required - clear address
      debugPrint('🔄 [CHECKOUT-SCREEN] Clearing address for pickup method');
      ref.read(customerCartProvider.notifier).clearDeliveryAddress();
    }
  }

  /// Show delivery method selection dialog/screen
  Future<void> _showDeliveryMethodSelection() async {
    final cartState = ref.read(customerCartProvider);

    // Get primary vendor ID from cart items
    final vendorId = cartState.items.isNotEmpty ? cartState.items.first.vendorId : '';

    // Show delivery method picker in a bottom sheet
    final selectedMethod = await showModalBottomSheet<CustomerDeliveryMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveryMethodSelectionBottomSheet(
        currentMethod: cartState.deliveryMethod,
        vendorId: vendorId,
        subtotal: cartState.subtotal,
        deliveryAddress: cartState.selectedAddress,
      ),
    );

    if (selectedMethod != null && selectedMethod != cartState.deliveryMethod) {
      // Handle delivery method change
      await _handleDeliveryMethodChange(selectedMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(customerCartProvider);
    final theme = Theme.of(context);

    // Watch checkout defaults and trigger auto-population when they change
    final checkoutDefaults = ref.watch(checkoutDefaultsProvider);

    // Add debugging for checkout defaults changes
    debugPrint('🔍 [CHECKOUT-SCREEN-BUILD] Building with checkout defaults: hasPaymentMethod=${checkoutDefaults.hasPaymentMethod}, defaultPaymentMethod=${checkoutDefaults.defaultPaymentMethod?.displayName ?? 'null'}');
    debugPrint('🔍 [CHECKOUT-SCREEN-BUILD] Current UI state: _savedPaymentMethod=${_savedPaymentMethod?.displayName ?? 'null'}, _useSavedPaymentMethod=$_useSavedPaymentMethod');

    // Trigger auto-population when checkout defaults change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCheckoutDefaultsChangeFromBuild(checkoutDefaults);
    });

    if (cartState.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Your cart is empty'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fallback guidance (if any issues)
                  const CheckoutFallbackWidget(showOnlyBlocking: false),

                  _buildDeliverySection(cartState, theme),
                  const SizedBox(height: 24),
                  _buildOrderSummary(cartState, theme),
                  const SizedBox(height: 24),
                  _buildPromoCodeSection(theme),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSection(theme),
                  const SizedBox(height: 24),
                  _buildOrderNotes(theme),
                ],
              ),
            ),
          ),
          _buildCheckoutBottomBar(cartState, theme),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(CustomerCartState cartState, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Delivery Details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isAutoPopulating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _refreshDefaults,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh defaults',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Delivery method
            Row(
              children: [
                Icon(Icons.delivery_dining, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartState.deliveryMethod.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        cartState.deliveryMethod.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showDeliveryMethodSelection(),
                  child: const Text('Change'),
                ),
              ],
            ),
            
            // Delivery address (if delivery method requires driver)
            if (cartState.deliveryMethod.requiresDriver) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Address',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          cartState.selectedAddress?.fullAddress ?? 'No address selected',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _changeDeliveryAddress(),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
            
            // Scheduled delivery time (if applicable)
            // TODO: Restore when CustomerDeliveryMethod is implemented
            // if (cartState.deliveryMethod == CustomerDeliveryMethod.scheduled) ...[
            // TODO: Restore when CustomerDeliveryMethod is implemented
            // if (false) ...[  // Placeholder - assume no scheduled delivery
            //   const SizedBox(height: 12),
            //   const Divider(),
            //   const SizedBox(height: 12),
            //   Row(
            //     children: [
            //       Icon(Icons.schedule, color: theme.colorScheme.primary),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Scheduled Time',
            //               style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            //             ),
            //             Text(
            //               cartState.scheduledDeliveryTime != null
            //                   ? _formatScheduledTime(cartState.scheduledDeliveryTime!)
            //                   : 'Not set',
            //               style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            //             ),
            //           ],
            //         ),
            //       ),
            //       TextButton(
            //         onPressed: () => _showScheduleTimePicker(),
            //         child: const Text('Change'),
            //       ),
            //     ],
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  // TODO: Restore when CustomerCartState is implemented
  Widget _buildOrderSummary(dynamic cartState, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Order items
            ...cartState.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${item.quantity}x'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    'RM ${item.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Price breakdown
            _buildPriceRow('Subtotal', cartState.subtotal, theme),
            _buildPriceRow('SST (6%)', cartState.sstAmount, theme),
            _buildPriceRow('Delivery Fee', cartState.deliveryFee, theme),
            if (_discount > 0)
              _buildPriceRow('Discount', -_discount, theme, isDiscount: true),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            _buildPriceRow(
              'Total',
              cartState.totalAmount - _discount,
              theme,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, ThemeData theme, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}RM ${amount.abs().toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal 
                  ? theme.colorScheme.primary 
                  : isDiscount 
                      ? Colors.green 
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promo Code',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    decoration: const InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Apply',
                  onPressed: _applyPromoCode,
                  type: ButtonType.secondary,
                  isExpanded: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isAutoPopulating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Show default payment method info if auto-populated
            Consumer(
              builder: (context, ref, child) {
                final defaults = ref.watch(checkoutDefaultsProvider);
                // Handle synchronous provider directly
                {
                    if (defaults.hasPaymentMethod && defaults.defaultPaymentMethod != null) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Default: ${defaults.defaultPaymentMethod!.displayName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                }
              },
            ),

            RadioListTile<String>(
              title: const Text('Credit/Debit Card'),
              subtitle: const Text('Pay securely with your card'),
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) async {
                setState(() => _selectedPaymentMethod = value!);
                ref.read(customerCartProvider.notifier).setPaymentMethod(value!);
                // Sync to enhanced cart provider with resilient error handling
                await _syncPaymentMethodToEnhancedCart(value!);
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Show card payment options when card is selected
            if (_selectedPaymentMethod == 'card') ...[
              const SizedBox(height: 12),
              _buildCardPaymentSection(theme),
            ],

            const SizedBox(height: 8),

            RadioListTile<String>(
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when your order arrives'),
              value: 'cash',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) async {
                setState(() => _selectedPaymentMethod = value!);
                ref.read(customerCartProvider.notifier).setPaymentMethod(value!);
                // Sync to enhanced cart provider with resilient error handling
                await _syncPaymentMethodToEnhancedCart(value!);
              },
              contentPadding: EdgeInsets.zero,
            ),

            RadioListTile<String>(
              title: const Text('Digital Wallet'),
              subtitle: const Text('GigaEats Wallet'),
              value: 'wallet',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) async {
                setState(() => _selectedPaymentMethod = value!);
                ref.read(customerCartProvider.notifier).setPaymentMethod(value!);
                // Sync to enhanced cart provider with resilient error handling
                await _syncPaymentMethodToEnhancedCart(value!);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNotes(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Notes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderNotesController,
              decoration: const InputDecoration(
                hintText: 'Any special instructions for your order?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                // TODO: Restore when customerCartProvider is implemented
                // ref.read(customerCartProvider.notifier).setSpecialInstructions(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Restore when CustomerCartState is implemented
  Widget _buildCheckoutBottomBar(dynamic cartState, ThemeData theme) {
    // TODO: Restore when orderCreationProvider is implemented
    // final orderState = ref.watch(orderCreationProvider);
    final orderState = null;
    final isLoading = _isProcessing || (orderState?.isLoading ?? false);
    final canCheckout = cartState.canCheckout && !isLoading;
    final totalAmount = cartState.totalAmount - _discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: isLoading
              ? 'Processing...'
              : 'Place Order - RM ${totalAmount.toStringAsFixed(2)}',
          onPressed: canCheckout ? _placeOrder : null,
          type: ButtonType.primary,
          isLoading: isLoading,
        ),
      ),
    );
  }

  // TODO: Restore unused method _showScheduleTimePicker when ScheduleTimePicker is implemented
  // void _showScheduleTimePicker() {
  //   showDialog(
  //     context: context,
  //     // TODO: Restore when ScheduleTimePicker is implemented
  //     // builder: (context) => ScheduleTimePicker(
  //     builder: (context) => AlertDialog( // Placeholder dialog
  //       title: const Text('Schedule Delivery'),
  //       content: const Text('Schedule delivery feature coming soon!'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    // TODO: Implement actual promo code validation
    // For now, just simulate a discount
    if (code.toLowerCase() == 'welcome10') {
      setState(() {
        // TODO: Restore when customerCartProvider is implemented
        // _discount = ref.read(customerCartProvider).subtotal * 0.1; // 10% discount
        _discount = 10.0; // Placeholder discount
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied! 10% discount'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show payment method selection dialog
  Future<void> _showPaymentMethodSelection() async {
    try {
      debugPrint('💳 [CHECKOUT-SCREEN] Showing payment method selection');

      // Get valid payment methods
      final paymentMethods = await ref.read(customerValidPaymentMethodsProvider.future);

      if (paymentMethods.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved payment methods found. Add a payment method first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final selectedMethod = await showDialog<CustomerPaymentMethod>(
        context: context,
        builder: (context) => _PaymentMethodSelectionDialog(
          paymentMethods: paymentMethods,
          currentSelection: _savedPaymentMethod,
        ),
      );

      if (selectedMethod != null) {
        // Map the selected payment method to the appropriate payment method value
        String paymentMethodValue;
        switch (selectedMethod.type) {
          case CustomerPaymentMethodType.card:
            paymentMethodValue = 'card';
            break;
          case CustomerPaymentMethodType.digitalWallet:
            paymentMethodValue = 'wallet';
            break;
          case CustomerPaymentMethodType.bankAccount:
            paymentMethodValue = 'fpx';
            break;
        }

        setState(() {
          _selectedPaymentMethod = paymentMethodValue;
          _savedPaymentMethod = selectedMethod;
          _useSavedPaymentMethod = true;
        });

        // Sync to providers
        ref.read(customerCartProvider.notifier).setPaymentMethod(paymentMethodValue);
        await _syncPaymentMethodToEnhancedCart(paymentMethodValue);

        debugPrint('✅ [CHECKOUT-SCREEN] Selected payment method: ${selectedMethod.displayName}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment method changed to: ${selectedMethod.displayName}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }

    } catch (e, stack) {
      debugPrint('❌ [CHECKOUT-SCREEN] Error showing payment method selection: $e');
      debugPrint('Stack trace: $stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load payment methods'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);

    try {
      // Validate payment method
      if (_selectedPaymentMethod == 'card') {
        if (_useSavedPaymentMethod && _savedPaymentMethod != null) {
          // Using saved payment method - validation passed
          debugPrint('✅ [CHECKOUT] Using saved payment method: ${_savedPaymentMethod!.stripePaymentMethodId}');
        } else if (!_useSavedPaymentMethod) {
          // Using new card - validate card details
          if (_cardDetails == null || !_cardDetails!.complete) {
            throw Exception('Please enter complete card details');
          }
          debugPrint('✅ [CHECKOUT] Using new card details');
        } else {
          throw Exception('No payment method available');
        }
      }

      // Create order and process payment
      final orderCreationNotifier = ref.read(orderCreationProvider.notifier);
      final success = await orderCreationNotifier.createOrderAndProcessPayment(
        paymentMethod: _selectedPaymentMethod == 'card' ? 'credit_card' : _selectedPaymentMethod,
        specialInstructions: _orderNotesController.text.trim().isNotEmpty
            ? _orderNotesController.text.trim()
            : null,
      );

      if (!success) {
        final error = ref.read(orderCreationProvider).error;
        throw Exception(error ?? 'Order creation failed');
      }

      // Order creation successful - handle post-order workflow
      if (success && mounted) {
        // Get the created order from state
        final createdOrder = ref.read(orderCreationProvider).order;
        final orderNumber = createdOrder?.orderNumber ?? 'Unknown';

        // Show success toast with order number
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! Order #$orderNumber'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Orders',
              textColor: Colors.white,
              onPressed: () => context.go('/customer/orders'),
            ),
          ),
        );

        // Invalidate customer orders provider to refresh the list
        ref.invalidate(currentCustomerOrdersProvider);

        // Add a brief delay to show the success message, then navigate
        await Future.delayed(const Duration(milliseconds: 1500));

        // Navigate to customer orders screen
        if (mounted) {
          context.go('/customer/orders');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // TODO: Restore unused method _processStripePayment when Stripe integration is implemented
  // Future<void> _processStripePayment(String clientSecret) async {
  //   try {
  //     // Get the current authenticated user's email from Supabase auth
  //     final currentUser = Supabase.instance.client.auth.currentUser;
  //     final userEmail = currentUser?.email;

  //     final paymentMethod = stripe.PaymentMethodParams.card(
  //       paymentMethodData: stripe.PaymentMethodData(
  //         billingDetails: stripe.BillingDetails(
  //           email: userEmail, // Use actual email from auth user
  //         ),
  //       ),
  //     );

  //     final result = await stripe.Stripe.instance.confirmPayment(
  //       paymentIntentClientSecret: clientSecret,
  //       data: paymentMethod,
  //     );

  //     if (result.status == stripe.PaymentIntentsStatus.Succeeded) {
  //       // Payment successful - webhook will handle order status update
  //       return;
  //     } else if (result.status == stripe.PaymentIntentsStatus.Canceled) {
  //       throw Exception('Payment was cancelled');
  //     } else {
  //       throw Exception('Payment failed: ${result.status}');
  //     }
  //   } catch (e) {
  //     if (e is stripe.StripeException) {
  //       throw Exception('Payment failed: ${e.error.localizedMessage ?? e.error.message}');
  //     } else {
  //       rethrow;
  //     }
  //   }
  // }

  // TODO: Restore unused method _formatScheduledTime when schedule delivery is implemented
  // String _formatScheduledTime(DateTime dateTime) {
  //   final now = DateTime.now();
  //   final today = DateTime(now.year, now.month, now.day);
  //   final tomorrow = today.add(const Duration(days: 1));
  //   final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

  //   final timeString = TimeOfDay.fromDateTime(dateTime).format(context);

  //   if (scheduledDay == today) {
  //     return 'Today, $timeString';
  //   } else if (scheduledDay == tomorrow) {
  //     return 'Tomorrow, $timeString';
  //   } else {
  //     final months = [
  //       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  //       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  //     ];
  //     final dateString = '${dateTime.day} ${months[dateTime.month - 1]}';
  //     return '$dateString, $timeString';
  //   }
  // }

  Future<void> _changeDeliveryAddress() async {
    final selectedAddressId = await context.push<String>('/customer/addresses/select');

    if (selectedAddressId != null) {
      // Get the selected address from the address provider
      final addressesState = ref.read(address_provider.customerAddressesProvider);
      final selectedAddress = addressesState.addresses
          .where((addr) => addr.id == selectedAddressId)
          .firstOrNull;

      if (selectedAddress != null) {
        // Use the selected address directly (already unified type)
        ref.read(customerCartProvider.notifier).setDeliveryAddress(selectedAddress);

        // Sync to enhanced cart provider with resilient error handling
        await _syncAddressToEnhancedCart(selectedAddress);

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delivery address updated to ${selectedAddress.label}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    }
  }

  /// Build card payment section with saved payment method support
  Widget _buildCardPaymentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show saved payment method if available
        if (_savedPaymentMethod != null) ...[
          _buildSavedPaymentMethodCard(theme),
          const SizedBox(height: 12),

          // Option to use saved payment method or enter new card
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _useSavedPaymentMethod = true;
                      _cardDetails = null; // Clear new card details
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _useSavedPaymentMethod
                        ? theme.colorScheme.primaryContainer
                        : null,
                    foregroundColor: _useSavedPaymentMethod
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.primary,
                  ),
                  child: const Text('Use Saved Card'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _useSavedPaymentMethod = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !_useSavedPaymentMethod
                        ? theme.colorScheme.primaryContainer
                        : null,
                    foregroundColor: !_useSavedPaymentMethod
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.primary,
                  ),
                  child: const Text('New Card'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Show card input field when using new card or no saved card available
        if (!_useSavedPaymentMethod || _savedPaymentMethod == null) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: stripe.CardField(
              onCardChanged: (details) {
                setState(() {
                  _cardDetails = details;
                });
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Card number',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              enablePostalCode: false, // Disable postal code for Malaysian cards
            ),
          ),
        ],
      ],
    );
  }

  /// Build saved payment method card display
  Widget _buildSavedPaymentMethodCard(ThemeData theme) {
    if (_savedPaymentMethod == null) return const SizedBox.shrink();

    final paymentMethod = _savedPaymentMethod!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _useSavedPaymentMethod
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: _useSavedPaymentMethod ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Card icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCardIcon(paymentMethod.cardBrand),
              size: 24,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),

          // Card details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentMethod.nickname ?? 'Saved Card',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '**** **** **** ${paymentMethod.cardLast4 ?? '****'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (paymentMethod.cardExpMonth != null && paymentMethod.cardExpYear != null)
                  Text(
                    'Expires ${paymentMethod.cardExpMonth!.toString().padLeft(2, '0')}/${paymentMethod.cardExpYear! % 100}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Selection indicator
          if (_useSavedPaymentMethod)
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 24,
            ),
        ],
      ),
    );
  }

  /// Get card icon based on card brand
  IconData _getCardIcon(CardBrand? brand) {
    switch (brand) {
      case CardBrand.visa:
        return Icons.credit_card;
      case CardBrand.mastercard:
        return Icons.credit_card;
      case CardBrand.amex:
        return Icons.credit_card;
      case CardBrand.discover:
        return Icons.credit_card;
      case CardBrand.jcb:
        return Icons.credit_card;
      case CardBrand.diners:
        return Icons.credit_card;
      case CardBrand.unionpay:
        return Icons.credit_card;
      case CardBrand.unknown:
      case null:
        return Icons.credit_card;
    }
  }
}

/// Bottom sheet for selecting delivery method
class _DeliveryMethodSelectionBottomSheet extends ConsumerStatefulWidget {
  final CustomerDeliveryMethod currentMethod;
  final String vendorId;
  final double subtotal;
  final CustomerAddress? deliveryAddress;

  const _DeliveryMethodSelectionBottomSheet({
    required this.currentMethod,
    required this.vendorId,
    required this.subtotal,
    this.deliveryAddress,
  });

  @override
  ConsumerState<_DeliveryMethodSelectionBottomSheet> createState() =>
      _DeliveryMethodSelectionBottomSheetState();
}

class _DeliveryMethodSelectionBottomSheetState
    extends ConsumerState<_DeliveryMethodSelectionBottomSheet> {
  late CustomerDeliveryMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.currentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Select Delivery Method',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Delivery method picker
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EnhancedDeliveryMethodPicker(
                selectedMethod: _selectedMethod,
                onMethodChanged: (method) {
                  setState(() {
                    _selectedMethod = method;
                  });
                },
                vendorId: widget.vendorId,
                subtotal: widget.subtotal,
                deliveryAddress: widget.deliveryAddress,
                showEstimatedTime: true,
                showFeatureComparison: false,
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedMethod),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for selecting payment methods in checkout
class _PaymentMethodSelectionDialog extends StatelessWidget {
  final List<CustomerPaymentMethod> paymentMethods;
  final CustomerPaymentMethod? currentSelection;

  const _PaymentMethodSelectionDialog({
    required this.paymentMethods,
    this.currentSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Payment Method'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: paymentMethods.length,
          itemBuilder: (context, index) {
            final paymentMethod = paymentMethods[index];
            final isSelected = currentSelection?.id == paymentMethod.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getPaymentMethodIcon(paymentMethod.type),
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                title: Text(
                  paymentMethod.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (paymentMethod.cardLast4 != null) ...[
                      Text('•••• •••• •••• ${paymentMethod.cardLast4}'),
                    ],
                    if (paymentMethod.isDefault) ...[
                      Text(
                        'Default',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(paymentMethod),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(CustomerPaymentMethodType type) {
    switch (type) {
      case CustomerPaymentMethodType.card:
        return Icons.credit_card;
      case CustomerPaymentMethodType.digitalWallet:
        return Icons.account_balance_wallet;
      case CustomerPaymentMethodType.bankAccount:
        return Icons.account_balance;
    }
  }
}
