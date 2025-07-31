import 'package:flutter/material.dart';

import '../../../data/models/driver_wallet_transaction.dart';

/// List item widget for displaying driver wallet transactions
class DriverTransactionListItem extends StatelessWidget {
  final DriverWalletTransaction transaction;
  final VoidCallback? onTap;
  final bool showDate;
  final bool showBalance;

  const DriverTransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDate = true,
    this.showBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction type icon
              _buildTransactionIcon(theme),
              
              const SizedBox(width: 16),
              
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction type and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.transactionType.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildStatusChip(theme),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description or reference
                    if (transaction.description != null) ...[
                      Text(
                        transaction.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (transaction.referenceId != null) ...[
                      Text(
                        'Ref: ${transaction.referenceId}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Date and additional info
                    Row(
                      children: [
                        if (showDate) ...[
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.formattedDateTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        
                        if (showBalance && showDate) ...[
                          const SizedBox(width: 16),
                          const Text('•'),
                          const SizedBox(width: 16),
                        ],
                        
                        if (showBalance) ...[
                          Icon(
                            Icons.account_balance_wallet,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Balance: ${transaction.currency} ${transaction.balanceAfter.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Amount and arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.isCredit 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  if (transaction.processingFee > 0) ...[
                    Text(
                      'Fee: ${transaction.currency} ${transaction.processingFee.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  
                  if (onTap != null) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(ThemeData theme) {
    Color backgroundColor;
    Color iconColor;
    IconData iconData;

    switch (transaction.transactionType) {
      case DriverWalletTransactionType.deliveryEarnings:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        iconColor = Colors.green;
        iconData = Icons.delivery_dining;
        break;
      case DriverWalletTransactionType.completionBonus:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        iconColor = Colors.purple;
        iconData = Icons.star;
        break;
      case DriverWalletTransactionType.tipPayment:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        iconColor = Colors.orange;
        iconData = Icons.attach_money;
        break;
      case DriverWalletTransactionType.performanceBonus:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        iconColor = Colors.blue;
        iconData = Icons.trending_up;
        break;
      case DriverWalletTransactionType.fuelAllowance:
        backgroundColor = Colors.teal.withValues(alpha: 0.1);
        iconColor = Colors.teal;
        iconData = Icons.local_gas_station;
        break;
      case DriverWalletTransactionType.withdrawalRequest:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        iconColor = Colors.red;
        iconData = Icons.account_balance;
        break;
      case DriverWalletTransactionType.bankTransfer:
        backgroundColor = Colors.indigo.withValues(alpha: 0.1);
        iconColor = Colors.indigo;
        iconData = Icons.account_balance;
        break;
      case DriverWalletTransactionType.ewalletPayout:
        backgroundColor = Colors.cyan.withValues(alpha: 0.1);
        iconColor = Colors.cyan;
        iconData = Icons.phone_android;
        break;
      case DriverWalletTransactionType.adjustment:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        iconColor = Colors.grey;
        iconData = Icons.tune;
        break;
      case DriverWalletTransactionType.refund:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        iconColor = Colors.green;
        iconData = Icons.undo;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    final isCompleted = transaction.processedAt != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCompleted ? 'Completed' : 'Pending',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isCompleted ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
