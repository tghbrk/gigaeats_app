import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/customer_order_filter_providers.dart';
import '../../../data/models/customer_order_history_models.dart';

/// Main date filter component for customer order history
class CustomerOrderDateFilter extends ConsumerStatefulWidget {
  final bool showAsBottomSheet;
  final VoidCallback? onFilterApplied;
  final bool showStatusFilter;

  const CustomerOrderDateFilter({
    super.key,
    this.showAsBottomSheet = false,
    this.onFilterApplied,
    this.showStatusFilter = true,
  });

  @override
  ConsumerState<CustomerOrderDateFilter> createState() => _CustomerOrderDateFilterState();
}

class _CustomerOrderDateFilterState extends ConsumerState<CustomerOrderDateFilter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Temporary state for dialog
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  CustomerQuickDateFilter? _tempQuickFilter;
  CustomerOrderFilterStatus? _tempStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.showStatusFilter ? 3 : 2, vsync: this);
    
    // Initialize with current filter state
    final currentState = ref.read(customerOrderFilterProvider);
    _tempStartDate = currentState.filter.startDate;
    _tempEndDate = currentState.filter.endDate;
    _tempQuickFilter = currentState.selectedQuickFilter;
    _tempStatusFilter = currentState.filter.statusFilter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.showAsBottomSheet) {
      return _buildBottomSheet(theme);
    } else {
      return _buildDialog(theme);
    }
  }

  Widget _buildBottomSheet(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildDialog(ThemeData theme) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        _buildHeader(theme),
        
        // Tab bar
        _buildTabBar(theme),
        
        // Tab content
        Flexible(child: _buildTabContent(theme)),
        
        // Action buttons
        _buildActionButtons(theme),
      ],
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
              'Filter Orders',
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
    final tabs = [
      const Tab(text: 'Quick Filters'),
      const Tab(text: 'Custom Range'),
      if (widget.showStatusFilter) const Tab(text: 'Status'),
    ];

    return TabBar(
      controller: _tabController,
      tabs: tabs,
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
      indicatorColor: theme.colorScheme.primary,
      indicatorWeight: 3,
      labelStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: theme.textTheme.titleSmall,
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
          
          // Custom range tab
          _buildCustomRangeTab(theme),
          
          // Status filter tab
          if (widget.showStatusFilter)
            _buildStatusFilterTab(theme),
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
          ...CustomerQuickDateFilter.values.map((filter) {
            final isSelected = _tempQuickFilter == filter;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(filter.displayName),
                subtitle: Text(
                  filter.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                leading: Radio<CustomerQuickDateFilter>(
                  value: filter,
                  groupValue: _tempQuickFilter,
                  onChanged: (value) {
                    setState(() {
                      _tempQuickFilter = value;
                      // Clear custom dates when selecting quick filter
                      if (value != null && value != CustomerQuickDateFilter.all) {
                        _tempStartDate = null;
                        _tempEndDate = null;
                      }
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _tempQuickFilter = filter;
                    if (filter != CustomerQuickDateFilter.all) {
                      _tempStartDate = null;
                      _tempEndDate = null;
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected 
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomRangeTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select custom date range',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Start date
          _buildDateField(
            theme,
            label: 'Start Date',
            date: _tempStartDate,
            onTap: () => _selectStartDate(),
            icon: Icons.calendar_today,
          ),
          
          const SizedBox(height: 16),
          
          // End date
          _buildDateField(
            theme,
            label: 'End Date',
            date: _tempEndDate,
            onTap: () => _selectEndDate(),
            icon: Icons.event,
          ),
          
          const SizedBox(height: 24),
          
          // Clear dates button
          if (_tempStartDate != null || _tempEndDate != null)
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _tempStartDate = null;
                    _tempEndDate = null;
                    _tempQuickFilter = CustomerQuickDateFilter.all;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Dates'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by order status',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          
          // Status filter options
          ...CustomerOrderFilterStatus.values.map((status) {
            final isSelected = _tempStatusFilter == status;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(status.displayName),
                subtitle: Text(
                  status.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                leading: Radio<CustomerOrderFilterStatus>(
                  value: status,
                  groupValue: _tempStatusFilter,
                  onChanged: (value) {
                    setState(() {
                      _tempStatusFilter = value;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _tempStatusFilter = status;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected 
                    ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateField(
    ThemeData theme, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null 
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Select date',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: date != null 
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      _tempQuickFilter = CustomerQuickDateFilter.all;
      _tempStatusFilter = CustomerOrderFilterStatus.all;
    });
  }

  void _applyFilters() {
    final filterNotifier = ref.read(customerOrderFilterProvider.notifier);
    
    // Apply quick filter or custom date range
    if (_tempQuickFilter != null && _tempQuickFilter != CustomerQuickDateFilter.all) {
      filterNotifier.applyQuickFilter(_tempQuickFilter!);
    } else {
      filterNotifier.updateDateRange(
        startDate: _tempStartDate,
        endDate: _tempEndDate,
      );
    }
    
    // Apply status filter
    if (_tempStatusFilter != null) {
      filterNotifier.updateStatusFilter(_tempStatusFilter);
    }
    
    // Apply and save the filter
    filterNotifier.applyFilter();
    
    // Callback and close
    widget.onFilterApplied?.call();
    Navigator.of(context).pop();
  }
}
