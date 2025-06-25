import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../../../../core/theme/app_theme.dart';
import '../providers/customer_wallet_provider.dart';
import '../providers/customer_wallet_topup_provider.dart';

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

  // Predefined amounts for quick selection
  final List<double> _quickAmounts = [10.0, 20.0, 50.0, 100.0, 200.0, 500.0];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
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

        // Quick Amount Selection
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
            if (amount < 1) {
              return 'Minimum amount is RM 1.00';
            }
            if (amount > 10000) {
              return 'Maximum amount is RM 10,000.00';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(BuildContext context, double amount) {
    final theme = Theme.of(context);
    final isSelected = _amountController.text == amount.toStringAsFixed(0);

    return FilterChip(
      label: Text('RM ${amount.toStringAsFixed(0)}'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _amountController.text = amount.toStringAsFixed(0);
        });
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    final theme = Theme.of(context);

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

        // Card Input Field
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildTopUpButton(BuildContext context) {
    final theme = Theme.of(context);
    final isFormValid = _cardDetails?.complete == true && 
                       _amountController.text.isNotEmpty;

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
    if (_cardDetails?.complete != true) {
      _showErrorSnackBar('Please enter valid card details');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      
      // Process the top-up using the provider
      await ref.read(customerWalletTopupProvider.notifier).processTopUp(
        amount: amount,
        savePaymentMethod: _savePaymentMethod,
      );

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
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
        title: const Text('Top-up Successful!'),
        content: Text(
          'RM ${amount.toStringAsFixed(2)} has been added to your wallet.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to wallet screen
              // Refresh wallet data
              ref.read(customerWalletProvider.notifier).refreshWallet();
            },
            child: const Text('Done'),
          ),
        ],
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
