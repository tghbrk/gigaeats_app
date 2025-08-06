import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';
import 'modern_date_filter_components_m3.dart';

/// Modern Material Design 3 compliant date filter dialog
class ModernDateFilterDialog extends ConsumerStatefulWidget {
  final VoidCallback? onFilterApplied;
  final bool showAsBottomSheet;

  const ModernDateFilterDialog({
    super.key,
    this.onFilterApplied,
    this.showAsBottomSheet = false,
  });

  @override
  ConsumerState<ModernDateFilterDialog> createState() => _ModernDateFilterDialogState();
}

class _ModernDateFilterDialogState extends ConsumerState<ModernDateFilterDialog>
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
    final colorScheme = theme.colorScheme;

    if (widget.showAsBottomSheet) {
      return _buildBottomSheetContent(theme, colorScheme);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: _buildDialogContent(theme, colorScheme),
    );
  }

  Widget _buildBottomSheetContent(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(
            child: _buildDialogContent(theme, colorScheme, isBottomSheet: true),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogContent(ThemeData theme, ColorScheme colorScheme, {bool isBottomSheet = false}) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: isBottomSheet ? MediaQuery.of(context).size.height * 0.8 : 700,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isBottomSheet ? 0 : 28),
        boxShadow: isBottomSheet ? null : [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(theme, colorScheme, isBottomSheet),
          
          // Tab bar
          _buildTabBar(theme, colorScheme),
          
          // Content
          Flexible(
            child: _buildTabContent(theme, colorScheme),
          ),
          
          // Actions
          _buildActions(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, bool isBottomSheet) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, isBottomSheet ? 16 : 24, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_alt_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Orders',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a time period to filter your order history',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isBottomSheet)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.speed_rounded, size: 20),
            text: 'Quick Filters',
          ),
          Tab(
            icon: Icon(Icons.calendar_month_rounded, size: 20),
            text: 'Custom Range',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme, ColorScheme colorScheme) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Quick filters tab
        _buildQuickFiltersTab(theme, colorScheme),
        
        // Custom range tab
        _buildCustomRangeTab(theme, colorScheme),
      ],
    );
  }

  Widget _buildQuickFiltersTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a time period',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from commonly used date ranges',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick filter grid
          _buildQuickFilterGrid(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildQuickFilterGrid(ThemeData theme, ColorScheme colorScheme) {
    final filters = QuickDateFilter.values;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filters.length,
      itemBuilder: (context, index) {
        final filter = filters[index];
        final isSelected = _tempQuickFilter == filter;
        
        return _buildQuickFilterCard(theme, colorScheme, filter, isSelected);
      },
    );
  }

  Widget _buildQuickFilterCard(ThemeData theme, ColorScheme colorScheme, QuickDateFilter filter, bool isSelected) {
    return Material(
      color: isSelected 
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _selectQuickFilter(filter),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    _getFilterIcon(filter),
                    size: 20,
                    color: isSelected 
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.primary,
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                filter.displayName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected 
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                filter.shortDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                      : colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangeTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: ModernDateRangePicker(
        initialStartDate: _tempStartDate,
        initialEndDate: _tempEndDate,
        onDateRangeChanged: (start, end) {
          setState(() {
            _tempStartDate = start;
            _tempEndDate = end;
            _tempQuickFilter = QuickDateFilter.all; // Clear quick filter when using custom range

          });
        },
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _buildActions(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          // Clear button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Apply button
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply Filters'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectQuickFilter(QuickDateFilter filter) {
    setState(() {
      _tempQuickFilter = filter;
      if (filter != QuickDateFilter.all) {
        _tempStartDate = null;
        _tempEndDate = null;
      }

    });
  }

  void _clearFilters() {
    setState(() {
      _tempQuickFilter = QuickDateFilter.all;
      _tempStartDate = null;
      _tempEndDate = null;

    });
  }

  void _applyFilters() {
    // Apply quick filter if selected
    if (_tempQuickFilter != null && _tempQuickFilter != QuickDateFilter.all) {
      ref.read(selectedQuickFilterProvider.notifier).setFilter(_tempQuickFilter!);
      ref.read(dateFilterProvider.notifier).reset();
    } else {
      // Apply custom date range
      ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
      ref.read(dateFilterProvider.notifier).setCustomDateRange(_tempStartDate, _tempEndDate);
    }
    
    widget.onFilterApplied?.call();
    Navigator.of(context).pop();
  }

  IconData _getFilterIcon(QuickDateFilter filter) {
    switch (filter) {
      case QuickDateFilter.today:
        return Icons.today_rounded;
      case QuickDateFilter.yesterday:
        return Icons.history_rounded;
      case QuickDateFilter.thisWeek:
      case QuickDateFilter.lastWeek:
      case QuickDateFilter.last7Days:
        return Icons.view_week_rounded;
      case QuickDateFilter.thisMonth:
      case QuickDateFilter.lastMonth:
      case QuickDateFilter.last30Days:
        return Icons.calendar_view_month_rounded;
      case QuickDateFilter.last90Days:
        return Icons.date_range_rounded;
      case QuickDateFilter.thisYear:
      case QuickDateFilter.lastYear:
        return Icons.calendar_today_rounded;
      case QuickDateFilter.all:
        return Icons.all_inclusive_rounded;
    }
  }
}

/// Show modern date filter dialog
Future<void> showModernDateFilterDialog(
  BuildContext context, {
  VoidCallback? onFilterApplied,
}) {
  return showDialog(
    context: context,
    builder: (context) => ModernDateFilterDialog(
      onFilterApplied: onFilterApplied,
    ),
  );
}

/// Show modern date filter bottom sheet
Future<void> showModernDateFilterBottomSheet(
  BuildContext context, {
  VoidCallback? onFilterApplied,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ModernDateFilterDialog(
      onFilterApplied: onFilterApplied,
      showAsBottomSheet: true,
    ),
  );
}
