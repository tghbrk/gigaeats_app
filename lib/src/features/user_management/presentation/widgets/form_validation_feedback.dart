import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A widget that provides visual feedback for form validation
class FormValidationFeedback extends ConsumerWidget {
  final String fieldName;
  final Widget child;
  final bool showSuccessIndicator;
  final EdgeInsets? padding;

  const FormValidationFeedback({
    super.key,
    required this.fieldName,
    required this.child,
    this.showSuccessIndicator = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 4),
          _buildValidationIndicator(theme, ref),
        ],
      ),
    );
  }

  Widget _buildValidationIndicator(ThemeData theme, WidgetRef ref) {
    // This would need to be implemented with the actual field error providers
    // For now, return empty container
    return const SizedBox.shrink();
  }
}

/// A widget that shows a validation summary for the entire form
class FormValidationSummary extends ConsumerWidget {
  final VoidCallback? onErrorTap;
  final bool showSuccessState;

  const FormValidationSummary({
    super.key,
    this.onErrorTap,
    this.showSuccessState = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Form Validation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildValidationItems(theme, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationItems(ThemeData theme, WidgetRef ref) {
    // This would show validation status for each field
    // For now, return placeholder
    return const Text('Validation summary will be implemented');
  }
}

/// A widget that shows real-time character count for text fields
class CharacterCountIndicator extends StatelessWidget {
  final int currentLength;
  final int maxLength;
  final int? minLength;
  final bool showOnlyWhenNearLimit;

  const CharacterCountIndicator({
    super.key,
    required this.currentLength,
    required this.maxLength,
    this.minLength,
    this.showOnlyWhenNearLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNearLimit = currentLength > (maxLength * 0.8);
    final isOverLimit = currentLength > maxLength;
    final isUnderMin = minLength != null && currentLength < minLength!;

    if (showOnlyWhenNearLimit && !isNearLimit && !isOverLimit && !isUnderMin) {
      return const SizedBox.shrink();
    }

    Color textColor;
    if (isOverLimit || isUnderMin) {
      textColor = theme.colorScheme.error;
    } else if (isNearLimit) {
      textColor = theme.colorScheme.tertiary;
    } else {
      textColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (minLength != null && isUnderMin) ...[
            Icon(
              Icons.warning_amber,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Min: $minLength',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isOverLimit) ...[
            Icon(
              Icons.error,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$currentLength/$maxLength',
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontSize: 11,
              fontWeight: isOverLimit ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that shows validation status with icon and message
class ValidationStatusIndicator extends StatelessWidget {
  final bool isValid;
  final String? errorMessage;
  final String? successMessage;
  final bool showSuccessState;

  const ValidationStatusIndicator({
    super.key,
    required this.isValid,
    this.errorMessage,
    this.successMessage,
    this.showSuccessState = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isValid && errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isValid && showSuccessState && successMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                successMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// A widget that provides helpful tips for form fields
class FormFieldTip extends StatelessWidget {
  final String tip;
  final IconData? icon;
  final bool isVisible;

  const FormFieldTip({
    super.key,
    required this.tip,
    this.icon,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.lightbulb_outline,
            size: 14,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
