import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _periods = [
    'Today',
    'This Week', 
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'Custom Range'
  ];

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
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Financial', icon: Icon(Icons.attach_money)),
            Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
            Tab(text: 'Export', icon: Icon(Icons.file_download)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Period: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    items: _periods.map((period) => DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                        _updateDateRange();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFinancialTab(),
                _buildPerformanceTab(),
                _buildExportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Revenue', 'RM 125,450', '+18%', Colors.green, Icons.attach_money)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Total Orders', '3,456', '+12%', Colors.blue, Icons.receipt_long)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Active Vendors', '89', '+5%', Colors.orange, Icons.store)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Active Users', '1,247', '+23%', Colors.purple, Icons.people)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Revenue Chart
          Text(
            'Revenue Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Revenue Chart\n(Chart implementation here)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Top Performers
          Text(
            'Top Performers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTopPerformerRow('Nasi Lemak Express', 'RM 12,450', '234 orders', Icons.store),
                  const Divider(),
                  _buildTopPerformerRow('John Doe (Sales Agent)', 'RM 8,920', '156 orders', Icons.person_pin),
                  const Divider(),
                  _buildTopPerformerRow('Teh Tarik Corner', 'RM 7,650', '189 orders', Icons.store),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary
          Text(
            'Financial Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildFinancialCard('Gross Revenue', 'RM 125,450', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildFinancialCard('Commission Paid', 'RM 12,545', Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFinancialCard('Platform Fees', 'RM 6,273', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildFinancialCard('Net Revenue', 'RM 106,632', Colors.purple)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Payment Methods
          Text(
            'Payment Methods Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPaymentMethodRow('Cash on Delivery', 'RM 45,230', '36%'),
                  const Divider(),
                  _buildPaymentMethodRow('Online Banking', 'RM 38,140', '30%'),
                  const Divider(),
                  _buildPaymentMethodRow('Credit/Debit Card', 'RM 25,080', '20%'),
                  const Divider(),
                  _buildPaymentMethodRow('E-Wallet', 'RM 17,000', '14%'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Monthly Comparison
          Text(
            'Monthly Comparison',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Monthly Comparison Chart\n(Chart implementation here)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Metrics
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildPerformanceCard('Avg Order Value', 'RM 36.25', '+8%', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildPerformanceCard('Order Completion', '94.2%', '+2%', Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPerformanceCard('Customer Satisfaction', '4.6/5', '+0.2', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildPerformanceCard('Delivery Time', '32 min', '-5 min', Colors.purple)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Vendor Performance
          Text(
            'Vendor Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildVendorPerformanceRow('Nasi Lemak Express', '4.8', '98%', '25 min'),
                  const Divider(),
                  _buildVendorPerformanceRow('Teh Tarik Corner', '4.6', '95%', '30 min'),
                  const Divider(),
                  _buildVendorPerformanceRow('Roti Canai House', '4.5', '92%', '35 min'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sales Agent Performance
          Text(
            'Sales Agent Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAgentPerformanceRow('John Doe', '156', 'RM 8,920', 'RM 892'),
                  const Divider(),
                  _buildAgentPerformanceRow('Jane Smith', '134', 'RM 7,650', 'RM 765'),
                  const Divider(),
                  _buildAgentPerformanceRow('Mike Johnson', '98', 'RM 5,430', 'RM 543'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download, color: Colors.blue),
                  title: const Text('Financial Report'),
                  subtitle: const Text('Revenue, expenses, and profit analysis'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _exportReport('financial'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.analytics, color: Colors.green),
                  title: const Text('Performance Report'),
                  subtitle: const Text('Vendor and sales agent performance metrics'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _exportReport('performance'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.orange),
                  title: const Text('Order Summary'),
                  subtitle: const Text('Detailed order history and statistics'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _exportReport('orders'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.purple),
                  title: const Text('User Activity Report'),
                  subtitle: const Text('User registration and activity trends'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _exportReport('users'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Export Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportAllReports('pdf'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export as PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportAllReports('excel'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export as Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String change, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  change,
                  style: TextStyle(
                    color: change.startsWith('+') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
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
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, String change, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              change,
              style: TextStyle(
                color: change.startsWith('+') || change.startsWith('-') && !change.contains('min') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformerRow(String name, String revenue, String orders, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(
            revenue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Text(
            orders,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(String method, String amount, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(method)),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Text(
            percentage,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorPerformanceRow(String name, String rating, String completion, String avgTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text('⭐ $rating'),
          const SizedBox(width: 16),
          Text(completion),
          const SizedBox(width: 16),
          Text(avgTime),
        ],
      ),
    );
  }

  Widget _buildAgentPerformanceRow(String name, String orders, String revenue, String commission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text('$orders orders'),
          const SizedBox(width: 16),
          Text(revenue),
          const SizedBox(width: 16),
          Text(commission),
        ],
      ),
    );
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'This Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Last Month':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case 'This Quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        _startDate = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        _endDate = now;
        break;
      case 'This Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom Range';
      });
    }
  }

  void _refreshReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing reports...')),
    );
  }

  void _exportReport(String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting $reportType report...')),
    );
  }

  void _exportAllReports(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting all reports as $format...')),
    );
  }
}
