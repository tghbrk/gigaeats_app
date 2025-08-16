import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/tokens.dart';
import '../../theme/theme.dart';

/// GigaEats Design System Text Field Component
/// 
/// A comprehensive text field component that supports multiple variants,
/// validation states, and role-specific theming.
class GETextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final GETextFieldVariant variant;
  final GETextFieldSize size;
  final bool isRequired;
  final String? Function(String?)? validator;

  const GETextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.maxLengthEnforcement,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.variant = GETextFieldVariant.outlined,
    this.size = GETextFieldSize.medium,
    this.isRequired = false,
    this.validator,
  });

  /// Outlined text field constructor
  const GETextField.outlined({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.maxLengthEnforcement,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.size = GETextFieldSize.medium,
    this.isRequired = false,
    this.validator,
  }) : variant = GETextFieldVariant.outlined;

  /// Filled text field constructor
  const GETextField.filled({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.maxLengthEnforcement,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.size = GETextFieldSize.medium,
    this.isRequired = false,
    this.validator,
  }) : variant = GETextFieldVariant.filled;

  /// Underlined text field constructor
  const GETextField.underlined({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.maxLengthEnforcement,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.size = GETextFieldSize.medium,
    this.isRequired = false,
    this.validator,
  }) : variant = GETextFieldVariant.underlined;

  @override
  State<GETextField> createState() => _GETextFieldState();
}

class _GETextFieldState extends State<GETextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    _errorText = widget.errorText;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleTheme = theme.extension<GERoleThemeExtension>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          _buildLabel(theme),
          const SizedBox(height: GESpacing.xs),
        ],
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _handleChanged,
          onTap: widget.onTap,
          onFieldSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          maxLengthEnforcement: widget.maxLengthEnforcement,
          style: _getTextStyle(theme),
          decoration: _buildInputDecoration(theme, roleTheme),
          validator: widget.validator,
        ),
        if (widget.helperText != null || _errorText != null) ...[
          const SizedBox(height: GESpacing.xs),
          _buildHelperText(theme),
        ],
      ],
    );
  }

  Widget _buildLabel(ThemeData theme) {
    return RichText(
      text: TextSpan(
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: GETypography.medium,
        ),
        children: [
          TextSpan(text: widget.label),
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHelperText(ThemeData theme) {
    final text = _errorText ?? widget.helperText;
    final isError = _errorText != null;
    
    return Text(
      text!,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isError 
            ? theme.colorScheme.error 
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme, GERoleThemeExtension? roleTheme) {
    final primaryColor = roleTheme?.accentColor ?? theme.colorScheme.primary;
    
    return InputDecoration(
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(theme),
      prefixText: widget.prefixText,
      suffixText: widget.suffixText,
      contentPadding: _getContentPadding(),
      border: _getBorder(theme, BorderType.normal),
      enabledBorder: _getBorder(theme, BorderType.enabled),
      focusedBorder: _getBorder(theme, BorderType.focused, primaryColor),
      errorBorder: _getBorder(theme, BorderType.error),
      focusedErrorBorder: _getBorder(theme, BorderType.focusedError),
      disabledBorder: _getBorder(theme, BorderType.disabled),
      fillColor: _getFillColor(theme),
      filled: widget.variant == GETextFieldVariant.filled,
      errorText: null, // We handle error text separately
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (widget.size) {
      case GETextFieldSize.small:
        return GETypography.bodySmall.copyWith(color: theme.colorScheme.onSurface);
      case GETextFieldSize.medium:
        return GETypography.bodyMedium.copyWith(color: theme.colorScheme.onSurface);
      case GETextFieldSize.large:
        return GETypography.bodyLarge.copyWith(color: theme.colorScheme.onSurface);
    }
  }

  EdgeInsetsGeometry _getContentPadding() {
    switch (widget.size) {
      case GETextFieldSize.small:
        return const EdgeInsets.symmetric(
          horizontal: GESpacing.md,
          vertical: GESpacing.sm,
        );
      case GETextFieldSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: GESpacing.lg,
          vertical: GESpacing.md,
        );
      case GETextFieldSize.large:
        return const EdgeInsets.symmetric(
          horizontal: GESpacing.lg,
          vertical: GESpacing.lg,
        );
    }
  }

  InputBorder _getBorder(ThemeData theme, BorderType type, [Color? customColor]) {
    Color borderColor;
    double borderWidth = GEBorder.thin;
    
    switch (type) {
      case BorderType.normal:
      case BorderType.enabled:
        borderColor = theme.colorScheme.outline;
        break;
      case BorderType.focused:
        borderColor = customColor ?? theme.colorScheme.primary;
        borderWidth = GEBorder.thick;
        break;
      case BorderType.error:
      case BorderType.focusedError:
        borderColor = theme.colorScheme.error;
        if (type == BorderType.focusedError) {
          borderWidth = GEBorder.thick;
        }
        break;
      case BorderType.disabled:
        borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.12);
        break;
    }
    
    switch (widget.variant) {
      case GETextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: GEBorderRadius.input,
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        );
      case GETextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: GEBorderRadius.input,
          borderSide: type == BorderType.focused || type == BorderType.focusedError
              ? BorderSide(color: borderColor, width: borderWidth)
              : BorderSide.none,
        );
      case GETextFieldVariant.underlined:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        );
    }
  }

  Color? _getFillColor(ThemeData theme) {
    if (widget.variant == GETextFieldVariant.filled) {
      return theme.colorScheme.surfaceContainerHighest;
    }
    return null;
  }

  void _handleChanged(String value) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }
    widget.onChanged?.call(value);
  }
}

/// Text field variant enumeration
enum GETextFieldVariant {
  outlined,
  filled,
  underlined,
}

/// Text field size enumeration
enum GETextFieldSize {
  small,
  medium,
  large,
}

/// Internal border type enumeration
enum BorderType {
  normal,
  enabled,
  focused,
  error,
  focusedError,
  disabled,
}
