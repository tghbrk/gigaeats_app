import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/commission.dart';
import '../../../data/services/commission_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_error_widget.dart';
import '../../widgets/custom_button.dart';

// Provider for commission service
final commissionServiceProvider = Provider<CommissionService>((ref) => CommissionService());

// Provider for commission summary
final commissionSummaryProvider = FutureProvider.family<CommissionSummary, String>((ref, salesAgentId) async {
  final commissionService = ref.read(commissionServiceProvider);
  return await commissionService.getCommissionSummary(salesAgentId);
});

// Provider for commissions list
final commissionsProvider = FutureProvider.family<List<Commission>, String>((ref, salesAgentId) async {
  final commissionService = ref.read(commissionServiceProvider);
  return await commissionService.getSalesAgentCommissions(salesAgentId, limit: 50);
});

// Provider for payouts list
final payoutsProvider = FutureProvider.family<List<Payout>, String>((ref, salesAgentId) async {
  final commissionService = ref.read(commissionServiceProvider);
  return await commissionService.getSalesAgentPayouts(salesAgentId, limit: 20);
});

class CommissionScreen extends ConsumerStatefulWidget {
  final String salesAgentId;

  const CommissionScreen({
    super.key,
    required this.salesAgentId,
  });

  @override
  ConsumerState<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends ConsumerState<CommissionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Generate sample data for testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commissionServiceProvider).generateSampleCommissions(widget.salesAgentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Commissions'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Commissions', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Payouts', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCommissionsTab(),
          _buildPayoutsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final summaryAsync = ref.watch(commissionSummaryProvider(widget.salesAgentId));

    return summaryAsync.when(
      data: (summary) => _buildOverviewContent(summary),
      loading: () => const LoadingWidget(message: 'Loading commission summary...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load commission data: $error',
        onRetry: () => ref.refresh(commissionSummaryProvider(widget.salesAgentId)),
      ),
    );
  }

  Widget _buildOverviewContent(CommissionSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Earnings Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Total Earnings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RM ${summary.totalEarnings.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEarningsItem(
                      'Pending',
                      summary.pendingCommissions,
                      Colors.orange,
                    ),
                    _buildEarningsItem(
                      'Approved',
                      summary.approvedCommissions,
                      Colors.blue,
                    ),
                    _buildEarningsItem(
                      'Paid',
                      summary.paidCommissions,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Orders',
                '${summary.totalOrders}',
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending Orders',
                '${summary.pendingOrders}',
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Commission',
                '${(summary.averageCommissionRate * 100).toStringAsFixed(1)}%',
                Icons.percent,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'This Month',
                'RM ${_getCurrentMonthEarnings(summary).toStringAsFixed(2)}',
                Icons.calendar_today,
                Colors.purple,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Quick Actions
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Request Payout',
                onPressed: summary.approvedCommissions > 0 ? _requestPayout : null,
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'View Report',
                onPressed: _viewDetailedReport,
                icon: Icons.assessment,
                type: ButtonType.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionsTab() {
    final commissionsAsync = ref.watch(commissionsProvider(widget.salesAgentId));

    return commissionsAsync.when(
      data: (commissions) => _buildCommissionsList(commissions),
      loading: () => const LoadingWidget(message: 'Loading commissions...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load commissions: $error',
        onRetry: () => ref.refresh(commissionsProvider(widget.salesAgentId)),
      ),
    );
  }

  Widget _buildCommissionsList(List<Commission> commissions) {
    if (commissions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No commissions yet'),
            Text('Start making sales to earn commissions!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return _buildCommissionCard(commission);
      },
    );
  }

  Widget _buildCommissionCard(Commission commission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(commission.status),
          child: Icon(
            _getStatusIcon(commission.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('Order ${commission.orderNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${commission.customerName}'),
            Text('Order Date: ${_formatDate(commission.orderDate)}'),
            Text('Commission Rate: ${(commission.commissionRate * 100).toStringAsFixed(1)}%'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM ${commission.netCommission.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              commission.status.name.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(commission.status),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () => _showCommissionDetails(commission),
      ),
    );
  }

  Widget _buildPayoutsTab() {
    final payoutsAsync = ref.watch(payoutsProvider(widget.salesAgentId));

    return payoutsAsync.when(
      data: (payouts) => _buildPayoutsList(payouts),
      loading: () => const LoadingWidget(message: 'Loading payouts...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load payouts: $error',
        onRetry: () => ref.refresh(payoutsProvider(widget.salesAgentId)),
      ),
    );
  }

  Widget _buildPayoutsList(List<Payout> payouts) {
    if (payouts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No payouts yet'),
            Text('Request a payout when you have approved commissions.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return _buildPayoutCard(payout);
      },
    );
  }

  Widget _buildPayoutCard(Payout payout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPayoutStatusColor(payout.status),
          child: Icon(
            _getPayoutStatusIcon(payout.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('Payout ${payout.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${payout.commissionIds.length} commissions'),
            Text('Scheduled: ${_formatDate(payout.scheduledDate)}'),
            if (payout.completedAt != null)
              Text('Completed: ${_formatDate(payout.completedAt!)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM ${payout.netAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              payout.status.name.toUpperCase(),
              style: TextStyle(
                color: _getPayoutStatusColor(payout.status),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Colors.orange;
      case CommissionStatus.approved:
        return Colors.blue;
      case CommissionStatus.paid:
        return Colors.green;
      case CommissionStatus.disputed:
        return Colors.red;
      case CommissionStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Icons.pending;
      case CommissionStatus.approved:
        return Icons.check;
      case CommissionStatus.paid:
        return Icons.monetization_on;
      case CommissionStatus.disputed:
        return Icons.error;
      case CommissionStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getPayoutStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.pending:
        return Colors.orange;
      case PayoutStatus.processing:
        return Colors.blue;
      case PayoutStatus.completed:
        return Colors.green;
      case PayoutStatus.failed:
        return Colors.red;
      case PayoutStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getPayoutStatusIcon(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.pending:
        return Icons.schedule;
      case PayoutStatus.processing:
        return Icons.sync;
      case PayoutStatus.completed:
        return Icons.check_circle;
      case PayoutStatus.failed:
        return Icons.error;
      case PayoutStatus.cancelled:
        return Icons.cancel;
    }
  }

  double _getCurrentMonthEarnings(CommissionSummary summary) {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return summary.monthlyBreakdown[currentMonthKey] ?? 0.0;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _requestPayout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout'),
        content: const Text('Payout request functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _viewDetailedReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Report'),
        content: const Text('Detailed commission report will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommissionDetails(Commission commission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commission Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${commission.orderNumber}'),
            Text('Customer: ${commission.customerName}'),
            Text('Vendor: ${commission.vendorName}'),
            Text('Order Amount: RM ${commission.orderAmount.toStringAsFixed(2)}'),
            Text('Commission Rate: ${(commission.commissionRate * 100).toStringAsFixed(1)}%'),
            Text('Commission: RM ${commission.commissionAmount.toStringAsFixed(2)}'),
            Text('Platform Fee: RM ${commission.platformFee.toStringAsFixed(2)}'),
            Text('Net Commission: RM ${commission.netCommission.toStringAsFixed(2)}'),
            Text('Status: ${commission.status.name}'),
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
}
