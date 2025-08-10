import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customer_order_filter_providers.dart';
import '../../../data/models/customer_order_history_models.dart';
import 'customer_calendar_date_picker.dart';

/// Comprehensive date filter dialog for customer orders with multiple selection methods
class CustomerDateFilterDialog extends ConsumerStatefulWidget {
  final VoidCallback? onFilterApplied;
  final bool showAsBottomSheet;

  const CustomerDateFilterDialog({
    super.key,
    this.onFilterApplied,
    this.showAsBottomSheet = false,
  });

  @override
  ConsumerState<CustomerDateFilterDialog> createState() => _CustomerDateFilterDialogState();
}

class _CustomerDateFilterDialogState extends ConsumerState<CustomerDateFilterDialog>
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
    _tabController = TabController(length: 3, vsync: this);
    
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
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
              Expanded(child: _buildContent(theme, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialog(ThemeData theme) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: _buildContent(theme, null),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ScrollController? scrollController) {
    return Column(
      children: [
        // Header
        _buildHeader(theme),
        
        // Tab bar
        _buildTabBar(theme),
        
        // Tab content
        Expanded(child: _buildTabContent(theme, scrollController)),
        
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
            Icons.tune,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Orders',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Customize your order history view',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(
          icon: Icon(Icons.flash_on),
          text: 'Quick',
        ),
        Tab(
          icon: Icon(Icons.calendar_month),
          text: 'Calendar',
        ),
        Tab(
          icon: Icon(Icons.filter_alt),
          text: 'Status',
        ),
      ],
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

  Widget _buildTabContent(ThemeData theme, ScrollController? scrollController) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Quick filters tab
        _buildQuickFiltersTab(theme, scrollController),
        
        // Calendar tab
        _buildCalendarTab(theme, scrollController),
        
        // Status filter tab
        _buildStatusFilterTab(theme, scrollController),
      ],
    );
  }

  Widget _buildQuickFiltersTab(ThemeData theme, ScrollController? scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a time period',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from predefined time ranges for quick filtering',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick filter grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2, // Reduced from 3.5 to 2.2 for much more height
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: CustomerQuickDateFilter.values.length,
            itemBuilder: (context, index) {
              final filter = CustomerQuickDateFilter.values[index];
              final isSelected = _tempQuickFilter == filter;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _tempQuickFilter = filter;
                    if (filter != CustomerQuickDateFilter.all) {
                      _tempStartDate = null;
                      _tempEndDate = null;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          filter.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Explicit smaller font size
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 1),
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(ThemeData theme, ScrollController? scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select custom date range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the calendar to select specific dates or date ranges',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Calendar picker
          CustomerOrderCalendarDatePicker(
            allowRangeSelection: true,
            initialStartDate: _tempStartDate,
            initialEndDate: _tempEndDate,
            onDateRangeSelected: (start, end) {
              setState(() {
                _tempStartDate = start;
                _tempEndDate = end;
                _tempQuickFilter = null; // Clear quick filter when using calendar
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterTab(ThemeData theme, ScrollController? scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by order status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show only orders with specific status',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Status filter options
          ...CustomerOrderFilterStatus.values.map((status) {
            final isSelected = _tempStatusFilter == status;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _tempStatusFilter = status;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<CustomerOrderFilterStatus>(
                        value: status,
                        groupValue: _tempStatusFilter,
                        onChanged: (value) {
                          setState(() {
                            _tempStatusFilter = value;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected 
                                    ? theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.check),
              label: const Text('Apply Filter'),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _tempStartDate = null;
      _tempEndDate = null;
      _tempQuickFilter = CustomerQuickDateFilter.all;
      _tempStatusFilter = CustomerOrderFilterStatus.active;
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

/// Function to show customer date filter dialog
Future<void> showCustomerDateFilterDialog(
  BuildContext context, {
  VoidCallback? onFilterApplied,
}) {
  return showDialog(
    context: context,
    builder: (context) => CustomerDateFilterDialog(
      onFilterApplied: onFilterApplied,
    ),
  );
}

/// Function to show customer date filter bottom sheet
Future<void> showCustomerDateFilterBottomSheet(
  BuildContext context, {
  VoidCallback? onFilterApplied,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CustomerDateFilterDialog(
      showAsBottomSheet: true,
      onFilterApplied: onFilterApplied,
    ),
  );
}
