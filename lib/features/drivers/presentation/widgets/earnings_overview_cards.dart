import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_earnings_provider.dart';

/// Animated earnings overview cards with counters and trend indicators
class EarningsOverviewCards extends ConsumerStatefulWidget {
  final String driverId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String period;

  const EarningsOverviewCards({
    super.key,
    required this.driverId,
    this.startDate,
    this.endDate,
    this.period = 'this_month',
  });

  @override
  ConsumerState<EarningsOverviewCards> createState() => _EarningsOverviewCardsState();
}

class _EarningsOverviewCardsState extends ConsumerState<EarningsOverviewCards>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _startAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create stable earnings parameters
    final stableKey = '${widget.period}_${widget.startDate?.millisecondsSinceEpoch ?? 0}_${widget.endDate?.millisecondsSinceEpoch ?? 0}';

    final earningsParams = EarningsParams(
      driverId: widget.driverId,
      startDate: widget.startDate,
      endDate: widget.endDate,
      period: widget.period,
      stableKey: stableKey,
    );

    final summaryAsync = ref.watch(driverEarningsSummaryProvider(earningsParams));

    return summaryAsync.when(
      loading: () => _buildLoadingCards(theme),
      error: (error, stack) => _buildErrorCard(theme, error.toString()),
      data: (summary) => _buildOverviewCards(theme, summary),
    );
  }

  /// Build loading state cards
  Widget _buildLoadingCards(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildSkeletonCard(theme)),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonCard(theme)),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonCard(theme)),
      ],
    );
  }

  /// Build skeleton loading card
  Widget _buildSkeletonCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard(ThemeData theme, String error) {
    return Card(
      elevation: 4,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build overview cards with data
  Widget _buildOverviewCards(ThemeData theme, Map<String, dynamic> summary) {
    final totalEarnings = (summary['total_net_earnings'] as double?) ?? 0.0;
    final totalDeliveries = (summary['total_deliveries'] as int?) ?? 0;
    final avgPerDelivery = (summary['average_earnings_per_delivery'] as double?) ?? 0.0;

    // Calculate trends (placeholder - would need historical data)
    final earningsTrend = _calculateTrend(totalEarnings, 'earnings');
    final deliveriesTrend = _calculateTrend(totalDeliveries.toDouble(), 'deliveries');
    final avgTrend = _calculateTrend(avgPerDelivery, 'average');

    return Row(
      children: [
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildAnimatedCard(
                  theme,
                  title: 'Total Earnings',
                  value: totalEarnings,
                  prefix: 'RM ',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  trend: earningsTrend,
                  delay: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildAnimatedCard(
                  theme,
                  title: 'Deliveries',
                  value: totalDeliveries.toDouble(),
                  prefix: '',
                  suffix: '',
                  icon: Icons.local_shipping,
                  color: Colors.blue,
                  trend: deliveriesTrend,
                  delay: 200,
                  isInteger: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildAnimatedCard(
                  theme,
                  title: 'Avg/Delivery',
                  value: avgPerDelivery,
                  prefix: 'RM ',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  trend: avgTrend,
                  delay: 400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build individual animated card
  Widget _buildAnimatedCard(
    ThemeData theme, {
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required TrendData trend,
    String prefix = '',
    String suffix = '',
    int delay = 0,
    bool isInteger = false,
  }) {
    return Card(
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.3),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Animated value
              AnimatedCounterWidget(
                value: value,
                prefix: prefix,
                suffix: suffix,
                isInteger: isInteger,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                duration: Duration(milliseconds: 1500 + delay),
              ),
              
              const Spacer(),
              
              // Trend indicator
              _buildTrendIndicator(theme, trend),
            ],
          ),
        ),
      ),
    );
  }

  /// Build trend indicator
  Widget _buildTrendIndicator(ThemeData theme, TrendData trend) {
    return Row(
      children: [
        Icon(
          trend.isPositive ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: trend.isPositive ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          '${trend.isPositive ? '+' : ''}${trend.percentage.toStringAsFixed(1)}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: trend.isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          trend.period,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Calculate trend data (placeholder implementation)
  TrendData _calculateTrend(double currentValue, String type) {
    // In a real implementation, this would compare with previous period data
    // For now, we'll generate some sample trend data
    final random = (currentValue * 7) % 100;
    final isPositive = random > 50;
    final percentage = (random % 20) + 1;
    
    return TrendData(
      isPositive: isPositive,
      percentage: percentage.toDouble(),
      period: 'vs last ${widget.period.replaceAll('_', ' ')}',
    );
  }
}

/// Trend data model
class TrendData {
  final bool isPositive;
  final double percentage;
  final String period;

  const TrendData({
    required this.isPositive,
    required this.percentage,
    required this.period,
  });
}

/// Animated counter widget for smooth number transitions
class AnimatedCounterWidget extends StatefulWidget {
  final double value;
  final String prefix;
  final String suffix;
  final bool isInteger;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounterWidget({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.isInteger = false,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedCounterWidget> createState() => _AnimatedCounterWidgetState();
}

class _AnimatedCounterWidgetState extends State<AnimatedCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;

      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final displayValue = widget.isInteger
            ? currentValue.round().toString()
            : currentValue.toStringAsFixed(2);

        return Text(
          '${widget.prefix}$displayValue${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Enhanced earnings overview cards with additional features
class EnhancedEarningsOverviewCards extends ConsumerStatefulWidget {
  final String driverId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String period;
  final bool showComparison;
  final VoidCallback? onCardTap;

  const EnhancedEarningsOverviewCards({
    super.key,
    required this.driverId,
    this.startDate,
    this.endDate,
    this.period = 'this_month',
    this.showComparison = true,
    this.onCardTap,
  });

  @override
  ConsumerState<EnhancedEarningsOverviewCards> createState() => _EnhancedEarningsOverviewCardsState();
}

class _EnhancedEarningsOverviewCardsState extends ConsumerState<EnhancedEarningsOverviewCards>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start subtle pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create stable earnings parameters
    final stableKey = '${widget.period}_${widget.startDate?.millisecondsSinceEpoch ?? 0}_${widget.endDate?.millisecondsSinceEpoch ?? 0}';

    final earningsParams = EarningsParams(
      driverId: widget.driverId,
      startDate: widget.startDate,
      endDate: widget.endDate,
      period: widget.period,
      stableKey: stableKey,
    );

    final summaryAsync = ref.watch(driverEarningsSummaryProvider(earningsParams));

    return summaryAsync.when(
      loading: () => _buildLoadingState(theme),
      error: (error, stack) => _buildErrorState(theme, error.toString()),
      data: (summary) => _buildEnhancedCards(theme, summary),
    );
  }

  /// Build loading state with shimmer effect
  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildShimmerCard(theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard(theme)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildShimmerCard(theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildShimmerCard(theme)),
          ],
        ),
      ],
    );
  }

  /// Build shimmer loading card
  Widget _buildShimmerCard(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Card(
            elevation: 4,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build error state
  Widget _buildErrorState(ThemeData theme, String error) {
    return Card(
      elevation: 4,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load earnings data',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build enhanced cards with additional metrics
  Widget _buildEnhancedCards(ThemeData theme, Map<String, dynamic> summary) {
    final totalEarnings = (summary['total_net_earnings'] as double?) ?? 0.0;
    final totalDeliveries = (summary['total_deliveries'] as int?) ?? 0;
    final avgPerDelivery = (summary['average_earnings_per_delivery'] as double?) ?? 0.0;
    final totalGross = (summary['total_gross_earnings'] as double?) ?? 0.0;

    return Column(
      children: [
        // Top row - main metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                title: 'Net Earnings',
                value: totalEarnings,
                prefix: 'RM ',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                title: 'Deliveries',
                value: totalDeliveries.toDouble(),
                icon: Icons.local_shipping,
                color: Colors.blue,
                isInteger: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row - secondary metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                title: 'Avg/Delivery',
                value: avgPerDelivery,
                prefix: 'RM ',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                title: 'Gross Earnings',
                value: totalGross,
                prefix: 'RM ',
                icon: Icons.monetization_on,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual metric card
  Widget _buildMetricCard(
    ThemeData theme, {
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    String prefix = '',
    String suffix = '',
    bool isInteger = false,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: widget.onCardTap,
      child: Card(
        elevation: isPrimary ? 8 : 4,
        shadowColor: color.withValues(alpha: 0.3),
        child: Container(
          height: isPrimary ? 120 : 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: isPrimary ? 0.15 : 0.1),
                color.withValues(alpha: isPrimary ? 0.08 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        size: isPrimary ? 20 : 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: isPrimary ? 12 : 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Animated value
                AnimatedCounterWidget(
                  value: value,
                  prefix: prefix,
                  suffix: suffix,
                  isInteger: isInteger,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: isPrimary ? 24 : 18,
                  ),
                  duration: const Duration(milliseconds: 1200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
