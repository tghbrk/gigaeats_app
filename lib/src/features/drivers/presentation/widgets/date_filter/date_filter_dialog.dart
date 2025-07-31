import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';
import 'calendar_date_picker.dart';

/// Comprehensive date filter dialog with multiple selection methods
class DateFilterDialog extends ConsumerStatefulWidget {
  final VoidCallback? onFilterApplied;

  const DateFilterDialog({
    super.key,
    this.onFilterApplied,
  });

  @override
  ConsumerState<DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends ConsumerState<DateFilterDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  QuickDateFilter? _tempQuickFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize with current filter state
    final currentFilter = ref.read(dateFilterProvider);
    final currentQuickFilter = ref.read(selectedQuickFilterProvider);
    
    _tempStartDate = currentFilter.startDate;
    _tempEndDate = currentFilter.endDate;
    _tempQuickFilter = currentQuickFilter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),
            
            // Tab bar
            _buildTabBar(theme),
            
            // Tab content
            Flexible(
              child: _buildTabContent(theme),
            ),
            
            // Action buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Filter Order History',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.tune),
            text: 'Quick Filters',
          ),
          Tab(
            icon: Icon(Icons.calendar_month),
            text: 'Calendar',
          ),
        ],
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium,
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TabBarView(
        controller: _tabController,
        children: [
          // Quick filters tab
          _buildQuickFiltersTab(theme),
          
          // Calendar tab
          _buildCalendarTab(theme),
        ],
      ),
    );
  }

  Widget _buildQuickFiltersTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a time period',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick filter options
          ...QuickDateFilter.values.map((filter) {
            final isSelected = _tempQuickFilter == filter;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _tempQuickFilter = filter;
                    if (filter != QuickDateFilter.all) {
                      _tempStartDate = null;
                      _tempEndDate = null;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected 
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getQuickFilterIcon(filter),
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              filter.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (filter != QuickDateFilter.all)
                              Text(
                                _getQuickFilterDescription(filter),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(ThemeData theme) {
    return OrderHistoryCalendarDatePicker(
      allowRangeSelection: true,
      initialDate: _tempStartDate ?? DateTime.now(),
      initialStartDate: _tempStartDate,
      initialEndDate: _tempEndDate,
      onDateRangeSelected: (start, end) {
        setState(() {
          _tempStartDate = start;
          _tempEndDate = end;
          _tempQuickFilter = null; // Clear quick filter when using calendar
        });
      },
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filter'),
            ),
          ),
        ],
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
        return Icons.view_week;
      case QuickDateFilter.lastWeek:
        return Icons.view_week_outlined;
      case QuickDateFilter.thisMonth:
        return Icons.calendar_view_month;
      case QuickDateFilter.lastMonth:
        return Icons.calendar_view_month_outlined;
      case QuickDateFilter.last7Days:
        return Icons.date_range;
      case QuickDateFilter.last30Days:
        return Icons.date_range;
      case QuickDateFilter.last90Days:
        return Icons.date_range_outlined;
      case QuickDateFilter.thisYear:
        return Icons.calendar_today;
      case QuickDateFilter.lastYear:
        return Icons.calendar_today_outlined;
      case QuickDateFilter.all:
        return Icons.history;
    }
  }

  String _getQuickFilterDescription(QuickDateFilter filter) {
    switch (filter) {
      case QuickDateFilter.today:
        return 'Orders delivered today';
      case QuickDateFilter.yesterday:
        return 'Orders delivered yesterday';
      case QuickDateFilter.thisWeek:
        return 'Orders from this week';
      case QuickDateFilter.lastWeek:
        return 'Orders from last week';
      case QuickDateFilter.thisMonth:
        return 'Orders from this month';
      case QuickDateFilter.lastMonth:
        return 'Orders from last month';
      case QuickDateFilter.last7Days:
        return 'Orders from the last 7 days';
      case QuickDateFilter.last30Days:
        return 'Orders from the last 30 days';
      case QuickDateFilter.last90Days:
        return 'Orders from the last 90 days';
      case QuickDateFilter.thisYear:
        return 'Orders from this year';
      case QuickDateFilter.lastYear:
        return 'Orders from last year';
      case QuickDateFilter.all:
        return 'All order history';
    }
  }

  void _resetFilters() {
    setState(() {
      _tempStartDate = null;
      _tempEndDate = null;
      _tempQuickFilter = QuickDateFilter.all;
    });
  }

  void _applyFilters() {
    debugPrint('🚗 DateFilterDialog: Applying filters - Quick: $_tempQuickFilter, Start: $_tempStartDate, End: $_tempEndDate');
    
    // Apply quick filter if selected
    if (_tempQuickFilter != null && _tempQuickFilter != QuickDateFilter.all) {
      ref.read(selectedQuickFilterProvider.notifier).setFilter(_tempQuickFilter!);
      ref.read(dateFilterProvider.notifier).reset(); // Reset custom filter
    } else {
      // Apply custom date range
      ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
      ref.read(dateFilterProvider.notifier).setCustomDateRange(_tempStartDate, _tempEndDate);
    }
    
    widget.onFilterApplied?.call();
    Navigator.of(context).pop();
  }
}

/// Utility function to show the date filter dialog
Future<void> showDateFilterDialog(
  BuildContext context, {
  VoidCallback? onFilterApplied,
}) {
  return showDialog(
    context: context,
    builder: (context) => DateFilterDialog(
      onFilterApplied: onFilterApplied,
    ),
  );
}
