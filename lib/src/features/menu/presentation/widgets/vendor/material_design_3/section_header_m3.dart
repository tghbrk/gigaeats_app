import 'package:flutter/material.dart';

import '../../../theme/template_theme_extension.dart';

/// Material Design 3 enhanced section header with consistent styling
class SectionHeaderM3 extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const SectionHeaderM3({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templateTheme = context.templateTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Trailing Widget
                if (trailing != null) trailing!,
                
                // Tap Indicator
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        
        // Divider
        if (showDivider)
          Divider(
            color: templateTheme.templateCardBorder,
            height: 1,
            thickness: 1,
          ),
      ],
    );
  }
}

/// Material Design 3 enhanced stats card for displaying metrics
class StatsCardM3 extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatsCardM3({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withValues(alpha: 0.1),
                cardColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: cardColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: cardColor,
                      size: 16,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Material Design 3 enhanced action button with consistent styling
class ActionButtonM3 extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const ActionButtonM3({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: isDestructive 
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          foregroundColor: isDestructive
              ? theme.colorScheme.onError
              : theme.colorScheme.onPrimary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDestructive 
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          side: BorderSide(
            color: isDestructive 
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            width: 1.5,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

/// Material Design 3 enhanced empty state component
class EmptyStateM3 extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  final Color? iconColor;

  const EmptyStateM3({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: iconColor ?? theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
