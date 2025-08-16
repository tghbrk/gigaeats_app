import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../providers/driver_wallet_provider.dart';
import '../providers/driver_wallet_verification_provider.dart' as verification;
import '../widgets/verification/verification_status_card.dart';
import '../widgets/verification/unified_verification_method_selector.dart';
import '../widgets/verification/verification_progress_indicator.dart';

/// Driver wallet verification screen that guides drivers through the verification process
class DriverWalletVerificationScreen extends ConsumerStatefulWidget {
  const DriverWalletVerificationScreen({super.key});

  @override
  ConsumerState<DriverWalletVerificationScreen> createState() => _DriverWalletVerificationScreenState();
}

class _DriverWalletVerificationScreenState extends ConsumerState<DriverWalletVerificationScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [WALLET-VERIFICATION] Screen initialized');
    
    // Load wallet and verification status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverWalletProvider.notifier).loadWallet();
      ref.read(verification.driverWalletVerificationStateProvider.notifier).loadVerificationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);
    final verificationState = ref.watch(verification.driverWalletVerificationStateProvider);

    debugPrint('🔍 [WALLET-VERIFICATION] Building screen - walletState: ${walletState.toString()}');
    debugPrint('🔍 [WALLET-VERIFICATION] Building screen - verificationState: ${verificationState.toString()}');
    debugPrint('🔍 [WALLET-VERIFICATION] Wallet loading: ${walletState.isLoading}, error: ${walletState.errorMessage}');
    debugPrint('🔍 [WALLET-VERIFICATION] Verification loading: ${verificationState.isLoading}, error: ${verificationState.error}');

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verification Status Overview
                _buildVerificationStatusOverview(theme, walletState, verificationState),
                const SizedBox(height: 24),

                // Verification Progress
                if (verificationState.currentStep != null) ...[
                  VerificationProgressIndicator(
                    currentStep: verificationState.currentStep!,
                    totalSteps: verificationState.totalSteps,
                  ),
                  const SizedBox(height: 24),
                ],

                // Main Content based on verification status
                _buildMainContent(theme, walletState, verificationState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Wallet Verification'),
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
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showVerificationHelp(),
          color: Colors.white,
          tooltip: 'Verification Help',
        ),
      ],
    );
  }

  Widget _buildVerificationStatusOverview(
    ThemeData theme,
    dynamic walletState,
    dynamic verificationState,
  ) {
    return VerificationStatusCard(
      isVerified: walletState.wallet?.isVerified ?? false,
      verificationStatus: verificationState.status,
      lastUpdated: verificationState.lastUpdated,
      onRetry: verificationState.canRetry ? () => _retryVerification() : null,
    );
  }

  Widget _buildMainContent(
    ThemeData theme,
    dynamic walletState,
    dynamic verificationState,
  ) {
    // Show loading state
    if (walletState.isLoading || verificationState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: LoadingWidget(message: 'Loading verification status...'),
        ),
      );
    }

    // Show error state
    if (walletState.errorMessage != null || verificationState.error != null) {
      return CustomErrorWidget(
        message: walletState.errorMessage ?? verificationState.error!,
        onRetry: _refreshData,
      );
    }

    // Already verified
    if (walletState.wallet?.isVerified == true) {
      return _buildAlreadyVerifiedContent(theme);
    }

    // Show verification methods
    return _buildVerificationMethodsContent(theme, verificationState);
  }

  Widget _buildAlreadyVerifiedContent(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.verified,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Wallet Verified!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your wallet is fully verified and ready for withdrawals.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/driver/wallet/withdraw'),
                icon: const Icon(Icons.account_balance),
                label: const Text('Make Withdrawal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationMethodsContent(ThemeData theme, dynamic verificationState) {
    return UnifiedVerificationMethodSelector(
      onStartVerification: _startUnifiedVerification,
      isLoading: verificationState.isProcessing,
    );
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 [WALLET-VERIFICATION] Refreshing verification data');
    await Future.wait(<Future<void>>[
      ref.read(driverWalletProvider.notifier).loadWallet(),
      ref.read(verification.driverWalletVerificationStateProvider.notifier).loadVerificationStatus(),
    ]);
  }

  void _startUnifiedVerification() {
    debugPrint('🚀 [WALLET-VERIFICATION] Starting unified verification');
    context.push(AppRoutes.driverWalletVerificationUnified);
  }

  void _retryVerification() {
    debugPrint('🔄 [WALLET-VERIFICATION] Retrying verification');
    ref.read(verification.driverWalletVerificationStateProvider.notifier).retryVerification();
  }

  void _showVerificationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Help'),
        content: const Text(
          'Wallet verification is required to ensure secure withdrawals. '
          'Choose from bank account verification, document upload, or instant verification methods. '
          'This process typically takes 1-3 business days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
