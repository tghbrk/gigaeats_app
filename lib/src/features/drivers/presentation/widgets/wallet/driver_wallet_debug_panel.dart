import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/driver_wallet_provider.dart';
import '../../providers/driver_wallet_realtime_provider.dart';
import '../../providers/driver_wallet_transaction_provider.dart';
import '../../providers/driver_wallet_integration_provider.dart';
import '../../../data/models/driver_wallet_transaction.dart';

/// Debug panel for driver wallet system - only shown in debug mode
class DriverWalletDebugPanel extends ConsumerWidget {
  const DriverWalletDebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);
    final transactionState = ref.watch(driverWalletTransactionProvider);
    final integrationState = ref.watch(driverWalletIntegrationProvider);
    final combinedState = ref.watch(driverWalletCombinedStateProvider);
    final healthStatus = ref.watch(driverWalletEarningsHealthProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.bug_report,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Wallet Debug Panel'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet State Section
                _buildDebugSection(
                  context,
                  'Wallet State',
                  [
                    'Loading: ${walletState.isLoading}',
                    'Error: ${walletState.errorMessage ?? 'None'}',
                    'Balance: ${walletState.formattedAvailableBalance}',
                    'Active: ${walletState.isWalletActive}',
                    'Verified: ${walletState.isWalletVerified}',
                    'Real-time: ${walletState.hasRealtimeConnection}',
                    'Last Updated: ${walletState.lastUpdated?.toString() ?? 'Never'}',
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Transaction State Section
                _buildDebugSection(
                  context,
                  'Transaction State',
                  [
                    'Loading: ${transactionState.isLoading}',
                    'Error: ${transactionState.errorMessage ?? 'None'}',
                    'Count: ${transactionState.transactions.length}',
                    'Has More: ${transactionState.hasMore}',
                    'Current Page: ${transactionState.currentPage}',
                    'Filter Type: ${transactionState.filter.type?.value ?? 'All'}',
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Integration State Section
                _buildDebugSection(
                  context,
                  'Integration State',
                  [
                    'Processing: ${integrationState['isProcessingEarnings'] ?? false}',
                    'Pending: ${(integrationState['pendingDeposits'] as List?)?.length ?? 0}',
                    'Failed: ${(integrationState['failedDeposits'] as List?)?.length ?? 0}',
                    'Total Processed: RM ${(integrationState['totalEarningsProcessed'] ?? 0.0).toStringAsFixed(2)}',
                    'Last Deposit: ${integrationState['lastEarningsDeposit']?['timestamp'] ?? 'None'}',
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Health Status Section
                _buildDebugSection(
                  context,
                  'Health Status',
                  [
                    'Status: ${healthStatus['status']}',
                    'Message: ${healthStatus['message']}',
                    'Failed Count: ${healthStatus['failedCount']}',
                    'Pending Count: ${healthStatus['pendingCount']}',
                    'Processing: ${healthStatus['isProcessing']}',
                    'Wallet Active: ${healthStatus['walletActive']}',
                    'Wallet Verified: ${healthStatus['walletVerified']}',
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Combined State Section
                _buildDebugSection(
                  context,
                  'Combined State',
                  [
                    'Real-time Connected: ${combinedState['realtimeConnected']}',
                    'Transaction Count: ${combinedState['transactionCount']}',
                    'Has Recent Transactions: ${combinedState['hasRecentTransactions']}',
                    'Last Updated: ${combinedState['lastUpdated']?.toString() ?? 'Never'}',
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Debug Actions
                _buildDebugActions(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection(BuildContext context, String title, List<String> items) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugActions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Debug Actions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 [WALLET-DEBUG] Manual wallet refresh triggered');
                ref.read(driverWalletProvider.notifier).loadWallet(refresh: true);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Wallet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 [WALLET-DEBUG] Manual transaction refresh triggered');
                ref.read(driverWalletTransactionProvider.notifier).refreshTransactions();
              },
              icon: const Icon(Icons.history, size: 16),
              label: const Text('Refresh Transactions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 [WALLET-DEBUG] Real-time connection refresh triggered');
                ref.read(driverWalletRealtimeProvider.notifier).refreshConnection();
              },
              icon: const Icon(Icons.wifi, size: 16),
              label: const Text('Refresh Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 [WALLET-DEBUG] Failed deposits retry triggered');
                ref.read(driverWalletIntegrationProvider.notifier).retryFailedDeposits();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Failed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 [WALLET-DEBUG] Integration state cleared');
                ref.read(driverWalletIntegrationProvider.notifier).clearState();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear State'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 [WALLET-DEBUG] Error state cleared');
                ref.read(driverWalletProvider.notifier).clearError();
                ref.read(driverWalletTransactionProvider.notifier).clearError();
              },
              icon: const Icon(Icons.error_outline, size: 16),
              label: const Text('Clear Errors'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Test Actions
        Text(
          'Test Actions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                debugPrint('🧪 [WALLET-DEBUG] Test earnings deposit triggered');
                ref.read(driverWalletIntegrationProvider.notifier).processDeliveryEarnings(
                  orderId: 'test-order-${DateTime.now().millisecondsSinceEpoch}',
                  grossEarnings: 25.00,
                  netEarnings: 22.50,
                  earningsBreakdown: {
                    'baseDeliveryFee': 15.00,
                    'distanceBonus': 5.00,
                    'tipAmount': 5.00,
                    'platformFee': -2.50,
                  },
                );
              },
              icon: const Icon(Icons.attach_money, size: 16),
              label: const Text('Test Earnings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
