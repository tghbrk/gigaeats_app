import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../design_system/design_system.dart';

/// Standard Vendor Header
/// 
/// A reusable header component that provides consistent styling across all vendor screens.
/// Based on the VendorDashboardHeader design with gradient background and enhanced styling.
class StandardVendorHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? titleIcon;
  final VoidCallback? onNotificationTap;
  final int? notificationCount;
  final VoidCallback? onProfileTap;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const StandardVendorHeader({
    super.key,
    required this.title,
    this.titleIcon,
    this.onNotificationTap,
    this.notificationCount,
    this.onProfileTap,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: const BoxDecoration(
        gradient: GEGradients.headerGradient135,
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000), // 15% opacity black
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        title: _buildTitle(theme),
        leading: showBackButton ? _buildBackButton(context) : null,
        automaticallyImplyLeading: showBackButton,
        actions: _buildActions(context),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: bottom,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      children: [
        if (titleIcon != null) ...[
          Icon(
            titleIcon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: GESpacing.xs),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    if (!showBackButton) return null;
    
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      tooltip: 'Back',
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actionsList = <Widget>[];

    // Add notification button if callback is provided
    if (onNotificationTap != null) {
      actionsList.add(
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: onNotificationTap,
              tooltip: 'Notifications',
            ),
            if (notificationCount != null && notificationCount! > 0)
              Positioned(
                right: 8,
                top: 8,
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
                    notificationCount! > 99 ? '99+' : notificationCount.toString(),
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
      );
    }

    // Add profile button if callback is provided
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

    return actionsList;
  }
}
