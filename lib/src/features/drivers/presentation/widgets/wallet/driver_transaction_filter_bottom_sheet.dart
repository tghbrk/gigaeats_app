import 'package:flutter/material.dart';

import '../../../data/models/driver_wallet_transaction.dart';
import '../../providers/driver_wallet_transaction_provider.dart';

/// Bottom sheet for advanced driver wallet transaction filtering
class DriverTransactionFilterBottomSheet extends StatefulWidget {
  final DriverWalletTransactionFilter currentFilter;
  final Function(DriverWalletTransactionFilter) onApplyFilter;

  const DriverTransactionFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  State<DriverTransactionFilterBottomSheet> createState() => 
      _DriverTransactionFilterBottomSheetState();
}

class _DriverTransactionFilterBottomSheetState 
    extends State<DriverTransactionFilterBottomSheet> {
  late DriverWalletTransactionFilter _filter;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    
    // Initialize amount controllers
    if (_filter.minAmount != null) {
      _minAmountController.text = _filter.minAmount!.toStringAsFixed(2);
    }
    if (_filter.maxAmount != null) {
      _maxAmountController.text = _filter.maxAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Transactions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Transaction type filter
                    _buildTransactionTypeFilter(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Date range filter
                    _buildDateRangeFilter(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Amount range filter
                    _buildAmountRangeFilter(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Sort options
                    _buildSortOptions(theme),
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionTypeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // All types option
            FilterChip(
              label: const Text('All Types'),
              selected: _filter.type == null,
              onSelected: (selected) {
                setState(() {
                  _filter = _filter.copyWith(type: null);
                });
              },
            ),
            
            // Individual transaction types
            ...DriverWalletTransactionType.values.map((type) {
              return FilterChip(
                label: Text(type.displayName),
                selected: _filter.type == type,
                onSelected: (selected) {
                  setState(() {
                    _filter = _filter.copyWith(type: selected ? type : null);
                  });
                },
                avatar: Text(type.icon),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectStartDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _filter.startDate != null
                      ? '${_filter.startDate!.day}/${_filter.startDate!.month}/${_filter.startDate!.year}'
                      : 'Start Date',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectEndDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _filter.endDate != null
                      ? '${_filter.endDate!.day}/${_filter.endDate!.month}/${_filter.endDate!.year}'
                      : 'End Date',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Quick date range options
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Today'),
              selected: _isToday(),
              onSelected: (selected) => _setDateRange('today'),
            ),
            FilterChip(
              label: const Text('This Week'),
              selected: _isThisWeek(),
              onSelected: (selected) => _setDateRange('week'),
            ),
            FilterChip(
              label: const Text('This Month'),
              selected: _isThisMonth(),
              onSelected: (selected) => _setDateRange('month'),
            ),
            FilterChip(
              label: const Text('Last 30 Days'),
              selected: _isLast30Days(),
              onSelected: (selected) => _setDateRange('30days'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount Range (RM)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: 'Min Amount',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _filter = _filter.copyWith(minAmount: amount);
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                decoration: const InputDecoration(
                  labelText: 'Max Amount',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _filter = _filter.copyWith(maxAmount: amount);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort Options',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _filter.sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sort By',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'created_at', child: Text('Date')),
                  DropdownMenuItem(value: 'amount', child: Text('Amount')),
                  DropdownMenuItem(value: 'transaction_type', child: Text('Type')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filter = _filter.copyWith(sortBy: value);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<bool>(
                initialValue: _filter.ascending,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: false, child: Text('Newest First')),
                  DropdownMenuItem(value: true, child: Text('Oldest First')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filter = _filter.copyWith(ascending: value);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filter.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _filter = _filter.copyWith(startDate: date);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filter.endDate ?? DateTime.now(),
      firstDate: _filter.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _filter = _filter.copyWith(endDate: date);
      });
    }
  }

  void _setDateRange(String range) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (range) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case '30days':
        startDate = now.subtract(const Duration(days: 30));
        break;
    }

    setState(() {
      _filter = _filter.copyWith(startDate: startDate, endDate: endDate);
    });
  }

  bool _isToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _filter.startDate?.isAtSameMomentAs(today) == true;
  }

  bool _isThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _filter.startDate?.isAtSameMomentAs(weekStart) == true;
  }

  bool _isThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _filter.startDate?.isAtSameMomentAs(monthStart) == true;
  }

  bool _isLast30Days() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return _filter.startDate?.isAtSameMomentAs(thirtyDaysAgo) == true;
  }

  void _clearAllFilters() {
    setState(() {
      _filter = const DriverWalletTransactionFilter();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    widget.onApplyFilter(_filter);
    Navigator.of(context).pop();
  }
}
