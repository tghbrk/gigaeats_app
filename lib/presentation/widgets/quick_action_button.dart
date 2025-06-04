import 'package:flutter/material.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? buttonColor.withValues(alpha: 0.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: buttonColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: buttonColor,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  final bool isEnabled;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.color,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnabled
                ? buttonColor.withValues(alpha: 0.1)
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? buttonColor.withValues(alpha: 0.2)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? buttonColor.withValues(alpha: 0.2)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isEnabled
                      ? buttonColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isEnabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const CustomFloatingActionButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      mini: mini,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      child: Icon(icon),
    );
  }
}
