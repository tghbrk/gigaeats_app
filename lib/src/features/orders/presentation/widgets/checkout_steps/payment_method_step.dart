import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../../providers/enhanced_cart_provider.dart';
import '../../providers/checkout_flow_provider.dart';
import '../../providers/checkout_defaults_provider.dart';
import '../../../../marketplace_wallet/data/models/customer_payment_method.dart';
import '../../../../marketplace_wallet/presentation/providers/customer_payment_methods_provider.dart';
import '../../../../marketplace_wallet/presentation/providers/customer_wallet_provider.dart';
import '../../../../marketplace_wallet/presentation/providers/wallet_validation_provider.dart';
import '../../../../marketplace_wallet/presentation/providers/loyalty_provider.dart';
import '../../../../marketplace_wallet/presentation/widgets/customer_wallet_balance_card.dart';
import '../../../../core/utils/logger.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import 'dart:math' as math;

/// Payment method step in checkout flow
class PaymentMethodStep extends ConsumerStatefulWidget {
  const PaymentMethodStep({super.key});

  @override
  ConsumerState<PaymentMethodStep> createState() => _PaymentMethodStepState();
}

class _PaymentMethodStepState extends ConsumerState<PaymentMethodStep>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _promoCodeController = TextEditingController();
  final AppLogger _logger = AppLogger();

  String _selectedPaymentMethod = 'card';
  bool _isAutoPopulating = false;
  bool _hasAutoPopulated = false;

  double _discount = 0.0;
  bool _isApplyingPromoCode = false;

  // Loyalty points state
  bool _usePoints = false;
  int _pointsToUse = 0;

  // Payment method auto-population state
  CustomerPaymentMethod? _selectedSavedPaymentMethod;
  bool _useSavedPaymentMethod = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Initialize from checkout state and auto-populate defaults
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentMethod();
    });
  }

  /// Initialize payment method with auto-population
  Future<void> _initializePaymentMethod() async {
    _logger.info('🚀 [PAYMENT-METHOD] Initializing payment method step');

    final checkoutState = ref.read(checkoutFlowProvider);
    _logger.debug('🔍 [PAYMENT-METHOD] Current checkout state: selectedPaymentMethod=${checkoutState.selectedPaymentMethod}');

    // First, load existing checkout state
    if (checkoutState.selectedPaymentMethod != null) {
      _logger.debug('🔄 [PAYMENT-METHOD] Loading existing payment method from checkout state: ${checkoutState.selectedPaymentMethod}');
      setState(() {
        _selectedPaymentMethod = checkoutState.selectedPaymentMethod!;
      });
    } else {
      _logger.debug('ℹ️ [PAYMENT-METHOD] No existing payment method in checkout state');
    }

    // Auto-populate defaults if not already set
    if (!_hasAutoPopulated) {
      _logger.debug('🔄 [PAYMENT-METHOD] Starting auto-population process');
      await _autoPopulateDefaults();
    } else {
      _logger.debug('ℹ️ [PAYMENT-METHOD] Auto-population already completed, skipping');
    }

    _logger.info('✅ [PAYMENT-METHOD] Payment method initialization completed');
  }

  /// Auto-populate default payment method
  Future<void> _autoPopulateDefaults() async {
    if (_hasAutoPopulated || _isAutoPopulating) {
      _logger.debug('🔄 [PAYMENT-METHOD] Skipping auto-population - already populated: $_hasAutoPopulated, currently populating: $_isAutoPopulating');
      return;
    }

    setState(() {
      _isAutoPopulating = true;
    });

    try {
      _logger.info('🔄 [PAYMENT-METHOD] Starting auto-population of defaults');

      // First, check the async state of payment methods
      final paymentMethodsAsync = ref.read(customerPaymentMethodsProvider);
      _logger.debug('🔍 [PAYMENT-METHOD] Payment methods async state: ${paymentMethodsAsync.runtimeType}');

      paymentMethodsAsync.when(
        data: (methods) => _logger.debug('📊 [PAYMENT-METHOD] Payment methods data available: ${methods.length} methods'),
        loading: () => _logger.debug('🔄 [PAYMENT-METHOD] Payment methods still loading'),
        error: (error, stack) => _logger.error('❌ [PAYMENT-METHOD] Payment methods error: $error'),
      );

      final defaults = ref.read(checkoutDefaultsProvider);
      _logger.debug('🔍 [PAYMENT-METHOD] Checkout defaults: hasPaymentMethod=${defaults.hasPaymentMethod}, hasAddress=${defaults.hasAddress}');
      _logger.debug('🔍 [PAYMENT-METHOD] Default payment method details: ${defaults.defaultPaymentMethod?.displayName ?? 'null'} (ID: ${defaults.defaultPaymentMethod?.id ?? 'null'})');

      if (defaults.paymentMethodError != null) {
        _logger.warning('⚠️ [PAYMENT-METHOD] Payment method error in defaults: ${defaults.paymentMethodError}');
      }

      if (defaults.hasPaymentMethod && defaults.defaultPaymentMethod != null) {
        _logger.info('✅ [PAYMENT-METHOD] Default payment method found: ${defaults.defaultPaymentMethod!.displayName}');

        // Map CustomerPaymentMethod to checkout payment method string
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

        _logger.debug('🔄 [PAYMENT-METHOD] Mapping payment method type ${defaults.defaultPaymentMethod!.type} to value: $paymentMethodValue');

        setState(() {
          _selectedPaymentMethod = paymentMethodValue;
          _selectedSavedPaymentMethod = defaults.defaultPaymentMethod;
          _useSavedPaymentMethod = true;
        });

        _logger.debug('🔄 [PAYMENT-METHOD] State updated - selectedPaymentMethod: $_selectedPaymentMethod, useSavedPaymentMethod: $_useSavedPaymentMethod, selectedSavedPaymentMethod: ${_selectedSavedPaymentMethod?.displayName}');

        // Update checkout flow provider
        ref.read(checkoutFlowProvider.notifier).setPaymentMethod(paymentMethodValue);
        _logger.debug('🔄 [PAYMENT-METHOD] Updated checkout flow provider with payment method: $paymentMethodValue');

        _logger.info('✅ [PAYMENT-METHOD] Auto-populated default payment method: ${defaults.defaultPaymentMethod!.displayName}');

        // Force a rebuild to ensure UI reflects the updated state
        if (mounted) {
          setState(() {});
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using default payment: ${defaults.defaultPaymentMethod!.displayName}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Change',
                textColor: Colors.white,
                onPressed: () {
                  // Focus on payment method section
                },
              ),
            ),
          );
        }
      } else {
        _logger.warning('⚠️ [PAYMENT-METHOD] No default payment method available for auto-population');
        _logger.debug('🔍 [PAYMENT-METHOD] hasPaymentMethod: ${defaults.hasPaymentMethod}, defaultPaymentMethod: ${defaults.defaultPaymentMethod}');
      }

      setState(() {
        _hasAutoPopulated = true;
      });

      _logger.info('✅ [PAYMENT-METHOD] Auto-population completed');

    } catch (e, stack) {
      _logger.error('❌ [PAYMENT-METHOD] Error auto-populating defaults', e, stack);
    } finally {
      setState(() {
        _isAutoPopulating = false;
      });
    }
  }

  /// Manually refresh defaults
  Future<void> _refreshDefaults() async {
    _logger.info('🔄 [PAYMENT-METHOD] Manually refreshing defaults');
    setState(() {
      _hasAutoPopulated = false;
      _useSavedPaymentMethod = false;
      _selectedSavedPaymentMethod = null;
    });
    await _autoPopulateDefaults();
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _logger.debug('🔄 [PAYMENT-METHOD-UI] Building PaymentMethodStep - selectedPaymentMethod: $_selectedPaymentMethod, useSavedPaymentMethod: $_useSavedPaymentMethod, hasAutoPopulated: $_hasAutoPopulated');

    final theme = Theme.of(context);
    final cartState = ref.watch(enhancedCartProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          _buildPaymentMethodSection(theme),
          const SizedBox(height: 24),
          _buildPromoCodeSection(theme),
          const SizedBox(height: 24),
          _buildLoyaltyPointsSection(theme),
          const SizedBox(height: 24),
          _buildOrderSummary(theme, cartState),
          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.payment,
                size: 24,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Choose how you\'d like to pay for your order',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Select Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                onPressed: () => _refreshDefaults(),
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh default payment method',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Show default payment method info if auto-populated
        Consumer(
          builder: (context, ref, child) {
            final defaults = ref.watch(checkoutDefaultsProvider);
            _logger.debug('🔍 [PAYMENT-METHOD-UI] Checkout defaults: hasPaymentMethod=${defaults.hasPaymentMethod}, defaultPaymentMethod=${defaults.defaultPaymentMethod?.displayName ?? 'null'}');

            if (defaults.hasPaymentMethod && defaults.defaultPaymentMethod != null) {
              _logger.debug('✅ [PAYMENT-METHOD-UI] Showing default payment method: ${defaults.defaultPaymentMethod!.displayName}');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
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
            } else {
              _logger.debug('ℹ️ [PAYMENT-METHOD-UI] No default payment method to show');
              return const SizedBox.shrink();
            }
          },
        ),

        const SizedBox(height: 12),
        _buildPaymentMethodOption(
          theme,
          'card',
          'Credit/Debit Card',
          'Pay securely with your card',
          Icons.credit_card,
        ),
        const SizedBox(height: 12),
        _buildWalletPaymentMethodOption(theme),
        const SizedBox(height: 12),
        _buildPaymentMethodOption(
          theme,
          'cash',
          'Cash on Delivery',
          'Pay with cash when order arrives',
          Icons.money,
        ),
        if (_selectedPaymentMethod == 'card') ...[
          const SizedBox(height: 16),
          _buildCardDetailsSection(theme),
        ],
        if (_selectedPaymentMethod == 'wallet') ...[
          const SizedBox(height: 16),
          _buildWalletDetailsSection(theme),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodOption(
    ThemeData theme,
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPaymentMethod(value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected 
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: value,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) => _selectPaymentMethod(value!),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetailsSection(ThemeData theme) {
    _logger.debug('🔍 [PAYMENT-METHOD-UI] Building card details section - useSavedPaymentMethod: $_useSavedPaymentMethod, selectedSavedPaymentMethod: ${_selectedSavedPaymentMethod?.displayName ?? 'null'}');

    // Log the decision path
    if (_useSavedPaymentMethod && _selectedSavedPaymentMethod != null) {
      _logger.debug('✅ [PAYMENT-METHOD-UI] Will show saved payment method card');
    } else {
      _logger.debug('🔄 [PAYMENT-METHOD-UI] Will show Stripe CardField for manual entry');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Show saved payment methods if available
          if (_useSavedPaymentMethod && _selectedSavedPaymentMethod != null) ...[
            _buildSavedPaymentMethodCard(theme),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _logger.debug('🔄 [PAYMENT-METHOD-UI] User chose to use different card');
                setState(() {
                  _useSavedPaymentMethod = false;
                  _selectedSavedPaymentMethod = null;
                });
              },
              icon: const Icon(Icons.add_card),
              label: const Text('Use different card'),
            ),
          ] else ...[
            // Show Stripe CardField for new card entry
            stripe.CardField(
              onCardChanged: (card) {
                // Card details are handled by Stripe internally
                _validatePayment();
              },
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedSavedPaymentMethod != null) ...[
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _useSavedPaymentMethod = true;
                  });
                },
                icon: const Icon(Icons.credit_card),
                label: Text('Use saved card (${_selectedSavedPaymentMethod!.displayName})'),
              ),
              const SizedBox(height: 8),
            ],
            // Button to select from saved payment methods
            TextButton.icon(
              onPressed: () => _showSavedPaymentMethodSelection(),
              icon: const Icon(Icons.credit_card),
              label: const Text('Choose from saved cards'),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              Icon(
                Icons.security,
                size: 16,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'Your payment information is secure and encrypted',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentMethodCard(ThemeData theme) {
    final paymentMethod = _selectedSavedPaymentMethod!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.credit_card,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentMethod.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (paymentMethod.cardLast4 != null) ...[
                  Text(
                    '•••• •••• •••• ${paymentMethod.cardLast4}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (paymentMethod.cardExpMonth != null && paymentMethod.cardExpYear != null) ...[
                  Text(
                    'Expires ${paymentMethod.cardExpMonth!.toString().padLeft(2, '0')}/${paymentMethod.cardExpYear! % 100}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Code',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _promoCodeController,
                hintText: 'Enter promo code',
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isApplyingPromoCode ? null : _applyPromoCode,
                child: _isApplyingPromoCode
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ),
          ],
        ),
        if (_discount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Promo code applied! You saved RM ${_discount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _removePromoCode,
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      color: theme.colorScheme.tertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoyaltyPointsSection(ThemeData theme) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final cartState = ref.watch(enhancedCartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loyalty Points',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.stars, color: Colors.amber.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Points',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${loyaltyState.availablePoints} points (RM ${(loyaltyState.availablePoints * 0.01).toStringAsFixed(2)} value)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (loyaltyState.availablePoints > 0) ...[
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _usePoints,
                          onChanged: (value) {
                            setState(() {
                              _usePoints = value ?? false;
                              if (_usePoints) {
                                // Calculate maximum points that can be used (up to order total)
                                final orderTotal = cartState.subtotal + cartState.deliveryFee + cartState.sstAmount - _discount;
                                final maxPointsValue = orderTotal;
                                final maxPoints = (maxPointsValue / 0.01).floor();
                                _pointsToUse = math.min(loyaltyState.availablePoints, maxPoints);
                              } else {
                                _pointsToUse = 0;
                              }
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use loyalty points for this order',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Save money with your earned points!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_usePoints) ...[
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select points to use:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _pointsToUse.toDouble(),
                                  min: 0,
                                  max: math.min(
                                    loyaltyState.availablePoints.toDouble(),
                                    ((cartState.subtotal + cartState.deliveryFee + cartState.sstAmount - _discount) / 0.01).floor().toDouble(),
                                  ),
                                  divisions: math.min(loyaltyState.availablePoints, ((cartState.subtotal + cartState.deliveryFee + cartState.sstAmount - _discount) / 0.01).floor()),
                                  onChanged: (value) {
                                    setState(() {
                                      _pointsToUse = value.round();
                                    });
                                  },
                                  activeColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Using $_pointsToUse points',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Save RM ${(_pointsToUse * 0.01).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No points available',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                'Earn 1 point for every RM spent on orders!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme, dynamic cartState) {
    final subtotal = cartState.subtotal;
    final deliveryFee = cartState.deliveryFee;
    final sstAmount = cartState.sstAmount;
    final loyaltyDiscount = _pointsToUse * 0.01;
    final totalAmount = subtotal + deliveryFee + sstAmount - _discount - loyaltyDiscount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(theme, 'Subtotal', 'RM ${subtotal.toStringAsFixed(2)}'),
          _buildSummaryRow(theme, 'Delivery Fee', deliveryFee > 0 ? 'RM ${deliveryFee.toStringAsFixed(2)}' : 'FREE'),
          _buildSummaryRow(theme, 'SST (6%)', 'RM ${sstAmount.toStringAsFixed(2)}'),
          if (_discount > 0)
            _buildSummaryRow(theme, 'Discount', '-RM ${_discount.toStringAsFixed(2)}', isDiscount: true),
          if (loyaltyDiscount > 0)
            _buildSummaryRow(theme, 'Loyalty Points ($_pointsToUse pts)', '-RM ${loyaltyDiscount.toStringAsFixed(2)}', isDiscount: true),
          const Divider(),
          _buildSummaryRow(
            theme,
            'Total Amount',
            'RM ${totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: isTotal
                  ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : isDiscount
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
          ),
        ],
      ),
    );
  }

  void _selectPaymentMethod(String method) {
    _logger.info('💳 [PAYMENT-METHOD] Selected method: $method');

    setState(() {
      _selectedPaymentMethod = method;

      // If selecting card method and we have a saved payment method, use it
      if (method == 'card') {
        final defaults = ref.read(checkoutDefaultsProvider);
        if (defaults.hasPaymentMethod && defaults.defaultPaymentMethod != null) {
          _logger.debug('🔄 [PAYMENT-METHOD] Auto-selecting saved payment method for card selection');
          _selectedSavedPaymentMethod = defaults.defaultPaymentMethod;
          _useSavedPaymentMethod = true;
        }
      } else {
        // For non-card methods, clear saved payment method state
        _useSavedPaymentMethod = false;
        _selectedSavedPaymentMethod = null;
      }
    });

    ref.read(checkoutFlowProvider.notifier).setPaymentMethod(method);
    _validatePayment();
  }

  void _validatePayment() {
    // Payment validation is handled by the checkout flow provider
    // This triggers revalidation
    ref.read(checkoutFlowProvider.notifier).setPaymentMethod(_selectedPaymentMethod);
  }

  /// Show saved payment method selection dialog
  Future<void> _showSavedPaymentMethodSelection() async {
    try {
      _logger.info('💳 [PAYMENT-METHOD] Showing saved payment method selection');

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
        builder: (context) => _SavedPaymentMethodSelectionDialog(
          paymentMethods: paymentMethods,
          currentSelection: _selectedSavedPaymentMethod,
        ),
      );

      if (selectedMethod != null) {
        setState(() {
          _selectedSavedPaymentMethod = selectedMethod;
          _useSavedPaymentMethod = true;
        });

        _logger.info('✅ [PAYMENT-METHOD] Selected saved payment method: ${selectedMethod.displayName}');
      }

    } catch (e, stack) {
      _logger.error('❌ [PAYMENT-METHOD] Error showing saved payment method selection', e, stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load saved payment methods'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyPromoCode() async {
    final promoCode = _promoCodeController.text.trim();
    if (promoCode.isEmpty) return;

    setState(() {
      _isApplyingPromoCode = true;
    });

    try {
      _logger.info('🎫 [PAYMENT-METHOD] Applying promo code: $promoCode');
      
      // Simulate promo code validation
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock discount calculation
      if (promoCode.toUpperCase() == 'SAVE10') {
        setState(() {
          _discount = 10.0;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promo code applied successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid promo code')),
          );
        }
      }
    } catch (e) {
      _logger.error('❌ [PAYMENT-METHOD] Failed to apply promo code', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to apply promo code')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingPromoCode = false;
        });
      }
    }
  }

  void _removePromoCode() {
    _logger.info('🗑️ [PAYMENT-METHOD] Removing promo code');
    
    setState(() {
      _discount = 0.0;
      _promoCodeController.clear();
    });
  }

  /// Build wallet payment method option with balance display
  Widget _buildWalletPaymentMethodOption(ThemeData theme) {
    final walletState = ref.watch(customerWalletProvider);
    final isSelected = _selectedPaymentMethod == 'wallet';

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPaymentMethod('wallet'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Wallet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (walletState.isLoading)
                        Text(
                          'Loading balance...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else if (walletState.hasError)
                        Text(
                          'Error loading balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        )
                      else if (walletState.wallet != null)
                        Text(
                          'Balance: RM ${walletState.wallet!.availableBalance.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: 'wallet',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) => _selectPaymentMethod(value!),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build wallet details section when wallet is selected
  Widget _buildWalletDetailsSection(ThemeData theme) {
    final validationState = ref.watch(walletValidationProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Payment Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Show wallet balance card
          CustomerWalletBalanceCard(),

          const SizedBox(height: 12),

          // Show validation results
          if (validationState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (validationState.hasError)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      validationState.error ?? 'Validation failed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (validationState.paymentOptions != null)
            _buildPaymentOptionsDisplay(theme, validationState.paymentOptions!),
        ],
      ),
    );
  }

  /// Build payment options display
  Widget _buildPaymentOptionsDisplay(ThemeData theme, dynamic paymentOptions) {
    // TODO: Implement payment options display based on validation results
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Options Available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your wallet payment has been validated successfully.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for selecting saved payment methods
class _SavedPaymentMethodSelectionDialog extends StatelessWidget {
  final List<CustomerPaymentMethod> paymentMethods;
  final CustomerPaymentMethod? currentSelection;

  const _SavedPaymentMethodSelectionDialog({
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
                    Icons.credit_card,
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
}
