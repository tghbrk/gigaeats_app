import 'package:flutter/material.dart';
import '../../../../../../design_system/design_system.dart';

/// Dashboard Empty State Component
/// 
/// A component that displays encouraging messages and call-to-action
/// buttons when there's no data to show in the dashboard.
class DashboardEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Color? iconColor;
  final Color? actionColor;
  final EdgeInsetsGeometry? margin;

  const DashboardEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onActionTap,
    this.iconColor,
    this.actionColor,
    this.margin,
  });

  /// Factory constructor for no orders state
  factory DashboardEmptyState.noOrders({
    VoidCallback? onGetMarketingTips,
    EdgeInsetsGeometry? margin,
  }) {
    return DashboardEmptyState(
      title: 'No orders yet today!',
      message: 'Try promoting your menu or adding special offers to attract more customers.',
      icon: Icons.trending_up,
      actionLabel: 'Get Marketing Tips',
      onActionTap: onGetMarketingTips,
      iconColor: GEVendorColors.primaryGreen,
      actionColor: GEVendorColors.primaryGreen,
      margin: margin,
    );
  }

  /// Factory constructor for no menu items state
  factory DashboardEmptyState.noMenuItems({
    VoidCallback? onAddMenuItem,
    EdgeInsetsGeometry? margin,
  }) {
    return DashboardEmptyState(
      title: 'No menu items yet!',
      message: 'Start by adding your first menu item to begin receiving orders.',
      icon: Icons.restaurant_menu,
      actionLabel: 'Add Menu Item',
      onActionTap: onAddMenuItem,
      iconColor: GEVendorColors.secondaryBlue,
      actionColor: GEVendorColors.secondaryBlue,
      margin: margin,
    );
  }

  /// Factory constructor for no revenue state
  factory DashboardEmptyState.noRevenue({
    VoidCallback? onViewTips,
    EdgeInsetsGeometry? margin,
  }) {
    return DashboardEmptyState(
      title: 'No revenue yet!',
      message: 'Focus on getting your first orders to start earning revenue.',
      icon: Icons.attach_money,
      actionLabel: 'View Growth Tips',
      onActionTap: onViewTips,
      iconColor: GEVendorColors.warningOrange,
      actionColor: GEVendorColors.warningOrange,
      margin: margin,
    );
  }

  /// Factory constructor for no reviews state
  factory DashboardEmptyState.noReviews({
    VoidCallback? onLearnMore,
    EdgeInsetsGeometry? margin,
  }) {
    return DashboardEmptyState(
      title: 'No reviews yet!',
      message: 'Provide excellent service to start receiving customer reviews.',
      icon: Icons.star_outline,
      actionLabel: 'Learn More',
      onActionTap: onLearnMore,
      iconColor: GEVendorColors.ratingIconColor,
      actionColor: GEVendorColors.ratingIconColor,
      margin: margin,
    );
  }

  /// Factory constructor for general empty state
  factory DashboardEmptyState.general({
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    String? actionLabel,
    VoidCallback? onActionTap,
    EdgeInsetsGeometry? margin,
  }) {
    return DashboardEmptyState(
      title: title,
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onActionTap: onActionTap,
      iconColor: GEVendorColors.textLight,
      actionColor: GEVendorColors.primaryGreen,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: GESpacing.screenPadding,
        vertical: GESpacing.md,
      ),
      child: GECard.elevated(
        padding: const EdgeInsets.all(GESpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            _buildIcon(),
            
            const SizedBox(height: GESpacing.sm),
            
            // Title
            _buildTitle(theme),
            
            const SizedBox(height: GESpacing.xs),
            
            // Message
            _buildMessage(theme),
            
            // Action button
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: GESpacing.sm),
              _buildActionButton(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: (iconColor ?? GEVendorColors.textLight).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 32,
        color: iconColor ?? GEVendorColors.textLight,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: GEVendorColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(ThemeData theme) {
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: GEVendorColors.textSecondary,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onActionTap,
        icon: Icon(
          Icons.lightbulb_outline,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          actionLabel!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: actionColor ?? GEVendorColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: GESpacing.sm,
            horizontal: GESpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GESpacing.xs),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

/// Animated Empty State with fade-in effect
class AnimatedDashboardEmptyState extends StatefulWidget {
  final DashboardEmptyState emptyState;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedDashboardEmptyState({
    super.key,
    required this.emptyState,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedDashboardEmptyState> createState() => _AnimatedDashboardEmptyStateState();
}

class _AnimatedDashboardEmptyStateState extends State<AnimatedDashboardEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
    
    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.emptyState,
          ),
        );
      },
    );
  }
}
