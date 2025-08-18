import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../design_system/design_system.dart';

/// Enhanced Vendor Dashboard Header
/// 
/// A custom header component with gradient background and enhanced
/// styling to match the UI/UX mockup specifications.
class VendorDashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final int? notificationCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const VendorDashboardHeader({
    super.key,
    this.title = 'Vendor Dashboard',
    this.onNotificationTap,
    this.notificationCount,
    this.onProfileTap,
    this.onSettingsTap,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.store,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: GESpacing.xs),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    if (!showBackButton) return null;
    
    return IconButton(
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      icon: const Icon(
        Icons.arrow_back,
        color: Colors.white,
      ),
      tooltip: 'Back',
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final defaultActions = <Widget>[
      // Notifications
      _buildHeaderIcon(
        icon: Icons.notifications,
        onTap: onNotificationTap,
        badge: notificationCount,
        tooltip: 'Notifications',
      ),
      
      // Profile
      _buildHeaderIcon(
        icon: Icons.account_circle,
        onTap: onProfileTap,
        tooltip: 'Profile',
      ),
      
      // Settings
      _buildHeaderIcon(
        icon: Icons.settings,
        onTap: onSettingsTap ?? () => _showSettingsMenu(context),
        tooltip: 'Settings',
      ),
    ];

    // Add custom actions if provided
    if (actions != null) {
      defaultActions.addAll(actions!);
    }

    return defaultActions;
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    VoidCallback? onTap,
    int? badge,
    String? tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: GESpacing.xs),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildBadge(badge),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: GEVendorColors.dangerRed,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GESpacing.sm),
        ),
      ),
      builder: (context) => _buildSettingsMenu(context),
    );
  }

  Widget _buildSettingsMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GESpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: GESpacing.md),
          
          // Title
          Text(
            'Dashboard Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: GESpacing.md),
          
          // Settings options
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to notification settings
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to theme settings
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to help
            },
          ),
          
          const SizedBox(height: GESpacing.sm),
        ],
      ),
    );
  }
}

/// Sliver version of the enhanced header for use with CustomScrollView
class SliverVendorDashboardHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final int? notificationCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final List<Widget>? actions;
  final bool pinned;
  final bool floating;

  const SliverVendorDashboardHeader({
    super.key,
    this.title = 'Vendor Dashboard',
    this.onNotificationTap,
    this.notificationCount,
    this.onProfileTap,
    this.onSettingsTap,
    this.actions,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.store,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: GESpacing.xs),
          Text(title),
        ],
      ),
      actions: _buildActions(context),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      pinned: pinned,
      floating: floating,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: GEGradients.headerGradient135,
        ),
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      // Use the same action building logic as the regular header
      VendorDashboardHeader(
        onNotificationTap: onNotificationTap,
        notificationCount: notificationCount,
        onProfileTap: onProfileTap,
        onSettingsTap: onSettingsTap,
        actions: actions,
      )._buildActions(context).first, // Get the first action as example
    ];
  }
}
