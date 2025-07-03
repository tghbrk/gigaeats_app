import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../compliance/data/models/compliance.dart';
import '../../../compliance/data/services/compliance_service.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';

// Provider for compliance service
final complianceServiceProvider = Provider<ComplianceService>((ref) => ComplianceService());

// Provider for vendors with compliance issues
final vendorsWithIssuesProvider = FutureProvider<List<String>>((ref) async {
  final complianceService = ref.read(complianceServiceProvider);
  return await complianceService.getVendorsWithComplianceIssues();
});

// Provider for vendor compliance summary
final vendorComplianceSummaryProvider = FutureProvider.family<ComplianceSummary, String>((ref, vendorId) async {
  final complianceService = ref.read(complianceServiceProvider);
  return await complianceService.getVendorComplianceSummary(vendorId);
});

class ComplianceManagementScreen extends ConsumerStatefulWidget {
  const ComplianceManagementScreen({super.key});

  @override
  ConsumerState<ComplianceManagementScreen> createState() => _ComplianceManagementScreenState();
}

class _ComplianceManagementScreenState extends ConsumerState<ComplianceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Compliance Management'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'SSM', icon: Icon(Icons.business)),
            Tab(text: 'Halal', icon: Icon(Icons.verified)),
            Tab(text: 'PDPA', icon: Icon(Icons.privacy_tip)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSSMTab(),
          _buildHalalTab(),
          _buildPDPATab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final vendorsWithIssuesAsync = ref.watch(vendorsWithIssuesProvider);

    return vendorsWithIssuesAsync.when(
      data: (vendorIds) => _buildOverviewContent(vendorIds),
      loading: () => const LoadingWidget(message: 'Loading compliance overview...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load compliance data: $error',
        onRetry: () => ref.refresh(vendorsWithIssuesProvider),
      ),
    );
  }

  Widget _buildOverviewContent(List<String> vendorIds) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Vendors',
                '150', // This would come from actual data
                Icons.store,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Issues Found',
                '${vendorIds.length}',
                Icons.warning,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Compliant',
                '${150 - vendorIds.length}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Pending Review',
                '12', // This would come from actual data
                Icons.pending,
                Colors.purple,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Vendors with Issues
        Text(
          'Vendors Requiring Attention',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (vendorIds.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All vendors are compliant!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No compliance issues found.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...vendorIds.map((vendorId) => _buildVendorComplianceCard(vendorId)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
                fontSize: 24,
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

  Widget _buildVendorComplianceCard(String vendorId) {
    final complianceSummaryAsync = ref.watch(vendorComplianceSummaryProvider(vendorId));

    return complianceSummaryAsync.when(
      data: (summary) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: _getGradeColor(summary.complianceGrade),
            child: Text(
              summary.complianceGrade,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text('Vendor $vendorId'), // In real app, this would be vendor name
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Compliance Score: ${(summary.complianceScore * 100).toStringAsFixed(0)}%'),
              if (summary.missingCompliances.isNotEmpty)
                Text(
                  'Missing: ${summary.missingCompliances.join(', ')}',
                  style: const TextStyle(color: Colors.red),
                ),
              if (summary.expiringCertifications.isNotEmpty)
                Text(
                  'Expiring: ${summary.expiringCertifications.join(', ')}',
                  style: const TextStyle(color: Colors.orange),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildComplianceRow('SSM Registration', summary.ssmCompliant),
                  _buildComplianceRow('Halal Certification', summary.halalCompliant),
                  _buildComplianceRow('SST Registration', summary.sstCompliant),
                  _buildComplianceRow('PDPA Compliance', summary.pdpaCompliant),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _reviewVendorCompliance(vendorId),
                          icon: const Icon(Icons.visibility),
                          label: const Text('Review'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _contactVendor(vendorId),
                          icon: const Icon(Icons.message),
                          label: const Text('Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Loading compliance data...'),
        ),
      ),
      error: (error, stack) => Card(
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: Text('Error loading vendor $vendorId'),
          subtitle: Text(error.toString()),
        ),
      ),
    );
  }

  Widget _buildComplianceRow(String label, bool isCompliant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isCompliant ? Icons.check_circle : Icons.cancel,
            color: isCompliant ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSSMTab() {
    return const Center(
      child: Text('SSM Registration Management\nComing Soon...'),
    );
  }

  Widget _buildHalalTab() {
    return const Center(
      child: Text('Halal Certification Management\nComing Soon...'),
    );
  }

  Widget _buildPDPATab() {
    return const Center(
      child: Text('PDPA Compliance Management\nComing Soon...'),
    );
  }

  void _reviewVendorCompliance(String vendorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Vendor $vendorId'),
        content: const Text('Detailed compliance review interface will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _contactVendor(String vendorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Vendor $vendorId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send compliance reminder:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent to vendor')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
