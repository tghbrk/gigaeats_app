import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_lazy_loading_providers.dart';
import '../../../data/services/customer_order_lazy_loading_service.dart';
import '../../../data/services/customer_order_memory_optimizer.dart';


/// Performance monitoring widget for customer order system
class CustomerOrderPerformanceMonitor extends ConsumerWidget {
  final bool showDetailedMetrics;
  final bool showMemoryStats;
  final bool showCacheStats;

  const CustomerOrderPerformanceMonitor({
    super.key,
    this.showDetailedMetrics = false,
    this.showMemoryStats = true,
    this.showCacheStats = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    if (!showDetailedMetrics) {
      return _buildCompactView(context, theme, ref);
    }
    
    return _buildDetailedView(context, theme, ref);
  }

  Widget _buildCompactView(BuildContext context, ThemeData theme, WidgetRef ref) {
    final cacheStats = ref.watch(customerOrderCacheStatsProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.speed,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            _getCompactPerformanceText(cacheStats),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context, ThemeData theme, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Monitor',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showPerformanceDetails(context, ref),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Show detailed metrics',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Performance metrics
            if (showCacheStats) ...[
              _buildCacheStatsSection(theme, ref),
              const SizedBox(height: 12),
            ],
            
            if (showMemoryStats) ...[
              _buildMemoryStatsSection(theme, ref),
              const SizedBox(height: 12),
            ],
            
            // Performance recommendations
            _buildRecommendationsSection(theme, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsSection(ThemeData theme, WidgetRef ref) {
    final cacheStats = ref.watch(customerOrderCacheStatsProvider);
    
    if (cacheStats == null) {
      return _buildLoadingSection(theme, 'Cache Statistics');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cache Performance',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Hit Rate',
                '${(cacheStats.hitRate * 100).toStringAsFixed(1)}%',
                Icons.track_changes,
                _getCacheHitRateColor(cacheStats.hitRate, theme),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Entries',
                '${cacheStats.totalEntries}/${cacheStats.maxCacheSize}',
                Icons.storage,
                theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Memory',
                '${cacheStats.totalMemoryKB.toStringAsFixed(1)}KB',
                Icons.memory,
                theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemoryStatsSection(ThemeData theme, WidgetRef ref) {
    final memoryOptimizer = CustomerOrderMemoryOptimizer();
    final memoryStats = memoryOptimizer.getMemoryStats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Memory Optimization',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Reuse Rate',
                '${(memoryStats.reuseRate * 100).toStringAsFixed(1)}%',
                Icons.recycling,
                _getReuseRateColor(memoryStats.reuseRate, theme),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Memory',
                '${memoryStats.currentMemoryUsageKB}KB',
                Icons.memory,
                _getMemoryUsageColor(memoryStats.currentMemoryUsageKB, theme),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Objects',
                '${memoryStats.totalObjectsCreated}',
                Icons.widgets,
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme, WidgetRef ref) {
    final memoryOptimizer = CustomerOrderMemoryOptimizer();
    final recommendations = memoryOptimizer.getOptimizationRecommendations();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optimization Tips',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        ...recommendations.take(2).map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading metrics...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getCompactPerformanceText(CustomerOrderCacheStats? cacheStats) {
    if (cacheStats == null) {
      return 'Loading...';
    }
    
    final hitRate = (cacheStats.hitRate * 100).toStringAsFixed(0);
    final memoryKB = cacheStats.totalMemoryKB.toStringAsFixed(0);
    
    return '$hitRate% cache, ${memoryKB}KB';
  }

  Color _getCacheHitRateColor(double hitRate, ThemeData theme) {
    if (hitRate >= 0.8) return Colors.green;
    if (hitRate >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getReuseRateColor(double reuseRate, ThemeData theme) {
    if (reuseRate >= 0.5) return Colors.green;
    if (reuseRate >= 0.3) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryUsageColor(int memoryKB, ThemeData theme) {
    if (memoryKB < 5120) return Colors.green; // < 5MB
    if (memoryKB < 10240) return Colors.orange; // < 10MB
    return Colors.red; // >= 10MB
  }

  void _showPerformanceDetails(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CustomerOrderPerformanceDialog(),
    );
  }
}

/// Detailed performance dialog
class CustomerOrderPerformanceDialog extends ConsumerWidget {
  const CustomerOrderPerformanceDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Performance Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Detailed metrics
            Expanded(
              child: SingleChildScrollView(
                child: CustomerOrderPerformanceMonitor(
                  showDetailedMetrics: true,
                  showMemoryStats: true,
                  showCacheStats: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
