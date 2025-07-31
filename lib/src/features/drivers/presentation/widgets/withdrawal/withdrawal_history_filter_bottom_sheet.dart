import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/models/driver_withdrawal_request.dart';

/// Bottom sheet widget for filtering withdrawal history
class WithdrawalHistoryFilterBottomSheet extends StatefulWidget {
  final DriverWithdrawalStatus? selectedStatus;
  final String? selectedMethod;
  final DateTimeRange? selectedDateRange;
  final double? minAmount;
  final double? maxAmount;
  final Function(
    DriverWithdrawalStatus?,
    String?,
    DateTimeRange?,
    double?,
    double?,
  ) onApplyFilters;

  const WithdrawalHistoryFilterBottomSheet({
    super.key,
    this.selectedStatus,
    this.selectedMethod,
    this.selectedDateRange,
    this.minAmount,
    this.maxAmount,
    required this.onApplyFilters,
  });

  @override
  State<WithdrawalHistoryFilterBottomSheet> createState() => _WithdrawalHistoryFilterBottomSheetState();
}

class _WithdrawalHistoryFilterBottomSheetState extends State<WithdrawalHistoryFilterBottomSheet> {
  late DriverWithdrawalStatus? _selectedStatus;
  late String? _selectedMethod;
  late DateTimeRange? _selectedDateRange;
  late double? _minAmount;
  late double? _maxAmount;

  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  final List<String> _withdrawalMethods = [
    'bank_transfer',
    'e_wallet',
    'cash_pickup',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedMethod = widget.selectedMethod;
    _selectedDateRange = widget.selectedDateRange;
    _minAmount = widget.minAmount;
    _maxAmount = widget.maxAmount;

    if (_minAmount != null) {
      _minAmountController.text = _minAmount!.toStringAsFixed(2);
    }
    if (_maxAmount != null) {
      _maxAmountController.text = _maxAmount!.toStringAsFixed(2);
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
                // Handle bar
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Filter Withdrawals',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
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
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status filter
                        _buildStatusFilter(theme),
                        const SizedBox(height: 24),

                        // Method filter
                        _buildMethodFilter(theme),
                        const SizedBox(height: 24),

                        // Date range filter
                        _buildDateRangeFilter(theme),
                        const SizedBox(height: 24),

                        // Amount range filter
                        _buildAmountRangeFilter(theme),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
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

  Widget _buildStatusFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip(theme, null, 'All'),
            ...DriverWithdrawalStatus.values.map(
              (status) => _buildStatusChip(theme, status, _getStatusDisplayName(status)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, DriverWithdrawalStatus? status, String label) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildMethodFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawal Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMethodChip(theme, null, 'All Methods'),
            ..._withdrawalMethods.map(
              (method) => _buildMethodChip(theme, method, _getMethodDisplayName(method)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodChip(ThemeData theme, String? method, String label) {
    final isSelected = _selectedMethod == method;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMethod = selected ? method : null;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
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
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                        : 'Select date range',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _selectedDateRange != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    iconSize: 20,
                  ),
              ],
            ),
          ),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Min Amount',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _minAmount = double.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Max Amount',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _maxAmount = double.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusDisplayName(DriverWithdrawalStatus status) {
    switch (status) {
      case DriverWithdrawalStatus.pending:
        return 'Pending';
      case DriverWithdrawalStatus.processing:
        return 'Processing';
      case DriverWithdrawalStatus.completed:
        return 'Completed';
      case DriverWithdrawalStatus.failed:
        return 'Failed';
      case DriverWithdrawalStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getMethodDisplayName(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'e_wallet':
        return 'E-Wallet';
      case 'cash_pickup':
        return 'Cash Pickup';
      default:
        return method.replaceAll('_', ' ').split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
        ).join(' ');
    }
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateRange = dateRange;
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedMethod = null;
      _selectedDateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(
      _selectedStatus,
      _selectedMethod,
      _selectedDateRange,
      _minAmount,
      _maxAmount,
    );
    Navigator.of(context).pop();
  }
}
