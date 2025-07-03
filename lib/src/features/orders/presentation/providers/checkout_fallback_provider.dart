import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../user_management/presentation/providers/customer_address_provider.dart';
import '../../../marketplace_wallet/presentation/providers/customer_payment_methods_provider.dart';
import '../../../core/utils/logger.dart';
import 'checkout_defaults_provider.dart';

part 'checkout_fallback_provider.g.dart';

/// Fallback scenario types
enum FallbackScenario {
  noDefaultAddress,
  noDefaultPaymentMethod,
  noSavedAddresses,
  noSavedPaymentMethods,
  addressLoadError,
  paymentMethodLoadError,
  networkError,
  authenticationError,
}

/// Fallback action types
enum FallbackAction {
  addAddress,
  addPaymentMethod,
  selectExistingAddress,
  selectExistingPaymentMethod,
  retry,
  continueWithoutDefaults,
  refreshData,
  contactSupport,
}

/// Fallback guidance model
class FallbackGuidance {
  final FallbackScenario scenario;
  final String title;
  final String message;
  final List<FallbackAction> suggestedActions;
  final String? primaryActionText;
  final FallbackAction? primaryAction;
  final bool isBlocking;
  final String? helpText;

  const FallbackGuidance({
    required this.scenario,
    required this.title,
    required this.message,
    required this.suggestedActions,
    this.primaryActionText,
    this.primaryAction,
    this.isBlocking = false,
    this.helpText,
  });

  @override
  String toString() {
    return 'FallbackGuidance(scenario: $scenario, title: $title, isBlocking: $isBlocking)';
  }
}

/// Checkout fallback state
class CheckoutFallbackState {
  final List<FallbackGuidance> activeGuidances;
  final bool hasBlockingIssues;
  final bool isRecovering;
  final String? lastError;

  const CheckoutFallbackState({
    this.activeGuidances = const [],
    this.hasBlockingIssues = false,
    this.isRecovering = false,
    this.lastError,
  });

  CheckoutFallbackState copyWith({
    List<FallbackGuidance>? activeGuidances,
    bool? hasBlockingIssues,
    bool? isRecovering,
    String? lastError,
  }) {
    return CheckoutFallbackState(
      activeGuidances: activeGuidances ?? this.activeGuidances,
      hasBlockingIssues: hasBlockingIssues ?? this.hasBlockingIssues,
      isRecovering: isRecovering ?? this.isRecovering,
      lastError: lastError,
    );
  }

  @override
  String toString() {
    return 'CheckoutFallbackState(guidances: ${activeGuidances.length}, blocking: $hasBlockingIssues, recovering: $isRecovering)';
  }
}

/// Provider for checkout fallback handling
@riverpod
class CheckoutFallback extends _$CheckoutFallback {
  final AppLogger _logger = AppLogger();

  @override
  CheckoutFallbackState build() {
    // Watch payment methods provider to auto-trigger analysis when state changes
    ref.listen(customerPaymentMethodsProvider, (previous, next) {
      _logger.debug('🔄 [CHECKOUT-FALLBACK] Payment methods provider changed');

      // Check if we transitioned from loading to data/error
      final wasLoading = previous?.isLoading ?? true;
      final isNowLoading = next.isLoading;

      if (wasLoading && !isNowLoading) {
        _logger.info('✅ [CHECKOUT-FALLBACK] Payment methods finished loading, re-triggering analysis');
        // Use Future.microtask to avoid calling during build
        Future.microtask(() => analyzeCheckoutState());
        return;
      }

      // Also check for data changes when both states have data
      if (!isNowLoading && previous != null && !previous.isLoading) {
        final previousData = previous.asData?.value ?? [];
        final currentData = next.asData?.value ?? [];

        // Check if payment methods count changed (new payment method added/removed)
        if (previousData.length != currentData.length) {
          _logger.info('🔄 [CHECKOUT-FALLBACK] Payment methods count changed: ${previousData.length} → ${currentData.length}, re-triggering analysis');
          Future.microtask(() => analyzeCheckoutState());
          return;
        }

        // Check if default payment method changed
        final previousDefault = previousData.where((m) => m.isDefault).firstOrNull;
        final currentDefault = currentData.where((m) => m.isDefault).firstOrNull;

        if (previousDefault?.id != currentDefault?.id) {
          _logger.info('🔄 [CHECKOUT-FALLBACK] Default payment method changed, re-triggering analysis');
          Future.microtask(() => analyzeCheckoutState());
          return;
        }
      }
    });

    return const CheckoutFallbackState();
  }

  /// Analyze checkout state and provide fallback guidance
  Future<void> analyzeCheckoutState() async {
    try {
      _logger.info('🔍 [CHECKOUT-FALLBACK] Analyzing checkout state');

      state = state.copyWith(isRecovering: true);

      final guidances = <FallbackGuidance>[];

      // Check defaults availability (now synchronous)
      final defaults = ref.read(checkoutDefaultsProvider);
      
      // Check address scenarios
      await _analyzeAddressScenarios(defaults, guidances);
      
      // Check payment method scenarios
      await _analyzePaymentMethodScenarios(defaults, guidances);

      // Check for blocking issues
      final hasBlocking = guidances.any((g) => g.isBlocking);

      state = state.copyWith(
        activeGuidances: guidances,
        hasBlockingIssues: hasBlocking,
        isRecovering: false,
        lastError: null,
      );

      _logger.info('✅ [CHECKOUT-FALLBACK] Analysis complete: ${guidances.length} guidances, blocking: $hasBlocking');

    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FALLBACK] Error analyzing checkout state', e, stack);
      
      state = state.copyWith(
        isRecovering: false,
        lastError: e.toString(),
        activeGuidances: [
          FallbackGuidance(
            scenario: FallbackScenario.networkError,
            title: 'Connection Error',
            message: 'Unable to load checkout information. Please check your connection and try again.',
            suggestedActions: [FallbackAction.retry, FallbackAction.contactSupport],
            primaryAction: FallbackAction.retry,
            primaryActionText: 'Retry',
            isBlocking: true,
          ),
        ],
        hasBlockingIssues: true,
      );
    }
  }

  /// Force re-analysis of checkout state (useful when returning from other screens)
  Future<void> forceReAnalysis({String? reason}) async {
    final reasonText = reason != null ? ' (reason: $reason)' : '';
    _logger.info('🔄 [CHECKOUT-FALLBACK] Force re-analysis requested$reasonText');

    // Invalidate checkout defaults to ensure fresh data
    ref.invalidate(checkoutDefaultsProvider);

    // Small delay to allow provider invalidation to propagate
    await Future.delayed(const Duration(milliseconds: 50));

    // Re-analyze with fresh data
    await analyzeCheckoutState();
  }

  /// Analyze address-related scenarios
  Future<void> _analyzeAddressScenarios(CheckoutDefaults defaults, List<FallbackGuidance> guidances) async {
    try {
      // Check if user has any addresses
      final hasAddresses = await ref.read(customerHasAddressesProvider.future);
      
      if (defaults.addressError != null) {
        // Address loading error
        guidances.add(FallbackGuidance(
          scenario: FallbackScenario.addressLoadError,
          title: 'Address Loading Error',
          message: 'Unable to load your saved addresses. You can still add a new address or try again.',
          suggestedActions: [FallbackAction.addAddress, FallbackAction.retry],
          primaryAction: FallbackAction.addAddress,
          primaryActionText: 'Add Address',
          helpText: 'Your addresses are safely stored. This is likely a temporary connection issue.',
        ));
      } else if (!hasAddresses) {
        // No saved addresses
        guidances.add(FallbackGuidance(
          scenario: FallbackScenario.noSavedAddresses,
          title: 'No Delivery Address',
          message: 'Add a delivery address to continue with your order.',
          suggestedActions: [FallbackAction.addAddress],
          primaryAction: FallbackAction.addAddress,
          primaryActionText: 'Add Address',
          isBlocking: true,
          helpText: 'You can save multiple addresses for faster checkout in the future.',
        ));
      } else if (!defaults.hasAddress) {
        // Has addresses but no default
        guidances.add(FallbackGuidance(
          scenario: FallbackScenario.noDefaultAddress,
          title: 'No Default Address',
          message: 'Select a delivery address or set one as default for faster checkout.',
          suggestedActions: [FallbackAction.selectExistingAddress, FallbackAction.addAddress],
          primaryAction: FallbackAction.selectExistingAddress,
          primaryActionText: 'Select Address',
          helpText: 'Setting a default address will speed up future orders.',
        ));
      }
    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FALLBACK] Error analyzing address scenarios', e, stack);
    }
  }

  /// Analyze payment method scenarios
  Future<void> _analyzePaymentMethodScenarios(CheckoutDefaults defaults, List<FallbackGuidance> guidances) async {
    try {
      // Check if payment methods are still loading
      final paymentMethodsAsync = ref.read(customerPaymentMethodsProvider);
      final isPaymentMethodsLoading = paymentMethodsAsync.isLoading;

      // If still loading, skip analysis but log for debugging
      if (isPaymentMethodsLoading) {
        _logger.debug('🔄 [CHECKOUT-FALLBACK] Payment methods still loading, skipping payment method analysis (will auto-retry when loaded)');
        return;
      }

      // Check if user has any payment methods
      final hasPaymentMethods = await ref.read(customerHasSavedPaymentMethodsProvider.future);

      if (defaults.paymentMethodError != null) {
        // Payment method loading error
        guidances.add(FallbackGuidance(
          scenario: FallbackScenario.paymentMethodLoadError,
          title: 'Payment Method Loading Error',
          message: 'Unable to load your saved payment methods. You can still add a new one or use cash on delivery.',
          suggestedActions: [FallbackAction.addPaymentMethod, FallbackAction.continueWithoutDefaults, FallbackAction.retry],
          primaryAction: FallbackAction.addPaymentMethod,
          primaryActionText: 'Add Payment Method',
          helpText: 'Your payment methods are safely stored. This is likely a temporary connection issue.',
        ));
      } else if (!hasPaymentMethods) {
        // No saved payment methods
        guidances.add(FallbackGuidance(
          scenario: FallbackScenario.noSavedPaymentMethods,
          title: 'No Payment Method',
          message: 'Add a payment method for faster checkout, or choose cash on delivery.',
          suggestedActions: [FallbackAction.addPaymentMethod, FallbackAction.continueWithoutDefaults],
          primaryAction: FallbackAction.addPaymentMethod,
          primaryActionText: 'Add Payment Method',
          helpText: 'Saved payment methods make checkout faster and more convenient.',
        ));
      } else if (!defaults.hasPaymentMethod) {
        // Has payment methods but no default
        guidances.add(FallbackGuidance(
          scenario: FallbackScenario.noDefaultPaymentMethod,
          title: 'No Default Payment Method',
          message: 'Select a payment method or set one as default for faster checkout.',
          suggestedActions: [FallbackAction.selectExistingPaymentMethod, FallbackAction.addPaymentMethod],
          primaryAction: FallbackAction.selectExistingPaymentMethod,
          primaryActionText: 'Select Payment Method',
          helpText: 'Setting a default payment method will speed up future orders.',
        ));
      }
    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FALLBACK] Error analyzing payment method scenarios', e, stack);
    }
  }

  /// Execute a fallback action
  Future<bool> executeFallbackAction(FallbackAction action) async {
    try {
      _logger.info('🔧 [CHECKOUT-FALLBACK] Executing action: $action');

      switch (action) {
        case FallbackAction.retry:
          await analyzeCheckoutState();
          return true;
          
        case FallbackAction.refreshData:
          // Refresh providers
          ref.invalidate(checkoutDefaultsProvider);
          ref.invalidate(customerAddressesProvider);
          ref.invalidate(customerPaymentMethodsProvider);
          await analyzeCheckoutState();
          return true;
          
        case FallbackAction.continueWithoutDefaults:
          // Clear guidances and allow checkout to continue
          state = state.copyWith(
            activeGuidances: [],
            hasBlockingIssues: false,
          );
          return true;
          
        default:
          // Other actions require navigation/UI interaction
          return false;
      }
    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FALLBACK] Error executing action: $action', e, stack);
      return false;
    }
  }

  /// Clear all guidances
  void clearGuidances() {
    state = state.copyWith(
      activeGuidances: [],
      hasBlockingIssues: false,
      lastError: null,
    );
  }

  /// Get guidance for a specific scenario
  FallbackGuidance? getGuidanceForScenario(FallbackScenario scenario) {
    return state.activeGuidances
        .where((g) => g.scenario == scenario)
        .firstOrNull;
  }
}

/// Provider for checking if checkout has fallback issues
@riverpod
bool checkoutHasFallbackIssues(Ref ref) {
  final fallbackState = ref.watch(checkoutFallbackProvider);
  return fallbackState.hasBlockingIssues;
}

/// Provider for getting primary fallback action
@riverpod
FallbackAction? primaryFallbackAction(Ref ref) {
  final fallbackState = ref.watch(checkoutFallbackProvider);
  final blockingGuidance = fallbackState.activeGuidances
      .where((g) => g.isBlocking)
      .firstOrNull;
  return blockingGuidance?.primaryAction;
}
