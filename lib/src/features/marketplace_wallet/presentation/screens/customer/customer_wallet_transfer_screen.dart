import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../providers/customer_wallet_provider.dart';
import '../../providers/customer_wallet_transfer_provider.dart';
import '../../widgets/customer_wallet_error_widget.dart';
import '../../../data/models/customer_wallet_error.dart';

class CustomerWalletTransferScreen extends ConsumerStatefulWidget {
  const CustomerWalletTransferScreen({super.key});

  @override
  ConsumerState<CustomerWalletTransferScreen> createState() => _CustomerWalletTransferScreenState();
}

class _CustomerWalletTransferScreenState extends ConsumerState<CustomerWalletTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isProcessing = false;
  String? _recipientError;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(customerWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Money'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => context.pop(),
        ),
      ),
      body: walletState.isLoading
          ? const LoadingWidget()
          : walletState.hasError
              ? CustomerWalletErrorWidget(
                  error: walletState.error ?? CustomerWalletError.fromMessage(walletState.errorMessage ?? 'Unknown error'),
                  onRetry: () => ref.read(customerWalletProvider.notifier).refreshWallet(),
                )
              : _buildTransferForm(context, walletState.wallet),
    );
  }

  Widget _buildTransferForm(BuildContext context, wallet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Balance Card
            _buildAvailableBalanceCard(context, wallet),
            const SizedBox(height: 24),

            // Recipient Section
            _buildRecipientSection(context),
            const SizedBox(height: 24),

            // Amount Section
            _buildAmountSection(context, wallet),
            const SizedBox(height: 24),

            // Note Section
            _buildNoteSection(context),
            const SizedBox(height: 32),

            // Transfer Button
            _buildTransferButton(context, wallet),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBalanceCard(BuildContext context, wallet) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              wallet?.formattedAvailableBalance ?? 'RM 0.00',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _recipientController,
          decoration: InputDecoration(
            labelText: 'Email or Phone Number',
            hintText: 'Enter recipient\'s email or phone',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            errorText: _recipientError,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter recipient information';
            }
            
            // Basic email or phone validation
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
            final phoneRegex = RegExp(r'^\+?[\d\s-()]+$');
            
            if (!emailRegex.hasMatch(value) && !phoneRegex.hasMatch(value)) {
              return 'Please enter a valid email or phone number';
            }
            
            return null;
          },
          onChanged: (value) {
            if (_recipientError != null) {
              setState(() => _recipientError = null);
            }
          },
        ),
        
        const SizedBox(height: 12),
        
        // Quick recipient suggestions (if any)
        _buildQuickRecipients(context),
      ],
    );
  }

  Widget _buildQuickRecipients(BuildContext context) {
    // For now, show placeholder for recent recipients
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            'Recent recipients will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context, wallet) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Transfer Amount',
            hintText: '0.00',
            prefixText: 'RM ',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: TextButton(
              onPressed: () {
                final availableBalance = wallet?.availableBalance ?? 0.0;
                _amountController.text = availableBalance.toStringAsFixed(2);
              },
              child: const Text('MAX'),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an amount';
            }
            
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            
            final availableBalance = wallet?.availableBalance ?? 0.0;
            if (amount > availableBalance) {
              return 'Insufficient balance';
            }
            
            if (amount < 1.0) {
              return 'Minimum transfer amount is RM 1.00';
            }
            
            return null;
          },
        ),
        
        const SizedBox(height: 12),
        
        // Quick amount buttons
        _buildQuickAmountButtons(context),
      ],
    );
  }

  Widget _buildQuickAmountButtons(BuildContext context) {
    final quickAmounts = [10.0, 20.0, 50.0, 100.0];
    
    return Wrap(
      spacing: 8,
      children: quickAmounts.map((amount) => 
        OutlinedButton(
          onPressed: () {
            _amountController.text = amount.toStringAsFixed(2);
          },
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text('RM ${amount.toStringAsFixed(0)}'),
        ),
      ).toList(),
    );
  }

  Widget _buildNoteSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (Optional)',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: 'Add a note',
            hintText: 'What\'s this transfer for?',
            prefixIcon: const Icon(Icons.note_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
          maxLength: 200,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildTransferButton(BuildContext context, wallet) {
    final theme = Theme.of(context);
    final isFormValid = _recipientController.text.isNotEmpty && 
                       _amountController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid && !_isProcessing ? _processTransfer : null,
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
                'Transfer ${_amountController.text.isNotEmpty ? 'RM ${_amountController.text}' : 'Money'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _processTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final recipient = _recipientController.text.trim();
    final note = _noteController.text.trim();

    // Show confirmation dialog first
    final confirmed = await _showTransferConfirmationDialog(amount, recipient, note);
    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      // Process the transfer using the provider
      await ref.read(customerWalletTransferProvider.notifier).processTransfer(
        recipientIdentifier: recipient,
        amount: amount,
        note: note.isNotEmpty ? note : null,
      );

      // Show success and navigate back
      if (mounted) {
        _showSuccessDialog(amount, recipient);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Transfer failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _showTransferConfirmationDialog(double amount, String recipient, String note) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.send_rounded,
          color: AppTheme.primaryColor,
          size: 48,
        ),
        title: const Text('Confirm Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please confirm the transfer details:'),
            const SizedBox(height: 16),
            _buildConfirmationRow('Amount:', 'RM ${amount.toStringAsFixed(2)}'),
            _buildConfirmationRow('To:', recipient),
            if (note.isNotEmpty) _buildConfirmationRow('Note:', note),
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
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This transfer cannot be undone. Please verify the recipient details.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Transfer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(double amount, String recipient) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Transfer Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RM ${amount.toStringAsFixed(2)} has been transferred to $recipient successfully.',
            ),
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
                  Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your wallet balance has been updated. The recipient will be notified.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
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
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Go back to wallet screen

              // Refresh wallet data
              ref.read(customerWalletProvider.notifier).refreshWallet();

              // Show success snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Transfer completed successfully'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Done'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.push('/customer/wallet/transfer-history'); // Navigate to transfer history
            },
            child: const Text('View History'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
