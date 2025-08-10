import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/customer_order_filter_providers.dart';
import '../../providers/enhanced_customer_order_history_providers.dart';
import '../../../data/models/customer_order_history_models.dart';

import 'customer_order_date_filter.dart';

/// Compact date filter bar for customer orders
class CustomerCompactDateFilterBar extends ConsumerWidget {
  final bool showOrderCount;
  final bool showSpendingTotal;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onFilterChanged;

  const CustomerCompactDateFilterBar({
    super.key,
    this.showOrderCount = true,
    this.showSpendingTotal = false,
    this.padding,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(customerOrderFilterProvider);
    final currentFilter = ref.watch(currentCustomerOrderFilterProvider);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Current filter display
          Expanded(
            child: _buildCurrentFilterDisplay(theme, filterState),
          ),
          
          const SizedBox(width: 12),
          
          // Order count and spending (if enabled)
          if (showOrderCount || showSpendingTotal) ...[
            _buildStatsDisplay(theme, ref, currentFilter),
            const SizedBox(width: 12),
          ],
          
          // Filter button
          _buildFilterButton(theme, context),
        ],
      ),
    );
  }

  Widget _buildCurrentFilterDisplay(ThemeData theme, CustomerOrderFilterState filterState) {
    String displayText;
    IconData icon;
    Color backgroundColor;
    Color foregroundColor;

    if (filterState.selectedQuickFilter != null && 
        filterState.selectedQuickFilter != CustomerQuickDateFilter.all) {
      displayText = filterState.selectedQuickFilter!.displayName;
      icon = _getQuickFilterIcon(filterState.selectedQuickFilter!);
      backgroundColor = theme.colorScheme.primaryContainer;
      foregroundColor = theme.colorScheme.onPrimaryContainer;
    } else if (filterState.filter.hasDateFilter) {
      displayText = _getCustomDateRangeText(filterState.filter);
      icon = Icons.date_range;
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
    } else {
      displayText = 'All Orders';
      icon = Icons.shopping_bag;
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      foregroundColor = theme.colorScheme.onSurfaceVariant;
    }

    // Add status filter indicator
    if (filterState.filter.statusFilter != null && 
        filterState.filter.statusFilter != CustomerOrderFilterStatus.active) {
      displayText += ' • ${filterState.filter.statusFilter!.displayName}';
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

  Widget _buildStatsDisplay(ThemeData theme, WidgetRef ref, CustomerDateRangeFilter filter) {
    if (showOrderCount) {
      final orderCountAsync = ref.watch(customerOrderCountProvider(filter));
      
      return orderCountAsync.when(
        data: (count) => _buildStatsChip(
          theme,
          icon: Icons.receipt_long,
          label: '$count orders',
          color: theme.colorScheme.tertiary,
        ),
        loading: () => _buildStatsChip(
          theme,
          icon: Icons.receipt_long,
          label: '...',
          color: theme.colorScheme.tertiary,
        ),
        error: (_, stackTrace) => _buildStatsChip(
          theme,
          icon: Icons.error_outline,
          label: 'Error',
          color: theme.colorScheme.error,
        ),
      );
    }

    if (showSpendingTotal) {
      final statsAsync = ref.watch(customerOrderHistoryStatsProvider(filter));
      
      return statsAsync.when(
        data: (stats) => _buildStatsChip(
          theme,
          icon: Icons.attach_money,
          label: 'RM${stats.totalSpent.toStringAsFixed(0)}',
          color: theme.colorScheme.tertiary,
        ),
        loading: () => _buildStatsChip(
          theme,
          icon: Icons.attach_money,
          label: '...',
          color: theme.colorScheme.tertiary,
        ),
        error: (_, stackTrace) => _buildStatsChip(
          theme,
          icon: Icons.error_outline,
          label: 'Error',
          color: theme.colorScheme.error,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatsChip(ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(ThemeData theme, BuildContext context) {
    return IconButton.filled(
      onPressed: () => _showFilterDialog(context),
      icon: const Icon(Icons.tune),
      tooltip: 'Filter orders',
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomerOrderDateFilter(
        onFilterApplied: onFilterChanged,
      ),
    );
  }

  IconData _getQuickFilterIcon(CustomerQuickDateFilter filter) {
    switch (filter) {
      case CustomerQuickDateFilter.today:
        return Icons.today;
      case CustomerQuickDateFilter.yesterday:
        return Icons.history;
      case CustomerQuickDateFilter.thisWeek:
      case CustomerQuickDateFilter.lastWeek:
      case CustomerQuickDateFilter.last7Days:
        return Icons.view_week;
      case CustomerQuickDateFilter.thisMonth:
      case CustomerQuickDateFilter.lastMonth:
      case CustomerQuickDateFilter.last30Days:
        return Icons.calendar_view_month;
      case CustomerQuickDateFilter.last90Days:
        return Icons.calendar_view_day;
      case CustomerQuickDateFilter.thisYear:
      case CustomerQuickDateFilter.lastYear:
        return Icons.calendar_today;
      case CustomerQuickDateFilter.all:
        return Icons.all_inclusive;
    }
  }

  String _getCustomDateRangeText(CustomerDateRangeFilter filter) {
    if (filter.startDate != null && filter.endDate != null) {
      return CustomerGroupedOrderHistory.getDateRangeDisplay(
        filter.startDate!,
        filter.endDate!,
      );
    } else if (filter.startDate != null) {
      return 'From ${DateFormat('MMM dd').format(filter.startDate!)}';
    } else if (filter.endDate != null) {
      return 'Until ${DateFormat('MMM dd').format(filter.endDate!)}';
    } else {
      return 'Custom Range';
    }
  }
}

/// Quick filter chips for customer orders
class CustomerQuickFilterChips extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final double chipSpacing;
  final VoidCallback? onFilterChanged;

  const CustomerQuickFilterChips({
    super.key,
    this.padding,
    this.chipSpacing = 8.0,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(customerOrderFilterProvider);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: CustomerQuickDateFilter.values.map((filter) {
            final isSelected = filterState.selectedQuickFilter == filter;
            
            return Padding(
              padding: EdgeInsets.only(right: chipSpacing),
              child: FilterChip(
                label: Text(filter.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(customerOrderFilterProvider.notifier).applyQuickFilter(filter);
                    onFilterChanged?.call();
                  }
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Customer order filter summary widget
class CustomerOrderFilterSummary extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;

  const CustomerOrderFilterSummary({
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentFilter = ref.watch(currentCustomerOrderFilterProvider);
    final statsAsync = ref.watch(customerOrderHistoryStatsProvider(currentFilter));
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: statsAsync.when(
        data: (stats) => _buildSummaryCard(theme, stats),
        loading: () => _buildLoadingCard(theme),
        error: (error, _) => _buildErrorCard(theme, error.toString()),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, CustomerOrderHistorySummary stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Total Orders',
                    '${stats.totalOrders}',
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Total Spent',
                    'RM${stats.totalSpent.toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Completed',
                    '${stats.completedOrders}',
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Cancelled',
                    '${stats.cancelledOrders}',
                    Icons.cancel,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final itemColor = color ?? theme.colorScheme.primary;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: itemColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              'Loading summary...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Error loading summary',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
