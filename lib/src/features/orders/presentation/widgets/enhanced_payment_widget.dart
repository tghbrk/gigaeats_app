import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../providers/enhanced_payment_provider.dart';

import '../../data/models/enhanced_payment_models.dart';
import '../../../core/utils/logger.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// Enhanced payment widget with Stripe CardField and wallet integration
class EnhancedPaymentWidget extends ConsumerStatefulWidget {
  final double amount;
  final String currency;
  final String? orderId;
  final ValueChanged<PaymentMethodSelection> onPaymentMethodChanged;
  final VoidCallback? onPaymentSuccess;
  final ValueChanged<String>? onPaymentError;
  final bool showWalletOption;
  final bool showSavedCards;

  const EnhancedPaymentWidget({
    super.key,
    required this.amount,
    this.currency = 'MYR',
    this.orderId,
    required this.onPaymentMethodChanged,
    this.onPaymentSuccess,
    this.onPaymentError,
    this.showWalletOption = true,
    this.showSavedCards = true,
  });

  @override
  ConsumerState<EnhancedPaymentWidget> createState() => _EnhancedPaymentWidgetState();
}

class _EnhancedPaymentWidgetState extends ConsumerState<EnhancedPaymentWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  PaymentMethodType _selectedType = PaymentMethodType.card;
  stripe.CardFieldInputDetails? _cardDetails;
  final bool _isProcessing = false;
  String? _errorMessage;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Load payment methods and wallet balance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enhancedPaymentProvider.notifier).loadPaymentMethods();
      if (widget.showWalletOption) {
        ref.read(enhancedPaymentProvider.notifier).loadWalletBalance();
      }
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentState = ref.watch(enhancedPaymentProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildPaymentMethodTabs(theme),
                  const SizedBox(height: 16),
                  _buildPaymentMethodContent(theme, paymentState),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(theme),
                  ],
                  const SizedBox(height: 16),
                  _buildPaymentSummary(theme),
                ],
              ),
            ),
            if (_isProcessing)
              const SimpleLoadingOverlay(
                message: 'Processing payment...',
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.payment,
            size: 20,
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Choose how you\'d like to pay',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTabs(ThemeData theme) {
    final tabs = <PaymentMethodType, String>{
      PaymentMethodType.card: 'Card',
      if (widget.showWalletOption) PaymentMethodType.wallet: 'Wallet',
      PaymentMethodType.cash: 'Cash',
    };

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.entries.map((entry) {
          final isSelected = _selectedType == entry.key;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectPaymentType(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected 
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethodContent(ThemeData theme, EnhancedPaymentState paymentState) {
    switch (_selectedType) {
      case PaymentMethodType.card:
        return _buildCardPaymentSection(theme, paymentState);
      case PaymentMethodType.wallet:
        return _buildWalletPaymentSection(theme, paymentState);
      case PaymentMethodType.cash:
        return _buildCashPaymentSection(theme);
    }
  }

  Widget _buildCardPaymentSection(ThemeData theme, EnhancedPaymentState paymentState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSavedCards && paymentState.savedCards.isNotEmpty) ...[
          Text(
            'Saved Cards',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...paymentState.savedCards.map((card) => _buildSavedCardOption(theme, card)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
        Text(
          'New Card',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: stripe.CardField(
            onCardChanged: (card) {
              setState(() {
                _cardDetails = card;
                _errorMessage = null;
              });
              _notifyPaymentMethodChange();
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
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.security,
              size: 16,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Your payment information is secure and encrypted',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavedCardOption(ThemeData theme, SavedPaymentMethod card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            _getCardIcon(card.brand),
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          '**** **** **** ${card.last4}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${card.brand.toUpperCase()} • Expires ${card.expiryMonth}/${card.expiryYear}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Radio<String>(
          value: card.id,
          groupValue: null, // TODO: Implement saved card selection
          onChanged: (value) {
            // TODO: Handle saved card selection
          },
        ),
      ),
    );
  }

  Widget _buildWalletPaymentSection(ThemeData theme, EnhancedPaymentState paymentState) {
    final walletBalance = paymentState.walletBalance;
    final canPayWithWallet = walletBalance != null && walletBalance >= widget.amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: canPayWithWallet
                ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canPayWithWallet
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                  : theme.colorScheme.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: canPayWithWallet 
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: canPayWithWallet 
                      ? theme.colorScheme.onTertiary
                      : theme.colorScheme.onError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Balance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      walletBalance != null 
                          ? 'RM ${walletBalance.toStringAsFixed(2)}'
                          : 'Loading...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: canPayWithWallet 
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (canPayWithWallet)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.tertiary,
                  size: 24,
                )
              else
                Icon(
                  Icons.error,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
            ],
          ),
        ),
        if (!canPayWithWallet && walletBalance != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Insufficient wallet balance. You need RM ${(widget.amount - walletBalance).toStringAsFixed(2)} more.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _topUpWallet(),
            icon: const Icon(Icons.add),
            label: const Text('Top Up Wallet'),
          ),
        ],
      ],
    );
  }

  Widget _buildCashPaymentSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
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
              Icons.money,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Pay with cash when your order arrives',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.tertiary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            'Total Amount:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  void _selectPaymentType(PaymentMethodType type) {
    setState(() {
      _selectedType = type;
      _errorMessage = null;
    });
    
    _notifyPaymentMethodChange();
    _logger.info('💳 [PAYMENT-WIDGET] Selected payment type: ${type.name}');
  }

  void _notifyPaymentMethodChange() {
    final selection = PaymentMethodSelection(
      type: _selectedType,
      cardDetails: _cardDetails,
      isValid: _isPaymentMethodValid(),
    );
    
    widget.onPaymentMethodChanged(selection);
  }

  bool _isPaymentMethodValid() {
    switch (_selectedType) {
      case PaymentMethodType.card:
        return _cardDetails?.complete == true;
      case PaymentMethodType.wallet:
        final walletBalance = ref.read(enhancedPaymentProvider).walletBalance;
        return walletBalance != null && walletBalance >= widget.amount;
      case PaymentMethodType.cash:
        return true;
    }
  }

  void _topUpWallet() {
    _logger.info('💰 [PAYMENT-WIDGET] Opening wallet top-up');
    // TODO: Navigate to wallet top-up screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet top-up coming soon')),
    );
  }
}

/// Payment method selection data
class PaymentMethodSelection {
  final PaymentMethodType type;
  final stripe.CardFieldInputDetails? cardDetails;
  final String? savedCardId;
  final bool isValid;

  const PaymentMethodSelection({
    required this.type,
    this.cardDetails,
    this.savedCardId,
    required this.isValid,
  });
}

/// Payment method types
enum PaymentMethodType {
  card,
  wallet,
  cash,
}
