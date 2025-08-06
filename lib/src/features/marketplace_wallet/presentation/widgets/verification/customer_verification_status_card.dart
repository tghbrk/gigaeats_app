import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget that displays the current customer wallet verification status with appropriate styling and actions
class CustomerVerificationStatusCard extends StatelessWidget {
  final bool isVerified;
  final String verificationStatus;
  final DateTime? lastUpdated;
  final VoidCallback? onRetry;
  final bool showInstantVerificationInfo;

  const CustomerVerificationStatusCard({
    super.key,
    required this.isVerified,
    required this.verificationStatus,
    this.lastUpdated,
    this.onRetry,
    this.showInstantVerificationInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Last updated info
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
                    'Last updated: ${DateFormat('MMM dd, yyyy \'at\' HH:mm').format(lastUpdated!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],

            // Informational banner for unverified status
            if (verificationStatus == 'unverified') ...[
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

            // Instant verification info banner
            if (showInstantVerificationInfo && verificationStatus == 'unverified') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enable instant verification for faster processing (optional).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (_shouldShowActions()) ...[
              const SizedBox(height: 16),
              _buildActionButtons(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (verificationStatus) {
      case 'verified':
        iconData = Icons.verified;
        iconColor = Colors.green;
        break;
      case 'pending':
        iconData = Icons.hourglass_empty;
        iconColor = Colors.orange;
        break;
      case 'failed':
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case 'unverified':
      default:
        iconData = Icons.shield_outlined;
        iconColor = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        size: 32,
        color: iconColor,
      ),
    );
  }

  String _getStatusTitle() {
    switch (verificationStatus) {
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

  String _getStatusDescription() {
    switch (verificationStatus) {
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

  bool _shouldShowActions() {
    return verificationStatus == 'failed' && onRetry != null;
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        if (verificationStatus == 'failed' && onRetry != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Verification'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
