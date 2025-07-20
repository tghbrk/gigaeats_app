import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance testing utilities for Phase 5.1 validation
/// Provides memory monitoring, battery optimization testing, and Android emulator integration
class PerformanceTestHelpers {
  static const MethodChannel _performanceChannel = MethodChannel('gigaeats/performance');
  
  /// Get current memory usage in bytes
  static int getCurrentMemoryUsage() {
    if (kIsWeb) {
      // Web doesn't have direct memory access, return mock value
      return 50 * 1024 * 1024; // 50MB mock
    }
    
    try {
      // For mobile platforms, use ProcessInfo
      final info = ProcessInfo.currentRss;
      return info;
    } catch (e) {
      debugPrint('Failed to get memory usage: $e');
      return 0;
    }
  }

  /// Force garbage collection for memory testing
  static Future<void> forceGarbageCollection() async {
    // Trigger garbage collection multiple times
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      // Create and discard objects to trigger GC
      final temp = List.generate(1000, (index) => 'temp_$index');
      temp.clear();
    }
    
    // Additional delay to allow GC to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Monitor memory usage over time
  static Future<List<int>> monitorMemoryUsage({
    required Duration duration,
    required Duration interval,
  }) async {
    final measurements = <int>[];
    final endTime = DateTime.now().add(duration);
    
    while (DateTime.now().isBefore(endTime)) {
      measurements.add(getCurrentMemoryUsage());
      await Future.delayed(interval);
    }
    
    return measurements;
  }

  /// Calculate memory statistics
  static Map<String, double> calculateMemoryStats(List<int> measurements) {
    if (measurements.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'average': 0.0,
        'peak': 0.0,
        'growth': 0.0,
      };
    }
    
    final min = measurements.reduce((a, b) => a < b ? a : b).toDouble();
    final max = measurements.reduce((a, b) => a > b ? a : b).toDouble();
    final average = measurements.reduce((a, b) => a + b) / measurements.length;
    final peak = max;
    final growth = measurements.last - measurements.first.toDouble();
    
    return {
      'min': min / (1024 * 1024), // Convert to MB
      'max': max / (1024 * 1024),
      'average': average / (1024 * 1024),
      'peak': peak / (1024 * 1024),
      'growth': growth / (1024 * 1024),
    };
  }

  /// Test battery optimization features
  static Future<Map<String, dynamic>> testBatteryOptimization({
    required Future<void> Function() operation,
    required Duration testDuration,
  }) async {
    final startTime = DateTime.now();
    final startBattery = await getBatteryLevel();
    
    // Run the operation
    await operation();
    
    // Wait for test duration
    await Future.delayed(testDuration);
    
    final endTime = DateTime.now();
    final endBattery = await getBatteryLevel();
    
    final actualDuration = endTime.difference(startTime);
    final batteryDrain = startBattery - endBattery;
    final drainRate = batteryDrain / actualDuration.inMinutes;
    
    return {
      'startBattery': startBattery,
      'endBattery': endBattery,
      'batteryDrain': batteryDrain,
      'drainRate': drainRate, // % per minute
      'duration': actualDuration.inMinutes,
      'isOptimized': drainRate < 1.0, // Less than 1% per minute is considered optimized
    };
  }

  /// Get current battery level (mock for testing)
  static Future<double> getBatteryLevel() async {
    try {
      if (kIsWeb) {
        // Web doesn't have battery API access in tests
        return 85.0; // Mock battery level
      }
      
      // For mobile platforms, try to get actual battery level
      final batteryLevel = await _performanceChannel.invokeMethod<double>('getBatteryLevel');
      return batteryLevel ?? 85.0; // Default to 85% if unavailable
    } catch (e) {
      debugPrint('Failed to get battery level: $e');
      return 85.0; // Mock value for testing
    }
  }

  /// Test database query performance
  static Future<Map<String, dynamic>> measureDatabasePerformance({
    required Future<dynamic> Function() query,
    required String queryName,
    int iterations = 1,
  }) async {
    final executionTimes = <int>[];
    final results = <dynamic>[];
    
    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      
      try {
        final result = await query();
        results.add(result);
      } catch (e) {
        debugPrint('Query failed on iteration $i: $e');
        results.add(null);
      }
      
      stopwatch.stop();
      executionTimes.add(stopwatch.elapsedMilliseconds);
    }
    
    final avgTime = executionTimes.reduce((a, b) => a + b) / executionTimes.length;
    final minTime = executionTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = executionTimes.reduce((a, b) => a > b ? a : b);
    final successCount = results.where((r) => r != null).length;
    
    return {
      'queryName': queryName,
      'iterations': iterations,
      'averageTime': avgTime,
      'minTime': minTime,
      'maxTime': maxTime,
      'successRate': successCount / iterations,
      'executionTimes': executionTimes,
    };
  }

  /// Test real-time subscription performance
  static Future<Map<String, dynamic>> measureSubscriptionPerformance({
    required Future<void> Function() setupSubscription,
    required Future<void> Function() teardownSubscription,
    required Duration testDuration,
    required Stream<dynamic> dataStream,
  }) async {
    final startTime = DateTime.now();
    final receivedEvents = <DateTime>[];
    
    // Setup subscription
    final setupStopwatch = Stopwatch()..start();
    await setupSubscription();
    setupStopwatch.stop();
    
    // Listen to events
    final subscription = dataStream.listen((event) {
      receivedEvents.add(DateTime.now());
    });
    
    // Wait for test duration
    await Future.delayed(testDuration);
    
    // Teardown subscription
    final teardownStopwatch = Stopwatch()..start();
    await subscription.cancel();
    await teardownSubscription();
    teardownStopwatch.stop();
    
    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);
    
    // Calculate event rate
    final eventRate = receivedEvents.length / totalDuration.inSeconds;
    
    // Calculate latency (time between consecutive events)
    final latencies = <int>[];
    for (int i = 1; i < receivedEvents.length; i++) {
      final latency = receivedEvents[i].difference(receivedEvents[i - 1]).inMilliseconds;
      latencies.add(latency);
    }
    
    final avgLatency = latencies.isNotEmpty 
        ? latencies.reduce((a, b) => a + b) / latencies.length 
        : 0.0;
    
    return {
      'setupTime': setupStopwatch.elapsedMilliseconds,
      'teardownTime': teardownStopwatch.elapsedMilliseconds,
      'totalDuration': totalDuration.inSeconds,
      'eventsReceived': receivedEvents.length,
      'eventRate': eventRate, // events per second
      'averageLatency': avgLatency, // milliseconds
      'isPerformant': eventRate > 0.1 && avgLatency < 1000, // Basic performance criteria
    };
  }

  /// Test concurrent operation performance
  static Future<Map<String, dynamic>> measureConcurrentPerformance({
    required List<Future<dynamic> Function()> operations,
    required String testName,
  }) async {
    final startTime = DateTime.now();
    final results = <dynamic>[];
    final errors = <String>[];
    
    try {
      // Execute all operations concurrently
      final futures = operations.map((op) => op()).toList();
      final operationResults = await Future.wait(futures, eagerError: false);
      
      for (int i = 0; i < operationResults.length; i++) {
        try {
          results.add(operationResults[i]);
        } catch (e) {
          errors.add('Operation $i failed: $e');
          results.add(null);
        }
      }
    } catch (e) {
      errors.add('Concurrent execution failed: $e');
    }
    
    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);
    final successCount = results.where((r) => r != null).length;
    
    return {
      'testName': testName,
      'operationCount': operations.length,
      'totalDuration': totalDuration.inMilliseconds,
      'successCount': successCount,
      'errorCount': errors.length,
      'successRate': successCount / operations.length,
      'averageTimePerOperation': totalDuration.inMilliseconds / operations.length,
      'errors': errors,
      'isPerformant': successRate > 0.9 && totalDuration.inSeconds < 30,
    };
  }

  /// Android emulator testing utilities
  static class AndroidEmulatorTestHelpers {
    /// Check if running on Android emulator
    static Future<bool> isRunningOnEmulator() async {
      try {
        if (!Platform.isAndroid) return false;
        
        final result = await _performanceChannel.invokeMethod<bool>('isEmulator');
        return result ?? false;
      } catch (e) {
        debugPrint('Failed to check emulator status: $e');
        return false;
      }
    }

    /// Simulate hot restart for testing
    static Future<void> simulateHotRestart() async {
      try {
        await _performanceChannel.invokeMethod('simulateHotRestart');
        // Wait for restart to complete
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Failed to simulate hot restart: $e');
      }
    }

    /// Get emulator performance metrics
    static Future<Map<String, dynamic>> getEmulatorMetrics() async {
      try {
        final metrics = await _performanceChannel.invokeMethod<Map>('getEmulatorMetrics');
        return Map<String, dynamic>.from(metrics ?? {});
      } catch (e) {
        debugPrint('Failed to get emulator metrics: $e');
        return {
          'cpuUsage': 0.0,
          'memoryUsage': 0.0,
          'diskUsage': 0.0,
          'networkLatency': 0.0,
        };
      }
    }

    /// Test with different emulator configurations
    static Future<Map<String, dynamic>> testWithEmulatorConfig({
      required String configName,
      required Future<dynamic> Function() testOperation,
    }) async {
      final startTime = DateTime.now();
      final startMetrics = await getEmulatorMetrics();
      
      dynamic result;
      String? error;
      
      try {
        result = await testOperation();
      } catch (e) {
        error = e.toString();
      }
      
      final endTime = DateTime.now();
      final endMetrics = await getEmulatorMetrics();
      final duration = endTime.difference(startTime);
      
      return {
        'configName': configName,
        'duration': duration.inMilliseconds,
        'success': error == null,
        'error': error,
        'result': result,
        'startMetrics': startMetrics,
        'endMetrics': endMetrics,
        'cpuDelta': (endMetrics['cpuUsage'] ?? 0.0) - (startMetrics['cpuUsage'] ?? 0.0),
        'memoryDelta': (endMetrics['memoryUsage'] ?? 0.0) - (startMetrics['memoryUsage'] ?? 0.0),
      };
    }
  }

  /// Performance assertion helpers
  static void assertPerformanceThreshold({
    required int actualTime,
    required int thresholdMs,
    required String operationName,
  }) {
    expect(
      actualTime,
      lessThan(thresholdMs),
      reason: '$operationName took ${actualTime}ms, expected less than ${thresholdMs}ms',
    );
  }

  static void assertMemoryUsage({
    required int actualMemory,
    required int maxMemoryMB,
    required String operationName,
  }) {
    final actualMB = actualMemory / (1024 * 1024);
    expect(
      actualMB,
      lessThan(maxMemoryMB),
      reason: '$operationName used ${actualMB.toStringAsFixed(2)}MB, expected less than ${maxMemoryMB}MB',
    );
  }

  static void assertBatteryOptimization({
    required double drainRate,
    required double maxDrainRate,
    required String operationName,
  }) {
    expect(
      drainRate,
      lessThan(maxDrainRate),
      reason: '$operationName drained ${drainRate.toStringAsFixed(2)}%/min, expected less than ${maxDrainRate}%/min',
    );
  }

  /// Generate performance report
  static Map<String, dynamic> generatePerformanceReport({
    required List<Map<String, dynamic>> testResults,
    required String testSuiteName,
  }) {
    final totalTests = testResults.length;
    final passedTests = testResults.where((r) => r['success'] == true).length;
    final failedTests = totalTests - passedTests;
    
    final executionTimes = testResults
        .map((r) => r['duration'] as int? ?? 0)
        .where((t) => t > 0)
        .toList();
    
    final avgExecutionTime = executionTimes.isNotEmpty
        ? executionTimes.reduce((a, b) => a + b) / executionTimes.length
        : 0.0;
    
    final maxExecutionTime = executionTimes.isNotEmpty
        ? executionTimes.reduce((a, b) => a > b ? a : b)
        : 0;
    
    return {
      'testSuiteName': testSuiteName,
      'timestamp': DateTime.now().toIso8601String(),
      'totalTests': totalTests,
      'passedTests': passedTests,
      'failedTests': failedTests,
      'successRate': passedTests / totalTests,
      'averageExecutionTime': avgExecutionTime,
      'maxExecutionTime': maxExecutionTime,
      'testResults': testResults,
      'summary': {
        'performance': passedTests / totalTests > 0.9 ? 'GOOD' : 'NEEDS_IMPROVEMENT',
        'recommendations': _generateRecommendations(testResults),
      },
    };
  }

  static List<String> _generateRecommendations(List<Map<String, dynamic>> testResults) {
    final recommendations = <String>[];
    
    final slowTests = testResults.where((r) => (r['duration'] as int? ?? 0) > 5000).toList();
    if (slowTests.isNotEmpty) {
      recommendations.add('Optimize slow operations: ${slowTests.map((t) => t['testName']).join(', ')}');
    }
    
    final failedTests = testResults.where((r) => r['success'] != true).toList();
    if (failedTests.isNotEmpty) {
      recommendations.add('Fix failing tests: ${failedTests.map((t) => t['testName']).join(', ')}');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is within acceptable thresholds');
    }
    
    return recommendations;
  }
}
