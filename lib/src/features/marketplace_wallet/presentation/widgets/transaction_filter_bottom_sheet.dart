import 'package:flutter/material.dart';

import '../providers/customer_transaction_management_provider.dart';
import '../../data/models/customer_wallet.dart';

/// Bottom sheet for advanced transaction filtering
class TransactionFilterBottomSheet extends StatefulWidget {
  final CustomerTransactionFilter currentFilter;
  final Function(CustomerTransactionFilter) onApplyFilter;

  const TransactionFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  State<TransactionFilterBottomSheet> createState() => _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState extends State<TransactionFilterBottomSheet> {
  late CustomerTransactionFilter _filter;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    
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

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Filter Transactions',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
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
      ),
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
            
            // Individual type options
            ...CustomerTransactionType.values.map((type) {
              return FilterChip(
                label: Text(type.displayName),
                selected: _filter.type == type,
                onSelected: (selected) {
                  setState(() {
                    _filter = _filter.copyWith(type: selected ? type : null);
                  });
                },
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
              child: _buildDateField(
                theme,
                'Start Date',
                _filter.startDate,
                (date) => setState(() {
                  _filter = _filter.copyWith(startDate: date);
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                theme,
                'End Date',
                _filter.endDate,
                (date) => setState(() {
                  _filter = _filter.copyWith(endDate: date);
                }),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Quick date range options
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateOption(theme, 'Last 7 days', 7),
            _buildQuickDateOption(theme, 'Last 30 days', 30),
            _buildQuickDateOption(theme, 'Last 90 days', 90),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    ThemeData theme,
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value != null 
                  ? '${value.day}/${value.month}/${value.year}'
                  : 'Select date',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateOption(ThemeData theme, String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final endDate = DateTime.now();
        final startDate = endDate.subtract(Duration(days: days));
        setState(() {
          _filter = _filter.copyWith(
            startDate: startDate,
            endDate: endDate,
          );
        });
      },
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
                  _filter = _filter.copyWith(minAmount: amount);
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
                  _filter = _filter.copyWith(maxAmount: amount);
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
          'Sort By',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _filter.sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'created_at', child: Text('Date')),
                  DropdownMenuItem(value: 'amount', child: Text('Amount')),
                  DropdownMenuItem(value: 'type', child: Text('Type')),
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
                value: _filter.ascending,
                decoration: const InputDecoration(
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

  void _clearAllFilters() {
    setState(() {
      _filter = const CustomerTransactionFilter();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    widget.onApplyFilter(_filter);
    Navigator.of(context).pop();
  }
}
