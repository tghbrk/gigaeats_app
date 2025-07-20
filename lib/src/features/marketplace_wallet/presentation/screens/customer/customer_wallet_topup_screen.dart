import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/customer_payment_method.dart';
import '../../providers/customer_wallet_provider.dart';
import '../../providers/customer_wallet_topup_provider.dart';
import '../../providers/customer_payment_methods_provider.dart';
import '../../widgets/payment_method_card.dart';

class CustomerWalletTopupScreen extends ConsumerStatefulWidget {
  const CustomerWalletTopupScreen({super.key});

  @override
  ConsumerState<CustomerWalletTopupScreen> createState() => _CustomerWalletTopupScreenState();
}

class _CustomerWalletTopupScreenState extends ConsumerState<CustomerWalletTopupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  stripe.CardFieldInputDetails? _cardDetails;
  bool _savePaymentMethod = false;
  bool _isProcessing = false;

  // Payment method selection
  CustomerPaymentMethod? _selectedSavedPaymentMethod;
  bool _useNewCard = true;

  // CardField lifecycle management
  bool _cardFieldMounted = false;

  // Enhanced quick amount options with more variety
  final List<double> _quickAmounts = [5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0];

  // Popular amounts based on user behavior
  final List<double> _popularAmounts = [25.0, 75.0, 150.0, 300.0];

  // Suggested amounts based on current balance
  List<double> _getSuggestedAmounts(double currentBalance) {
    if (currentBalance < 10) {
      return [10.0, 25.0, 50.0];
    } else if (currentBalance < 50) {
      return [20.0, 50.0, 100.0];
    } else if (currentBalance < 100) {
      return [50.0, 100.0, 200.0];
    } else {
      return [100.0, 200.0, 500.0];
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-selection logic is handled in _buildSavedPaymentMethodSelection

    // Initialize CardField after a brief delay to ensure proper platform view setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _cardFieldMounted = true;
        });
        debugPrint('✅ [WALLET-TOPUP] CardField initialized and mounted');
      }
    });
  }

  @override
  void dispose() {
    debugPrint('🔧 [WALLET-TOPUP] Disposing screen and cleaning up CardField');

    // Mark CardField as unmounted to prevent platform view conflicts
    _cardFieldMounted = false;

    _amountController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(customerWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Disable Material 3 surface tinting
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Balance Card
              _buildCurrentBalanceCard(context, walletState),
              const SizedBox(height: 24),

              // Amount Selection Section
              _buildAmountSelectionSection(context),
              const SizedBox(height: 24),

              // Payment Method Section
              _buildPaymentMethodSection(context),
              const SizedBox(height: 24),

              // Payment Options
              _buildPaymentOptionsSection(context),
              const SizedBox(height: 32),

              // Top Up Button
              _buildTopUpButton(context),
              const SizedBox(height: 16),

              // Terms and Conditions
              _buildTermsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalanceCard(BuildContext context, CustomerWalletState walletState) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  walletState.formattedBalance,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelectionSection(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);
    final currentBalance = walletState.wallet?.availableBalance ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Amount',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Suggested amounts based on current balance
        if (currentBalance > 0) ...[
          Text(
            'Suggested for you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getSuggestedAmounts(currentBalance).map((amount) {
              return _buildQuickAmountChip(context, amount, isHighlighted: true);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Popular amounts
        Text(
          'Popular amounts',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularAmounts.map((amount) {
            return _buildQuickAmountChip(context, amount);
          }).toList(),
        ),
        const SizedBox(height: 16),

        // All quick amounts
        Text(
          'Quick amounts',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amount) {
            return _buildQuickAmountChip(context, amount);
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom Amount Input
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Custom Amount',
            hintText: 'Enter amount (RM)',
            prefixText: 'RM ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _amountController.clear(),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid amount';
            }
            if (amount < 10) {
              return 'Minimum top-up amount is RM 10.00';
            }
            if (amount > 10000) {
              return 'Maximum top-up amount is RM 10,000.00';
            }
            // Check for reasonable decimal places (max 2)
            final decimalPlaces = value.split('.').length > 1 ? value.split('.')[1].length : 0;
            if (decimalPlaces > 2) {
              return 'Amount can have maximum 2 decimal places';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(BuildContext context, double amount, {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    final isSelected = _amountController.text == amount.toStringAsFixed(0);

    return FilterChip(
      label: Text('RM ${amount.toStringAsFixed(0)}'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _amountController.text = amount.toStringAsFixed(0);
          debugPrint('🔍 [WALLET-TOPUP] Amount selected: RM ${amount.toStringAsFixed(0)}');
        });
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: isHighlighted && !isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.05)
          : null,
      side: isHighlighted && !isSelected
          ? BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3))
          : null,
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.primaryColor
            : isHighlighted
                ? AppTheme.primaryColor.withValues(alpha: 0.8)
                : theme.colorScheme.onSurface,
        fontWeight: isSelected || isHighlighted ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    final theme = Theme.of(context);
    final savedPaymentMethodsAsync = ref.watch(customerValidPaymentMethodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Payment method selection tabs
        savedPaymentMethodsAsync.when(
          data: (savedMethods) {
            if (savedMethods.isNotEmpty) {
              return Column(
                children: [
                  // Tab selection
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _useNewCard = false;
                              debugPrint('🔍 [WALLET-TOPUP] Switched to saved cards tab');
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_useNewCard ? AppTheme.primaryColor : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Saved Cards',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: !_useNewCard ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: !_useNewCard ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _useNewCard = true;
                              debugPrint('🔍 [WALLET-TOPUP] Switched to new card tab');
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _useNewCard ? AppTheme.primaryColor : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                'New Card',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _useNewCard ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: _useNewCard ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content based on selection
                  if (_useNewCard)
                    _buildNewCardInput(context)
                  else
                    _buildSavedPaymentMethodSelection(context, savedMethods),
                ],
              );
            } else {
              // No saved methods, show only new card input
              return _buildNewCardInput(context);
            }
          },
          loading: () => _buildNewCardInput(context),
          error: (error, stackTrace) => _buildNewCardInput(context),
        ),
      ],
    );
  }

  Widget _buildNewCardInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Loading payment form...'),
            ),
          ),
    );
  }

  Widget _buildSavedPaymentMethodSelection(BuildContext context, List<CustomerPaymentMethod> savedMethods) {
    // Auto-select default method if none selected
    if (savedMethods.isNotEmpty && _selectedSavedPaymentMethod == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final defaultMethod = savedMethods.firstWhere(
          (method) => method.isDefault,
          orElse: () => savedMethods.first,
        );
        setState(() {
          _selectedSavedPaymentMethod = defaultMethod;
        });
        debugPrint('🔍 [WALLET-TOPUP] Auto-selected payment method: ${defaultMethod.displayName}');
      });
    }

    return Column(
      children: [
        ...savedMethods.map((method) {
          final isSelected = _selectedSavedPaymentMethod?.id == method.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
            ),
            child: PaymentMethodCard(
              paymentMethod: method,
              onTap: () {
                setState(() {
                  _selectedSavedPaymentMethod = isSelected ? null : method;
                  debugPrint('🔍 [WALLET-TOPUP] Payment method selected: ${method.displayName} (was selected: $isSelected)');
                  debugPrint('🔍 [WALLET-TOPUP] Current selected method: ${_selectedSavedPaymentMethod?.displayName}');
                });
              },
            ),
          );
        }),

        if (savedMethods.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _useNewCard = true),
            icon: const Icon(Icons.add),
            label: const Text('Add New Card'),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOptionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Save Payment Method Option
        CheckboxListTile(
          title: const Text('Save payment method for future use'),
          subtitle: Text(
            'Securely save this card for faster top-ups',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          value: _savePaymentMethod,
          onChanged: (value) {
            setState(() {
              _savePaymentMethod = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  bool _isPaymentMethodValid() {
    if (_useNewCard) {
      final isValid = _cardDetails?.complete == true;
      debugPrint('🔍 [WALLET-TOPUP] New card validation: $isValid (cardDetails: $_cardDetails)');
      return isValid;
    } else {
      final isValid = _selectedSavedPaymentMethod != null;
      debugPrint('🔍 [WALLET-TOPUP] Saved card validation: $isValid (selected: ${_selectedSavedPaymentMethod?.displayName})');
      return isValid;
    }
  }

  Widget _buildTopUpButton(BuildContext context) {
    final theme = Theme.of(context);
    final isPaymentMethodValid = _isPaymentMethodValid();
    final isAmountValid = _amountController.text.isNotEmpty;
    final isFormValid = isPaymentMethodValid && isAmountValid;

    debugPrint('🔍 [WALLET-TOPUP] Button state - Payment valid: $isPaymentMethodValid, Amount valid: $isAmountValid, Form valid: $isFormValid, Processing: $_isProcessing');
    debugPrint('🔍 [WALLET-TOPUP] Amount text: "${_amountController.text}", Use new card: $_useNewCard');

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid && !_isProcessing ? _processTopUp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Top Up ${_amountController.text.isNotEmpty ? 'RM ${_amountController.text}' : 'Wallet'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'By proceeding, you agree to our Terms of Service and Privacy Policy. '
      'All transactions are processed securely through Stripe.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _processTopUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate payment method
    if (!_isPaymentMethodValid()) {
      if (_useNewCard) {
        _showErrorSnackBar('Please enter valid card details');
      } else {
        _showErrorSnackBar('Please select a payment method');
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);

      if (_useNewCard) {
        // Process with new card
        await ref.read(customerWalletTopupProvider.notifier).processTopUp(
          amount: amount,
          savePaymentMethod: _savePaymentMethod,
        );
      } else {
        // Process with saved payment method
        await ref.read(customerWalletTopupProvider.notifier).processTopUpWithSavedMethod(
          amount: amount,
          paymentMethodId: _selectedSavedPaymentMethod!.stripePaymentMethodId,
        );
      }

      // Show success and navigate back
      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Top-up failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(double amount) {
    final topupState = ref.read(customerWalletTopupProvider);
    final transactionId = topupState.lastTransactionId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TopUpReceiptDialog(
        amount: amount,
        transactionId: transactionId,
        paymentMethod: _useNewCard
            ? 'New Card'
            : _selectedSavedPaymentMethod?.displayName ?? 'Saved Card',
        onDone: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to wallet screen
          // Refresh wallet data
          ref.read(customerWalletProvider.notifier).refreshWallet();

          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Wallet topped up successfully with RM ${amount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Receipt dialog for successful wallet top-up
class _TopUpReceiptDialog extends StatelessWidget {
  final double amount;
  final String? transactionId;
  final String paymentMethod;
  final VoidCallback onDone;

  const _TopUpReceiptDialog({
    required this.amount,
    this.transactionId,
    required this.paymentMethod,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Top-up Successful!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 24),

            // Receipt Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Amount', 'RM ${amount.toStringAsFixed(2)}', theme, isAmount: true),
                  const Divider(),
                  _buildReceiptRow('Payment Method', paymentMethod, theme),
                  const Divider(),
                  _buildReceiptRow('Date & Time', _formatDateTime(now), theme),
                  if (transactionId != null) ...[
                    const Divider(),
                    _buildReceiptRow('Transaction ID', transactionId!, theme, isTransactionId: true),
                  ],
                  const Divider(),
                  _buildReceiptRow('Status', 'Completed', theme, isStatus: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReceipt(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, ThemeData theme, {
    bool isAmount = false,
    bool isTransactionId = false,
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                color: isAmount
                    ? AppTheme.primaryColor
                    : isStatus
                        ? AppTheme.successColor
                        : theme.colorScheme.onSurface,
                fontSize: isAmount ? 16 : 14,
              ),
              textAlign: TextAlign.end,
              overflow: isTransactionId ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareReceipt(BuildContext context) {
    // TODO: Implement share functionality
    // Receipt content will include:
    // - Amount: RM ${amount.toStringAsFixed(2)}
    // - Payment Method: $paymentMethod
    // - Date & Time: ${_formatDateTime(DateTime.now())}
    // - Transaction ID: $transactionId
    // - Status: Completed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
