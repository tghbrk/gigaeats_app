import 'package:flutter/material.dart';

/// Compact summary widget for scheduled delivery information in order confirmations
class ScheduledDeliverySummary extends StatelessWidget {
  final DateTime scheduledTime;
  final bool showIcon;
  final bool showTimeUntil;
  final TextStyle? titleStyle;
  final TextStyle? timeStyle;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const ScheduledDeliverySummary({
    super.key,
    required this.scheduledTime,
    this.showIcon = true,
    this.showTimeUntil = true,
    this.titleStyle,
    this.timeStyle,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.schedule,
              size: 20,
              color: iconColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scheduled Delivery',
                  style: titleStyle ?? theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatScheduledTime(scheduledTime),
                  style: timeStyle ?? theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showTimeUntil) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Delivery in ${_getTimeUntilDelivery(scheduledTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (scheduledDay == today) {
      return 'Today at $timeString';
    } else if (scheduledDay == tomorrow) {
      return 'Tomorrow at $timeString';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final dateString = '${dateTime.day} ${months[dateTime.month - 1]}';
      return '$dateString at $timeString';
    }
  }

  String _getTimeUntilDelivery(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'very soon';
    }
  }
}

/// Inline scheduled delivery info for order lists
class InlineScheduledDeliveryInfo extends StatelessWidget {
  final DateTime scheduledTime;
  final bool compact;

  const InlineScheduledDeliveryInfo({
    super.key,
    required this.scheduledTime,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatCompactTime(scheduledTime),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatScheduledTime(scheduledTime),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (scheduledDay == today) {
      return 'Today $timeString';
    } else if (scheduledDay == tomorrow) {
      return 'Tomorrow $timeString';
    } else {
      return '${dateTime.day}/${dateTime.month} $timeString';
    }
  }

  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (scheduledDay == today) {
      return 'Today at $timeString';
    } else if (scheduledDay == tomorrow) {
      return 'Tomorrow at $timeString';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final dateString = '${dateTime.day} ${months[dateTime.month - 1]}';
      return '$dateString at $timeString';
    }
  }
}

/// Badge widget for scheduled delivery status
class ScheduledDeliveryBadge extends StatelessWidget {
  final DateTime scheduledTime;
  final bool showTimeUntil;

  const ScheduledDeliveryBadge({
    super.key,
    required this.scheduledTime,
    this.showTimeUntil = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(scheduledTime);
    final isTomorrow = _isTomorrow(scheduledTime);
    
    Color badgeColor;
    String badgeText;
    
    if (isToday) {
      badgeColor = theme.colorScheme.error;
      badgeText = 'Today';
    } else if (isTomorrow) {
      badgeColor = theme.colorScheme.secondary;
      badgeText = 'Tomorrow';
    } else {
      badgeColor = theme.colorScheme.primary;
      badgeText = 'Scheduled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            showTimeUntil ? _getTimeUntilDelivery(scheduledTime) : badgeText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return scheduledDay == today;
  }

  bool _isTomorrow(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return scheduledDay == tomorrow;
  }

  String _getTimeUntilDelivery(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Soon';
    }
  }
}
