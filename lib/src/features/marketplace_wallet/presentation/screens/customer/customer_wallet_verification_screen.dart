import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../data/models/user_role.dart';
import '../../../../../shared/widgets/auth_guard.dart';

/// Customer wallet verification screen matching the provided screenshot design
class CustomerWalletVerificationScreen extends ConsumerStatefulWidget {
  const CustomerWalletVerificationScreen({super.key});

  @override
  ConsumerState<CustomerWalletVerificationScreen> createState() => _CustomerWalletVerificationScreenState();
}

class _CustomerWalletVerificationScreenState extends ConsumerState<CustomerWalletVerificationScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔐 [CUSTOMER-WALLET-VERIFICATION] Screen initialized');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AuthGuard(
      allowedRoles: const [UserRole.customer, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verification Status Overview
              _buildVerificationStatusCard(theme),
              const SizedBox(height: 24),
              
              // Choose Verification Method Section
              _buildVerificationMethodsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      title: const Text(
        'Wallet Verification',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () => _showHelpDialog(),
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildVerificationStatusCard(ThemeData theme) {
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 32,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Not Verified',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete verification to enable wallet withdrawals.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                  'Last updated: Jul 27, 2025 at 12:32',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
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
        ),
      ),
    );
  }

  Widget _buildVerificationMethodsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Verification Method',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select how you\'d like to verify your wallet for secure withdrawals.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        
        // Bank Account Verification
        _buildVerificationMethodCard(
          theme: theme,
          icon: Icons.account_balance,
          iconColor: Colors.blue,
          title: 'Bank Account',
          subtitle: 'Verify using bank account details',
          duration: '1-2 days',
          badge: 'Most secure',
          badgeColor: Colors.green,
          onTap: () => _startVerification('bank_account'),
        ),
        
        const SizedBox(height: 16),
        
        // Document Upload Verification
        _buildVerificationMethodCard(
          theme: theme,
          icon: Icons.upload_file,
          iconColor: Colors.green,
          title: 'Document Upload',
          subtitle: 'Upload IC and selfie for verification',
          duration: '2-3 days',
          badge: 'Upload required',
          badgeColor: Colors.orange,
          onTap: () => _startVerification('document'),
        ),
        
        const SizedBox(height: 16),
        
        // Instant Verification
        _buildVerificationMethodCard(
          theme: theme,
          icon: Icons.flash_on,
          iconColor: Colors.orange,
          title: 'Instant Verification',
          subtitle: 'Quick verification with IC number',
          duration: 'Instant',
          badge: 'IC required',
          badgeColor: Colors.blue,
          onTap: () => _startVerification('instant'),
        ),
      ],
    );
  }

  Widget _buildVerificationMethodCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String duration,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            duration,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startVerification(String method) {
    debugPrint('🚀 [CUSTOMER-WALLET-VERIFICATION] Starting verification with method: $method');

    switch (method) {
      case 'bank_account':
        // TODO: Navigate to bank account verification
        _showComingSoonDialog('Bank Account Verification');
        break;
      case 'document':
        context.push('/customer/wallet/verification/documents');
        break;
      case 'instant':
        context.push('/customer/wallet/verification/instant');
        break;
      default:
        debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION] Unknown verification method: $method');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Verification Help'),
        content: const Text(
          'Wallet verification is required to enable withdrawals and ensure the security of your funds. '
          'Choose the verification method that works best for you.',
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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
