import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';
import 'driver_order_date_filter.dart';

/// Compact date filter bar for app bar or header usage
class CompactDateFilterBar extends ConsumerWidget {
  final bool showOrderCount;
  final EdgeInsetsGeometry? padding;

  const CompactDateFilterBar({
    super.key,
    this.showOrderCount = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedQuickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final combinedFilter = ref.watch(combinedDateFilterProvider);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Current filter display
          Expanded(
            child: _buildCurrentFilterDisplay(theme, selectedQuickFilter, dateFilter),
          ),
          
          const SizedBox(width: 12),
          
          // Order count (if enabled)
          if (showOrderCount) ...[
            _buildOrderCount(theme, ref, combinedFilter),
            const SizedBox(width: 12),
          ],
          
          // Filter button
          _buildFilterButton(theme, context),
        ],
      ),
    );
  }

  Widget _buildCurrentFilterDisplay(
    ThemeData theme,
    QuickDateFilter selectedQuickFilter,
    DateRangeFilter dateFilter,
  ) {
    String displayText;
    IconData icon;
    Color? backgroundColor;
    Color? foregroundColor;

    if (selectedQuickFilter != QuickDateFilter.all) {
      displayText = selectedQuickFilter.displayName;
      icon = _getQuickFilterIcon(selectedQuickFilter);
      backgroundColor = theme.colorScheme.primaryContainer;
      foregroundColor = theme.colorScheme.onPrimaryContainer;
    } else if (dateFilter.startDate != null || dateFilter.endDate != null) {
      displayText = _getCustomDateRangeText(dateFilter);
      icon = Icons.date_range;
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
    } else {
      displayText = 'All Orders';
      icon = Icons.history;
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      foregroundColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              displayText,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCount(ThemeData theme, WidgetRef ref, DateRangeFilter filter) {
    final orderCountAsync = ref.watch(orderCountByDateProvider(filter));
    
    return orderCountAsync.when(
      data: (count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      loading: () => Container(
        width: 24,
        height: 20,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '?',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(ThemeData theme, BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () => _showFilterBottomSheet(context),
      icon: const Icon(Icons.tune),
      tooltip: 'Filter orders',
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  IconData _getQuickFilterIcon(QuickDateFilter filter) {
    switch (filter) {
      case QuickDateFilter.today:
        return Icons.today;
      case QuickDateFilter.yesterday:
        return Icons.history;
      case QuickDateFilter.thisWeek:
      case QuickDateFilter.lastWeek:
      case QuickDateFilter.last7Days:
        return Icons.view_week;
      case QuickDateFilter.thisMonth:
      case QuickDateFilter.lastMonth:
      case QuickDateFilter.last30Days:
        return Icons.calendar_view_month;
      case QuickDateFilter.last90Days:
        return Icons.date_range;
      case QuickDateFilter.thisYear:
      case QuickDateFilter.lastYear:
        return Icons.calendar_today;
      case QuickDateFilter.all:
        return Icons.history;
    }
  }

  String _getCustomDateRangeText(DateRangeFilter filter) {
    if (filter.startDate != null && filter.endDate != null) {
      final start = filter.startDate!;
      final end = filter.endDate!;
      
      if (start.year == end.year) {
        if (start.month == end.month) {
          return '${DateFormat('MMM dd').format(start)} - ${end.day}';
        } else {
          return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}';
        }
      } else {
        return '${DateFormat('MMM dd, yy').format(start)} - ${DateFormat('MMM dd, yy').format(end)}';
      }
    } else if (filter.startDate != null) {
      return 'From ${DateFormat('MMM dd').format(filter.startDate!)}';
    } else if (filter.endDate != null) {
      return 'Until ${DateFormat('MMM dd').format(filter.endDate!)}';
    }
    return 'Custom Range';
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DriverOrderDateFilter(
        showAsBottomSheet: true,
      ),
    );
  }
}

/// Quick filter chips for horizontal scrolling
class QuickFilterChips extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const QuickFilterChips({
    super.key,
    this.padding,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedQuickFilter = ref.watch(selectedQuickFilterProvider);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: QuickDateFilter.values.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final filter = QuickDateFilter.values[index];
          final isSelected = selectedQuickFilter == filter;

          return FilterChip(
            label: Text(filter.displayName),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(selectedQuickFilterProvider.notifier).setFilter(filter);
                if (filter != QuickDateFilter.all) {
                  ref.read(dateFilterProvider.notifier).reset();
                }
              }
            },
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: isSelected 
                ? BorderSide(color: theme.colorScheme.primary, width: 1)
                : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

/// Date range summary widget
class DateRangeSummary extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;

  const DateRangeSummary({
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final combinedFilter = ref.watch(combinedDateFilterProvider);
    final summaryAsync = ref.watch(orderHistorySummaryProvider(combinedFilter));

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: summaryAsync.when(
        data: (summary) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        theme,
                        'Total Orders',
                        '${summary.totalOrders}',
                        Icons.receipt_long,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        theme,
                        'Delivered',
                        '${summary.deliveredOrders}',
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (summary.cancelledOrders > 0)
                      Expanded(
                        child: _buildSummaryItem(
                          theme,
                          'Cancelled',
                          '${summary.cancelledOrders}',
                          Icons.cancel,
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        loading: () => const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final itemColor = color ?? theme.colorScheme.onSurfaceVariant;
    
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: itemColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: itemColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
