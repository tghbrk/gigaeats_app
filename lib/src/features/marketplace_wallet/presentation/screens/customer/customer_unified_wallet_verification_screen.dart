import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../data/models/user_role.dart';
import '../../../../../shared/widgets/auth_guard.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../shared/widgets/custom_error_widget.dart';
import '../../providers/customer_wallet_provider.dart';
import '../../providers/customer_wallet_verification_provider.dart' as verification;
import '../../widgets/verification/customer_unified_verification_form.dart';

/// Unified customer wallet verification screen that combines all verification methods
class CustomerUnifiedWalletVerificationScreen extends ConsumerStatefulWidget {
  const CustomerUnifiedWalletVerificationScreen({super.key});

  @override
  ConsumerState<CustomerUnifiedWalletVerificationScreen> createState() => 
      _CustomerUnifiedWalletVerificationScreenState();
}

class _CustomerUnifiedWalletVerificationScreenState 
    extends ConsumerState<CustomerUnifiedWalletVerificationScreen> {
  final _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _logger.info('🔍 [CUSTOMER-UNIFIED-VERIFICATION] Screen initialized');
    
    // Load wallet and verification status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerWalletProvider.notifier).loadWallet();
      ref.read(verification.customerWalletVerificationStateProvider.notifier).loadVerificationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);
    final verificationState = ref.watch(verification.customerWalletVerificationStateProvider);

    return AuthGuard(
      allowedRoles: const [UserRole.customer, UserRole.admin],
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
                  _buildVerificationProgress(theme, verificationState),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    size: 32,
                    color: _getStatusColor(status),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(status),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(status),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lastUpdated != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last updated: ${_formatDateTime(lastUpdated)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'unverified') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verification is required to withdraw funds from your wallet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationProgress(ThemeData theme, dynamic verificationState) {
    final currentStep = verificationState.currentStep ?? 1;
    final totalSteps = verificationState.totalSteps ?? 3;
    final progress = currentStep / totalSteps;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verification Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Step $currentStep of $totalSteps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).round()}% Complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
        CustomerUnifiedVerificationForm(
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
                      'This unified process combines bank account verification, identity document verification, and optional instant verification for enhanced security.',
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
    _logger.info('🔄 [CUSTOMER-UNIFIED-VERIFICATION] Refreshing verification data');
    await Future.wait(<Future<void>>[
      ref.read(customerWalletProvider.notifier).loadWallet(),
      ref.read(verification.customerWalletVerificationStateProvider.notifier).loadVerificationStatus(),
    ]);
  }

  Future<void> _handleVerificationSubmit(Map<String, dynamic> verificationData) async {
    _logger.info('🚀 [UNIFIED-VERIFICATION] Starting unified verification submission');
    _logger.debug('🚀 [UNIFIED-VERIFICATION] Received verification data from form');

    // Log detailed verification data (without sensitive info)
    final bankDetails = verificationData['bankDetails'] as Map<String, dynamic>?;
    final documents = verificationData['documents'] as Map<String, dynamic>?;
    final instantVerification = verificationData['instantVerification'] as Map<String, dynamic>?;

    _logger.info('📊 [UNIFIED-VERIFICATION] Bank: ${bankDetails?['bankName']} (${bankDetails?['bankCode']})');
    _logger.info('📊 [UNIFIED-VERIFICATION] Method: ${verificationData['verificationMethod']}');
    _logger.info('📊 [UNIFIED-VERIFICATION] Documents: ${documents != null ? 'IC Front & Back provided' : 'No documents'}');
    _logger.info('📊 [UNIFIED-VERIFICATION] Instant verification: ${instantVerification != null ? 'included' : 'not included'}');

    if (instantVerification != null) {
      _logger.debug('📊 [UNIFIED-VERIFICATION] Instant verification includes IC number and full name');
    }

    try {
      _logger.debug('🔄 [UNIFIED-VERIFICATION] Calling provider startUnifiedVerification method');
      final success = await ref
          .read(verification.customerWalletVerificationStateProvider.notifier)
          .startUnifiedVerification(verificationData);

      _logger.info('✅ [UNIFIED-VERIFICATION] Provider call completed - Success: $success');

      if (success && mounted) {
        _logger.info('✅ [UNIFIED-VERIFICATION] Showing success message to user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification submitted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (!success) {
        _logger.warning('⚠️ [UNIFIED-VERIFICATION] Provider returned false - verification may have failed');
      } else if (!mounted) {
        _logger.warning('⚠️ [UNIFIED-VERIFICATION] Widget not mounted - cannot show success message');
      }
    } catch (e) {
      _logger.error('❌ [UNIFIED-VERIFICATION] Error submitting verification: $e');
      _logger.debug('❌ [UNIFIED-VERIFICATION] Error type: ${e.runtimeType}');

      if (mounted) {
        _logger.info('❌ [UNIFIED-VERIFICATION] Showing error message to user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _logger.warning('❌ [UNIFIED-VERIFICATION] Widget not mounted - cannot show error message');
      }
    }
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
          '• Optional instant verification with IC number\n\n'
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'unverified':
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      case 'unverified':
      default:
        return Icons.shield_outlined;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'verified':
        return 'Wallet Verified';
      case 'pending':
        return 'Verification Pending';
      case 'failed':
        return 'Verification Failed';
      case 'unverified':
      default:
        return 'Wallet Not Verified';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'verified':
        return 'Your wallet is verified and ready for withdrawals.';
      case 'pending':
        return 'Your verification is being processed. This may take 1-3 business days.';
      case 'failed':
        return 'Verification failed. Please try again or contact support.';
      case 'unverified':
      default:
        return 'Complete verification to enable wallet withdrawals.';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
