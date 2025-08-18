import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/enhanced_vendor_order_history_providers.dart';
import '../../../data/models/vendor_date_range_filter.dart';

/// Compact date filter bar for vendor orders
class VendorCompactDateFilterBar extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final bool showOrderCount;

  const VendorCompactDateFilterBar({
    super.key,
    this.padding,
    this.showOrderCount = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedQuickFilter = ref.watch(vendorSelectedQuickFilterProvider);
    final dateFilter = ref.watch(vendorDateFilterProvider);
    final combinedFilter = ref.watch(vendorCombinedDateFilterProvider);

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

  Widget _buildCurrentFilterDisplay(ThemeData theme, VendorQuickDateFilter selectedQuickFilter, VendorDateRangeFilter dateFilter) {
    String displayText;
    IconData icon;
    Color? backgroundColor;
    Color? foregroundColor;

    if (selectedQuickFilter != VendorQuickDateFilter.all) {
      displayText = selectedQuickFilter.displayName;
      icon = Icons.schedule;
      backgroundColor = theme.colorScheme.primaryContainer;
      foregroundColor = theme.colorScheme.onPrimaryContainer;
    } else if (dateFilter.hasActiveFilter) {
      displayText = dateFilter.description;
      icon = Icons.date_range;
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
    } else {
      displayText = 'All Orders';
      icon = Icons.filter_list;
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      foregroundColor = theme.colorScheme.onSurface;
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

  Widget _buildOrderCount(ThemeData theme, WidgetRef ref, VendorDateRangeFilter filter) {
    final orderCountAsync = ref.watch(vendorOrderCountByDateProvider(filter));

    return orderCountAsync.when(
      data: (countByDate) {
        final totalCount = countByDate.values.fold(0, (sum, count) => sum + count);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalCount orders',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFilterButton(ThemeData theme, BuildContext context) {
    return IconButton.filled(
      onPressed: () => _showFilterBottomSheet(context),
      icon: const Icon(Icons.tune),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const VendorOrderDateFilter(showAsBottomSheet: true),
    );
  }
}

/// Main date filter component for vendor order history
class VendorOrderDateFilter extends ConsumerStatefulWidget {
  final bool showAsBottomSheet;
  final VoidCallback? onFilterApplied;

  const VendorOrderDateFilter({
    super.key,
    this.showAsBottomSheet = false,
    this.onFilterApplied,
  });

  @override
  ConsumerState<VendorOrderDateFilter> createState() => _VendorOrderDateFilterState();
}

class _VendorOrderDateFilterState extends ConsumerState<VendorOrderDateFilter> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  VendorQuickDateFilter? _tempQuickFilter;
  VendorOrderFilterStatus? _tempStatusFilter;

  @override
  void initState() {
    super.initState();
    // Initialize with current filter state
    final currentFilter = ref.read(vendorDateFilterProvider);
    final currentQuickFilter = ref.read(vendorSelectedQuickFilterProvider);
    
    _tempStartDate = currentFilter.startDate;
    _tempEndDate = currentFilter.endDate;
    _tempQuickFilter = currentQuickFilter;
    _tempStatusFilter = currentFilter.statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.showAsBottomSheet) {
      return _buildBottomSheetContent(theme);
    }
    
    return _buildInlineContent(theme);
  }

  Widget _buildBottomSheetContent(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Orders',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Filter content
          _buildFilterContent(theme),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineContent(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Orders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterContent(theme),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick filters
        Text(
          'Quick Filters',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickFilters(theme),
        
        const SizedBox(height: 24),
        
        // Status filter
        Text(
          'Order Status',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusFilter(theme),
        
        const SizedBox(height: 24),
        
        // Custom date range (only show if custom is selected)
        if (_tempQuickFilter == VendorQuickDateFilter.custom) ...[
          Text(
            'Custom Date Range',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildCustomDateRange(theme),
        ],
      ],
    );
  }

  Widget _buildQuickFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VendorQuickDateFilter.values.map((filter) {
        final isSelected = _tempQuickFilter == filter;
        return FilterChip(
          label: Text(filter.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _tempQuickFilter = selected ? filter : VendorQuickDateFilter.all;
              if (filter != VendorQuickDateFilter.custom) {
                // Clear custom dates when selecting a quick filter
                _tempStartDate = null;
                _tempEndDate = null;
              }
            });
          },
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildStatusFilter(ThemeData theme) {
    return DropdownButtonFormField<VendorOrderFilterStatus>(
      initialValue: _tempStatusFilter,
      decoration: const InputDecoration(
        labelText: 'Filter by Status',
        border: OutlineInputBorder(),
      ),
      items: VendorOrderFilterStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _tempStatusFilter = value;
        });
      },
    );
  }

  Widget _buildCustomDateRange(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _tempStartDate != null
                        ? DateFormat('MMM dd, yyyy').format(_tempStartDate!)
                        : 'Select start date',
                    style: _tempStartDate != null
                        ? null
                        : TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _tempEndDate != null
                        ? DateFormat('MMM dd, yyyy').format(_tempEndDate!)
                        : 'Select end date',
                    style: _tempEndDate != null
                        ? null
                        : TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_tempStartDate != null && _tempEndDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Date range: ${_tempEndDate!.difference(_tempStartDate!).inDays + 1} days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tempStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _tempEndDate ?? DateTime.now(),
      helpText: 'Select Start Date',
    );
    
    if (date != null) {
      setState(() {
        _tempStartDate = date;
        _tempQuickFilter = VendorQuickDateFilter.custom; // Set to custom when setting custom date
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tempEndDate ?? DateTime.now(),
      firstDate: _tempStartDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Select End Date',
    );
    
    if (date != null) {
      setState(() {
        _tempEndDate = date;
        _tempQuickFilter = VendorQuickDateFilter.custom; // Set to custom when setting custom date
      });
    }
  }

  void _resetFilters() {
    debugPrint('🏪 VendorDateFilter: Resetting filters');
    setState(() {
      _tempStartDate = null;
      _tempEndDate = null;
      _tempQuickFilter = VendorQuickDateFilter.all;
      _tempStatusFilter = null;
    });
  }

  void _applyFilters() {
    debugPrint('🏪 VendorDateFilter: Applying filters - Quick: $_tempQuickFilter, Start: $_tempStartDate, End: $_tempEndDate, Status: $_tempStatusFilter');
    
    // Apply quick filter if selected
    if (_tempQuickFilter != null && _tempQuickFilter != VendorQuickDateFilter.all) {
      ref.read(vendorSelectedQuickFilterProvider.notifier).setFilter(_tempQuickFilter!);
      if (_tempQuickFilter != VendorQuickDateFilter.custom) {
        ref.read(vendorDateFilterProvider.notifier).reset(); // Reset custom filter
      }
    } else {
      // Apply custom date range
      ref.read(vendorSelectedQuickFilterProvider.notifier).setFilter(VendorQuickDateFilter.all);
      ref.read(vendorDateFilterProvider.notifier).setCustomDateRange(_tempStartDate, _tempEndDate);
    }
    
    // Apply status filter
    ref.read(vendorDateFilterProvider.notifier).setStatusFilter(_tempStatusFilter);
    
    widget.onFilterApplied?.call();
    
    if (widget.showAsBottomSheet) {
      Navigator.of(context).pop();
    }
  }
}
