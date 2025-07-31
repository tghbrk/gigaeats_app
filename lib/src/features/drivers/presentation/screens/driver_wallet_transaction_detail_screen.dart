import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../data/models/driver_wallet_transaction.dart';
import '../providers/driver_wallet_transaction_provider.dart';

/// Detailed view of a specific driver wallet transaction
class DriverWalletTransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const DriverWalletTransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionState = ref.watch(driverWalletTransactionProvider);
    
    // Find the transaction in the current list
    final transaction = transactionState.transactions
        .where((t) => t.id == transactionId)
        .firstOrNull;

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Transaction Details'),
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          actions: [
            if (transaction != null) ...[
              PopupMenuButton<String>(
                onSelected: (action) => _handleMenuAction(context, action, transaction),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Export'),
                      ],
                    ),
                  ),
                  if (transaction.referenceType == 'order') ...[
                    const PopupMenuItem(
                      value: 'view_order',
                      child: Row(
                        children: [
                          Icon(Icons.receipt),
                          SizedBox(width: 8),
                          Text('View Order'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        body: transaction == null
            ? _buildTransactionNotFound(theme)
            : _buildTransactionDetails(theme, transaction),
      ),
    );
  }

  Widget _buildTransactionNotFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Transaction Not Found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The requested transaction could not be found.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(ThemeData theme, DriverWalletTransaction transaction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction header card
          _buildTransactionHeader(theme, transaction),
          
          const SizedBox(height: 16),
          
          // Transaction details card
          _buildTransactionDetailsCard(theme, transaction),
          
          const SizedBox(height: 16),
          
          // Balance information card
          _buildBalanceInformationCard(theme, transaction),
          
          if (transaction.metadata != null && transaction.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMetadataCard(theme, transaction),
          ],
          
          const SizedBox(height: 16),
          
          // Transaction timeline
          _buildTransactionTimeline(theme, transaction),
        ],
      ),
    );
  }

  Widget _buildTransactionHeader(ThemeData theme, DriverWalletTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Transaction type icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: transaction.isCredit 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                transaction.isCredit ? Icons.add_circle : Icons.remove_circle,
                size: 40,
                color: transaction.isCredit ? Colors.green : Colors.red,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Transaction type
            Text(
              transaction.transactionType.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Amount
            Text(
              transaction.formattedAmount,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.isCredit ? Colors.green : Colors.red,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: transaction.processedAt != null
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                transaction.status,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: transaction.processedAt != null ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsCard(ThemeData theme, DriverWalletTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(theme, 'Transaction ID', transaction.id),
            _buildDetailRow(theme, 'Date & Time', transaction.formattedDateTime),
            
            if (transaction.description != null) ...[
              _buildDetailRow(theme, 'Description', transaction.description!),
            ],
            
            if (transaction.referenceType != null && transaction.referenceId != null) ...[
              _buildDetailRow(theme, 'Reference Type', transaction.referenceType!),
              _buildDetailRow(theme, 'Reference ID', transaction.referenceId!),
            ],
            
            if (transaction.processingFee > 0) ...[
              _buildDetailRow(
                theme, 
                'Processing Fee', 
                '${transaction.currency} ${transaction.processingFee.toStringAsFixed(2)}'
              ),
            ],
            
            if (transaction.processedBy != null) ...[
              _buildDetailRow(theme, 'Processed By', transaction.processedBy!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInformationCard(ThemeData theme, DriverWalletTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    theme,
                    'Balance Before',
                    '${transaction.currency} ${transaction.balanceBefore.toStringAsFixed(2)}',
                    Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceItem(
                    theme,
                    'Balance After',
                    '${transaction.currency} ${transaction.balanceAfter.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(ThemeData theme, DriverWalletTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ...transaction.metadata!.entries.map((entry) {
              return _buildDetailRow(theme, entry.key, entry.value.toString());
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTimeline(ThemeData theme, DriverWalletTransaction transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Timeline',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTimelineItem(
              theme,
              'Transaction Created',
              transaction.formattedDateTime,
              Icons.add_circle_outline,
              true,
            ),
            
            if (transaction.processedAt != null) ...[
              _buildTimelineItem(
                theme,
                'Transaction Processed',
                '${transaction.processedAt!.day}/${transaction.processedAt!.month}/${transaction.processedAt!.year} ${transaction.processedAt!.hour.toString().padLeft(2, '0')}:${transaction.processedAt!.minute.toString().padLeft(2, '0')}',
                Icons.check_circle,
                true,
              ),
            ] else ...[
              _buildTimelineItem(
                theme,
                'Processing',
                'In progress...',
                Icons.schedule,
                false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, DriverWalletTransaction transaction) {
    switch (action) {
      case 'share':
        debugPrint('📤 [TRANSACTION-DETAIL] Share transaction: ${transaction.id}');
        _shareTransaction(context, transaction);
        break;
      case 'export':
        debugPrint('📤 [TRANSACTION-DETAIL] Export transaction: ${transaction.id}');
        _exportTransaction(context, transaction);
        break;
      case 'view_order':
        debugPrint('📋 [TRANSACTION-DETAIL] View order: ${transaction.referenceId}');
        if (transaction.referenceId != null) {
          context.push('/driver/orders/${transaction.referenceId}');
        }
        break;
    }
  }

  /// Share transaction details
  void _shareTransaction(BuildContext context, DriverWalletTransaction transaction) {
    final shareText = _generateTransactionShareText(transaction);

    // Copy to clipboard as a simple share implementation
    Clipboard.setData(ClipboardData(text: shareText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction details copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Export single transaction
  void _exportTransaction(BuildContext context, DriverWalletTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Transaction'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportTransactionAsJSON(context, transaction);
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportTransactionAsText(context, transaction);
            },
            child: const Text('Text'),
          ),
        ],
      ),
    );
  }

  /// Generate shareable text for transaction
  String _generateTransactionShareText(DriverWalletTransaction transaction) {
    final buffer = StringBuffer();

    buffer.writeln('🧾 TRANSACTION DETAILS');
    buffer.writeln('');
    buffer.writeln('ID: ${transaction.id}');
    buffer.writeln('Type: ${transaction.transactionType.displayName}');
    buffer.writeln('Amount: ${transaction.formattedAmount}');
    buffer.writeln('Date: ${transaction.createdAt.toIso8601String().split('T')[0]}');

    if (transaction.description != null) {
      buffer.writeln('Description: ${transaction.description}');
    }

    buffer.writeln('Status: ${transaction.processedAt != null ? 'Completed' : 'Pending'}');

    if (transaction.referenceId != null) {
      buffer.writeln('Reference: ${transaction.referenceId}');
    }

    if (transaction.processingFee > 0) {
      buffer.writeln('Processing Fee: ${transaction.currency} ${transaction.processingFee.toStringAsFixed(2)}');
    }

    buffer.writeln('');
    buffer.writeln('Generated from GigaEats Driver App');

    return buffer.toString();
  }

  /// Export transaction as JSON
  void _exportTransactionAsJSON(BuildContext context, DriverWalletTransaction transaction) {
    final jsonData = const JsonEncoder.withIndent('  ').convert(transaction.toJson());

    _showExportPreview(context, jsonData, 'JSON');
  }

  /// Export transaction as formatted text
  void _exportTransactionAsText(BuildContext context, DriverWalletTransaction transaction) {
    final textData = _generateTransactionShareText(transaction);

    _showExportPreview(context, textData, 'Text');
  }

  /// Show export preview dialog
  void _showExportPreview(BuildContext context, String exportData, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Preview ($format)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              exportData,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportData));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export data copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
