import 'package:flutter/material.dart';

import '../../data/models/driver.dart';

/// Widget to display driver status with appropriate color and icon
class DriverStatusIndicator extends StatelessWidget {
  final DriverStatus status;
  final double size;
  final bool showLabel;
  final bool showIcon;

  const DriverStatusIndicator({
    super.key,
    required this.status,
    this.size = 16,
    this.showLabel = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor();
    final icon = _getStatusIcon();

    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              icon,
              color: color,
              size: size,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (showIcon) {
      return Icon(
        icon,
        color: color,
        size: size,
      );
    }

    // Just a colored dot if no icon or label
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case DriverStatus.offline:
        return Colors.grey;
      case DriverStatus.online:
        return Colors.green;
      case DriverStatus.onDelivery:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case DriverStatus.offline:
        return Icons.cancel;
      case DriverStatus.online:
        return Icons.check_circle;
      case DriverStatus.onDelivery:
        return Icons.local_shipping;
    }
  }
}

/// Animated status indicator that pulses for active statuses
class AnimatedDriverStatusIndicator extends StatefulWidget {
  final DriverStatus status;
  final double size;
  final bool showLabel;

  const AnimatedDriverStatusIndicator({
    super.key,
    required this.status,
    this.size = 16,
    this.showLabel = false,
  });

  @override
  State<AnimatedDriverStatusIndicator> createState() => _AnimatedDriverStatusIndicatorState();
}

class _AnimatedDriverStatusIndicatorState extends State<AnimatedDriverStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Only animate for active statuses
    if (widget.status == DriverStatus.online || widget.status == DriverStatus.onDelivery) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedDriverStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.status != widget.status) {
      if (widget.status == DriverStatus.online || widget.status == DriverStatus.onDelivery) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: DriverStatusIndicator(
            status: widget.status,
            size: widget.size,
            showLabel: widget.showLabel,
          ),
        );
      },
    );
  }
}

/// Status badge with background color
class DriverStatusBadge extends StatelessWidget {
  final DriverStatus status;
  final EdgeInsets padding;

  const DriverStatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case DriverStatus.offline:
        return Colors.grey;
      case DriverStatus.online:
        return Colors.green;
      case DriverStatus.onDelivery:
        return Colors.blue;
    }
  }
}

/// Large status card for dashboard display
class DriverStatusCard extends StatelessWidget {
  final DriverStatus status;
  final int count;
  final VoidCallback? onTap;

  const DriverStatusCard({
    super.key,
    required this.status,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                _getStatusIcon(),
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case DriverStatus.offline:
        return Colors.grey;
      case DriverStatus.online:
        return Colors.green;
      case DriverStatus.onDelivery:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case DriverStatus.offline:
        return Icons.cancel;
      case DriverStatus.online:
        return Icons.check_circle;
      case DriverStatus.onDelivery:
        return Icons.local_shipping;
    }
  }
}
