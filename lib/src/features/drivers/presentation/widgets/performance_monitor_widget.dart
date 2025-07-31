import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../providers/optimized_order_history_providers.dart';
import '../../data/services/order_history_cache_service.dart';

/// Performance monitoring widget for debugging and optimization
class PerformanceMonitorWidget extends ConsumerStatefulWidget {
  final bool showInProduction;
  final Duration updateInterval;

  const PerformanceMonitorWidget({
    super.key,
    this.showInProduction = false,
    this.updateInterval = const Duration(seconds: 2),
  });

  @override
  ConsumerState<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends ConsumerState<PerformanceMonitorWidget> {
  Timer? _updateTimer;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPerformanceMonitoring() {
    _updateTimer = Timer.periodic(widget.updateInterval, (_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update performance stats
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show in production unless explicitly enabled
    if (!widget.showInProduction && const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final performanceData = ref.watch(performanceMonitorProvider);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: _isExpanded ? 300 : 120,
            maxHeight: _isExpanded ? 400 : 60,
          ),
          child: _isExpanded ? _buildExpandedView(theme, performanceData) : _buildCompactView(theme, performanceData),
        ),
      ),
    );
  }

  Widget _buildCompactView(ThemeData theme, Map<String, dynamic> performanceData) {
    final cacheStats = performanceData['cacheStats'] as Map<String, dynamic>? ?? {};
    final lazyStats = performanceData['lazyLoadingStats'] as Map<String, dynamic>? ?? {};

    return InkWell(
      onTap: () => setState(() => _isExpanded = true),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache: ${cacheStats['memoryEntries'] ?? 0}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Load: ${lazyStats['activeStates'] ?? 0}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(ThemeData theme, Map<String, dynamic> performanceData) {
    final cacheStats = performanceData['cacheStats'] as Map<String, dynamic>? ?? {};
    final lazyStats = performanceData['lazyLoadingStats'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Performance Monitor',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _isExpanded = false),
                icon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Cache Statistics
          _buildSection(
            theme,
            'Cache Statistics',
            Icons.storage,
            [
              _buildStatRow('Memory Entries', '${cacheStats['memoryEntries'] ?? 0}'),
              _buildStatRow('Summary Entries', '${cacheStats['summaryEntries'] ?? 0}'),
              _buildStatRow('Count Entries', '${cacheStats['countEntries'] ?? 0}'),
              _buildStatRow('Persistent Entries', '${cacheStats['persistentEntries'] ?? 0}'),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Lazy Loading Statistics
          _buildSection(
            theme,
            'Lazy Loading',
            Icons.refresh,
            [
              _buildStatRow('Active States', '${lazyStats['activeStates'] ?? 0}'),
              _buildStatRow('Ongoing Requests', '${lazyStats['ongoingRequests'] ?? 0}'),
              _buildStatRow('Active Timers', '${lazyStats['activeTimers'] ?? 0}'),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearCache,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Clear Cache', style: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _exportStats,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Export', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      await OrderHistoryCacheService.instance.clearAllCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing cache: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _exportStats() {
    final performanceData = ref.read(performanceMonitorProvider);
    debugPrint('🚗 Performance Stats Export: $performanceData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance stats exported to debug console'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Performance overlay for development
class PerformanceOverlay extends ConsumerWidget {
  final Widget child;
  final bool enabled;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,
        if (enabled)
          const PerformanceMonitorWidget(),
      ],
    );
  }
}

/// Performance metrics display widget
class PerformanceMetricsCard extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;

  const PerformanceMetricsCard({
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final performanceData = ref.watch(performanceMonitorProvider);
    final cacheStats = performanceData['cacheStats'] as Map<String, dynamic>? ?? {};
    final lazyStats = performanceData['lazyLoadingStats'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Performance Metrics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Cache efficiency
              _buildMetricRow(
                theme,
                'Cache Efficiency',
                '${_calculateCacheEfficiency(cacheStats).toStringAsFixed(1)}%',
                Icons.storage,
                _getCacheEfficiencyColor(theme, _calculateCacheEfficiency(cacheStats)),
              ),
              
              const SizedBox(height: 8),
              
              // Loading performance
              _buildMetricRow(
                theme,
                'Active Loads',
                '${lazyStats['ongoingRequests'] ?? 0}',
                Icons.refresh,
                theme.colorScheme.primary,
              ),
              
              const SizedBox(height: 8),
              
              // Memory usage
              _buildMetricRow(
                theme,
                'Memory Entries',
                '${cacheStats['memoryEntries'] ?? 0}',
                Icons.memory,
                theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateCacheEfficiency(Map<String, dynamic> cacheStats) {
    final memoryEntries = cacheStats['memoryEntries'] as int? ?? 0;
    final persistentEntries = cacheStats['persistentEntries'] as int? ?? 0;
    final totalEntries = memoryEntries + persistentEntries;
    
    if (totalEntries == 0) return 0.0;
    
    // Simple efficiency calculation based on cache utilization
    return (totalEntries / 50.0 * 100).clamp(0.0, 100.0);
  }

  Color _getCacheEfficiencyColor(ThemeData theme, double efficiency) {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return theme.colorScheme.error;
  }
}
