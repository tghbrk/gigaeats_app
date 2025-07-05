import 'package:flutter/material.dart';

import '../../data/validation/menu_validation_service.dart';
import '../../../../core/errors/menu_exceptions.dart';

/// Comprehensive validation feedback widget for menu forms
class MenuValidationFeedback extends StatelessWidget {
  final MenuValidationResult validationResult;
  final bool showWarnings;
  final bool compact;
  final VoidCallback? onDismiss;

  const MenuValidationFeedback({
    super.key,
    required this.validationResult,
    this.showWarnings = true,
    this.compact = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (validationResult.isValid && validationResult.warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactFeedback(context);
    } else {
      return _buildDetailedFeedback(context);
    }
  }

  Widget _buildCompactFeedback(BuildContext context) {
    final hasErrors = !validationResult.isValid;
    final hasWarnings = validationResult.warnings.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasErrors
            ? Colors.red[50]
            : hasWarnings
                ? Colors.orange[50]
                : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasErrors
              ? Colors.red[300]!
              : hasWarnings
                  ? Colors.orange[300]!
                  : Colors.green[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasErrors
                ? Icons.error_outline
                : hasWarnings
                    ? Icons.warning_outlined
                    : Icons.check_circle_outline,
            color: hasErrors
                ? Colors.red[700]
                : hasWarnings
                    ? Colors.orange[700]
                    : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              validationResult.summary,
              style: TextStyle(
                color: hasErrors
                    ? Colors.red[700]
                    : hasWarnings
                        ? Colors.orange[700]
                        : Colors.green[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedFeedback(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (!validationResult.isValid) ...[
              const SizedBox(height: 12),
              _buildErrorsList(context),
            ],
            if (showWarnings && validationResult.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWarningsList(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasErrors = !validationResult.isValid;
    final hasWarnings = validationResult.warnings.isNotEmpty;

    return Row(
      children: [
        Icon(
          hasErrors
              ? Icons.error_outline
              : hasWarnings
                  ? Icons.warning_outlined
                  : Icons.check_circle_outline,
          color: hasErrors
              ? Colors.red[700]
              : hasWarnings
                  ? Colors.orange[700]
                  : Colors.green[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasErrors
                ? 'Validation Errors'
                : hasWarnings
                    ? 'Validation Warnings'
                    : 'Validation Passed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasErrors
                  ? Colors.red[700]
                  : hasWarnings
                      ? Colors.orange[700]
                      : Colors.green[700],
            ),
          ),
        ),
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  Widget _buildErrorsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Errors (${validationResult.errors.length})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        ...validationResult.errors.entries.map((entry) => 
          _buildValidationItem(
            context,
            entry.key,
            entry.value,
            Icons.error_outline,
            Colors.red[700]!,
          )
        ),
      ],
    );
  }

  Widget _buildWarningsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warnings (${validationResult.warnings.length})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 8),
        ...validationResult.warnings.asMap().entries.map((entry) => 
          _buildValidationItem(
            context,
            'warning_${entry.key}',
            entry.value,
            Icons.warning_outlined,
            Colors.orange[700]!,
          )
        ),
      ],
    );
  }

  Widget _buildValidationItem(
    BuildContext context,
    String field,
    String message,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (field.isNotEmpty && !field.startsWith('warning_'))
                  Text(
                    _formatFieldName(field),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFieldName(String fieldName) {
    // Convert field names to user-friendly labels
    final fieldMap = {
      'name': 'Name',
      'description': 'Description',
      'basePrice': 'Base Price',
      'category': 'Category',
      'vendorId': 'Vendor',
      'stockQuantity': 'Stock Quantity',
      'preparationTime': 'Preparation Time',
      'minimumPrice': 'Minimum Price',
      'maximumPrice': 'Maximum Price',
      'displayStyle': 'Display Style',
    };

    // Handle complex field names (e.g., bulkTier_0_minQuantity)
    if (fieldName.contains('_')) {
      final parts = fieldName.split('_');
      if (parts.length >= 2) {
        final prefix = parts[0];
        final suffix = parts.length > 2 ? parts[2] : parts[1];
        
        switch (prefix) {
          case 'bulkTier':
            return 'Bulk Tier ${int.parse(parts[1]) + 1} - ${_formatFieldName(suffix)}';
          case 'promotion':
            return 'Promotion ${int.parse(parts[1]) + 1} - ${_formatFieldName(suffix)}';
          case 'timeRule':
            return 'Time Rule ${int.parse(parts[1]) + 1} - ${_formatFieldName(suffix)}';
          case 'category':
            return 'Category ${int.parse(parts[1]) + 1} - ${_formatFieldName(suffix)}';
          case 'customization':
            return 'Customization ${int.parse(parts[1]) + 1} - ${_formatFieldName(suffix)}';
        }
      }
    }

    return fieldMap[fieldName] ?? fieldName.replaceAll('_', ' ').toUpperCase();
  }
}

/// Form field wrapper with validation feedback
class ValidatedFormField extends StatelessWidget {
  final Widget child;
  final MenuValidationResult? validationResult;
  final String fieldName;
  final bool showFieldError;

  const ValidatedFormField({
    super.key,
    required this.child,
    this.validationResult,
    required this.fieldName,
    this.showFieldError = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = validationResult?.hasFieldError(fieldName) ?? false;
    final errorMessage = validationResult?.getFieldError(fieldName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: hasError
              ? BoxDecoration(
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: child,
        ),
        if (showFieldError && hasError && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Error recovery suggestions widget
class MenuErrorRecovery extends StatelessWidget {
  final MenuException exception;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final Map<String, VoidCallback>? customActions;

  const MenuErrorRecovery({
    super.key,
    required this.exception,
    this.onRetry,
    this.onCancel,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildErrorHeader(context),
            const SizedBox(height: 12),
            _buildErrorMessage(context),
            const SizedBox(height: 16),
            _buildRecoverySuggestions(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getErrorIcon(),
          color: Colors.red[700],
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getErrorTitle(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(
        exception.userFriendlyMessage,
        style: TextStyle(
          color: Colors.red[700],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRecoverySuggestions(BuildContext context) {
    final suggestions = _getRecoverySuggestions();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Actions:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map((suggestion) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_right, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        if (customActions != null)
          ...customActions!.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: entry.value,
                child: Text(entry.key),
              ),
            )
          ),
        if (onRetry != null && exception.isRecoverable)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
      ],
    );
  }

  IconData _getErrorIcon() {
    switch (exception.runtimeType) {
      case MenuNotFoundException _:
        return Icons.search_off;
      case MenuUnauthorizedException _:
        return Icons.lock_outline;
      case MenuValidationException _:
        return Icons.error_outline;
      case PricingCalculationException _:
        return Icons.calculate;
      case CustomizationException _:
        return Icons.tune;
      case MenuOrganizationException _:
        return Icons.reorder;
      case MenuAnalyticsException _:
        return Icons.analytics;
      case MenuFileUploadException _:
        return Icons.cloud_upload;
      case MenuRealtimeException _:
        return Icons.sync_problem;
      default:
        return Icons.error;
    }
  }

  String _getErrorTitle() {
    switch (exception.runtimeType) {
      case MenuNotFoundException _:
        return 'Item Not Found';
      case MenuUnauthorizedException _:
        return 'Access Denied';
      case MenuValidationException _:
        return 'Validation Error';
      case PricingCalculationException _:
        return 'Pricing Error';
      case CustomizationException _:
        return 'Customization Error';
      case MenuOrganizationException _:
        return 'Organization Error';
      case MenuAnalyticsException _:
        return 'Analytics Error';
      case MenuFileUploadException _:
        return 'Upload Error';
      case MenuRealtimeException _:
        return 'Sync Error';
      default:
        return 'Error';
    }
  }

  List<String> _getRecoverySuggestions() {
    switch (exception.runtimeType) {
      case MenuNotFoundException _:
        return [
          'Check if the item exists in your menu',
          'Refresh the page to reload data',
          'Contact support if the problem persists',
        ];
      case MenuUnauthorizedException _:
        return [
          'Verify you have permission to perform this action',
          'Check if you are logged in as the correct user',
          'Contact your administrator for access',
        ];
      case MenuValidationException _:
        return [
          'Review and correct the highlighted fields',
          'Ensure all required information is provided',
          'Check for any formatting errors',
        ];
      case PricingCalculationException _:
        return [
          'Check your pricing configuration',
          'Verify all pricing rules are valid',
          'Remove conflicting pricing rules',
        ];
      case CustomizationException _:
        return [
          'Review your customization settings',
          'Check for invalid option configurations',
          'Ensure all required options are available',
        ];
      case MenuOrganizationException _:
        return [
          'Check your menu organization structure',
          'Verify category relationships are valid',
          'Remove any circular references',
        ];
      case MenuRealtimeException _:
        return [
          'Check your internet connection',
          'Refresh the page to reconnect',
          'Try again in a few moments',
        ];
      default:
        return [
          'Try refreshing the page',
          'Check your internet connection',
          'Contact support if the issue persists',
        ];
    }
  }
}
