import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/tokens.dart';
import '../theme/theme.dart';
import '../../data/models/user_role.dart';

/// GigaEats Design System App Bar Component
/// 
/// A standardized app bar that supports role-specific theming
/// and consistent branding across all user interfaces.
class GEAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final UserRole? userRole;
  final bool showRoleIndicator;
  final VoidCallback? onNotificationTap;
  final int? notificationCount;
  final VoidCallback? onProfileTap;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final double toolbarHeight;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;

  const GEAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.userRole,
    this.showRoleIndicator = false,
    this.onNotificationTap,
    this.notificationCount,
    this.onProfileTap,
    this.systemOverlayStyle,
    this.toolbarHeight = kToolbarHeight,
    this.flexibleSpace,
    this.bottom,
  });

  /// App bar with role indicator
  const GEAppBar.withRole({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    required this.userRole,
    this.onNotificationTap,
    this.notificationCount,
    this.onProfileTap,
    this.systemOverlayStyle,
    this.toolbarHeight = kToolbarHeight,
    this.flexibleSpace,
    this.bottom,
  }) : showRoleIndicator = true;

  /// Simple app bar with just title
  const GEAppBar.simple({
    super.key,
    required this.title,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.userRole,
    this.systemOverlayStyle,
    this.toolbarHeight = kToolbarHeight,
    this.flexibleSpace,
    this.bottom,
  }) : titleWidget = null,
       actions = null,
       showRoleIndicator = false,
       onNotificationTap = null,
       notificationCount = null,
       onProfileTap = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleTheme = userRole != null 
        ? GERoleThemeExtension.fromUserRole(userRole!)
        : theme.extension<GERoleThemeExtension>();
    
    final appBarBackgroundColor = backgroundColor ?? 
        roleTheme?.accentColor ?? 
        theme.colorScheme.primary;
    
    final appBarForegroundColor = foregroundColor ?? 
        roleTheme?.accentOnColor ?? 
        theme.colorScheme.onPrimary;
    
    return AppBar(
      title: _buildTitle(context, theme, roleTheme),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: _buildActions(context, theme, appBarForegroundColor),
      centerTitle: centerTitle,
      elevation: elevation ?? GEElevation.appBar,
      backgroundColor: appBarBackgroundColor,
      foregroundColor: appBarForegroundColor,
      systemOverlayStyle: systemOverlayStyle ?? _getSystemOverlayStyle(appBarBackgroundColor),
      toolbarHeight: toolbarHeight,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      titleTextStyle: GETypography.headlineSmall.copyWith(
        color: appBarForegroundColor,
        fontWeight: GETypography.semiBold,
      ),
      iconTheme: IconThemeData(
        color: appBarForegroundColor,
      ),
      actionsIconTheme: IconThemeData(
        color: appBarForegroundColor,
      ),
    );
  }

  Widget? _buildTitle(
    BuildContext context,
    ThemeData theme,
    GERoleThemeExtension? roleTheme,
  ) {
    if (titleWidget != null) return titleWidget;
    if (title == null) return null;
    
    if (showRoleIndicator && roleTheme != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(GESpacing.xs),
            decoration: BoxDecoration(
              color: roleTheme.accentOnColor.withValues(alpha: 0.2),
              borderRadius: GEBorderRadius.smRadius,
            ),
            child: Icon(
              roleTheme.roleIcon,
              size: 16,
              color: roleTheme.accentOnColor,
            ),
          ),
          const SizedBox(width: GESpacing.sm),
          Flexible(
            child: Text(
              title!,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    
    return Text(title!);
  }

  List<Widget>? _buildActions(
    BuildContext context,
    ThemeData theme,
    Color foregroundColor,
  ) {
    final actionsList = <Widget>[];
    
    // Add notification action if callback provided
    if (onNotificationTap != null) {
      actionsList.add(
        _NotificationButton(
          onTap: onNotificationTap!,
          count: notificationCount,
          color: foregroundColor,
        ),
      );
    }
    
    // Add profile action if callback provided
    if (onProfileTap != null) {
      actionsList.add(
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: onProfileTap,
          tooltip: 'Profile',
        ),
      );
    }
    
    // Add custom actions
    if (actions != null) {
      actionsList.addAll(actions!);
    }
    
    return actionsList.isNotEmpty ? actionsList : null;
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.light 
          ? Brightness.dark 
          : Brightness.light,
      statusBarBrightness: brightness,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}

/// Notification button with badge
class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final int? count;
  final Color color;

  const _NotificationButton({
    required this.onTap,
    this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        children: [
          Icon(
            Icons.notifications_outlined,
            color: color,
          ),
          if (count != null && count! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count! > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
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
      onPressed: onTap,
      tooltip: 'Notifications',
    );
  }
}

/// Search app bar variant
class GESearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final List<Widget>? actions;
  final UserRole? userRole;
  final double toolbarHeight;

  const GESearchAppBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.actions,
    this.userRole,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  State<GESearchAppBar> createState() => _GESearchAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}

class _GESearchAppBarState extends State<GESearchAppBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleTheme = widget.userRole != null 
        ? GERoleThemeExtension.fromUserRole(widget.userRole!)
        : theme.extension<GERoleThemeExtension>();
    
    final backgroundColor = roleTheme?.accentColor ?? theme.colorScheme.primary;
    final foregroundColor = roleTheme?.accentOnColor ?? theme.colorScheme.onPrimary;
    
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: GEElevation.appBar,
      title: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: GETypography.bodyMedium.copyWith(color: foregroundColor),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search...',
          hintStyle: GETypography.bodyMedium.copyWith(
            color: foregroundColor.withValues(alpha: 0.7),
          ),
          border: InputBorder.none,
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: foregroundColor),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear?.call();
                    widget.onChanged?.call('');
                  },
                )
              : Icon(Icons.search, color: foregroundColor),
        ),
      ),
      actions: widget.actions,
      toolbarHeight: widget.toolbarHeight,
    );
  }
}
