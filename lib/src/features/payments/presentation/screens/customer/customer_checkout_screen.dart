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
import '../../../../orders/presentation/widgets/customer/schedule_time_picker.dart';
import '../../../../orders/presentation/widgets/customer/scheduled_delivery_display.dart';
import '../../../../orders/presentation/providers/customer/customer_cart_provider.dart';
import '../../../../orders/presentation/providers/customer/customer_order_provider.dart';
import '../../../../orders/presentation/providers/enhanced_cart_provider.dart';
import '../../../../orders/data/models/customer_delivery_method.dart';
import '../../../../../core/services/card_field_manager.dart';
import '../../../../user_management/presentation/providers/customer_address_provider.dart' as address_provider;
import '../../../../orders/presentation/providers/checkout_defaults_provider.dart';
import '../../../../orders/presentation/providers/checkout_fallback_provider.dart';
import '../../../../orders/presentation/widgets/checkout_fallback_widget.dart';
import '../../../../orders/presentation/widgets/enhanced_delivery_method_picker.dart';
import '../../../../marketplace_wallet/data/models/customer_payment_method.dart';
import '../../../../marketplace_wallet/presentation/providers/customer_payment_methods_provider.dart';
import '../../../../marketplace_wallet/presentation/providers/customer_wallet_provider.dart';
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
  bool _hasUserSelectedPaymentMethod = false; // Track if user has manually selected a payment method
  final TextEditingController _promoCodeController = TextEditingController();
  double _discount = 0.0;
  stripe.CardFieldInputDetails? _cardDetails;
  final TextEditingController _orderNotesController = TextEditingController();

  // Saved payment method state
  CustomerPaymentMethod? _savedPaymentMethod;
  bool _useSavedPaymentMethod = false;

  // Payment method selection UI visibility state
  bool _showFullPaymentMethodUI = false;

  // CardField lifecycle management
  bool _cardFieldMounted = false;
  final CardFieldManager _cardFieldManager = CardFieldManager();
  static const String _screenId = 'customer_checkout_screen';

  @override
  void initState() {
    super.initState();
    // Auto-populate defaults and analyze fallback scenarios when checkout screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckout();
      // Request CardField permission after checkout initialization
      _requestCardFieldPermission();
    });
  }

  /// Check if this screen is still the active route and release CardField if not
  void _checkRouteStatus() {
    if (!mounted) return;

    final currentRoute = ModalRoute.of(context);
    if (currentRoute != null && !currentRoute.isCurrent) {
      // This screen is no longer the current route, release CardField permission
      debugPrint('🔄 [CHECKOUT-SCREEN] Screen no longer current, releasing CardField permission');
      _cardFieldManager.releaseCardFieldPermission(_screenId);
      setState(() {
        _cardFieldMounted = false;
      });
    }
  }

  /// Force checkout fallback re-analysis to detect payment method changes
  Future<void> _forceCheckoutFallbackReAnalysis() async {
    try {
      debugPrint('🔄 [CHECKOUT-SCREEN] Forcing fallback re-analysis for payment method detection');

      // First, refresh payment methods to ensure we have the latest data
      try {
        await ref.read(customerPaymentMethodsProvider.notifier).refresh();
        debugPrint('✅ [CHECKOUT-SCREEN] Payment methods refreshed successfully');
      } catch (e) {
        debugPrint('⚠️ [CHECKOUT-SCREEN] Payment methods refresh failed: $e');
        // Continue with fallback analysis even if refresh fails
      }

      // Force re-analysis of checkout fallback state
      await ref.read(checkoutFallbackProvider.notifier).forceReAnalysis(
        reason: 'Returned to checkout screen - checking for payment method changes'
      );

      debugPrint('✅ [CHECKOUT-SCREEN] Fallback re-analysis completed');
    } catch (e, stack) {
      debugPrint('❌ [CHECKOUT-SCREEN] Error during fallback re-analysis: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  /// Request permission to use CardField from global manager
  void _requestCardFieldPermission() {
    if (!mounted) return;

    final hasPermission = _cardFieldManager.requestCardFieldPermission(_screenId);
    if (hasPermission) {
      // Register cleanup callback
      _cardFieldManager.registerCleanupCallback(_screenId, () {
        if (mounted) {
          setState(() {
            _cardFieldMounted = false;
          });
        }
      });

      // Initialize CardField
      setState(() {
        _cardFieldMounted = true;
      });
      debugPrint('✅ [CHECKOUT-SCREEN] CardField initialized and mounted');
    } else {
      debugPrint('❌ [CHECKOUT-SCREEN] CardField permission denied - another CardField is active');
      // Don't show error in checkout screen, just disable CardField
      setState(() {
        _cardFieldMounted = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if this screen is still the active route for CardField management
    _checkRouteStatus();

    // Check if we need to re-trigger auto-population after hot restart
    // and watch for checkout defaults changes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndRetriggerAutoPopulation();
      await _handleCheckoutDefaultsChange();

      // Force fallback re-analysis when returning to checkout screen
      // This ensures that if users added payment methods in another screen,
      // the fallback UI will automatically transition to normal checkout
      await _forceCheckoutFallbackReAnalysis();
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

    // Reset payment method UI state to default (compact view)
    setState(() {
      _showFullPaymentMethodUI = false;
    });

    // Ensure provider synchronization first
    await _ensureProviderSynchronization();

    // Initialize payment method from cart state if available
    final cartState = ref.read(customerCartProvider);
    if (cartState.selectedPaymentMethod != null) {
      setState(() {
        _selectedPaymentMethod = cartState.selectedPaymentMethod!;
      });
    }

    // Load wallet data for potential wallet payments
    debugPrint('💳 [CHECKOUT-SCREEN] Loading wallet data during initialization');
    ref.read(customerWalletProvider.notifier).loadWallet();

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
    debugPrint('🔧 [CHECKOUT-SCREEN] Disposing screen and cleaning up CardField');

    // Release CardField permission from global manager
    _cardFieldManager.releaseCardFieldPermission(_screenId);

    // Mark CardField as unmounted to prevent platform view conflicts
    _cardFieldMounted = false;

    // Dispose controllers
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
        // ONLY auto-populate if user hasn't made any payment method selection
        if ((_selectedPaymentMethod != 'card' || _savedPaymentMethod == null) && !_hasUserSelectedPaymentMethod) {
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
      // ONLY auto-populate if user hasn't made any payment method selection
      if (checkoutDefaults.hasPaymentMethod &&
          checkoutDefaults.defaultPaymentMethod != null &&
          _savedPaymentMethod == null &&
          !_useSavedPaymentMethod &&
          !_hasUserSelectedPaymentMethod) {

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
      // ONLY auto-populate if user hasn't made any payment method selection
      if (defaults.hasPaymentMethod &&
          defaults.defaultPaymentMethod != null &&
          _savedPaymentMethod == null &&
          !_useSavedPaymentMethod &&
          !_hasUserSelectedPaymentMethod) {

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
            if (cartState.deliveryMethod == CustomerDeliveryMethod.scheduled) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              ScheduledDeliveryDisplay(
                scheduledTime: cartState.scheduledDeliveryTime,
                onTap: () => _showScheduleTimePicker(),
                onEdit: () => _showScheduleTimePicker(),
                showEditButton: true,
                showClearButton: false,
                showValidationStatus: true,
                isRequired: true,
                title: 'Scheduled Delivery',
                emptyStateText: 'Tap to schedule delivery time',
                padding: const EdgeInsets.all(12),
              ),
            ],
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

            // Conditional rendering based on default payment method and UI state
            Consumer(
              builder: (context, ref, child) {
                final defaults = ref.watch(checkoutDefaultsProvider);

                // Show compact default view when user has default payment method and hasn't chosen to change it
                if (defaults.hasPaymentMethod &&
                    defaults.defaultPaymentMethod != null &&
                    !_showFullPaymentMethodUI) {
                  return _buildCompactDefaultPaymentView(defaults.defaultPaymentMethod!, theme);
                }

                // Show full payment method selection UI
                return _buildFullPaymentMethodSelection(theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build compact default payment method view
  Widget _buildCompactDefaultPaymentView(CustomerPaymentMethod defaultPaymentMethod, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Payment Method',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      defaultPaymentMethod.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFullPaymentMethodUI = true;
                  });
                },
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build full payment method selection UI
  Widget _buildFullPaymentMethodSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show "Back to Default" option if user has a default payment method
        Consumer(
          builder: (context, ref, child) {
            final defaults = ref.watch(checkoutDefaultsProvider);
            if (defaults.hasPaymentMethod && defaults.defaultPaymentMethod != null && _showFullPaymentMethodUI) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFullPaymentMethodUI = false;
                        });
                      },
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text('Back to Default (${defaults.defaultPaymentMethod!.displayName})'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        RadioListTile<String>(
          title: const Text('Credit/Debit Card'),
          subtitle: const Text('Pay securely with your card'),
          value: 'card',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) async {
            setState(() {
              _selectedPaymentMethod = value!;
              // Mark that user has manually selected a payment method
              _hasUserSelectedPaymentMethod = true;
            });
            ref.read(customerCartProvider.notifier).setPaymentMethod(value!);
            // Sync to enhanced cart provider with resilient error handling
            await _syncPaymentMethodToEnhancedCart(value);
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
            setState(() {
              _selectedPaymentMethod = value!;
              // Clear saved payment method state when selecting cash
              _useSavedPaymentMethod = false;
              _savedPaymentMethod = null;
              // Mark that user has manually selected a payment method
              _hasUserSelectedPaymentMethod = true;
            });
            ref.read(customerCartProvider.notifier).setPaymentMethod(value!);
            // Sync to enhanced cart provider with resilient error handling
            await _syncPaymentMethodToEnhancedCart(value);

            debugPrint('💳 [CHECKOUT] Selected cash payment - cleared saved payment method state');
          },
          contentPadding: EdgeInsets.zero,
        ),

        RadioListTile<String>(
          title: const Text('Digital Wallet'),
          subtitle: const Text('GigaEats Wallet'),
          value: 'wallet',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) async {
            setState(() {
              _selectedPaymentMethod = value!;
              // Clear saved payment method state when selecting wallet
              _useSavedPaymentMethod = false;
              _savedPaymentMethod = null;
              // Mark that user has manually selected a payment method
              _hasUserSelectedPaymentMethod = true;
            });
            ref.read(customerCartProvider.notifier).setPaymentMethod(value!);
            // Sync to enhanced cart provider with resilient error handling
            await _syncPaymentMethodToEnhancedCart(value);

            // Load wallet data when wallet payment is selected
            if (value == 'wallet') {
              debugPrint('💳 [CHECKOUT] Loading wallet data for wallet payment selection');
              ref.read(customerWalletProvider.notifier).loadWallet();
            }

            debugPrint('💳 [CHECKOUT] Selected wallet payment - cleared saved payment method state');
          },
          contentPadding: EdgeInsets.zero,
        ),

        // Show wallet balance info when wallet is selected
        if (_selectedPaymentMethod == 'wallet') ...[
          const SizedBox(height: 12),
          _buildWalletBalanceInfo(theme),
        ],
      ],
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

  /// Show enhanced schedule time picker
  void _showScheduleTimePicker() {
    final cartState = ref.read(customerCartProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScheduleTimePicker(
        initialDateTime: cartState.scheduledDeliveryTime,
        onDateTimeSelected: (dateTime) {
          if (dateTime != null) {
            ref.read(customerCartProvider.notifier).setScheduledDeliveryTime(dateTime);
            debugPrint('🕒 [CHECKOUT-SCREEN] Scheduled delivery time set: $dateTime');
          }
        },
        onCancel: () {
          debugPrint('🚫 [CHECKOUT-SCREEN] Schedule delivery cancelled');
        },
        title: 'Schedule Your Delivery',
        subtitle: 'Choose when you\'d like your order to be delivered',
        showBusinessHours: true,
        minimumAdvanceHours: 2,
        maxDaysAhead: 7,
      ),
    );
  }

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
      } else if (_selectedPaymentMethod == 'wallet') {
        // Validate wallet balance before proceeding
        final isValid = await _validateWalletBalance();
        if (!isValid) {
          // Validation failed, dialog already shown
          return;
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
        // Enhanced error handling for wallet payments
        if (_selectedPaymentMethod == 'wallet') {
          _showWalletPaymentErrorDialog(e.toString());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error placing order: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _placeOrder(),
              ),
            ),
          );
        }
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

  /// Check if the error message indicates a delivery time constraint issue
  bool _isDeliveryTimeConstraintError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    return lowerError.contains('delivery time must be between') ||
           lowerError.contains('8:00 am and 10:00 pm') ||
           lowerError.contains('business hours') ||
           (lowerError.contains('delivery time') && lowerError.contains('between'));
  }



  /// Show enhanced error dialog for wallet payment failures
  void _showWalletPaymentErrorDialog(String errorMessage) {
    // Check if this is an insufficient balance error
    if (errorMessage.toLowerCase().contains('insufficient') &&
        errorMessage.toLowerCase().contains('balance')) {
      // Extract balance information if available
      final regex = RegExp(r'RM\s*([\d.]+)');
      final matches = regex.allMatches(errorMessage);

      if (matches.length >= 2) {
        // Try to extract available balance and required amount
        final amounts = matches.map((m) => double.tryParse(m.group(1) ?? '0') ?? 0.0).toList();

        // Show the proper insufficient balance dialog
        _showInsufficientBalanceDialog(amounts[0], amounts[1]);
        return;
      } else {
        // Fallback: show insufficient balance dialog with current wallet state
        final walletState = ref.read(customerWalletProvider);
        final cartState = ref.read(customerCartProvider); // Use same provider as Place Order button
        if (walletState.wallet != null) {
          final fallbackWalletBalance = walletState.wallet!.availableBalance;
          final fallbackOrderTotal = cartState.totalAmount - _discount; // Apply discount like the Place Order button

          debugPrint('🔍 [ERROR-DIALOG-ROUTING] === FALLBACK DIALOG ROUTING ===');
          debugPrint('🔍 [ERROR-DIALOG-ROUTING] Fallback wallet balance: RM ${fallbackWalletBalance.toStringAsFixed(2)}');
          debugPrint('🔍 [ERROR-DIALOG-ROUTING] Fallback order total: RM ${fallbackOrderTotal.toStringAsFixed(2)}');
          debugPrint('🔍 [ERROR-DIALOG-ROUTING] Discount applied: RM ${_discount.toStringAsFixed(2)}');

          _showInsufficientBalanceDialog(
            fallbackWalletBalance,
            fallbackOrderTotal,
          );
          return;
        }
      }
    }

    // Parse error message to extract error code and guidance
    final lines = errorMessage.split('\n');
    final mainError = lines.first.replaceFirst('Payment failed: ', '');
    final guidance = lines.length > 1 ? lines.skip(1).join('\n') : null;

    // Check if this is a delivery time constraint error
    final isDeliveryTimeError = _isDeliveryTimeConstraintError(errorMessage);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          isDeliveryTimeError
              ? Icons.schedule_outlined
              : Icons.account_balance_wallet_outlined,
          color: Colors.red.shade600,
          size: 48,
        ),
        title: Text(
          isDeliveryTimeError
              ? 'Delivery Time Issue'
              : 'Wallet Payment Failed',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDeliveryTimeError
                  ? 'Your order cannot be processed because the delivery is scheduled outside our operating hours.'
                  : mainError,
              style: const TextStyle(fontSize: 16),
            ),
            if (isDeliveryTimeError) ...[
              const SizedBox(height: 8),
              Text(
                'Operating Hours: 8:00 AM - 10:00 PM daily',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDeliveryTimeError
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDeliveryTimeError
                      ? Colors.orange.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDeliveryTimeError
                            ? Icons.schedule_outlined
                            : Icons.lightbulb_outline,
                        color: isDeliveryTimeError
                            ? Colors.orange.shade600
                            : Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDeliveryTimeError
                            ? 'Schedule your delivery:'
                            : 'How to fix this:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDeliveryTimeError
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDeliveryTimeError
                        ? 'Click "Schedule Delivery" below to choose a valid delivery time and complete your order.'
                        : guidance ?? 'Please try again or contact support if the issue persists.',
                    style: TextStyle(
                      color: isDeliveryTimeError
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to wallet screen for top-up if insufficient funds
              if (!isDeliveryTimeError && mainError.toLowerCase().contains('insufficient')) {
                context.go('/customer/wallet');
              }
            },
            child: Text(
              isDeliveryTimeError
                  ? 'Cancel'
                  : mainError.toLowerCase().contains('insufficient')
                      ? 'Top Up Wallet'
                      : 'OK',
            ),
          ),
          if (isDeliveryTimeError)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showScheduleTimePicker();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Schedule Delivery'),
            )
          else if (errorMessage.contains('retry_allowed'))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _placeOrder(); // Retry the order
              },
              child: const Text('Try Again'),
            )
          else if (!mainError.toLowerCase().contains('insufficient'))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Change payment method
                setState(() {
                  _selectedPaymentMethod = 'card';
                });
              },
              child: const Text('Use Card Instead'),
            ),
        ],
      ),
    );
  }

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

  /// Build wallet balance info widget
  Widget _buildWalletBalanceInfo(ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final walletState = ref.watch(customerWalletProvider);
        final cartState = ref.watch(enhancedCartProvider);

        if (walletState.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (walletState.hasError || walletState.wallet == null) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Wallet not available. Please choose another payment method.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final wallet = walletState.wallet!;
        final walletBalance = wallet.availableBalance;
        final orderTotal = cartState.totalAmount;
        final hasSufficientBalance = walletBalance >= orderTotal;

        return Card(
          color: hasSufficientBalance ? Colors.green.shade50 : Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: hasSufficientBalance ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wallet Balance: RM ${walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasSufficientBalance ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!hasSufficientBalance) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Order Total: RM ${orderTotal.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                  Text(
                    'Shortfall: RM ${(orderTotal - walletBalance).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          context.go('/customer/wallet/top-up');
                        },
                        child: const Text('Top Up Wallet'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Validate wallet balance for current order
  Future<bool> _validateWalletBalance() async {
    try {
      setState(() => _isProcessing = true);

      // Get wallet state
      final walletState = ref.read(customerWalletProvider);
      if (walletState.isLoading) {
        // Wait for wallet to load
        await Future.delayed(const Duration(seconds: 1));
      }

      // Check if wallet exists
      if (walletState.wallet == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet not found. Please choose another payment method.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      // Get cart total and wallet balance
      final cartState = ref.read(customerCartProvider); // Use same provider as Place Order button
      final cartTotalBeforeDiscount = cartState.totalAmount;
      final discountAmount = _discount;
      final orderTotal = cartTotalBeforeDiscount - discountAmount; // Apply discount like the Place Order button
      final walletBalance = walletState.wallet!.availableBalance;

      // Debug logging for amount verification
      debugPrint('🔍 [CHECKOUT-VALIDATION] === WALLET BALANCE VALIDATION ===');
      debugPrint('🔍 [CHECKOUT-VALIDATION] Cart total (before discount): RM ${cartTotalBeforeDiscount.toStringAsFixed(2)}');
      debugPrint('🔍 [CHECKOUT-VALIDATION] Discount amount: RM ${discountAmount.toStringAsFixed(2)}');
      debugPrint('🔍 [CHECKOUT-VALIDATION] Order total (after discount): RM ${orderTotal.toStringAsFixed(2)}');
      debugPrint('🔍 [CHECKOUT-VALIDATION] Wallet balance: RM ${walletBalance.toStringAsFixed(2)}');
      debugPrint('🔍 [CHECKOUT-VALIDATION] Shortfall: RM ${(orderTotal - walletBalance).toStringAsFixed(2)}');

      // Check if balance is sufficient
      if (walletBalance < orderTotal) {
        debugPrint('❌ [CHECKOUT] Insufficient wallet balance: $walletBalance < $orderTotal');

        if (mounted) {
          _showInsufficientBalanceDialog(walletBalance, orderTotal);
        }
        return false;
      }

      debugPrint('✅ [CHECKOUT] Wallet balance sufficient: $walletBalance >= $orderTotal');
      return true;
    } catch (e) {
      debugPrint('❌ [CHECKOUT] Error validating wallet balance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating wallet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Show insufficient wallet balance dialog
  void _showInsufficientBalanceDialog(double walletBalance, double orderTotal) {
    if (!mounted) return;

    final shortfall = orderTotal - walletBalance;

    // Debug logging for dialog parameters
    debugPrint('🔍 [DIALOG-DISPLAY] === INSUFFICIENT BALANCE DIALOG ===');
    debugPrint('🔍 [DIALOG-DISPLAY] Received wallet balance: RM ${walletBalance.toStringAsFixed(2)}');
    debugPrint('🔍 [DIALOG-DISPLAY] Received order total: RM ${orderTotal.toStringAsFixed(2)}');
    debugPrint('🔍 [DIALOG-DISPLAY] Calculated shortfall: RM ${shortfall.toStringAsFixed(2)}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Insufficient Wallet Balance',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your wallet balance is insufficient for this order.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Balance: RM ${walletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Order Total: RM ${orderTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You need RM ${shortfall.toStringAsFixed(2)} more to complete this order.',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Return to payment method selection
              setState(() {
                _showFullPaymentMethodUI = true;
                _selectedPaymentMethod = 'card';
              });
            },
            child: const Text('Choose Different Payment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to wallet top-up screen
              context.go('/customer/wallet/top-up');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Top Up Wallet'),
          ),
        ],
      ),
    );
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
            child: _cardFieldMounted
              ? stripe.CardField(
                  onCardChanged: (details) {
                    if (!mounted) return; // Prevent setState after disposal
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
                )
              : Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Loading payment form...'),
                  ),
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
