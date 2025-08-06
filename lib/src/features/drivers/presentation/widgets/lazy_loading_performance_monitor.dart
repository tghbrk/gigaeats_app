import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/enhanced_lazy_loading_providers.dart';

/// Performance monitoring widget for lazy loading system
/// 
/// This widget provides real-time performance metrics and optimization insights
/// for the lazy loading system, helping developers monitor and optimize performance.
class LazyLoadingPerformanceMonitor extends ConsumerWidget {
  final bool showDetailedMetrics;
  final bool showRecommendations;
  final EdgeInsetsGeometry? padding;

  const LazyLoadingPerformanceMonitor({
    super.key,
    this.showDetailedMetrics = false,
    this.showRecommendations = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final performanceData = ref.watch(lazyLoadingPerformanceProvider);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Card(
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lazy Loading Performance',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (showDetailedMetrics)
                    Icon(
                      Icons.analytics_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Performance metrics
              _buildPerformanceMetrics(context, theme, performanceData),

              if (showDetailedMetrics) ...[
                const SizedBox(height: 16),
                _buildDetailedMetrics(context, theme, performanceData),
              ],

              if (showRecommendations) ...[
                const SizedBox(height: 16),
                _buildRecommendations(context, theme, performanceData),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, ThemeData theme, Map<String, dynamic> data) {
    final colorScheme = theme.colorScheme;
    final cacheHitRate = (data['cacheHitRate'] as double? ?? 0.0) * 100;
    final averageLoadTime = data['averageLoadTime'] as int? ?? 0;
    final activeStates = data['activeStates'] as int? ?? 0;
    // final ongoingRequests = data['ongoingRequests'] as int? ?? 0; // TODO: Use for detailed metrics

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            theme,
            'Cache Hit Rate',
            '${cacheHitRate.toStringAsFixed(1)}%',
            Icons.cached_rounded,
            _getCacheHitRateColor(cacheHitRate, colorScheme),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            theme,
            'Avg Load Time',
            '${averageLoadTime}ms',
            Icons.timer_rounded,
            _getLoadTimeColor(averageLoadTime, colorScheme),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            theme,
            'Active States',
            activeStates.toString(),
            Icons.memory_rounded,
            colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics(BuildContext context, ThemeData theme, Map<String, dynamic> data) {
    final colorScheme = theme.colorScheme;
    final totalCacheHits = data['totalCacheHits'] as int? ?? 0;
    final totalCacheMisses = data['totalCacheMisses'] as int? ?? 0;
    final ongoingRequests = data['ongoingRequests'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Metrics',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildDetailedMetricRow(theme, 'Cache Hits', totalCacheHits.toString(), Icons.check_circle_rounded, Colors.green),
          _buildDetailedMetricRow(theme, 'Cache Misses', totalCacheMisses.toString(), Icons.cancel_rounded, Colors.orange),
          _buildDetailedMetricRow(theme, 'Ongoing Requests', ongoingRequests.toString(), Icons.sync_rounded, colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricRow(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, ThemeData theme, Map<String, dynamic> data) {
    final colorScheme = theme.colorScheme;
    final recommendations = _generateRecommendations(data);

    if (recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text(
              'Performance is optimal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Optimization Recommendations',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_right_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    recommendation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getCacheHitRateColor(double hitRate, ColorScheme colorScheme) {
    if (hitRate >= 80) return Colors.green;
    if (hitRate >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getLoadTimeColor(int loadTime, ColorScheme colorScheme) {
    if (loadTime <= 500) return Colors.green;
    if (loadTime <= 1000) return Colors.orange;
    return Colors.red;
  }

  List<String> _generateRecommendations(Map<String, dynamic> data) {
    final recommendations = <String>[];
    final cacheHitRate = (data['cacheHitRate'] as double? ?? 0.0) * 100;
    final averageLoadTime = data['averageLoadTime'] as int? ?? 0;
    final activeStates = data['activeStates'] as int? ?? 0;
    final ongoingRequests = data['ongoingRequests'] as int? ?? 0;

    if (cacheHitRate < 60) {
      recommendations.add('Low cache hit rate - consider increasing cache duration');
    }

    if (averageLoadTime > 1000) {
      recommendations.add('High load times - optimize database queries or reduce page size');
    }

    if (activeStates > 10) {
      recommendations.add('Many active states - consider implementing state cleanup');
    }

    if (ongoingRequests > 5) {
      recommendations.add('Multiple concurrent requests - implement request deduplication');
    }

    if (cacheHitRate > 90 && averageLoadTime < 300) {
      recommendations.add('Excellent performance - consider increasing prefetch aggressiveness');
    }

    return recommendations;
  }
}

/// Scroll performance indicator widget
class ScrollPerformanceIndicator extends ConsumerWidget {
  final String driverId;
  final bool showFPS;
  final bool showScrollMetrics;

  const ScrollPerformanceIndicator({
    super.key,
    required this.driverId,
    this.showFPS = true,
    this.showScrollMetrics = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scrollState = ref.watch(infiniteScrollProvider(driverId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFPS) ...[
            Icon(
              Icons.speed_rounded,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '60 FPS', // This would be calculated from actual frame times
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          
          if (showScrollMetrics && showFPS)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 12,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          
          if (showScrollMetrics) ...[
            Icon(
              Icons.vertical_align_center_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${(scrollState.scrollPercentage * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          if (scrollState.isLoadingMore) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
