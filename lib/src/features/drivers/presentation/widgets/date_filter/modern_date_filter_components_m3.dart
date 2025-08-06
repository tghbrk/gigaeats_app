import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';

/// Modern Material Design 3 compliant date filter components
/// 
/// This file contains enhanced UI components that follow Material Design 3 guidelines
/// with improved accessibility, responsive design, and modern visual styling.

/// Modern quick filter chip bar with Material Design 3 styling
class ModernQuickFilterChipBar extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final bool showScrollIndicators;
  final double chipSpacing;
  final bool showFilterCount;
  final VoidCallback? onFilterChanged;

  const ModernQuickFilterChipBar({
    super.key,
    this.padding,
    this.showScrollIndicators = true,
    this.chipSpacing = 8.0,
    this.showFilterCount = false,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedQuickFilter = ref.watch(selectedQuickFilterProvider);
    final colorScheme = theme.colorScheme;
    
    // Get commonly used filters for better UX
    final commonFilters = QuickDateFilter.values.where((f) => f.isCommonlyUsed).toList();
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Filters',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showFilterCount) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${commonFilters.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: commonFilters.length,
              separatorBuilder: (context, index) => SizedBox(width: chipSpacing),
              itemBuilder: (context, index) {
                final filter = commonFilters[index];
                final isSelected = selectedQuickFilter == filter;
                
                return _buildModernFilterChip(
                  context,
                  theme,
                  filter,
                  isSelected,
                  ref,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(
    BuildContext context,
    ThemeData theme,
    QuickDateFilter filter,
    bool isSelected,
    WidgetRef ref,
  ) {
    final colorScheme = theme.colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleFilterSelection(ref, filter),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFilterIcon(filter),
                size: 16,
                color: isSelected 
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                filter.displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected 
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleFilterSelection(WidgetRef ref, QuickDateFilter filter) {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(filter);
    if (filter != QuickDateFilter.all) {
      ref.read(dateFilterProvider.notifier).reset();
    }
    onFilterChanged?.call();
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

/// Modern filter status card with Material Design 3 styling
class ModernFilterStatusCard extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final bool showClearButton;
  final bool showOrderCount;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClearTap;

  const ModernFilterStatusCard({
    super.key,
    this.padding,
    this.showClearButton = true,
    this.showOrderCount = true,
    this.onFilterTap,
    this.onClearTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedQuickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final combinedFilter = ref.watch(combinedDateFilterProvider);
    
    final hasActiveFilter = selectedQuickFilter != QuickDateFilter.all || dateFilter.hasActiveFilter;
    final filterDescription = _getFilterDescription(selectedQuickFilter, dateFilter);
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Material(
        color: hasActiveFilter 
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        elevation: hasActiveFilter ? 2 : 0,
        shadowColor: colorScheme.primary.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Filter icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasActiveFilter 
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasActiveFilter 
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_outlined,
                    size: 20,
                    color: hasActiveFilter 
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Filter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasActiveFilter ? 'Active Filter' : 'All Orders',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        filterDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showOrderCount) ...[
                        const SizedBox(height: 4),
                        Consumer(
                          builder: (context, ref, child) {
                            final orderCountAsync = ref.watch(orderCountByDateProvider(combinedFilter));
                            return orderCountAsync.when(
                              data: (count) => Text(
                                '$count orders',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              loading: () => SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                              error: (_, stackTrace) => Text(
                                'Error loading count',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasActiveFilter && showClearButton)
                      IconButton(
                        onPressed: onClearTap ?? () => _clearFilters(ref),
                        icon: Icon(
                          Icons.clear_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'Clear filters',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.tune_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFilterDescription(QuickDateFilter quickFilter, DateRangeFilter dateFilter) {
    if (quickFilter != QuickDateFilter.all) {
      return quickFilter.shortDescription;
    } else if (dateFilter.hasActiveFilter) {
      return dateFilter.description;
    } else {
      return 'Showing all order history';
    }
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
    ref.read(dateFilterProvider.notifier).reset();
  }
}

/// Modern date range picker with Material Design 3 styling
class ModernDateRangePicker extends ConsumerStatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime?, DateTime?)? onDateRangeChanged;
  final bool showPresets;
  final EdgeInsetsGeometry? padding;

  const ModernDateRangePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.onDateRangeChanged,
    this.showPresets = true,
    this.padding,
  });

  @override
  ConsumerState<ModernDateRangePicker> createState() => _ModernDateRangePickerState();
}

class _ModernDateRangePickerState extends ConsumerState<ModernDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Custom Date Range',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date selection cards
          Row(
            children: [
              Expanded(
                child: _buildDateCard(
                  context,
                  theme,
                  'Start Date',
                  _startDate,
                  Icons.event_rounded,
                  () => _selectStartDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateCard(
                  context,
                  theme,
                  'End Date',
                  _endDate,
                  Icons.event_available_rounded,
                  () => _selectEndDate(context),
                ),
              ),
            ],
          ),

          if (widget.showPresets) ...[
            const SizedBox(height: 20),
            _buildPresetButtons(theme),
          ],

          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 16),
            _buildRangeSummary(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    ThemeData theme,
    String label,
    DateTime? date,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = theme.colorScheme;
    final hasDate = date != null;

    return Material(
      color: hasDate
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasDate
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: hasDate ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: hasDate
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasDate
                    ? _formatDate(date)
                    : 'Select date',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasDate
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButtons(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final presets = [
      {'label': 'Last 7 days', 'days': 7},
      {'label': 'Last 30 days', 'days': 30},
      {'label': 'Last 90 days', 'days': 90},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            return OutlinedButton.icon(
              onPressed: () => _applyPreset(preset['days'] as int),
              icon: Icon(
                Icons.schedule_rounded,
                size: 16,
              ),
              label: Text(preset['label'] as String),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRangeSummary(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final hasValidRange = _startDate != null && _endDate != null;

    String summaryText;
    if (hasValidRange) {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      summaryText = '$days days selected (${_formatDate(_startDate!)} - ${_formatDate(_endDate!)})';
    } else if (_startDate != null) {
      summaryText = 'From ${_formatDate(_startDate!)}';
    } else if (_endDate != null) {
      summaryText = 'Until ${_formatDate(_endDate!)}';
    } else {
      summaryText = 'No date range selected';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summaryText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              onPressed: _clearDateRange,
              icon: Icon(
                Icons.clear_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Clear date range',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        // Ensure end date is not before start date
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
      widget.onDateRangeChanged?.call(_startDate, _endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
      widget.onDateRangeChanged?.call(_startDate, _endDate);
    }
  }

  void _applyPreset(int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });

    widget.onDateRangeChanged?.call(_startDate, _endDate);
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    widget.onDateRangeChanged?.call(null, null);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
