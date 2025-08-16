import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/widgets/buttons/ge_button.dart';

class CommissionScreen extends ConsumerStatefulWidget {
  const CommissionScreen({super.key});

  @override
  ConsumerState<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends ConsumerState<CommissionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Earnings',
                'RM 2,450.00',
                Icons.monetization_on,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending',
                'RM 320.50',
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
                'This Month',
                'RM 850.00',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Commission Rate',
                '7.5%',
                Icons.percent,
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
              child: GEButton.primary(
                text: 'Request Payout',
                onPressed: _requestPayout,
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GEButton.outline(
                text: 'View Report',
                onPressed: _viewDetailedReport,
                icon: Icons.assessment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommissionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCommissionCard('Order #12345', 'RM 25.50', 'Paid', Colors.green),
        _buildCommissionCard('Order #12344', 'RM 18.75', 'Pending', Colors.orange),
        _buildCommissionCard('Order #12343', 'RM 32.00', 'Paid', Colors.green),
        _buildCommissionCard('Order #12342', 'RM 15.25', 'Processing', Colors.blue),
      ],
    );
  }

  Widget _buildPayoutsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPayoutCard('Payout #001', 'RM 450.00', 'Completed', Colors.green),
        _buildPayoutCard('Payout #002', 'RM 320.50', 'Processing', Colors.blue),
        _buildPayoutCard('Payout #003', 'RM 280.75', 'Pending', Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionCard(String orderNumber, String amount, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.monetization_on, color: statusColor),
        ),
        title: Text(orderNumber),
        subtitle: Text('Commission: $amount'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutCard(String payoutId, String amount, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.account_balance_wallet, color: statusColor),
        ),
        title: Text(payoutId),
        subtitle: Text('Amount: $amount'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
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
}
