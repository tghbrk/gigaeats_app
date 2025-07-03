import 'package:flutter/foundation.dart';
import 'performance_monitor.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  bool _isInitialized = false;

  // Initialize monitoring services
  void initialize() {
    if (_isInitialized) return;

    _performanceMonitor.initialize();
    _isInitialized = true;

    if (kDebugMode) {
      print('🔍 MonitoringService: Initialized');
    }
  }

  // Customization-specific monitoring methods
  Future<T> monitorCustomizationLoad<T>({
    required String menuItemId,
    required Future<T> Function() operation,
    int? customizationCount,
    int? optionCount,
  }) async {
    return await _performanceMonitor.measureOperation(
      operation: 'load_customizations',
      category: 'customization',
      function: operation,
      metadata: {
        'menu_item_id': menuItemId,
        if (customizationCount != null) 'customization_count': customizationCount,
        if (optionCount != null) 'option_count': optionCount,
      },
    );
  }

  Future<T> monitorPricingCalculation<T>({
    required Future<T> Function() operation,
    int? itemCount,
    int? customizationCount,
    double? basePrice,
    double? totalPrice,
  }) async {
    return await _performanceMonitor.measureOperation(
      operation: 'calculate_pricing',
      category: 'customization',
      function: operation,
      metadata: {
        if (itemCount != null) 'item_count': itemCount,
        if (customizationCount != null) 'customization_count': customizationCount,
        if (basePrice != null) 'base_price': basePrice,
        if (totalPrice != null) 'total_price': totalPrice,
      },
    );
  }

  Future<T> monitorCartOperation<T>({
    required String operation,
    required Future<T> Function() function,
    int? itemCount,
    bool? hasCustomizations,
    double? totalAmount,
  }) async {
    return await _performanceMonitor.measureOperation(
      operation: 'cart_$operation',
      category: 'ui',
      function: function,
      metadata: {
        if (itemCount != null) 'item_count': itemCount,
        if (hasCustomizations != null) 'has_customizations': hasCustomizations,
        if (totalAmount != null) 'total_amount': totalAmount,
      },
    );
  }

  Future<T> monitorDatabaseQuery<T>({
    required String table,
    required String operation,
    required Future<T> Function() function,
    int? recordCount,
    Map<String, dynamic>? queryParams,
  }) async {
    return await _performanceMonitor.measureOperation(
      operation: '${operation}_$table',
      category: 'database',
      function: function,
      metadata: {
        'table': table,
        if (recordCount != null) 'record_count': recordCount,
        if (queryParams != null) 'query_params': queryParams,
      },
    );
  }

  Future<T> monitorUIRender<T>({
    required String screen,
    required String component,
    required Future<T> Function() operation,
    Map<String, dynamic>? renderData,
  }) async {
    return await _performanceMonitor.measureOperation(
      operation: 'render_$component',
      category: 'ui',
      function: operation,
      metadata: {
        'screen': screen,
        'component': component,
        if (renderData != null) ...renderData,
      },
    );
  }

  // Quick recording methods for simple operations
  void recordCustomizationMetric({
    required String operation,
    required int durationMs,
    String? menuItemId,
    int? customizationCount,
    int? optionCount,
  }) {
    _performanceMonitor.recordCustomizationMetric(
      operation: operation,
      durationMs: durationMs,
      menuItemId: menuItemId,
      customizationCount: customizationCount,
      optionCount: optionCount,
    );
  }

  void recordDatabaseMetric({
    required String operation,
    required int durationMs,
    String? table,
    int? recordCount,
  }) {
    _performanceMonitor.recordDatabaseMetric(
      operation: operation,
      durationMs: durationMs,
      table: table,
      recordCount: recordCount,
    );
  }

  void recordUIMetric({
    required String operation,
    required int durationMs,
    String? screen,
    String? component,
  }) {
    _performanceMonitor.recordUIMetric(
      operation: operation,
      durationMs: durationMs,
      screen: screen,
      component: component,
    );
  }

  // Get performance statistics
  Future<PerformanceStats> getOverallStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _performanceMonitor.getStats(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<PerformanceStats> getCustomizationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _performanceMonitor.getStats(
      category: 'customization',
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<PerformanceStats> getDatabaseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _performanceMonitor.getStats(
      category: 'database',
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<PerformanceStats> getUIStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _performanceMonitor.getStats(
      category: 'ui',
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Dispose resources
  void dispose() {
    _performanceMonitor.dispose();
    _isInitialized = false;
  }
}

// Extension methods for easy monitoring integration
extension MonitoredFuture<T> on Future<T> {
  Future<T> monitorAs({
    required String operation,
    required String category,
    Map<String, dynamic>? metadata,
  }) async {
    return await MonitoringService()._performanceMonitor.measureOperation(
      operation: operation,
      category: category,
      function: () => this,
      metadata: metadata,
    );
  }

  Future<T> monitorCustomization({
    required String operation,
    String? menuItemId,
    int? customizationCount,
    int? optionCount,
  }) async {
    return await MonitoringService().monitorCustomizationLoad(
      menuItemId: menuItemId ?? 'unknown',
      operation: () => this,
      customizationCount: customizationCount,
      optionCount: optionCount,
    );
  }

  Future<T> monitorDatabase({
    required String table,
    required String operation,
    int? recordCount,
    Map<String, dynamic>? queryParams,
  }) async {
    return await MonitoringService().monitorDatabaseQuery(
      table: table,
      operation: operation,
      function: () => this,
      recordCount: recordCount,
      queryParams: queryParams,
    );
  }

  Future<T> monitorUI({
    required String screen,
    required String component,
    Map<String, dynamic>? renderData,
  }) async {
    return await MonitoringService().monitorUIRender(
      screen: screen,
      component: component,
      operation: () => this,
      renderData: renderData,
    );
  }
}
