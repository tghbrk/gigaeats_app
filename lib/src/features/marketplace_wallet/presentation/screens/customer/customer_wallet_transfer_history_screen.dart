import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../providers/customer_wallet_transfer_provider.dart';
import '../../widgets/customer_wallet_error_widget.dart';
import '../../../data/models/customer_wallet_error.dart';

class CustomerWalletTransferHistoryScreen extends ConsumerStatefulWidget {
  const CustomerWalletTransferHistoryScreen({super.key});

  @override
  ConsumerState<CustomerWalletTransferHistoryScreen> createState() => _CustomerWalletTransferHistoryScreenState();
}

class _CustomerWalletTransferHistoryScreenState extends ConsumerState<CustomerWalletTransferHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load recent transfers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerWalletTransferProvider.notifier).loadRecentTransfers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(customerWalletTransferProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customerWalletTransferProvider.notifier).loadRecentTransfers(),
          ),
        ],
      ),
      body: transferState.isLoading
          ? const LoadingWidget()
          : transferState.errorMessage != null
              ? CustomerWalletErrorWidget(
                  error: CustomerWalletError.fromMessage(transferState.errorMessage ?? 'Unknown error'),
                  onRetry: () => ref.read(customerWalletTransferProvider.notifier).loadRecentTransfers(),
                )
              : _buildTransferHistory(context, transferState),
    );
  }

  Widget _buildTransferHistory(BuildContext context, transferState) {
    final transfers = transferState.recentTransfers;

    if (transfers.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(customerWalletTransferProvider.notifier).loadRecentTransfers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transfers.length,
        itemBuilder: (context, index) {
          final transfer = transfers[index];
          return _buildTransferCard(context, transfer);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Transfer History',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transfer history will appear here once you start sending money.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/customer/wallet/transfer'),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send Money'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, transfer) {
    final theme = Theme.of(context);
    final isOutgoing = transfer.type == 'outgoing'; // Assuming transfer has type field

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutgoing ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
            color: isOutgoing ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ),
        title: Text(
          isOutgoing ? 'Sent to ${transfer.recipientName ?? transfer.recipientIdentifier}' : 'Received from ${transfer.senderName ?? transfer.senderIdentifier}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transfer.note != null && transfer.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transfer.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(transfer.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isOutgoing ? '-' : '+'}RM ${transfer.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isOutgoing ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transfer.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(transfer.status),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(transfer.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransferDetails(context, transfer),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  void _showTransferDetails(BuildContext context, transfer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount:', 'RM ${transfer.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Status:', _getStatusText(transfer.status)),
            _buildDetailRow('Date:', _formatDate(transfer.createdAt)),
            if (transfer.note != null && transfer.note!.isNotEmpty)
              _buildDetailRow('Note:', transfer.note!),
            if (transfer.transactionId != null)
              _buildDetailRow('Transaction ID:', transfer.transactionId!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
