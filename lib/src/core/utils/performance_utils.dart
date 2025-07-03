import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PerformanceUtils {
  static const int _defaultCacheSize = 100;
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  // Simple in-memory cache
  static final Map<String, CacheEntry> _cache = {};

  // Debounce utility for search and other frequent operations
  static Timer? _debounceTimer;

  /// Debounce function calls to improve performance
  static void debounce(
    Duration duration,
    VoidCallback callback,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Cache data with expiration
  static void cacheData<T>(
    String key,
    T data, {
    Duration? duration,
  }) {
    final expiry = DateTime.now().add(duration ?? _defaultCacheDuration);
    _cache[key] = CacheEntry(data, expiry);

    // Clean up old entries if cache is too large
    if (_cache.length > _defaultCacheSize) {
      _cleanupCache();
    }
  }

  /// Retrieve cached data
  static T? getCachedData<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Clear specific cache entry
  static void clearCache(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  static void clearAllCache() {
    _cache.clear();
  }

  /// Clean up expired cache entries
  static void _cleanupCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiry));
  }

  /// Measure execution time of a function (debug only)
  static Future<T> measureExecutionTime<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    if (!kDebugMode) {
      return await function();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      debugPrint('⏱️ $operation took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ $operation failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Batch operations to reduce UI updates
  static Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 10,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
      
      // Small delay between batches to prevent UI blocking
      if (i + batchSize < operations.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }

  /// Lazy loading helper for lists
  static bool shouldLoadMore(
    ScrollController controller, {
    double threshold = 0.8,
  }) {
    if (!controller.hasClients) return false;
    
    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    
    return currentScroll >= maxScroll * threshold;
  }

  /// Memory usage monitoring (debug only)
  static void logMemoryUsage(String context) {
    if (!kDebugMode) return;
    
    // This is a simplified memory monitoring
    // In a real app, you might use more sophisticated tools
    debugPrint('📊 Memory check at $context');
  }

  /// Image caching helper with optimized caching
  static ImageProvider getCachedImage(String url) {
    // Use CachedNetworkImageProvider for better caching performance
    return CachedNetworkImageProvider(url);
  }

  /// Get cached image with custom cache configuration
  static ImageProvider getCachedImageWithConfig(
    String url, {
    Duration? maxAge,
    int? maxWidth,
    int? maxHeight,
  }) {
    return CachedNetworkImageProvider(
      url,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      cacheKey: url,
    );
  }

  /// Dispose resources
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    clearAllCache();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);
}

/// Mixin for widgets that need performance optimizations
mixin PerformanceOptimizedWidget<T extends StatefulWidget> on State<T> {
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;

  ScrollController get scrollController => _scrollController;
  bool get isLoadingMore => _isLoadingMore;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (PerformanceUtils.shouldLoadMore(_scrollController) && !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      await onLoadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Override this method to implement lazy loading
  Future<void> onLoadMore() async {}
}

/// Widget for optimized list building with performance enhancements
class OptimizedListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? loadingIndicator;
  final VoidCallback? onLoadMore;
  final double? itemExtent;
  final double? cacheExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.loadingIndicator,
    this.onLoadMore,
    this.itemExtent,
    this.cacheExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
  });

  @override
  State<OptimizedListView> createState() => _OptimizedListViewState();
}

class _OptimizedListViewState extends State<OptimizedListView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();

    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else if (widget.onLoadMore != null) {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (PerformanceUtils.shouldLoadMore(_scrollController)) {
      widget.onLoadMore?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.itemCount + (widget.onLoadMore != null ? 1 : 0),
      itemExtent: widget.itemExtent,
      cacheExtent: widget.cacheExtent,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      itemBuilder: (context, index) {
        if (index == widget.itemCount) {
          // Loading indicator at the end
          return widget.loadingIndicator ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        return widget.itemBuilder(context, index);
      },
    );
  }
}

/// Debounced search field widget
class DebouncedSearchField extends StatefulWidget {
  final String? hintText;
  final Duration debounceDuration;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController? controller;
  final InputDecoration? decoration;

  const DebouncedSearchField({
    super.key,
    this.hintText,
    this.debounceDuration = const Duration(milliseconds: 500),
    required this.onSearchChanged,
    this.controller,
    this.decoration,
  });

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearchChanged(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: widget.decoration ?? 
          InputDecoration(
            hintText: widget.hintText ?? 'Search...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _controller.clear();
                      widget.onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );
  }
}
