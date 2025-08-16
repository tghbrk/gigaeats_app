import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/checkout_steps/cart_review_step.dart';
import '../widgets/checkout_steps/delivery_details_step.dart';
import '../widgets/checkout_steps/payment_method_step.dart';
import '../widgets/checkout_steps/order_confirmation_step.dart';

import '../providers/enhanced_cart_provider.dart';
import '../providers/checkout_flow_provider.dart';
import '../providers/checkout_fallback_provider.dart';

import '../../../core/utils/logger.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';

/// Enhanced multi-step checkout flow screen
class EnhancedCheckoutFlowScreen extends ConsumerStatefulWidget {
  final int? initialStep;

  const EnhancedCheckoutFlowScreen({
    super.key,
    this.initialStep,
  });

  @override
  ConsumerState<EnhancedCheckoutFlowScreen> createState() => _EnhancedCheckoutFlowScreenState();
}

class _EnhancedCheckoutFlowScreenState extends ConsumerState<EnhancedCheckoutFlowScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    
    final initialStep = widget.initialStep ?? 0;
    _pageController = PageController(initialPage: initialStep);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Initialize checkout flow with fallback analysis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckout();
      _fadeController.forward();
    });
  }

  /// Initialize checkout with fallback analysis
  Future<void> _initializeCheckout() async {
    ref.read(checkoutFlowProvider.notifier).initializeCheckout();
    // Analyze fallback scenarios after initialization
    await ref.read(checkoutFallbackProvider.notifier).analyzeCheckoutState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = ref.watch(enhancedCartProvider);
    final checkoutState = ref.watch(checkoutFlowProvider);

    // Redirect if cart is empty
    if (cartState.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/customer/restaurants');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(theme, checkoutState),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildStepIndicator(theme, checkoutState),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
                children: const [
                  CartReviewStep(),
                  DeliveryDetailsStep(),
                  PaymentMethodStep(),
                  OrderConfirmationStep(),
                ],
              ),
            ),
            _buildBottomNavigation(theme, checkoutState),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, CheckoutFlowState checkoutState) {
    return AppBar(
      title: Text(
        _getStepTitle(checkoutState.currentStep),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        onPressed: _canGoBack(checkoutState) ? _goBack : null,
        icon: Icon(
          Icons.arrow_back,
          color: _canGoBack(checkoutState) 
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
      actions: [
        if (checkoutState.currentStep < CheckoutStep.confirmation.index)
          TextButton(
            onPressed: () => _showExitDialog(),
            child: Text(
              'Exit',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepIndicator(ThemeData theme, CheckoutFlowState checkoutState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: CheckoutStep.values.map((step) {
          final stepIndex = step.index;
          final isActive = stepIndex == checkoutState.currentStep;
          final isCompleted = stepIndex < checkoutState.currentStep;
          final isAccessible = stepIndex <= checkoutState.maxAccessibleStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isAccessible ? () => _goToStep(stepIndex) : null,
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? theme.colorScheme.primary
                                : isActive
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: isActive && !isCompleted
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check
                                : _getStepIcon(step),
                            size: 16,
                            color: isCompleted
                                ? theme.colorScheme.onPrimary
                                : isActive
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStepLabel(step),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isActive || isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                if (stepIndex < CheckoutStep.values.length - 1)
                  Container(
                    width: 24,
                    height: 2,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme, CheckoutFlowState checkoutState) {
    final canGoNext = _canGoNext(checkoutState);
    final canGoBack = _canGoBack(checkoutState);
    final isLastStep = checkoutState.currentStep == CheckoutStep.confirmation.index;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (canGoBack)
              Expanded(
                child: GEButton.outline(
                  text: 'Back',
                  onPressed: _goBack,
                  icon: Icons.arrow_back,
                ),
              ),
            if (canGoBack) const SizedBox(width: 12),
            Expanded(
              flex: canGoBack ? 1 : 2,
              child: GEButton.primary(
                text: _getNextButtonText(checkoutState),
                onPressed: canGoNext ? _goNext : null,
                isLoading: checkoutState.isProcessing,
                icon: isLastStep ? Icons.check : Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (CheckoutStep.values[step]) {
      case CheckoutStep.cartReview:
        return 'Review Order';
      case CheckoutStep.deliveryDetails:
        return 'Delivery Details';
      case CheckoutStep.paymentMethod:
        return 'Payment Method';
      case CheckoutStep.confirmation:
        return 'Order Confirmation';
    }
  }

  String _getStepLabel(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.cartReview:
        return 'Review';
      case CheckoutStep.deliveryDetails:
        return 'Delivery';
      case CheckoutStep.paymentMethod:
        return 'Payment';
      case CheckoutStep.confirmation:
        return 'Confirm';
    }
  }

  IconData _getStepIcon(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.cartReview:
        return Icons.shopping_cart;
      case CheckoutStep.deliveryDetails:
        return Icons.local_shipping;
      case CheckoutStep.paymentMethod:
        return Icons.payment;
      case CheckoutStep.confirmation:
        return Icons.receipt;
    }
  }

  String _getNextButtonText(CheckoutFlowState checkoutState) {
    switch (CheckoutStep.values[checkoutState.currentStep]) {
      case CheckoutStep.cartReview:
        return 'Continue to Delivery';
      case CheckoutStep.deliveryDetails:
        return 'Continue to Payment';
      case CheckoutStep.paymentMethod:
        return 'Place Order';
      case CheckoutStep.confirmation:
        return 'Done';
    }
  }

  bool _canGoNext(CheckoutFlowState checkoutState) {
    if (checkoutState.isProcessing) return false;
    
    switch (CheckoutStep.values[checkoutState.currentStep]) {
      case CheckoutStep.cartReview:
        return checkoutState.isCartValid;
      case CheckoutStep.deliveryDetails:
        return checkoutState.isDeliveryValid;
      case CheckoutStep.paymentMethod:
        return checkoutState.isPaymentValid;
      case CheckoutStep.confirmation:
        return true;
    }
  }

  bool _canGoBack(CheckoutFlowState checkoutState) {
    return checkoutState.currentStep > 0 && 
           checkoutState.currentStep < CheckoutStep.confirmation.index;
  }

  void _onPageChanged(int page) {
    ref.read(checkoutFlowProvider.notifier).setCurrentStep(page);
  }

  void _goNext() {
    final checkoutState = ref.read(checkoutFlowProvider);
    final nextStep = checkoutState.currentStep + 1;

    if (nextStep < CheckoutStep.values.length) {
      _goToStep(nextStep);
    } else {
      // Checkout complete
      _completeCheckout();
    }
  }

  void _goBack() {
    final checkoutState = ref.read(checkoutFlowProvider);
    final previousStep = checkoutState.currentStep - 1;

    if (previousStep >= 0) {
      _goToStep(previousStep);
    }
  }

  void _goToStep(int step) {
    _logger.info('🛒 [CHECKOUT-FLOW] Navigating to step: $step');
    
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    ref.read(checkoutFlowProvider.notifier).setCurrentStep(step);
  }

  void _completeCheckout() {
    _logger.info('✅ [CHECKOUT-FLOW] Checkout completed');
    context.pushReplacement('/customer/orders');
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Checkout'),
        content: const Text('Are you sure you want to exit? Your cart will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

/// Checkout step enumeration
enum CheckoutStep {
  cartReview,
  deliveryDetails,
  paymentMethod,
  confirmation,
}
