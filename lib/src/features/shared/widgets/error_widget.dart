import 'package:flutter/material.dart';

/// Error widget types
enum ErrorType {
  network,
  server,
  notFound,
  unauthorized,
  validation,
  generic,
}

/// A comprehensive error widget for different error scenarios
class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final ErrorType type;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final IconData? customIcon;
  final Color? customColor;
  final bool showIcon;
  final bool isCompact;
  final EdgeInsetsGeometry? padding;

  const CustomErrorWidget({
    super.key,
    this.title,
    this.message,
    this.type = ErrorType.generic,
    this.onRetry,
    this.retryButtonText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.customIcon,
    this.customColor,
    this.showIcon = true,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = customColor ?? theme.colorScheme.error;
    
    final errorInfo = _getErrorInfo(context);
    final displayTitle = title ?? errorInfo.title;
    final displayMessage = message ?? errorInfo.message;
    final displayIcon = customIcon ?? errorInfo.icon;

    if (isCompact) {
      return _buildCompactError(context, theme, errorColor, displayTitle, displayMessage, displayIcon);
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  displayIcon,
                  size: 48,
                  color: errorColor,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              displayTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              displayMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactError(
    BuildContext context,
    ThemeData theme,
    Color errorColor,
    String displayTitle,
    String displayMessage,
    IconData displayIcon,
  ) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              displayIcon,
              color: errorColor,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (displayMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(retryButtonText ?? 'Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    final buttons = <Widget>[];

    if (onRetry != null) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(retryButtonText ?? 'Try Again'),
        ),
      );
    }

    if (onSecondaryAction != null) {
      buttons.add(
        OutlinedButton(
          onPressed: onSecondaryAction,
          child: Text(secondaryActionText ?? 'Go Back'),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    if (buttons.length == 1) {
      return buttons.first;
    }

    return Column(
      children: [
        buttons.first,
        const SizedBox(height: 12),
        buttons.last,
      ],
    );
  }

  _ErrorInfo _getErrorInfo(BuildContext context) {
    return switch (type) {
      ErrorType.network => _ErrorInfo(
        title: 'Connection Problem',
        message: 'Please check your internet connection and try again.',
        icon: Icons.wifi_off,
      ),
      ErrorType.server => _ErrorInfo(
        title: 'Server Error',
        message: 'Something went wrong on our end. Please try again later.',
        icon: Icons.error_outline,
      ),
      ErrorType.notFound => _ErrorInfo(
        title: 'Not Found',
        message: 'The content you\'re looking for could not be found.',
        icon: Icons.search_off,
      ),
      ErrorType.unauthorized => _ErrorInfo(
        title: 'Access Denied',
        message: 'You don\'t have permission to access this content.',
        icon: Icons.lock_outline,
      ),
      ErrorType.validation => _ErrorInfo(
        title: 'Invalid Input',
        message: 'Please check your input and try again.',
        icon: Icons.warning_outlined,
      ),
      ErrorType.generic => _ErrorInfo(
        title: 'Something Went Wrong',
        message: 'An unexpected error occurred. Please try again.',
        icon: Icons.error_outline,
      ),
    };
  }
}

/// Error info data class
class _ErrorInfo {
  final String title;
  final String message;
  final IconData icon;

  const _ErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
  });
}

/// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      type: ErrorType.network,
      message: customMessage,
      onRetry: onRetry,
    );
  }
}

/// Server error widget
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const ServerErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      type: ErrorType.server,
      message: customMessage,
      onRetry: onRetry,
    );
  }
}

/// Not found error widget
class NotFoundErrorWidget extends StatelessWidget {
  final VoidCallback? onGoBack;
  final String? customMessage;

  const NotFoundErrorWidget({
    super.key,
    this.onGoBack,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      type: ErrorType.notFound,
      message: customMessage,
      onSecondaryAction: onGoBack,
      secondaryActionText: 'Go Back',
    );
  }
}

/// Inline error widget for forms and inputs
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? color;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = color ?? theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.error_outline,
            size: 16,
            color: errorColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error banner widget
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;
  final Color? backgroundColor;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onAction,
    this.actionText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.errorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText ?? 'Action',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onErrorContainer,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget (technically not an error, but related)
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText ?? 'Get Started'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
