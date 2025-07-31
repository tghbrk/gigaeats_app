import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../providers/driver_wallet_provider.dart';
import '../providers/driver_withdrawal_provider.dart';
import '../../data/models/driver_wallet.dart';
import '../widgets/withdrawal/withdrawal_amount_input.dart';
import '../widgets/withdrawal/withdrawal_method_selector.dart';
import '../widgets/withdrawal/bank_account_selector.dart';
import '../widgets/withdrawal/withdrawal_summary_card.dart';
import '../widgets/withdrawal/withdrawal_limits_info.dart';

/// Comprehensive withdrawal request screen with Material Design 3
/// Includes real-time validation, bank account selection, and fraud detection
class DriverWithdrawalRequestScreen extends ConsumerStatefulWidget {
  const DriverWithdrawalRequestScreen({super.key});

  @override
  ConsumerState<DriverWithdrawalRequestScreen> createState() => _DriverWithdrawalRequestScreenState();
}

class _DriverWithdrawalRequestScreenState extends ConsumerState<DriverWithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedMethod = 'bank_transfer';
  String? _selectedBankAccountId;
  bool _isProcessing = false;

  
  @override
  void initState() {
    super.initState();
    // Load withdrawal limits and bank accounts on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverWithdrawalProvider.notifier).loadWithdrawalLimits();
      ref.read(driverWithdrawalProvider.notifier).loadBankAccounts();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);
    final withdrawalState = ref.watch(driverWithdrawalProvider);

    return AuthGuard(
      allowedRoles: const [UserRole.driver],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Withdraw Funds'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showHelpDialog(context),
              tooltip: 'Help',
              color: Colors.white,
            ),
          ],
        ),
        body: _buildBody(context, walletState, withdrawalState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DriverWalletState walletState, dynamic withdrawalState) {
    if (walletState.isLoading) {
      return const LoadingWidget(message: 'Loading wallet information...');
    }

    if (walletState.errorMessage != null) {
      return CustomErrorWidget(
        message: 'Failed to load wallet: ${walletState.errorMessage}',
        onRetry: () => ref.read(driverWalletProvider.notifier).loadWallet(),
      );
    }

    if (walletState.wallet == null) {
      return const Center(
        child: CustomErrorWidget(
          message: 'Wallet not found. Please contact support.',
        ),
      );
    }

    return _buildWithdrawalForm(context, walletState.wallet!, withdrawalState);
  }

  Widget _buildWithdrawalForm(BuildContext context, DriverWallet wallet, dynamic withdrawalState) {
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Balance Summary
              _buildBalanceSummary(context, wallet),
              const SizedBox(height: 24),

              // Withdrawal Limits Information
              WithdrawalLimitsInfo(
                limits: withdrawalState.limits,
                currentUsage: withdrawalState.currentUsage,
              ),
              const SizedBox(height: 24),

              // Amount Input Section
              _buildAmountSection(context, wallet),
              const SizedBox(height: 24),

              // Withdrawal Method Selection
              _buildMethodSection(context),
              const SizedBox(height: 24),

              // Bank Account Selection (if bank transfer)
              if (_selectedMethod == 'bank_transfer') ...[
                _buildBankAccountSection(context, withdrawalState),
                const SizedBox(height: 24),
              ],

              // Advanced Options
              _buildAdvancedOptions(context),
              const SizedBox(height: 24),

              // Withdrawal Summary
              if (_amountController.text.isNotEmpty) ...[
                WithdrawalSummaryCard(
                  amount: double.tryParse(_amountController.text) ?? 0.0,
                  method: _selectedMethod,
                  bankAccountId: _selectedBankAccountId,
                  processingFee: _calculateProcessingFee(),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              _buildSubmitButton(context, wallet, withdrawalState),
              const SizedBox(height: 16),

              // Terms and Conditions
              _buildTermsAndConditions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(BuildContext context, dynamic wallet) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available Balance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'RM ${wallet.availableBalance.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (wallet.pendingBalance > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Pending: RM ${wallet.pendingBalance.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context, dynamic wallet) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawal Amount',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        WithdrawalAmountInput(
          controller: _amountController,
          maxAmount: wallet.availableBalance,
          onChanged: (value) => setState(() {}),
          onQuickAmountSelected: (amount) {
            _amountController.text = amount.toStringAsFixed(2);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildMethodSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawal Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        WithdrawalMethodSelector(
          selectedMethod: _selectedMethod,
          onMethodChanged: (method) {
            setState(() {
              _selectedMethod = method;
              if (method != 'bank_transfer') {
                _selectedBankAccountId = null;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildBankAccountSection(BuildContext context, dynamic withdrawalState) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bank Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push('/driver/wallet/bank-accounts/add'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Account'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BankAccountSelector(
          bankAccounts: withdrawalState.bankAccounts ?? [],
          selectedAccountId: _selectedBankAccountId,
          onAccountSelected: (accountId) {
            setState(() {
              _selectedBankAccountId = accountId;
            });
          },
          isLoading: withdrawalState.isLoading,
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    final theme = Theme.of(context);
    
    return ExpansionTile(
      title: Text(
        'Advanced Options',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: const Icon(Icons.tune),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes (Optional)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Add any notes for this withdrawal...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, dynamic wallet, dynamic withdrawalState) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final isValidAmount = amount >= 10.0 && amount <= wallet.availableBalance;
    final hasSelectedBankAccount = _selectedMethod != 'bank_transfer' || _selectedBankAccountId != null;
    final canSubmit = isValidAmount && hasSelectedBankAccount && !_isProcessing;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSubmit ? _processWithdrawal : null,
        icon: _isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send),
        label: Text(_isProcessing ? 'Processing...' : 'Request Withdrawal'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Important Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Withdrawals are processed within 1-3 business days\n'
              '• Minimum withdrawal amount is RM 10.00\n'
              '• Processing fees may apply based on withdrawal method\n'
              '• Ensure your bank account details are correct\n'
              '• Contact support if you need assistance',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      ref.read(driverWalletProvider.notifier).loadWallet(refresh: true),
      ref.read(driverWithdrawalProvider.notifier).loadWithdrawalLimits(),
      ref.read(driverWithdrawalProvider.notifier).loadBankAccounts(),
    ]);
  }

  double _calculateProcessingFee() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    switch (_selectedMethod) {
      case 'bank_transfer':
        return amount * 0.01; // 1% fee, max RM 5
      case 'ewallet':
        return 0.0; // No fee for e-wallet
      default:
        return 0.0;
    }
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      // Check fraud score first
      final fraudScore = await ref.read(driverWithdrawalProvider.notifier).checkFraudScore(
        amount: amount,
        withdrawalMethod: _selectedMethod,
      );

      if (fraudScore['risk_level'] == 'high') {
        _showFraudWarningDialog(context, fraudScore);
        return;
      }

      // Create withdrawal request
      final requestId = await ref.read(driverWithdrawalProvider.notifier).createWithdrawalRequest(
        amount: amount,
        withdrawalMethod: _selectedMethod,
        bankAccountId: _selectedBankAccountId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        // Show success dialog
        _showSuccessDialog(context, requestId, fraudScore);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String requestId, Map<String, dynamic> fraudScore) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: theme.colorScheme.primary,
          size: 48,
        ),
        title: const Text('Withdrawal Request Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your withdrawal request has been submitted successfully.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request ID: ${requestId.substring(0, 8)}...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amount: RM ${_amountController.text}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Risk Level: ${fraudScore['risk_level']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getRiskLevelColor(theme, fraudScore['risk_level']),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You will be notified when your withdrawal is processed. This usually takes 1-3 business days.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/driver/wallet/withdrawals');
            },
            child: const Text('View Withdrawals'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Withdrawal Failed'),
        content: Text(error),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFraudWarningDialog(BuildContext context, Map<String, dynamic> fraudScore) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning,
          color: theme.colorScheme.error,
          size: 48,
        ),
        title: const Text('High Risk Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This withdrawal request has been flagged as high risk:'),
            const SizedBox(height: 12),
            Text(
              fraudScore['reason'] ?? 'Multiple risk factors detected',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please contact support if you believe this is an error.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/driver/support');
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdrawal Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How to withdraw funds:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Enter the amount you want to withdraw'),
              Text('2. Select your preferred withdrawal method'),
              Text('3. Choose or add a bank account (for bank transfers)'),
              Text('4. Review the details and submit'),
              SizedBox(height: 16),
              Text('Processing times:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Bank Transfer: 1-3 business days'),
              Text('• E-Wallet: Instant to 24 hours'),
              SizedBox(height: 16),
              Text('Need help? Contact our support team.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(ThemeData theme, String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
