import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

/// A responsive app bar that adapts to different screen sizes
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: _getTitleFontSize(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: _buildActions(context),
      leading: leading,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      toolbarHeight: _getToolbarHeight(context),
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (actions == null) return null;
    
    // On desktop, add more spacing between action buttons
    if (context.isDesktop) {
      return actions!.map((action) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: action,
        );
      }).toList();
    }
    
    return actions;
  }

  double _getTitleFontSize(BuildContext context) {
    if (context.isMobile) return 20;
    if (context.isTablet) return 22;
    return 24;
  }

  double _getToolbarHeight(BuildContext context) {
    if (context.isMobile) return kToolbarHeight;
    if (context.isTablet) return kToolbarHeight + 8;
    return kToolbarHeight + 16;
  }

  @override
  Size get preferredSize {
    final height = bottom == null 
        ? kToolbarHeight + 16 // Add extra height for desktop
        : kToolbarHeight + 16 + bottom!.preferredSize.height;
    return Size.fromHeight(height);
  }
}

/// A responsive floating action button that adapts to screen size
class ResponsiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final String? heroTag;
  final bool extended;
  final Widget? label;
  final Widget? icon;

  const ResponsiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.heroTag,
    this.extended = false,
    this.label,
    this.icon,
  });

  const ResponsiveFloatingActionButton.extended({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.tooltip,
    this.heroTag,
  }) : extended = true,
       child = const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    // On desktop, always use extended FAB for better UX
    if (context.isDesktop && extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: icon,
        label: label!,
        tooltip: tooltip,
        heroTag: heroTag,
      );
    }
    
    // On tablet, use extended if specified
    if (context.isTablet && extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: icon,
        label: label!,
        tooltip: tooltip,
        heroTag: heroTag,
      );
    }
    
    // On mobile or when not extended, use regular FAB
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      heroTag: heroTag,
      child: child,
    );
  }
}

/// A responsive bottom navigation bar that adapts to screen size
class ResponsiveBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavigationBarItem> items;
  final BottomNavigationBarType? type;

  const ResponsiveBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    // On desktop, don't show bottom navigation (use sidebar instead)
    if (context.isDesktop) {
      return const SizedBox.shrink();
    }
    
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items.map((item) {
        return NavigationDestination(
          icon: item.icon,
          selectedIcon: item.activeIcon,
          label: item.label ?? '',
        );
      }).toList(),
    );
  }
}

/// A responsive drawer that adapts to screen size
class ResponsiveDrawer extends StatelessWidget {
  final Widget child;
  final double? width;

  const ResponsiveDrawer({
    super.key,
    required this.child,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final drawerWidth = width ?? ResponsiveUtils.getSidebarWidth(context);
    
    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: child,
      ),
    );
  }
}

/// A responsive scaffold that provides different layouts for different screen sizes
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? bottom;
  final bool extendBodyBehindAppBar;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottom,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null 
          ? ResponsiveAppBar(
              title: title!,
              actions: actions,
              bottom: bottom,
            )
          : null,
      body: ResponsiveContainer(child: body),
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
