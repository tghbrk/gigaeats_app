import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/monitoring/performance_monitor.dart';

class PerformanceMonitoringDashboard extends ConsumerStatefulWidget {
  const PerformanceMonitoringDashboard({super.key});

  @override
  ConsumerState<PerformanceMonitoringDashboard> createState() => _PerformanceMonitoringDashboardState();
}

class _PerformanceMonitoringDashboardState extends ConsumerState<PerformanceMonitoringDashboard> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  PerformanceStats? _overallStats;
  PerformanceStats? _customizationStats;
  PerformanceStats? _databaseStats;
  PerformanceStats? _uiStats;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final results = await Future.wait([
        _monitor.getStats(startDate: yesterday, endDate: now),
        _monitor.getStats(category: 'customization', startDate: yesterday, endDate: now),
        _monitor.getStats(category: 'database', startDate: yesterday, endDate: now),
        _monitor.getStats(category: 'ui', startDate: yesterday, endDate: now),
      ]);

      setState(() {
        _overallStats = results[0];
        _customizationStats = results[1];
        _databaseStats = results[2];
        _uiStats = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Run comprehensive benchmark
      await _runCustomizationBenchmark();
      await _runDatabaseBenchmark();
      await _runUIBenchmark();
      
      // Reload stats
      await _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Benchmark completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Benchmark failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runCustomizationBenchmark() async {
    // Simulate customization operations
    for (int i = 0; i < 10; i++) {
      await _monitor.measureOperation(
        operation: 'load_customizations',
        category: 'customization',
        function: () async {
          await Future.delayed(Duration(milliseconds: 50 + (i * 10)));
          return 'success';
        },
        metadata: {
          'menu_item_id': 'test-item-$i',
          'customization_count': 3 + i,
        },
      );

      await _monitor.measureOperation(
        operation: 'calculate_pricing',
        category: 'customization',
        function: () async {
          await Future.delayed(Duration(milliseconds: 20 + (i * 5)));
          return 'success';
        },
        metadata: {
          'option_count': 5 + i,
        },
      );
    }
  }

  Future<void> _runDatabaseBenchmark() async {
    // Simulate database operations
    for (int i = 0; i < 5; i++) {
      await _monitor.measureOperation(
        operation: 'query_customizations',
        category: 'database',
        function: () async {
          await Future.delayed(Duration(milliseconds: 100 + (i * 20)));
          return 'success';
        },
        metadata: {
          'table': 'menu_item_customizations',
          'record_count': 10 + i,
        },
      );

      await _monitor.measureOperation(
        operation: 'insert_order_item',
        category: 'database',
        function: () async {
          await Future.delayed(Duration(milliseconds: 80 + (i * 15)));
          return 'success';
        },
        metadata: {
          'table': 'order_items',
          'has_customizations': true,
        },
      );
    }
  }

  Future<void> _runUIBenchmark() async {
    // Simulate UI operations
    for (int i = 0; i < 8; i++) {
      await _monitor.measureOperation(
        operation: 'render_customization_form',
        category: 'ui',
        function: () async {
          await Future.delayed(Duration(milliseconds: 30 + (i * 8)));
          return 'success';
        },
        metadata: {
          'screen': 'product_details',
          'component': 'customization_form',
        },
      );

      await _monitor.measureOperation(
        operation: 'update_cart_display',
        category: 'ui',
        function: () async {
          await Future.delayed(Duration(milliseconds: 15 + (i * 3)));
          return 'success';
        },
        metadata: {
          'screen': 'cart',
          'item_count': 3 + i,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitoring'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Performance Dashboard',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _runBenchmark,
                            icon: const Icon(Icons.speed),
                            label: const Text('Run Benchmark'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last 24 hours performance metrics',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Overall Stats
                      _buildStatsCard(
                        title: '📊 Overall Performance',
                        stats: _overallStats,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      // Category-specific stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatsCard(
                              title: '🍔 Customizations',
                              stats: _customizationStats,
                              color: Colors.orange,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatsCard(
                              title: '🗄️ Database',
                              stats: _databaseStats,
                              color: Colors.green,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildStatsCard(
                        title: '🎨 User Interface',
                        stats: _uiStats,
                        color: Colors.purple,
                      ),

                      const SizedBox(height: 24),

                      // Performance Targets
                      _buildTargetsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required PerformanceStats? stats,
    required Color color,
    bool compact = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForTitle(title),
                    color: color,
                    size: compact ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats == null || stats.totalOperations == 0)
              const Text('No data available')
            else ...[
              if (!compact) ...[
                _buildStatRow('Total Operations', '${stats.totalOperations}'),
                _buildStatRow('Average Duration', '${stats.averageDuration.toStringAsFixed(1)}ms'),
                _buildStatRow('Min Duration', '${stats.minDuration}ms'),
                _buildStatRow('Max Duration', '${stats.maxDuration}ms'),
                _buildStatRow('95th Percentile', '${stats.p95Duration.toStringAsFixed(1)}ms'),
                _buildStatRow('99th Percentile', '${stats.p99Duration.toStringAsFixed(1)}ms'),
              ] else ...[
                _buildStatRow('Operations', '${stats.totalOperations}'),
                _buildStatRow('Avg Duration', '${stats.averageDuration.toStringAsFixed(1)}ms'),
                _buildStatRow('P95', '${stats.p95Duration.toStringAsFixed(1)}ms'),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Performance Targets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTargetRow('Page Load', '< 3000ms', _getTargetStatus(_overallStats?.averageDuration, 3000)),
            _buildTargetRow('Price Updates', '< 500ms', _getTargetStatus(_customizationStats?.averageDuration, 500)),
            _buildTargetRow('Cart Operations', '< 1000ms', _getTargetStatus(_uiStats?.averageDuration, 1000)),
            _buildTargetRow('Database Queries', '< 200ms', _getTargetStatus(_databaseStats?.averageDuration, 200)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(String label, String target, bool isGood) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            color: isGood ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            target,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGood ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Overall')) return Icons.analytics;
    if (title.contains('Customizations')) return Icons.tune;
    if (title.contains('Database')) return Icons.storage;
    if (title.contains('Interface')) return Icons.dashboard;
    return Icons.bar_chart;
  }

  bool _getTargetStatus(double? average, double target) {
    if (average == null) return false;
    return average <= target;
  }
}
