import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_driver_order_history_providers.dart';
import 'modern_date_filter_components_m3.dart';
import 'modern_date_filter_dialog_m3.dart';

/// Complete modern Material Design 3 date filter interface
/// 
/// This widget provides a comprehensive filtering interface that combines
/// quick filter chips, status display, and access to advanced filtering options.
class ModernCompleteFilterInterface extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final bool showQuickFilters;
  final bool showStatusCard;
  final bool showOrderCount;
  final bool enableAdvancedFilters;
  final VoidCallback? onFilterChanged;

  const ModernCompleteFilterInterface({
    super.key,
    this.padding,
    this.showQuickFilters = true,
    this.showStatusCard = true,
    this.showOrderCount = true,
    this.enableAdvancedFilters = true,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter status card
          if (showStatusCard)
            ModernFilterStatusCard(
              showOrderCount: showOrderCount,
              onFilterTap: enableAdvancedFilters 
                  ? () => _showAdvancedFilters(context)
                  : null,
              onClearTap: () => _clearAllFilters(ref),
            ),

          if (showStatusCard && showQuickFilters)
            const SizedBox(height: 16),

          // Quick filter chips
          if (showQuickFilters)
            ModernQuickFilterChipBar(
              showFilterCount: true,
              onFilterChanged: onFilterChanged,
            ),

          // Performance indicator (if enabled)
          if (enableAdvancedFilters) ...[
            const SizedBox(height: 12),
            _buildPerformanceIndicator(theme, colorScheme, ref),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(ThemeData theme, ColorScheme colorScheme, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final combinedFilter = ref.watch(combinedDateFilterProvider);
        final performanceImpact = _getPerformanceImpact(combinedFilter);
        
        if (performanceImpact == FilterPerformanceImpact.low) {
          return const SizedBox.shrink(); // Don't show for low impact
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getPerformanceColor(performanceImpact, colorScheme).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getPerformanceColor(performanceImpact, colorScheme).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPerformanceIcon(performanceImpact),
                size: 16,
                color: _getPerformanceColor(performanceImpact, colorScheme),
              ),
              const SizedBox(width: 6),
              Text(
                performanceImpact.description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getPerformanceColor(performanceImpact, colorScheme),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  FilterPerformanceImpact _getPerformanceImpact(DateRangeFilter filter) {
    final now = DateTime.now();
    
    if (filter.startDate != null) {
      final daysDiff = now.difference(filter.startDate!).inDays;
      if (daysDiff <= 1) return FilterPerformanceImpact.low;
      if (daysDiff <= 7) return FilterPerformanceImpact.low;
      if (daysDiff <= 30) return FilterPerformanceImpact.medium;
      if (daysDiff <= 90) return FilterPerformanceImpact.high;
      return FilterPerformanceImpact.veryHigh;
    }
    
    return FilterPerformanceImpact.medium;
  }

  Color _getPerformanceColor(FilterPerformanceImpact impact, ColorScheme colorScheme) {
    switch (impact) {
      case FilterPerformanceImpact.low:
        return colorScheme.primary;
      case FilterPerformanceImpact.medium:
        return Colors.orange;
      case FilterPerformanceImpact.high:
        return Colors.deepOrange;
      case FilterPerformanceImpact.veryHigh:
        return colorScheme.error;
    }
  }

  IconData _getPerformanceIcon(FilterPerformanceImpact impact) {
    switch (impact) {
      case FilterPerformanceImpact.low:
        return Icons.speed_rounded;
      case FilterPerformanceImpact.medium:
        return Icons.schedule_rounded;
      case FilterPerformanceImpact.high:
        return Icons.hourglass_top_rounded;
      case FilterPerformanceImpact.veryHigh:
        return Icons.warning_rounded;
    }
  }

  void _showAdvancedFilters(BuildContext context) {
    showModernDateFilterBottomSheet(
      context,
      onFilterApplied: onFilterChanged,
    );
  }

  void _clearAllFilters(WidgetRef ref) {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
    ref.read(dateFilterProvider.notifier).reset();
    onFilterChanged?.call();
  }
}

/// Modern filter summary widget for displaying current filter state
class ModernFilterSummary extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final bool showAnalytics;
  final bool showRecommendations;

  const ModernFilterSummary({
    super.key,
    this.padding,
    this.showAnalytics = false,
    this.showRecommendations = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedQuickFilter = ref.watch(selectedQuickFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final combinedFilter = ref.watch(combinedDateFilterProvider);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current filter summary
          _buildFilterSummary(theme, colorScheme, selectedQuickFilter, dateFilter),

          if (showAnalytics) ...[
            const SizedBox(height: 16),
            _buildAnalytics(theme, colorScheme, ref, combinedFilter),
          ],

          if (showRecommendations) ...[
            const SizedBox(height: 16),
            _buildRecommendations(theme, colorScheme, selectedQuickFilter),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    QuickDateFilter quickFilter,
    DateRangeFilter dateFilter,
  ) {
    final hasActiveFilter = quickFilter != QuickDateFilter.all || dateFilter.hasActiveFilter;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasActiveFilter 
                    ? Icons.filter_alt_rounded
                    : Icons.filter_alt_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Filter',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilter 
                ? (quickFilter != QuickDateFilter.all 
                    ? quickFilter.shortDescription
                    : dateFilter.description)
                : 'Showing all order history',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics(
    ThemeData theme,
    ColorScheme colorScheme,
    WidgetRef ref,
    DateRangeFilter combinedFilter,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final orderCountAsync = ref.watch(orderCountByDateProvider(combinedFilter));
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Analytics',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              orderCountAsync.when(
                data: (count) => _buildAnalyticsContent(theme, colorScheme, count, combinedFilter),
                loading: () => const CircularProgressIndicator(),
                error: (_, stackTrace) => Text(
                  'Unable to load analytics',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsContent(
    ThemeData theme,
    ColorScheme colorScheme,
    int orderCount,
    DateRangeFilter filter,
  ) {
    final dayRange = filter.startDate != null && filter.endDate != null
        ? filter.endDate!.difference(filter.startDate!).inDays + 1
        : null;
    
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsItem(
            theme,
            colorScheme,
            'Orders',
            orderCount.toString(),
            Icons.receipt_long_rounded,
          ),
        ),
        if (dayRange != null) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildAnalyticsItem(
              theme,
              colorScheme,
              'Days',
              dayRange.toString(),
              Icons.calendar_today_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildAnalyticsItem(
              theme,
              colorScheme,
              'Avg/Day',
              (orderCount / dayRange).toStringAsFixed(1),
              Icons.trending_up_rounded,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsItem(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(
    ThemeData theme,
    ColorScheme colorScheme,
    QuickDateFilter currentFilter,
  ) {
    final recommendations = _getFilterRecommendations(currentFilter);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $recommendation',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )),
        ],
      ),
    );
  }

  List<String> _getFilterRecommendations(QuickDateFilter currentFilter) {
    final recommendations = <String>[];
    
    switch (currentFilter) {
      case QuickDateFilter.all:
        recommendations.add('Try "Today" or "This Week" for faster loading');
        break;
      case QuickDateFilter.today:
        recommendations.add('Check "Yesterday" to compare performance');
        break;
      case QuickDateFilter.thisWeek:
        recommendations.add('Use "Last Week" to see weekly trends');
        break;
      case QuickDateFilter.thisMonth:
        recommendations.add('Compare with "Last Month" for insights');
        break;
      default:
        break;
    }
    
    return recommendations;
  }
}
