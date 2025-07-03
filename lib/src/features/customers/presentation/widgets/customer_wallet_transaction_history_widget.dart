import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Transaction history widget for customer wallet
class CustomerWalletTransactionHistoryWidget extends ConsumerWidget {
  final int? limit;
  final bool showHeader;

  const CustomerWalletTransactionHistoryWidget({
    super.key,
    this.limit,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text(
            'Recent Transactions',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
        ],
        // Placeholder for transaction list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3, // Mock data
          itemBuilder: (context, index) {
            return _TransactionTile(
              title: 'Transaction ${index + 1}',
              amount: (index + 1) * 25.0,
              date: DateTime.now().subtract(Duration(days: index)),
              type: index % 2 == 0 ? 'credit' : 'debit',
            );
          },
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final String type;

  const _TransactionTile({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = type == 'credit';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCredit 
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isCredit ? Icons.add : Icons.remove,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        '${date.day}/${date.month}/${date.year}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}RM ${amount.toStringAsFixed(2)}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: isCredit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Compact transaction history widget
class CustomerWalletCompactTransactionHistoryWidget extends ConsumerWidget {
  const CustomerWalletCompactTransactionHistoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomerWalletTransactionHistoryWidget(
      limit: 5,
      showHeader: false,
    );
  }
}
