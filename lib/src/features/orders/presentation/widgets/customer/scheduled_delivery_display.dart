import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../data/services/schedule_delivery_validation_service.dart';
import '../../providers/schedule_validation_provider.dart';
import 'schedule_time_picker.dart';

/// Enhanced display widget for scheduled delivery information
class ScheduledDeliveryDisplay extends ConsumerWidget {
  final DateTime? scheduledTime;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onClear;
  final bool showEditButton;
  final bool showClearButton;
  final bool showValidationStatus;
  final bool isRequired;
  final String? title;
  final String? emptyStateText;
  final EdgeInsetsGeometry? padding;
  final dynamic vendor;

  const ScheduledDeliveryDisplay({
    super.key,
    this.scheduledTime,
    this.onTap,
    this.onEdit,
    this.onClear,
    this.showEditButton = true,
    this.showClearButton = false,
    this.showValidationStatus = true,
    this.isRequired = false,
    this.title = 'Scheduled Delivery',
    this.emptyStateText = 'Tap to select delivery time',
    this.padding,
    this.vendor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasScheduledTime = scheduledTime != null;
    
    // Get validation status if time is set and validation is enabled
    ScheduleValidationResult? validationResult;
    if (hasScheduledTime && showValidationStatus) {
      validationResult = ref.watch(scheduleTimeValidationProvider(scheduledTime!));
    }

    return Card(
      elevation: hasScheduledTime ? 1 : 4,
      color: _getCardColor(theme, hasScheduledTime, validationResult),
      child: InkWell(
        onTap: onTap ?? _showScheduleTimePicker(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, hasScheduledTime, validationResult),
              if (hasScheduledTime) ...[
                const SizedBox(height: 8),
                _buildScheduledTimeInfo(theme, validationResult),
              ],
              if (validationResult != null && validationResult.hasWarnings) ...[
                const SizedBox(height: 12),
                _buildWarnings(theme, validationResult),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color? _getCardColor(ThemeData theme, bool hasScheduledTime, ScheduleValidationResult? validation) {
    if (!hasScheduledTime && isRequired) {
      return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
    }
    
    if (validation != null && !validation.isValid) {
      return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
    }
    
    if (!hasScheduledTime) {
      return theme.colorScheme.primaryContainer.withValues(alpha: 0.1);
    }
    
    return null;
  }

  Widget _buildHeader(ThemeData theme, bool hasScheduledTime, ScheduleValidationResult? validation) {
    final isError = (!hasScheduledTime && isRequired) || (validation != null && !validation.isValid);
    
    return Row(
      children: [
        Icon(
          Icons.schedule,
          color: isError 
              ? theme.colorScheme.error
              : hasScheduledTime 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'Scheduled Delivery',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isError ? theme.colorScheme.error : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasScheduledTime 
                    ? _formatScheduledTime(scheduledTime!)
                    : emptyStateText ?? 'Tap to select delivery time',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasScheduledTime
                      ? theme.colorScheme.onSurfaceVariant
                      : isError
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                  fontWeight: hasScheduledTime ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildActionButtons(theme, hasScheduledTime),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool hasScheduledTime) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasScheduledTime && showEditButton)
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Edit scheduled time',
          ),
        if (hasScheduledTime && showClearButton)
          IconButton(
            onPressed: onClear,
            icon: Icon(
              Icons.clear,
              size: 20,
              color: theme.colorScheme.error,
            ),
            tooltip: 'Clear scheduled time',
          ),
        if (!hasScheduledTime || (!showEditButton && !showClearButton))
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }

  Widget _buildScheduledTimeInfo(ThemeData theme, ScheduleValidationResult? validation) {
    final timeUntil = _getTimeUntilDelivery(scheduledTime!);
    final isValid = validation?.isValid ?? true;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: isValid 
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid 
                  ? 'Delivery in $timeUntil'
                  : validation?.primaryError ?? 'Invalid time selected',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isValid 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(ThemeData theme, ScheduleValidationResult validation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Please Note:',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...validation.warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              '• $warning',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontSize: 11,
              ),
            ),
          )),
        ],
      ),
    );
  }

  VoidCallback? _showScheduleTimePicker(BuildContext context, WidgetRef ref) {
    return () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ScheduleTimePicker(
          initialDateTime: scheduledTime,
          onDateTimeSelected: (dateTime) {
            if (dateTime != null) {
              onTap?.call();
              AppLogger().info('ScheduledDeliveryDisplay: Time selected: $dateTime');
            }
          },
          onCancel: () {
            AppLogger().info('ScheduledDeliveryDisplay: Selection cancelled');
          },
          vendor: vendor,
          title: 'Schedule Your Delivery',
          subtitle: 'Choose when you\'d like your order to be delivered',
        ),
      );
    };
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
