import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/driver_withdrawal_request.dart';

/// List item widget for displaying withdrawal request in history
class WithdrawalHistoryListItem extends StatelessWidget {
  final DriverWithdrawalRequest request;
  final VoidCallback onTap;

  const WithdrawalHistoryListItem({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with amount and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RM ${request.amount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (request.processingFee > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Net: RM ${request.netAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, request.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Method and destination info
              Row(
                children: [
                  Icon(
                    _getMethodIcon(request.withdrawalMethod),
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getMethodDisplayName(request.withdrawalMethod),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (request.destinationDetails.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getDestinationDisplayText(request.destinationDetails),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Date and reference info
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(request.requestedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (request.transactionReference != null) ...[
                    Text(
                      'Ref: ${request.transactionReference}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
              
              // Processing timeline for non-pending requests
              if (request.status != DriverWithdrawalStatus.pending) ...[
                const SizedBox(height: 12),
                _buildProcessingTimeline(context, request),
              ],
              
              // Failure reason if failed
              if (request.status == DriverWithdrawalStatus.failed && request.failureReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.failureReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, DriverWithdrawalStatus status) {
    final theme = Theme.of(context);
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo['icon'],
            size: 12,
            color: statusInfo['color'],
          ),
          const SizedBox(width: 4),
          Text(
            statusInfo['label'],
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusInfo['color'],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingTimeline(BuildContext context, DriverWithdrawalRequest request) {
    final theme = Theme.of(context);
    final timelineItems = <Map<String, dynamic>>[];

    // Add requested
    timelineItems.add({
      'label': 'Requested',
      'date': request.requestedAt,
      'completed': true,
    });

    // Add processed if available
    if (request.processedAt != null) {
      timelineItems.add({
        'label': 'Processed',
        'date': request.processedAt,
        'completed': true,
      });
    }

    // Add completed if available
    if (request.completedAt != null) {
      timelineItems.add({
        'label': 'Completed',
        'date': request.completedAt,
        'completed': true,
      });
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: timelineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == timelineItems.length - 1;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item['completed'] 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['label'],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: item['completed'] 
                            ? theme.colorScheme.onSurface 
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatTimelineDate(item['date']),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  Expanded(
                    child: Container(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(DriverWithdrawalStatus status) {
    switch (status) {
      case DriverWithdrawalStatus.pending:
        return {
          'label': 'Pending',
          'icon': Icons.schedule,
          'color': Colors.orange,
        };
      case DriverWithdrawalStatus.processing:
        return {
          'label': 'Processing',
          'icon': Icons.sync,
          'color': Colors.blue,
        };
      case DriverWithdrawalStatus.completed:
        return {
          'label': 'Completed',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case DriverWithdrawalStatus.failed:
        return {
          'label': 'Failed',
          'icon': Icons.error,
          'color': Colors.red,
        };
      case DriverWithdrawalStatus.cancelled:
        return {
          'label': 'Cancelled',
          'icon': Icons.cancel,
          'color': Colors.grey,
        };
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return Icons.account_balance;
      case 'e_wallet':
        return Icons.account_balance_wallet;
      case 'cash_pickup':
        return Icons.local_atm;
      default:
        return Icons.payment;
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

  String _getDestinationDisplayText(Map<String, dynamic> destinationDetails) {
    if (destinationDetails.containsKey('bank_name') && destinationDetails.containsKey('account_number')) {
      final bankName = destinationDetails['bank_name'] ?? '';
      final accountNumber = destinationDetails['account_number'] ?? '';
      final maskedAccount = accountNumber.length > 4 
          ? '**** ${accountNumber.substring(accountNumber.length - 4)}'
          : accountNumber;
      return '$bankName - $maskedAccount';
    }
    
    if (destinationDetails.containsKey('wallet_provider')) {
      return destinationDetails['wallet_provider'] ?? 'E-Wallet';
    }
    
    return 'Withdrawal destination';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(date);
    } else {
      return DateFormat('MMM dd, HH:mm').format(date);
    }
  }

  String _formatTimelineDate(DateTime date) {
    return DateFormat('MMM dd\nHH:mm').format(date);
  }
}
