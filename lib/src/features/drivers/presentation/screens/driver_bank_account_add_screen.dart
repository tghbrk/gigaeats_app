import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../providers/driver_wallet_provider.dart';
import '../widgets/verification/bank_account_form.dart';

/// Screen for adding a new bank account for withdrawals
class DriverBankAccountAddScreen extends ConsumerStatefulWidget {
  const DriverBankAccountAddScreen({super.key});

  @override
  ConsumerState<DriverBankAccountAddScreen> createState() => _DriverBankAccountAddScreenState();
}

class _DriverBankAccountAddScreenState extends ConsumerState<DriverBankAccountAddScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🏦 [BANK-ADD-SCREEN] DriverBankAccountAddScreen initialized');
    debugPrint('🏦 [BANK-ADD-SCREEN] This is the standalone bank account add screen with green AppBar');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: _buildAppBar(theme),
        body: _buildBody(theme, walletState),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Add Bank Account'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent, // Disable Material 3 surface tinting
      shadowColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        color: Colors.white,
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildBody(ThemeData theme, dynamic walletState) {
    if (walletState.isLoading) {
      return const Center(
        child: LoadingWidget(message: 'Loading wallet information...'),
      );
    }

    if (walletState.errorMessage != null) {
      return CustomErrorWidget(
        message: walletState.errorMessage!,
        onRetry: () => ref.refresh(driverWalletProvider),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Bank Account Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your bank account details for verification. We\'ll send small deposits to verify ownership.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Bank account form
          BankAccountForm(
            onSubmit: _handleBankAccountSubmit,
            isLoading: _isSubmitting,
          ),

          const SizedBox(height: 32),

          // Security notice
          _buildSecurityNotice(theme),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Security & Privacy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSecurityPoint(
            theme,
            'Your bank details are encrypted and stored securely',
          ),
          _buildSecurityPoint(
            theme,
            'We only send deposits of RM 0.01 - RM 0.99',
          ),
          _buildSecurityPoint(
            theme,
            'Verification typically takes 1-2 business days',
          ),
          _buildSecurityPoint(
            theme,
            'Your information is never shared with third parties',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBankAccountSubmit(Map<String, String> bankDetails) async {
    debugPrint('🏦 [BANK-ADD] Submitting bank account details');
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Add bank account through wallet provider
      final success = await ref.read(driverWalletProvider.notifier).addBankAccount(
        bankCode: bankDetails['bankCode']!,
        accountNumber: bankDetails['accountNumber']!,
        accountHolderName: bankDetails['accountHolderName']!,
        icNumber: bankDetails['icNumber'],
      );

      if (success && mounted) {
        debugPrint('✅ [BANK-ADD] Bank account added successfully');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bank account added successfully! Verification will begin shortly.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to withdrawal screen or wallet dashboard
        context.pop();
      }
    } catch (error) {
      debugPrint('❌ [BANK-ADD] Error adding bank account: $error');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bank account: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
