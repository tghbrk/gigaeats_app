import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/enhanced_error_handling_provider.dart';


/// Enhanced text field with real-time validation
class EnhancedValidatedTextField extends ConsumerStatefulWidget {
  final String fieldName;
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool validateOnChange;
  final bool showErrorIcon;

  const EnhancedValidatedTextField({
    super.key,
    required this.fieldName,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validateOnChange = true,
    this.showErrorIcon = true,
  });

  @override
  ConsumerState<EnhancedValidatedTextField> createState() => _EnhancedValidatedTextFieldState();
}

class _EnhancedValidatedTextFieldState extends ConsumerState<EnhancedValidatedTextField> {
  late TextEditingController _controller;


  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    
    if (widget.validateOnChange) {
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.validator != null) {
      ref.read(enhancedErrorHandlingProvider.notifier).validateField(
        widget.fieldName,
        _controller.text,
        widget.validator!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = ref.watch(fieldHasErrorProvider(widget.fieldName));
    final errorMessage = ref.watch(fieldErrorProvider(widget.fieldName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: _buildSuffixIcon(theme, hasError),
            errorText: null, // We'll show errors separately
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError 
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError 
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError 
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            widget.onChanged?.call(value);
            if (!widget.validateOnChange && widget.validator != null) {
              ref.read(enhancedErrorHandlingProvider.notifier).validateField(
                widget.fieldName,
                value,
                widget.validator!,
              );
            }
          },
          onEditingComplete: widget.onEditingComplete,
          onFieldSubmitted: widget.onSubmitted,
        ),
        if (hasError && errorMessage != null) ...[
          const SizedBox(height: 4),
          _buildErrorMessage(theme, errorMessage),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme, bool hasError) {
    if (hasError && widget.showErrorIcon) {
      return Icon(
        Icons.error_outline,
        color: theme.colorScheme.error,
        size: 20,
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        onPressed: widget.onSuffixIconPressed,
        icon: Icon(widget.suffixIcon),
      );
    }

    return null;
  }

  Widget _buildErrorMessage(ThemeData theme, String errorMessage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            errorMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

/// Enhanced error display widget
class EnhancedErrorDisplay extends ConsumerWidget {
  final bool showGlobalErrors;
  final bool showWarnings;
  final bool showRecommendations;
  final bool isCompact;
  final EdgeInsetsGeometry? padding;

  const EnhancedErrorDisplay({
    super.key,
    this.showGlobalErrors = true,
    this.showWarnings = true,
    this.showRecommendations = true,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final globalErrors = ref.watch(globalErrorsProvider);
    final warnings = ref.watch(warningsProvider);
    final recommendations = ref.watch(recommendationsProvider);

    final hasContent = (showGlobalErrors && globalErrors.isNotEmpty) ||
                      (showWarnings && warnings.isNotEmpty) ||
                      (showRecommendations && recommendations.isNotEmpty);

    if (!hasContent) return const SizedBox.shrink();

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGlobalErrors && globalErrors.isNotEmpty) ...[
            _buildErrorSection(theme, 'Errors', globalErrors, theme.colorScheme.error, Icons.error),
            if ((showWarnings && warnings.isNotEmpty) || (showRecommendations && recommendations.isNotEmpty))
              const SizedBox(height: 12),
          ],
          if (showWarnings && warnings.isNotEmpty) ...[
            _buildErrorSection(theme, 'Warnings', warnings, Colors.orange, Icons.warning),
            if (showRecommendations && recommendations.isNotEmpty)
              const SizedBox(height: 12),
          ],
          if (showRecommendations && recommendations.isNotEmpty) ...[
            _buildErrorSection(theme, 'Recommendations', recommendations, theme.colorScheme.tertiary, Icons.lightbulb),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorSection(ThemeData theme, String title, List<String> items, Color color, IconData icon) {
    if (isCompact) {
      return _buildCompactSection(theme, title, items, color, icon);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCompactSection(ThemeData theme, String title, List<String> items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              items.length == 1 ? items.first : '${items.length} ${title.toLowerCase()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced validation status widget
class EnhancedValidationStatus extends ConsumerWidget {
  final bool showWhenValid;
  final EdgeInsetsGeometry? padding;

  const EnhancedValidationStatus({
    super.key,
    this.showWhenValid = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasErrors = ref.watch(hasErrorsProvider);
    final hasWarnings = ref.watch(hasWarningsProvider);
    final statusMessage = ref.watch(validationStatusMessageProvider);

    if (!hasErrors && !hasWarnings && !showWhenValid) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String displayMessage;

    if (hasErrors) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.error_outline;
      displayMessage = statusMessage ?? 'Please fix errors before proceeding';
    } else if (hasWarnings) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_outlined;
      displayMessage = statusMessage ?? 'Warnings detected';
    } else {
      statusColor = theme.colorScheme.tertiary;
      statusIcon = Icons.check_circle_outline;
      displayMessage = 'All validations passed';
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced form validation wrapper
class EnhancedFormValidation extends ConsumerWidget {
  final Widget child;
  final bool showValidationStatus;
  final bool showErrorDisplay;
  final EdgeInsetsGeometry? padding;

  const EnhancedFormValidation({
    super.key,
    required this.child,
    this.showValidationStatus = true,
    this.showErrorDisplay = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showErrorDisplay) ...[
          EnhancedErrorDisplay(padding: padding),
          const SizedBox(height: 8),
        ],
        child,
        if (showValidationStatus) ...[
          const SizedBox(height: 8),
          EnhancedValidationStatus(padding: padding),
        ],
      ],
    );
  }
}
