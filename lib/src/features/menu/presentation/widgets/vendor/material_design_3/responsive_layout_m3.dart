import 'package:flutter/material.dart';

/// Material Design 3 responsive layout helper for template interface
class ResponsiveLayoutM3 extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayoutM3({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 768) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Responsive grid for template cards
class ResponsiveTemplateGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveTemplateGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 3; // Desktop: 3 columns
        } else if (constraints.maxWidth >= 768) {
          crossAxisCount = 2; // Tablet: 2 columns
        } else {
          crossAxisCount = 1; // Mobile: 1 column
        }

        return Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: runSpacing,
              childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth >= 1200) {
      return 1.2; // Desktop: wider cards
    } else if (screenWidth >= 768) {
      return 1.1; // Tablet: slightly wider
    } else {
      return 1.0; // Mobile: square-ish cards
    }
  }
}

/// Responsive spacing helper
class ResponsiveSpacing {
  static double small(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 8;
    if (screenWidth >= 768) return 6;
    return 4;
  }

  static double medium(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 16;
    if (screenWidth >= 768) return 12;
    return 8;
  }

  static double large(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 24;
    if (screenWidth >= 768) return 20;
    return 16;
  }

  static double extraLarge(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 32;
    if (screenWidth >= 768) return 28;
    return 24;
  }
}

/// Responsive typography helper
class ResponsiveTypography {
  static TextStyle? displayLarge(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return theme.textTheme.displayLarge?.copyWith(fontSize: 36);
    } else if (screenWidth >= 768) {
      return theme.textTheme.displayLarge?.copyWith(fontSize: 32);
    } else {
      return theme.textTheme.displayLarge?.copyWith(fontSize: 28);
    }
  }

  static TextStyle? titleLarge(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return theme.textTheme.titleLarge?.copyWith(fontSize: 20);
    } else if (screenWidth >= 768) {
      return theme.textTheme.titleLarge?.copyWith(fontSize: 18);
    } else {
      return theme.textTheme.titleLarge?.copyWith(fontSize: 16);
    }
  }

  static TextStyle? bodyLarge(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return theme.textTheme.bodyLarge?.copyWith(fontSize: 18);
    } else if (screenWidth >= 768) {
      return theme.textTheme.bodyLarge?.copyWith(fontSize: 16);
    } else {
      return theme.textTheme.bodyLarge?.copyWith(fontSize: 14);
    }
  }
}

/// Responsive container with adaptive padding and margins
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    EdgeInsetsGeometry responsivePadding = padding ?? EdgeInsets.all(
      screenWidth >= 1200 ? 24 : screenWidth >= 768 ? 20 : 16,
    );
    
    EdgeInsetsGeometry responsiveMargin = margin ?? EdgeInsets.all(
      screenWidth >= 1200 ? 16 : screenWidth >= 768 ? 12 : 8,
    );

    Widget container = Container(
      padding: responsivePadding,
      margin: responsiveMargin,
      color: color,
      decoration: decoration,
      child: child,
    );

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: container,
        ),
      );
    }

    return container;
  }
}

/// Responsive card with adaptive elevation and border radius
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    double responsiveElevation = elevation ?? (screenWidth >= 768 ? 3 : 2);
    double responsiveBorderRadius = screenWidth >= 768 ? 16 : 12;
    
    EdgeInsetsGeometry responsivePadding = padding ?? EdgeInsets.all(
      screenWidth >= 1200 ? 20 : screenWidth >= 768 ? 16 : 12,
    );
    
    EdgeInsetsGeometry responsiveMargin = margin ?? EdgeInsets.all(
      screenWidth >= 1200 ? 12 : screenWidth >= 768 ? 10 : 8,
    );

    return Card(
      elevation: responsiveElevation,
      color: color,
      margin: responsiveMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
        child: Padding(
          padding: responsivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive button with adaptive sizing
class ResponsiveButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isExpanded;

  const ResponsiveButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    EdgeInsetsGeometry responsivePadding = EdgeInsets.symmetric(
      horizontal: screenWidth >= 1200 ? 24 : screenWidth >= 768 ? 20 : 16,
      vertical: screenWidth >= 1200 ? 16 : screenWidth >= 768 ? 14 : 12,
    );

    Widget button = isPrimary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
            label: Text(label),
            style: FilledButton.styleFrom(
              padding: responsivePadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth >= 768 ? 12 : 8),
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: responsivePadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth >= 768 ? 12 : 8),
              ),
            ),
          );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Screen size breakpoints
class ScreenBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1200;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
}
