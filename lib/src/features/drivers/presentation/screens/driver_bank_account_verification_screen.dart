import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../providers/driver_wallet_verification_provider.dart' as verification;
import '../widgets/verification/bank_account_form.dart';
import '../widgets/verification/micro_deposit_verification_form.dart';
import '../widgets/verification/verification_progress_indicator.dart';

/// Screen for bank account verification process
class DriverBankAccountVerificationScreen extends ConsumerStatefulWidget {
  const DriverBankAccountVerificationScreen({super.key});

  @override
  ConsumerState<DriverBankAccountVerificationScreen> createState() => _DriverBankAccountVerificationScreenState();
}

class _DriverBankAccountVerificationScreenState extends ConsumerState<DriverBankAccountVerificationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    debugPrint('🏦 [BANK-VERIFICATION-SCREEN] DriverBankAccountVerificationScreen initialized');
    debugPrint('🏦 [BANK-VERIFICATION-SCREEN] This is the multi-step verification screen with fixed green AppBar');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verificationState = ref.watch(verification.driverWalletVerificationStateProvider);

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            // Progress indicator
            if (verificationState.currentStep != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: VerificationProgressIndicator(
                  currentStep: verificationState.currentStep!,
                  totalSteps: verificationState.totalSteps,
                  stepLabels: const [
                    'Bank Details',
                    'Micro Deposits',
                    'Verified',
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // Page 1: Bank account details form
                  _buildBankDetailsPage(theme, verificationState),
                  
                  // Page 2: Micro deposit verification
                  _buildMicroDepositPage(theme, verificationState),
                  
                  // Page 3: Success page
                  _buildSuccessPage(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Bank Account Verification'),
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
        onPressed: () {
          if (_currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            context.pop();
          }
        },
        color: Colors.white,
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildBankDetailsPage(ThemeData theme, dynamic verificationState) {
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
            onSubmit: _handleBankDetailsSubmit,
            isLoading: verificationState.isProcessing,
          ),

          const SizedBox(height: 24),

          // Security notice
          _buildSecurityNotice(theme),
        ],
      ),
    );
  }

  Widget _buildMicroDepositPage(ThemeData theme, dynamic verificationState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Verify Micro Deposits',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent two small deposits to your bank account. Enter the amounts to complete verification.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Micro deposit form
          MicroDepositVerificationForm(
            accountId: _accountId ?? '',
            onSubmit: _handleMicroDepositSubmit,
            isLoading: verificationState.isProcessing,
          ),

          const SizedBox(height: 24),

          // Help section
          _buildMicroDepositHelp(theme),
        ],
      ),
    );
  }

  Widget _buildSuccessPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Verification Complete!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your bank account has been successfully verified. You can now withdraw funds from your wallet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/driver/wallet'),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Go to Wallet'),
            ),
          ),
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
          const SizedBox(height: 8),
          Text(
            '• Your bank details are encrypted and stored securely\n'
            '• We only send deposits of RM 0.01 - RM 0.99\n'
            '• Verification typically takes 1-2 business days\n'
            '• Your information is never shared with third parties',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroDepositHelp(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Need Help?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Check your bank statement or mobile banking app\n'
              '• Look for deposits from "GigaEats Verification"\n'
              '• Deposits may take 1-2 business days to appear\n'
              '• Enter amounts in cents (e.g., RM 0.23 = 23)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBankDetailsSubmit(Map<String, String> bankDetails) async {
    debugPrint('🚀 [BANK-VERIFICATION] Submitting bank details');
    
    final success = await ref.read(verification.driverWalletVerificationStateProvider.notifier)
        .startBankAccountVerification(
      bankCode: bankDetails['bankCode']!,
      accountNumber: bankDetails['accountNumber']!,
      accountHolderName: bankDetails['accountHolderName']!,
      icNumber: bankDetails['icNumber'],
    );

    if (success) {
      final verificationData = ref.read(verification.driverWalletVerificationStateProvider).verificationData;
      _accountId = verificationData?['account_id'];
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleMicroDepositSubmit(List<double> amounts) async {
    debugPrint('🔍 [BANK-VERIFICATION] Submitting micro deposit amounts');
    
    if (_accountId == null) {
      debugPrint('❌ [BANK-VERIFICATION] No account ID available');
      return;
    }

    final success = await ref.read(verification.driverWalletVerificationStateProvider.notifier)
        .submitMicroDepositVerification(
      accountId: _accountId!,
      amounts: amounts,
    );

    if (success) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
