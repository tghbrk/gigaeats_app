import 'package:flutter/material.dart';

/// A reusable quick action button widget for dashboard and navigation
class QuickActionButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final bool isEnabled;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;
  final double? width;
  final double? height;

  const QuickActionButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.isEnabled = true,
    this.showBadge = false,
    this.badgeText,
    this.badgeColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? actionColor.withValues(alpha: 0.1);

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: isEnabled ? 2 : 0,
        color: isEnabled ? null : theme.colorScheme.surface.withValues(alpha: 0.5),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isEnabled ? bgColor : Colors.transparent,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isEnabled 
                          ? actionColor 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled 
                            ? theme.colorScheme.onSurface 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled 
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                if (showBadge && isEnabled)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeText ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal quick action button variant
class HorizontalQuickActionButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool isEnabled;
  final bool showArrow;

  const HorizontalQuickActionButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.color,
    this.isEnabled = true,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: isEnabled ? 1 : 0,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? actionColor.withValues(alpha: 0.1)
                      : theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isEnabled 
                      ? actionColor 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled 
                            ? theme.colorScheme.onSurface 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled 
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showArrow && isEnabled)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact quick action button for toolbars
class CompactQuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool isEnabled;
  final bool isSelected;

  const CompactQuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.color,
    this.isEnabled = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? actionColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: actionColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isEnabled 
                  ? (isSelected ? actionColor : theme.colorScheme.onSurface)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isEnabled 
                    ? (isSelected ? actionColor : theme.colorScheme.onSurface)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A grid of quick action buttons
class QuickActionGrid extends StatelessWidget {
  final List<QuickActionButton> actions;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const QuickActionGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.2,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => actions[index],
    );
  }
}

/// A horizontal list of quick action buttons
class QuickActionRow extends StatelessWidget {
  final List<Widget> actions;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const QuickActionRow({
    super.key,
    required this.actions,
    this.spacing = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions
              .expand((action) => [action, SizedBox(width: spacing)])
              .take(actions.length * 2 - 1)
              .toList(),
        ),
      ),
    );
  }
}
