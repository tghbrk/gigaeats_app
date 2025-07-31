import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';

/// Main date filter component for driver order history
class DriverOrderDateFilter extends ConsumerStatefulWidget {
  final bool showAsBottomSheet;
  final VoidCallback? onFilterApplied;

  const DriverOrderDateFilter({
    super.key,
    this.showAsBottomSheet = false,
    this.onFilterApplied,
  });

  @override
  ConsumerState<DriverOrderDateFilter> createState() => _DriverOrderDateFilterState();
}

class _DriverOrderDateFilterState extends ConsumerState<DriverOrderDateFilter> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  QuickDateFilter? _tempQuickFilter;

  @override
  void initState() {
    super.initState();
    // Initialize with current filter state
    final currentFilter = ref.read(dateFilterProvider);
    final currentQuickFilter = ref.read(selectedQuickFilterProvider);
    
    _tempStartDate = currentFilter.startDate;
    _tempEndDate = currentFilter.endDate;
    _tempQuickFilter = currentQuickFilter;
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
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Filter Order History',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Content
          _buildFilterContent(theme),
          
          const SizedBox(height: 32),
          
          // Action buttons
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildInlineContent(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Orders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterContent(theme),
            const SizedBox(height: 16),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick filters section
        Text(
          'Quick Filters',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickFilters(theme),
        
        const SizedBox(height: 24),
        
        // Custom date range section
        Text(
          'Custom Date Range',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildCustomDateRange(theme),
      ],
    );
  }

  Widget _buildQuickFilters(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: QuickDateFilter.values.map((filter) {
        final isSelected = _tempQuickFilter == filter;
        
        return FilterChip(
          label: Text(filter.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _tempQuickFilter = filter;
                // Clear custom dates when selecting quick filter
                if (filter != QuickDateFilter.all) {
                  _tempStartDate = null;
                  _tempEndDate = null;
                }
              } else {
                _tempQuickFilter = null;
              }
            });
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
        );
      }).toList(),
    );
  }

  Widget _buildCustomDateRange(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                theme: theme,
                label: 'Start Date',
                value: _tempStartDate,
                onTap: () => _selectStartDate(),
                enabled: _tempQuickFilter == null || _tempQuickFilter == QuickDateFilter.all,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                theme: theme,
                label: 'End Date',
                value: _tempEndDate,
                onTap: () => _selectEndDate(),
                enabled: _tempQuickFilter == null || _tempQuickFilter == QuickDateFilter.all,
              ),
            ),
          ],
        ),
        
        if (_tempStartDate != null || _tempEndDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
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
                    _getDateRangeDescription(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_tempStartDate != null || _tempEndDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _tempStartDate = null;
                        _tempEndDate = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    tooltip: 'Clear custom dates',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required ThemeData theme,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled 
                ? theme.colorScheme.outline.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled 
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: enabled 
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: enabled 
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null 
                        ? DateFormat('MMM dd, yyyy').format(value)
                        : 'Select date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: enabled 
                          ? (value != null 
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant)
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
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
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }

  String _getDateRangeDescription() {
    if (_tempStartDate != null && _tempEndDate != null) {
      final days = _tempEndDate!.difference(_tempStartDate!).inDays + 1;
      return 'Showing orders from $days day${days == 1 ? '' : 's'}';
    } else if (_tempStartDate != null) {
      return 'Showing orders from ${DateFormat('MMM dd').format(_tempStartDate!)} onwards';
    } else if (_tempEndDate != null) {
      return 'Showing orders until ${DateFormat('MMM dd').format(_tempEndDate!)}';
    }
    return '';
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
        _tempQuickFilter = null; // Clear quick filter when setting custom date
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
        _tempQuickFilter = null; // Clear quick filter when setting custom date
      });
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
    debugPrint('🚗 DateFilter: Applying filters - Quick: $_tempQuickFilter, Start: $_tempStartDate, End: $_tempEndDate');
    
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
    
    if (widget.showAsBottomSheet) {
      Navigator.of(context).pop();
    }
  }
}
