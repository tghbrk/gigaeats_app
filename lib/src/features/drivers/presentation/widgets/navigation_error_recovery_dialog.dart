import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/navigation_models.dart';
import '../providers/enhanced_navigation_provider.dart';

/// Navigation error recovery dialog that provides users with recovery options
/// when navigation errors occur in the Enhanced In-App Navigation System
class NavigationErrorRecoveryDialog extends ConsumerWidget {
  final NavigationErrorRecoveryResult recoveryResult;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const NavigationErrorRecoveryDialog({
    super.key,
    required this.recoveryResult,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getErrorIcon(),
            color: _getErrorColor(theme),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: _getErrorColor(theme),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          Text(
            recoveryResult.message,
            style: theme.textTheme.bodyMedium,
          ),
          
          // Suggested action (if available)
          if (recoveryResult.suggestedAction != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recoveryResult.suggestedAction!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // External navigation apps (if available)
          if (recoveryResult.availableApps?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(
              'Continue with external navigation:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...recoveryResult.availableApps!.map((app) => _buildExternalAppOption(context, ref, app)),
          ],
          
          // Degraded features warning (if applicable)
          if (recoveryResult.degradedFeatures?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Limited Features',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The following features are temporarily unavailable: ${recoveryResult.degradedFeatures!.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: _buildActions(context, ref),
    );
  }

  /// Build external navigation app option
  Widget _buildExternalAppOption(BuildContext context, WidgetRef ref, ExternalNavApp app) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _launchExternalApp(context, ref, app),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getAppIcon(app.name),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.launch,
                  color: theme.colorScheme.outline,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build dialog actions
  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    final actions = <Widget>[];
    
    // Dismiss button (always available)
    actions.add(
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          onDismiss?.call();
        },
        child: const Text('Dismiss'),
      ),
    );
    
    // Retry button (for retryable errors)
    if (recoveryResult.type == NavigationErrorRecoveryType.retry && onRetry != null) {
      actions.add(
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry?.call();
          },
          child: Text('Retry${recoveryResult.retryCount != null ? ' (${recoveryResult.retryCount})' : ''}'),
        ),
      );
    }
    
    // Settings button (for permission/service errors)
    if (recoveryResult.type == NavigationErrorRecoveryType.permissionRequired ||
        recoveryResult.type == NavigationErrorRecoveryType.serviceRequired) {
      actions.add(
        FilledButton(
          onPressed: () => _openSettings(context),
          child: const Text('Settings'),
        ),
      );
    }
    
    return actions;
  }

  /// Launch external navigation app
  Future<void> _launchExternalApp(BuildContext context, WidgetRef ref, ExternalNavApp app) async {
    if (recoveryResult.destination == null) return;
    
    try {
      final navService = ref.read(enhancedNavigationProvider.notifier);
      final success = await navService.launchExternalNavigation(app, recoveryResult.destination!);
      
      if (success) {
        Navigator.of(context).pop();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launched ${app.name} for navigation'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch ${app.name}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching ${app.name}: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Open device settings
  void _openSettings(BuildContext context) {
    Navigator.of(context).pop();
    // In a real implementation, you would open the appropriate settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please check your device settings'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Get error icon based on recovery type
  IconData _getErrorIcon() {
    switch (recoveryResult.type) {
      case NavigationErrorRecoveryType.networkUnavailable:
        return Icons.wifi_off;
      case NavigationErrorRecoveryType.permissionRequired:
        return Icons.location_disabled;
      case NavigationErrorRecoveryType.serviceRequired:
        return Icons.gps_off;
      case NavigationErrorRecoveryType.degraded:
        return Icons.warning_amber;
      case NavigationErrorRecoveryType.externalNavigation:
        return Icons.navigation;
      case NavigationErrorRecoveryType.retry:
        return Icons.refresh;
      case NavigationErrorRecoveryType.failed:
        return Icons.error;
      case NavigationErrorRecoveryType.cooldown:
        return Icons.timer;
    }
  }

  /// Get error color based on recovery type
  Color _getErrorColor(ThemeData theme) {
    switch (recoveryResult.type) {
      case NavigationErrorRecoveryType.failed:
        return Colors.red.shade700;
      case NavigationErrorRecoveryType.degraded:
        return Colors.orange.shade700;
      case NavigationErrorRecoveryType.networkUnavailable:
      case NavigationErrorRecoveryType.permissionRequired:
      case NavigationErrorRecoveryType.serviceRequired:
        return Colors.amber.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  /// Get dialog title based on recovery type
  String _getTitle() {
    switch (recoveryResult.type) {
      case NavigationErrorRecoveryType.networkUnavailable:
        return 'Network Unavailable';
      case NavigationErrorRecoveryType.permissionRequired:
        return 'Permission Required';
      case NavigationErrorRecoveryType.serviceRequired:
        return 'Service Required';
      case NavigationErrorRecoveryType.degraded:
        return 'Limited Navigation';
      case NavigationErrorRecoveryType.externalNavigation:
        return 'Navigation Error';
      case NavigationErrorRecoveryType.retry:
        return 'Navigation Issue';
      case NavigationErrorRecoveryType.failed:
        return 'Navigation Failed';
      case NavigationErrorRecoveryType.cooldown:
        return 'Please Wait';
    }
  }

  /// Get app icon based on app name
  IconData _getAppIcon(String appName) {
    switch (appName.toLowerCase()) {
      case 'google maps':
        return Icons.map;
      case 'waze':
        return Icons.traffic;
      case 'apple maps':
        return Icons.map_outlined;
      default:
        return Icons.navigation;
    }
  }
}

/// Show navigation error recovery dialog
Future<void> showNavigationErrorRecoveryDialog(
  BuildContext context,
  NavigationErrorRecoveryResult recoveryResult, {
  VoidCallback? onDismiss,
  VoidCallback? onRetry,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: !recoveryResult.isUrgent,
    builder: (context) => NavigationErrorRecoveryDialog(
      recoveryResult: recoveryResult,
      onDismiss: onDismiss,
      onRetry: onRetry,
    ),
  );
}
