import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer_wallet_error.dart';
import '../providers/customer_wallet_provider.dart';

/// Enhanced error display widget for customer wallet errors
class CustomerWalletErrorWidget extends ConsumerWidget {
  final CustomerWalletError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showRetryButton;
  final bool showDismissButton;

  const CustomerWalletErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showRetryButton = true,
    this.showDismissButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canRetry = ref.watch(customerWalletCanRetryProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error header with icon
          Row(
            children: [
              Icon(
                _getErrorIcon(error.type),
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getErrorTitle(error.type),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showDismissButton)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  onPressed: onDismiss ?? () => ref.read(customerWalletProvider.notifier).clearError(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Error message
          Text(
            error.userFriendlyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Suggested action
          Text(
            error.suggestedAction,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),

          // Error timestamp
          if (error.isRecent)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Occurred ${error.formattedTimestamp}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
            ),

          // Action buttons
          if (showRetryButton && error.isRetryable)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!canRetry)
                    Text(
                      'Too many retries. Please wait.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  const Spacer(),
                  if (canRetry) ...[
                    TextButton(
                      onPressed: onRetry ?? () => ref.read(customerWalletProvider.notifier).retryLoadWallet(),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => ref.read(customerWalletProvider.notifier).forceReload(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      child: const Text('Force Reload'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getErrorIcon(CustomerWalletErrorType type) {
    switch (type) {
      case CustomerWalletErrorType.networkError:
        return Icons.wifi_off;
      case CustomerWalletErrorType.authenticationError:
        return Icons.lock_outline;
      case CustomerWalletErrorType.walletNotFound:
        return Icons.account_balance_wallet_outlined;
      case CustomerWalletErrorType.insufficientBalance:
        return Icons.money_off_outlined;
      case CustomerWalletErrorType.transactionFailed:
        return Icons.error_outline;
      case CustomerWalletErrorType.serverError:
        return Icons.cloud_off_outlined;
      case CustomerWalletErrorType.unknownError:
        return Icons.help_outline;
    }
  }

  String _getErrorTitle(CustomerWalletErrorType type) {
    switch (type) {
      case CustomerWalletErrorType.networkError:
        return 'Connection Problem';
      case CustomerWalletErrorType.authenticationError:
        return 'Authentication Required';
      case CustomerWalletErrorType.walletNotFound:
        return 'Wallet Setup';
      case CustomerWalletErrorType.insufficientBalance:
        return 'Insufficient Balance';
      case CustomerWalletErrorType.transactionFailed:
        return 'Transaction Failed';
      case CustomerWalletErrorType.serverError:
        return 'Server Unavailable';
      case CustomerWalletErrorType.unknownError:
        return 'Something Went Wrong';
    }
  }
}

/// Compact error banner for inline display
class CustomerWalletErrorBanner extends ConsumerWidget {
  final CustomerWalletError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const CustomerWalletErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canRetry = ref.watch(customerWalletCanRetryProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.userFriendlyMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (error.isRetryable && canRetry) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry ?? () => ref.read(customerWalletProvider.notifier).retryLoadWallet(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.error,
              size: 16,
            ),
            onPressed: onDismiss ?? () => ref.read(customerWalletProvider.notifier).clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state widget with enhanced feedback
class CustomerWalletLoadingWidget extends ConsumerWidget {
  final String? message;
  final bool showRetryCount;

  const CustomerWalletLoadingWidget({
    super.key,
    this.message,
    this.showRetryCount = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final retryCount = ref.watch(customerWalletRetryCountProvider);
    final isRefreshing = ref.watch(customerWalletProvider.select((state) => state.isRefreshing));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? (isRefreshing ? 'Refreshing wallet...' : 'Loading wallet...'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          if (showRetryCount && retryCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Retry attempt $retryCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
