import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../providers/driver_wallet_provider.dart';
import '../providers/driver_wallet_verification_provider.dart' as verification;
import '../widgets/verification/verification_status_card.dart';
import '../widgets/verification/verification_progress_indicator.dart';
import '../widgets/verification/unified_verification_form.dart';

/// Unified driver wallet verification screen that combines all verification methods
class DriverUnifiedWalletVerificationScreen extends ConsumerStatefulWidget {
  const DriverUnifiedWalletVerificationScreen({super.key});

  @override
  ConsumerState<DriverUnifiedWalletVerificationScreen> createState() => 
      _DriverUnifiedWalletVerificationScreenState();
}

class _DriverUnifiedWalletVerificationScreenState 
    extends ConsumerState<DriverUnifiedWalletVerificationScreen> {
  final _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _logger.info('🔍 [UNIFIED-VERIFICATION] Screen initialized');
    
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
                    stepLabels: const [
                      'Submit Details',
                      'Processing',
                      'Verified',
                    ],
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
      title: const Text('Complete Verification'),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        color: Colors.white,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showVerificationHelp,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildVerificationStatusOverview(
    ThemeData theme,
    dynamic walletState,
    dynamic verificationState,
  ) {
    final status = verificationState.status ?? 'unverified';
    final lastUpdated = verificationState.lastUpdated;

    return VerificationStatusCard(
      isVerified: status == 'verified',
      verificationStatus: status,
      lastUpdated: lastUpdated,
      onRetry: verificationState.canRetry ? _retryVerification : null,
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

    // Show unified verification form
    return _buildUnifiedVerificationContent(theme, verificationState);
  }

  Widget _buildAlreadyVerifiedContent(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.verified,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Wallet Verified',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your wallet has been successfully verified. You can now withdraw funds.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedVerificationContent(ThemeData theme, dynamic verificationState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildVerificationHeader(theme),
        const SizedBox(height: 24),
        
        // Unified verification form
        UnifiedVerificationForm(
          onSubmit: _handleVerificationSubmit,
          isLoading: verificationState.isProcessing,
        ),
      ],
    );
  }

  Widget _buildVerificationHeader(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.security,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Verification',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verify your identity and bank account to enable secure wallet withdrawals',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This process combines bank account verification with identity document verification for enhanced security.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    _logger.info('🔄 [UNIFIED-VERIFICATION] Refreshing verification data');
    await Future.wait(<Future<void>>[
      ref.read(driverWalletProvider.notifier).loadWallet(),
      ref.read(verification.driverWalletVerificationStateProvider.notifier).loadVerificationStatus(),
    ]);
  }

  Future<void> _handleVerificationSubmit(Map<String, dynamic> verificationData) async {
    _logger.info('🚀 [UNIFIED-VERIFICATION] Starting unified verification');
    _logger.info('📊 [UNIFIED-VERIFICATION] Bank: ${verificationData['bankDetails']['bankName']}');
    _logger.info('📊 [UNIFIED-VERIFICATION] Method: ${verificationData['verificationMethod']}');

    try {
      // TODO: Implement unified verification service call
      // This will be implemented in the next task
      final success = await ref
          .read(verification.driverWalletVerificationStateProvider.notifier)
          .startUnifiedVerification(verificationData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification submitted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _logger.error('❌ [UNIFIED-VERIFICATION] Error submitting verification', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _retryVerification() {
    _logger.info('🔄 [UNIFIED-VERIFICATION] Retrying verification');
    ref.read(verification.driverWalletVerificationStateProvider.notifier).retryVerification();
  }

  void _showVerificationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Help'),
        content: const Text(
          'Complete verification requires:\n\n'
          '• Bank account details (for secure withdrawals)\n'
          '• Malaysian IC photos (front and back)\n'
          '• Agreement to terms and conditions\n\n'
          'This unified process ensures maximum security for your wallet transactions.',
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
