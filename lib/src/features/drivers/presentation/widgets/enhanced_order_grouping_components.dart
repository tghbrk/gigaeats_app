import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../orders/data/models/order.dart';
import '../../data/models/grouped_order_history.dart';
import '../providers/enhanced_driver_order_history_providers.dart';

/// Enhanced order grouping components with collapsible sections and improved display
/// 
/// This file contains advanced grouping widgets that provide collapsible date sections,
/// comprehensive order counts, earnings summaries, and enhanced empty states.

/// Enhanced collapsible order group widget
class EnhancedCollapsibleOrderGroup extends ConsumerStatefulWidget {
  final GroupedOrderHistory group;
  final Widget Function(BuildContext, Order) itemBuilder;
  final bool initiallyExpanded;
  final bool showEarningsSummary;
  final bool showOrderCount;
  final bool showDateDetails;
  final VoidCallback? onExpansionChanged;

  const EnhancedCollapsibleOrderGroup({
    super.key,
    required this.group,
    required this.itemBuilder,
    this.initiallyExpanded = true,
    this.showEarningsSummary = true,
    this.showOrderCount = true,
    this.showDateDetails = true,
    this.onExpansionChanged,
  });

  @override
  ConsumerState<EnhancedCollapsibleOrderGroup> createState() => _EnhancedCollapsibleOrderGroupState();
}

class _EnhancedCollapsibleOrderGroupState extends ConsumerState<EnhancedCollapsibleOrderGroup>
    with TickerProviderStateMixin {
  
  late AnimationController _expansionController;
  late AnimationController _iconController;
  late Animation<double> _expansionAnimation;
  late Animation<double> _iconAnimation;
  
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );
    
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));
    
    if (_isExpanded) {
      _expansionController.value = 1.0;
      _iconController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expansionController.forward();
        _iconController.forward();
      } else {
        _expansionController.reverse();
        _iconController.reverse();
      }
    });
    widget.onExpansionChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Group header with expansion controls
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpansion,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Date and status indicator
                    Expanded(
                      child: _buildGroupHeader(theme, colorScheme),
                    ),
                    
                    // Order count and earnings
                    if (widget.showOrderCount || widget.showEarningsSummary)
                      _buildGroupSummary(theme, colorScheme),
                    
                    const SizedBox(width: 12),
                    
                    // Expansion icon
                    AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconAnimation.value * 3.14159,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Expandable content
          SizeTransition(
            sizeFactor: _expansionAnimation,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Order items
                  ...widget.group.orders.asMap().entries.map((entry) {
                    final index = entry.key;
                    final order = entry.value;
                    
                    return Container(
                      decoration: BoxDecoration(
                        border: index < widget.group.orders.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.05),
                                ),
                              )
                            : null,
                      ),
                      child: widget.itemBuilder(context, order),
                    );
                  }),
                  
                  // Group footer with detailed statistics
                  if (_isExpanded && widget.showEarningsSummary)
                    _buildGroupFooter(theme, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(ThemeData theme, ColorScheme colorScheme) {
    final isToday = widget.group.isToday;
    final isYesterday = widget.group.isYesterday;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Date indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isToday 
                    ? colorScheme.primaryContainer
                    : isYesterday
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.group.displayDate,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isToday 
                      ? colorScheme.onPrimaryContainer
                      : isYesterday
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            if (widget.showDateDetails) ...[
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE').format(widget.group.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        
        if (widget.showDateDetails) ...[
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, yyyy').format(widget.group.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupSummary(ThemeData theme, ColorScheme colorScheme) {
    final totalEarnings = widget.group.totalEarnings;
    // final deliveredCount = widget.group.deliveredOrders; // TODO: Use for detailed stats
    final cancelledCount = widget.group.cancelledOrders;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.showOrderCount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.group.totalOrders} orders',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        
        if (widget.showEarningsSummary && totalEarnings > 0) ...[
          const SizedBox(height: 4),
          Text(
            'RM ${totalEarnings.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        
        if (cancelledCount > 0) ...[
          const SizedBox(height: 2),
          Text(
            '$cancelledCount cancelled',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupFooter(ThemeData theme, ColorScheme colorScheme) {
    final deliveredCount = widget.group.deliveredOrders;
    final cancelledCount = widget.group.cancelledOrders;
    final totalEarnings = widget.group.totalEarnings;
    final averageOrderValue = deliveredCount > 0 ? totalEarnings / deliveredCount : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterStat(
              theme,
              colorScheme,
              'Delivered',
              deliveredCount.toString(),
              Icons.check_circle_rounded,
              Colors.green,
            ),
          ),
          
          if (cancelledCount > 0) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildFooterStat(
                theme,
                colorScheme,
                'Cancelled',
                cancelledCount.toString(),
                Icons.cancel_rounded,
                colorScheme.error,
              ),
            ),
          ],
          
          if (averageOrderValue > 0) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildFooterStat(
                theme,
                colorScheme,
                'Avg Value',
                'RM ${averageOrderValue.toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterStat(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
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
}

/// Enhanced empty state widget with contextual messaging
class EnhancedOrderHistoryEmptyState extends ConsumerWidget {
  final DateRangeFilter filter;
  final QuickDateFilter quickFilter;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRefresh;
  final String? customMessage;
  final String? customSubtitle;

  const EnhancedOrderHistoryEmptyState({
    super.key,
    required this.filter,
    required this.quickFilter,
    this.onClearFilters,
    this.onRefresh,
    this.customMessage,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActiveFilter = _hasActiveFilter();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyStateIcon(hasActiveFilter),
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              customMessage ?? _getEmptyStateTitle(hasActiveFilter),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              customSubtitle ?? _getEmptyStateSubtitle(hasActiveFilter),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(context, theme, colorScheme, hasActiveFilter),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, ColorScheme colorScheme, bool hasActiveFilter) {
    return Column(
      children: [
        if (hasActiveFilter && onClearFilters != null)
          FilledButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Clear Filters'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

        if (hasActiveFilter && onClearFilters != null && onRefresh != null)
          const SizedBox(height: 12),

        if (onRefresh != null)
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              side: BorderSide(color: colorScheme.outline),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
      ],
    );
  }

  bool _hasActiveFilter() {
    return quickFilter != QuickDateFilter.all ||
           filter.startDate != null ||
           filter.endDate != null;
  }

  IconData _getEmptyStateIcon(bool hasActiveFilter) {
    if (hasActiveFilter) {
      return Icons.filter_alt_off_rounded;
    }
    return Icons.inbox_rounded;
  }

  String _getEmptyStateTitle(bool hasActiveFilter) {
    if (hasActiveFilter) {
      return 'No orders found';
    }
    return 'No order history yet';
  }

  String _getEmptyStateSubtitle(bool hasActiveFilter) {
    if (hasActiveFilter) {
      if (quickFilter != QuickDateFilter.all) {
        return 'No orders found for ${quickFilter.displayName.toLowerCase()}.\nTry adjusting your filter settings.';
      } else if (filter.startDate != null || filter.endDate != null) {
        return 'No orders found in the selected date range.\nTry expanding your search criteria.';
      }
      return 'No orders match your current filters.\nTry adjusting your search criteria.';
    }

    return 'Your completed orders will appear here.\nStart delivering to build your history!';
  }
}

/// Enhanced order statistics summary widget
class EnhancedOrderStatisticsSummary extends ConsumerWidget {
  final List<GroupedOrderHistory> groups;
  final bool showDetailedStats;
  final bool showTrends;
  final EdgeInsetsGeometry? padding;

  const EnhancedOrderStatisticsSummary({
    super.key,
    required this.groups,
    this.showDetailedStats = true,
    this.showTrends = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    final summary = _calculateSummary();

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Card(
        color: colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${groups.length} days',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      colorScheme,
                      'Total Orders',
                      summary.totalOrders.toString(),
                      Icons.receipt_long_rounded,
                      colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      colorScheme,
                      'Total Earnings',
                      'RM ${summary.totalEarnings.toStringAsFixed(2)}',
                      Icons.account_balance_wallet_rounded,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              if (showDetailedStats) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        colorScheme,
                        'Delivered',
                        summary.deliveredOrders.toString(),
                        Icons.check_circle_rounded,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        colorScheme,
                        'Cancelled',
                        summary.cancelledOrders.toString(),
                        Icons.cancel_rounded,
                        colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        colorScheme,
                        'Avg/Day',
                        (summary.totalOrders / groups.length).toStringAsFixed(1),
                        Icons.trending_up_rounded,
                        colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],

              if (showTrends) ...[
                const SizedBox(height: 16),
                _buildTrendIndicators(theme, colorScheme, summary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildTrendIndicators(ThemeData theme, ColorScheme colorScheme, OrderSummaryData summary) {
    // This would calculate trends based on historical data
    // For now, showing placeholder trend indicators
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Performance trends coming soon',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  OrderSummaryData _calculateSummary() {
    int totalOrders = 0;
    int deliveredOrders = 0;
    int cancelledOrders = 0;
    double totalEarnings = 0.0;

    for (final group in groups) {
      totalOrders += group.totalOrders;
      deliveredOrders += group.deliveredOrders;
      cancelledOrders += group.cancelledOrders;
      totalEarnings += group.totalEarnings;
    }

    return OrderSummaryData(
      totalOrders: totalOrders,
      deliveredOrders: deliveredOrders,
      cancelledOrders: cancelledOrders,
      totalEarnings: totalEarnings,
    );
  }
}

/// Order summary data model
class OrderSummaryData {
  final int totalOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalEarnings;

  const OrderSummaryData({
    required this.totalOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalEarnings,
  });

  double get averageOrderValue => deliveredOrders > 0 ? totalEarnings / deliveredOrders : 0.0;
  double get successRate => totalOrders > 0 ? deliveredOrders / totalOrders : 0.0;
}
