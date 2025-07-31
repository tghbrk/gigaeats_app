import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/driver_withdrawal_request.dart';

/// Filter chips widget for withdrawal status and other filters
class WithdrawalStatusFilterChips extends StatelessWidget {
  final DriverWithdrawalStatus? selectedStatus;
  final String? selectedMethod;
  final DateTimeRange? selectedDateRange;
  final Function(DriverWithdrawalStatus?) onStatusChanged;
  final Function(String?) onMethodChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final VoidCallback onClearFilters;

  const WithdrawalStatusFilterChips({
    super.key,
    this.selectedStatus,
    this.selectedMethod,
    this.selectedDateRange,
    required this.onStatusChanged,
    required this.onMethodChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Filters',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Status filter chip
              if (selectedStatus != null)
                _buildFilterChip(
                  context,
                  label: _getStatusDisplayName(selectedStatus!),
                  icon: _getStatusIcon(selectedStatus!),
                  color: _getStatusColor(selectedStatus!),
                  onDeleted: () => onStatusChanged(null),
                ),

              // Method filter chip
              if (selectedMethod != null && selectedMethod!.isNotEmpty)
                _buildFilterChip(
                  context,
                  label: _getMethodDisplayName(selectedMethod!),
                  icon: Icons.payment,
                  color: theme.colorScheme.primary,
                  onDeleted: () => onMethodChanged(null),
                ),

              // Date range filter chip
              if (selectedDateRange != null)
                _buildFilterChip(
                  context,
                  label: _getDateRangeDisplayName(selectedDateRange!),
                  icon: Icons.date_range,
                  color: theme.colorScheme.secondary,
                  onDeleted: () => onDateRangeChanged(null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onDeleted,
  }) {
    final theme = Theme.of(context);

    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: color,
      ),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
        size: 16,
        color: color,
      ),
      onDeleted: onDeleted,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(
        color: color.withValues(alpha: 0.3),
        width: 1,
      ),
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

  IconData _getStatusIcon(DriverWithdrawalStatus status) {
    switch (status) {
      case DriverWithdrawalStatus.pending:
        return Icons.schedule;
      case DriverWithdrawalStatus.processing:
        return Icons.sync;
      case DriverWithdrawalStatus.completed:
        return Icons.check_circle;
      case DriverWithdrawalStatus.failed:
        return Icons.error;
      case DriverWithdrawalStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(DriverWithdrawalStatus status) {
    switch (status) {
      case DriverWithdrawalStatus.pending:
        return Colors.orange;
      case DriverWithdrawalStatus.processing:
        return Colors.blue;
      case DriverWithdrawalStatus.completed:
        return Colors.green;
      case DriverWithdrawalStatus.failed:
        return Colors.red;
      case DriverWithdrawalStatus.cancelled:
        return Colors.grey;
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

  String _getDateRangeDisplayName(DateTimeRange dateRange) {
    final formatter = DateFormat('MMM dd');
    final startDate = formatter.format(dateRange.start);
    final endDate = formatter.format(dateRange.end);
    
    if (dateRange.start.year != dateRange.end.year) {
      final yearFormatter = DateFormat('MMM dd, yyyy');
      return '${yearFormatter.format(dateRange.start)} - ${yearFormatter.format(dateRange.end)}';
    }
    
    return '$startDate - $endDate';
  }
}
