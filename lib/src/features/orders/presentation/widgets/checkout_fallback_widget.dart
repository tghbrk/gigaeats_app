import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/checkout_fallback_provider.dart';
import '../../../../core/utils/logger.dart';

/// Widget that displays checkout fallback guidance
class CheckoutFallbackWidget extends ConsumerWidget {
  final bool showOnlyBlocking;
  final VoidCallback? onActionCompleted;

  const CheckoutFallbackWidget({
    super.key,
    this.showOnlyBlocking = false,
    this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackState = ref.watch(checkoutFallbackProvider);
    
    if (fallbackState.isRecovering) {
      return const _LoadingWidget();
    }

    final guidancesToShow = showOnlyBlocking
        ? fallbackState.activeGuidances.where((g) => g.isBlocking).toList()
        : fallbackState.activeGuidances;

    if (guidancesToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: guidancesToShow.map((guidance) => 
        _FallbackGuidanceCard(
          guidance: guidance,
          onActionExecuted: onActionCompleted,
        )
      ).toList(),
    );
  }
}

/// Loading widget for when fallback analysis is in progress
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Checking checkout requirements...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual fallback guidance card
class _FallbackGuidanceCard extends ConsumerWidget {
  final FallbackGuidance guidance;
  final VoidCallback? onActionExecuted;

  const _FallbackGuidanceCard({
    required this.guidance,
    this.onActionExecuted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logger = AppLogger();

    return Card(
      color: guidance.isBlocking 
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  guidance.isBlocking ? Icons.error : Icons.info,
                  color: guidance.isBlocking 
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guidance.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: guidance.isBlocking 
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              guidance.message,
              style: theme.textTheme.bodyMedium,
            ),
            if (guidance.helpText != null) ...[
              const SizedBox(height: 8),
              Text(
                guidance.helpText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: guidance.suggestedActions.map((action) {
                final isPrimary = action == guidance.primaryAction;
                return _ActionButton(
                  action: action,
                  isPrimary: isPrimary,
                  customText: isPrimary ? guidance.primaryActionText : null,
                  onPressed: () => _executeAction(context, ref, action, logger),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeAction(
    BuildContext context,
    WidgetRef ref,
    FallbackAction action,
    AppLogger logger,
  ) async {
    logger.info('🔧 [FALLBACK-WIDGET] Executing action: $action');

    try {
      switch (action) {
        case FallbackAction.addAddress:
          context.push('/customer/addresses/add');
          break;
          
        case FallbackAction.addPaymentMethod:
          context.push('/customer/payment-methods/add');
          break;
          
        case FallbackAction.selectExistingAddress:
          context.push('/customer/addresses/select');
          break;
          
        case FallbackAction.selectExistingPaymentMethod:
          context.push('/customer/payment-methods/select');
          break;
          
        case FallbackAction.retry:
        case FallbackAction.refreshData:
        case FallbackAction.continueWithoutDefaults:
          final success = await ref.read(checkoutFallbackProvider.notifier)
              .executeFallbackAction(action);
          if (success && onActionExecuted != null) {
            onActionExecuted!();
          }
          break;
          
        case FallbackAction.contactSupport:
          // TODO: Implement support contact
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Support contact feature coming soon'),
              ),
            );
          }
          break;
      }
    } catch (e, stack) {
      logger.error('❌ [FALLBACK-WIDGET] Error executing action: $action', e, stack);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute action: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Action button for fallback actions
class _ActionButton extends StatelessWidget {
  final FallbackAction action;
  final bool isPrimary;
  final String? customText;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.action,
    required this.isPrimary,
    required this.onPressed,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = customText ?? _getActionText(action);

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        child: Text(text),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }
  }

  String _getActionText(FallbackAction action) {
    switch (action) {
      case FallbackAction.addAddress:
        return 'Add Address';
      case FallbackAction.addPaymentMethod:
        return 'Add Payment Method';
      case FallbackAction.selectExistingAddress:
        return 'Select Address';
      case FallbackAction.selectExistingPaymentMethod:
        return 'Select Payment Method';
      case FallbackAction.retry:
        return 'Retry';
      case FallbackAction.continueWithoutDefaults:
        return 'Continue';
      case FallbackAction.refreshData:
        return 'Refresh';
      case FallbackAction.contactSupport:
        return 'Contact Support';
    }
  }
}

/// Compact fallback indicator for headers/status bars
class CheckoutFallbackIndicator extends ConsumerWidget {
  final VoidCallback? onTap;

  const CheckoutFallbackIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasIssues = ref.watch(checkoutHasFallbackIssuesProvider);
    
    if (!hasIssues) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              size: 16,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Setup Required',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
