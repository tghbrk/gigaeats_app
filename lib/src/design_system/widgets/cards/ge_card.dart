import 'package:flutter/material.dart';
import '../../tokens/tokens.dart';
import '../../theme/theme.dart';

/// GigaEats Design System Card Component
/// 
/// A flexible card component that supports multiple variants,
/// interactive states, and role-specific theming.
class GECard extends StatelessWidget {
  final Widget child;
  final GECardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final String? tooltip;

  const GECard({
    super.key,
    required this.child,
    this.variant = GECardVariant.elevated,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isLoading = false,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.tooltip,
  });

  /// Elevated card constructor
  const GECard.elevated({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isLoading = false,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.tooltip,
  }) : variant = GECardVariant.elevated;

  /// Outlined card constructor
  const GECard.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isLoading = false,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.tooltip,
  }) : variant = GECardVariant.outlined;

  /// Filled card constructor
  const GECard.filled({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isLoading = false,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.tooltip,
  }) : variant = GECardVariant.filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final geTheme = theme.extension<GEThemeExtension>();
    final roleTheme = theme.extension<GERoleThemeExtension>();
    
    Widget card = _buildCard(context, theme, geTheme, roleTheme);
    
    if (tooltip != null) {
      card = Tooltip(
        message: tooltip!,
        child: card,
      );
    }
    
    return card;
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    GEThemeExtension? geTheme,
    GERoleThemeExtension? roleTheme,
  ) {
    final cardColors = _getCardColors(theme, geTheme, roleTheme);
    final cardElevation = _getCardElevation();
    final cardBorderRadius = borderRadius ?? GEBorderRadius.card;
    final cardBorder = _getCardBorder(theme, geTheme, roleTheme);
    
    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(GESpacing.lg),
      margin: margin,
      decoration: BoxDecoration(
        color: cardColors.backgroundColor,
        borderRadius: cardBorderRadius,
        border: cardBorder,
        boxShadow: variant == GECardVariant.elevated
            ? GEElevation.getShadow(cardElevation, isDark: theme.brightness == Brightness.dark)
            : null,
      ),
      child: isLoading ? _buildLoadingContent() : child,
    );

    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: cardBorderRadius,
          splashColor: cardColors.splashColor,
          highlightColor: cardColors.highlightColor,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  _CardColors _getCardColors(
    ThemeData theme,
    GEThemeExtension? geTheme,
    GERoleThemeExtension? roleTheme,
  ) {
    final colorScheme = theme.colorScheme;
    
    Color baseBackgroundColor;
    Color splashColor;
    Color highlightColor;
    
    switch (variant) {
      case GECardVariant.elevated:
        baseBackgroundColor = backgroundColor ?? colorScheme.surface;
        break;
      case GECardVariant.outlined:
        baseBackgroundColor = backgroundColor ?? colorScheme.surface;
        break;
      case GECardVariant.filled:
        baseBackgroundColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
        break;
    }
    
    if (isSelected && roleTheme != null) {
      baseBackgroundColor = roleTheme.accentContainer;
      splashColor = roleTheme.accentColor.withValues(alpha: 0.1);
      highlightColor = roleTheme.accentColor.withValues(alpha: 0.05);
    } else {
      splashColor = colorScheme.onSurface.withValues(alpha: 0.1);
      highlightColor = colorScheme.onSurface.withValues(alpha: 0.05);
    }
    
    return _CardColors(
      backgroundColor: baseBackgroundColor,
      splashColor: splashColor,
      highlightColor: highlightColor,
    );
  }

  double _getCardElevation() {
    if (elevation != null) return elevation!;
    
    switch (variant) {
      case GECardVariant.elevated:
        return isSelected ? GEElevation.level3 : GEElevation.card;
      case GECardVariant.outlined:
      case GECardVariant.filled:
        return GEElevation.level0;
    }
  }

  Border? _getCardBorder(
    ThemeData theme,
    GEThemeExtension? geTheme,
    GERoleThemeExtension? roleTheme,
  ) {
    if (border != null) return border;
    
    switch (variant) {
      case GECardVariant.outlined:
        if (isSelected && roleTheme != null) {
          return Border.all(
            color: roleTheme.accentColor,
            width: GEBorder.thick,
          );
        }
        return Border.all(
          color: theme.colorScheme.outline,
          width: GEBorder.thin,
        );
      case GECardVariant.elevated:
      case GECardVariant.filled:
        return null;
    }
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// Dashboard Card - specialized card for dashboard metrics
class GEDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? trend;
  final bool isPositiveTrend;

  const GEDashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.isLoading = false,
    this.trend,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleTheme = theme.extension<GERoleThemeExtension>();
    final cardIconColor = iconColor ?? roleTheme?.accentColor ?? theme.colorScheme.primary;
    
    return GECard.elevated(
      onTap: onTap,
      isLoading: isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(GESpacing.sm),
                decoration: BoxDecoration(
                  color: cardIconColor.withValues(alpha: 0.1),
                  borderRadius: GEBorderRadius.smRadius,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: cardIconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: GESpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: GETypography.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: GESpacing.xs),
            Row(
              children: [
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                if (trend != null) ...[
                  Icon(
                    isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isPositiveTrend ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: GESpacing.xs),
                  Text(
                    trend!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPositiveTrend ? Colors.green : Colors.red,
                      fontWeight: GETypography.medium,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Card variant enumeration
enum GECardVariant {
  elevated,
  outlined,
  filled,
}

/// Internal class for card colors
class _CardColors {
  final Color backgroundColor;
  final Color splashColor;
  final Color highlightColor;

  const _CardColors({
    required this.backgroundColor,
    required this.splashColor,
    required this.highlightColor,
  });
}
