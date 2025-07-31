import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget that displays the current verification status with appropriate styling and actions
class VerificationStatusCard extends StatelessWidget {
  final bool isVerified;
  final String verificationStatus;
  final DateTime? lastUpdated;
  final VoidCallback? onRetry;

  const VerificationStatusCard({
    super.key,
    required this.isVerified,
    required this.verificationStatus,
    this.lastUpdated,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy \'at\' HH:mm').format(lastUpdated!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
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

  Color _getStatusColor() {
    switch (verificationStatus) {
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

  bool _shouldShowActions() {
    return verificationStatus == 'failed' || verificationStatus == 'unverified';
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (verificationStatus == 'failed' && onRetry != null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry Verification'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
          ),
        ),
      );
    }

    if (verificationStatus == 'unverified') {
      return Column(
        children: [
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
                    'Verification is required to withdraw funds from your wallet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
