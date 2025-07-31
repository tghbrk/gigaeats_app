import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/data/models/order.dart';
import '../../data/services/lazy_loading_service.dart';
import '../providers/enhanced_driver_order_history_providers.dart';
import '../providers/optimized_order_history_providers.dart';

/// Enhanced lazy loading components with infinite scroll and performance optimization
/// 
/// This file contains advanced lazy loading widgets that provide smooth 60fps scrolling,
/// intelligent prefetching, skeleton screens, and comprehensive loading states.

/// Enhanced infinite scroll list with performance optimization
class EnhancedInfiniteScrollList extends ConsumerStatefulWidget {
  final DateRangeFilter filter;
  final Widget Function(BuildContext, Order, int) itemBuilder;
  final Widget Function(BuildContext)? emptyBuilder;
  final Widget Function(BuildContext, String)? errorBuilder;
  final EdgeInsetsGeometry? padding;
  final bool enablePrefetch;
  final bool showPerformanceIndicator;
  final double prefetchThreshold;
  final int initialLoadCount;

  const EnhancedInfiniteScrollList({
    super.key,
    required this.filter,
    required this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.padding,
    this.enablePrefetch = true,
    this.showPerformanceIndicator = false,
    this.prefetchThreshold = 0.8,
    this.initialLoadCount = 20,
  });

  @override
  ConsumerState<EnhancedInfiniteScrollList> createState() => _EnhancedInfiniteScrollListState();
}

class _EnhancedInfiniteScrollListState extends ConsumerState<EnhancedInfiniteScrollList>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  late ScrollController _scrollController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;
  
  bool _isLoadingMore = false;
  bool _hasScrolledToThreshold = false;
  int _lastFrameTime = 0;
  double _currentFps = 60.0;
  
  // Performance monitoring
  final List<int> _frameTimes = [];
  static const int _maxFrameTimesSamples = 60;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeScrollController();
    _initializeAnimations();
    _startPerformanceMonitoring();
  }

  void _initializeScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _loadingAnimationController.repeat();
  }

  void _startPerformanceMonitoring() {
    if (widget.showPerformanceIndicator) {
      WidgetsBinding.instance.addPostFrameCallback(_measureFrameTime);
    }
  }

  void _measureFrameTime(Duration timestamp) {
    final currentTime = timestamp.inMilliseconds;
    if (_lastFrameTime != 0) {
      final frameTime = currentTime - _lastFrameTime;
      _frameTimes.add(frameTime);
      
      if (_frameTimes.length > _maxFrameTimesSamples) {
        _frameTimes.removeAt(0);
      }
      
      // Calculate FPS
      if (_frameTimes.isNotEmpty) {
        final averageFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        _currentFps = 1000 / averageFrameTime;
      }
    }
    _lastFrameTime = currentTime;
    
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback(_measureFrameTime);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enablePrefetch || _isLoadingMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * widget.prefetchThreshold;

    if (currentScroll >= threshold && !_hasScrolledToThreshold) {
      _hasScrolledToThreshold = true;
      _loadMore();
    }
    
    // Reset threshold flag when scrolling back up
    if (currentScroll < threshold * 0.5) {
      _hasScrolledToThreshold = false;
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final notifier = ref.read(optimizedDriverOrderHistoryProvider(widget.filter).notifier);
      await notifier.loadMore();
    } catch (e) {
      debugPrint('🚀 EnhancedInfiniteScroll: Error loading more: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final orderHistoryAsync = ref.watch(optimizedDriverOrderHistoryProvider(widget.filter));
    
    return orderHistoryAsync.when(
      data: (result) => _buildScrollableList(context, result),
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildScrollableList(BuildContext context, LazyLoadingResult<Order> result) {
    if (result.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ?? _buildDefaultEmptyState(context);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Performance indicator (debug mode only)
        if (widget.showPerformanceIndicator && !const bool.fromEnvironment('dart.vm.product'))
          SliverToBoxAdapter(
            child: _buildPerformanceIndicator(context, result),
          ),

        // Main content
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Show skeleton loading for items being loaded
                if (index >= result.items.length) {
                  return _buildSkeletonItem(context);
                }
                
                final order = result.items[index];
                return widget.itemBuilder(context, order, index);
              },
              childCount: result.items.length + (_isLoadingMore ? 3 : 0),
            ),
          ),
        ),

        // Load more indicator
        if (result.hasMore || _isLoadingMore)
          SliverToBoxAdapter(
            child: _buildLoadMoreIndicator(context, result),
          ),

        // Bottom padding for better UX
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSkeletonItem(context),
              childCount: widget.initialLoadCount,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return widget.errorBuilder?.call(context, error) ?? 
           _buildDefaultErrorState(context, error);
  }

  Widget _buildSkeletonItem(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              _buildShimmerBox(60, 20, colorScheme),
              const Spacer(),
              _buildShimmerBox(80, 16, colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content skeleton
          _buildShimmerBox(double.infinity, 16, colorScheme),
          const SizedBox(height: 8),
          _buildShimmerBox(200, 14, colorScheme),
          const SizedBox(height: 12),
          
          // Footer skeleton
          Row(
            children: [
              _buildShimmerBox(100, 14, colorScheme),
              const Spacer(),
              _buildShimmerBox(60, 14, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainerHighest.withOpacity(0.5),
                colorScheme.surfaceContainerHighest,
              ],
              stops: [
                0.0,
                _loadingAnimation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context, LazyLoadingResult<Order> result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_isLoadingMore) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading more orders...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (result.hasMore) ...[
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Scroll for more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            Icon(
              Icons.check_circle_outline_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'All orders loaded',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(BuildContext context, LazyLoadingResult<Order> result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final fpsColor = _currentFps >= 55 
        ? Colors.green 
        : _currentFps >= 45 
            ? Colors.orange 
            : Colors.red;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, size: 16, color: fpsColor),
          const SizedBox(width: 8),
          Text(
            'FPS: ${_currentFps.toStringAsFixed(1)}',
            style: theme.textTheme.labelSmall?.copyWith(color: fpsColor),
          ),
          const SizedBox(width: 16),
          Icon(Icons.list_rounded, size: 16, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '${result.items.length} items',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (result.fromCache) ...[
            const SizedBox(width: 8),
            Icon(Icons.cached_rounded, size: 14, color: Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter settings',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load orders',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(optimizedDriverOrderHistoryProvider(widget.filter));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
