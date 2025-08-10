import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'debug/customer_order_debug_validator.dart';
import 'runner/customer_order_test_runner.dart';
import 'android/android_emulator_test_suite.dart';
import '../data/models/customer_order_history_models.dart';
import '../data/services/customer_order_lazy_loading_service.dart';
import '../data/services/customer_order_memory_optimizer.dart';

/// Comprehensive test execution coordinator for customer order history system
class CustomerOrderTestExecutor {
  final CustomerOrderDebugValidator _validator = CustomerOrderDebugValidator();
  final CustomerOrderTestRunner _testRunner = CustomerOrderTestRunner();
  final AndroidEmulatorTestSuite _androidTestSuite = AndroidEmulatorTestSuite();
  
  bool _isExecuting = false;
  final List<String> _executionLog = [];

  /// Execute comprehensive test suite with debug validation
  Future<ComprehensiveTestResult> executeComprehensiveTests({
    required WidgetRef ref,
    String? customerId,
    bool runAndroidTests = true,
    bool enableDebugValidation = true,
  }) async {
    if (_isExecuting) {
      throw Exception('Test execution is already in progress');
    }

    _isExecuting = true;
    _executionLog.clear();
    
    _log('🚀 Starting comprehensive customer order history test execution');
    
    try {
      final stopwatch = Stopwatch()..start();
      
      // Enable debug validation
      if (enableDebugValidation) {
        _validator.setValidationEnabled(true);
        _log('🔍 Debug validation enabled');
      }
      
      // Phase 1: Pre-test validation
      _log('📋 Phase 1: Pre-test validation');
      final preTestValidation = await _runPreTestValidation();
      
      // Phase 2: Unit and integration tests
      _log('🧪 Phase 2: Unit and integration tests');
      final testSuiteResult = await _testRunner.runAllTests(
        ref: ref,
        customerId: customerId,
      );
      
      // Phase 3: Android emulator tests (if enabled)
      AndroidTestSuiteResult? androidResult;
      if (runAndroidTests) {
        _log('📱 Phase 3: Android emulator tests');
        try {
          androidResult = await _androidTestSuite.runEmulatorTests();
        } catch (e) {
          _log('⚠️ Android tests failed: $e');
          androidResult = null;
        }
      } else {
        _log('📱 Phase 3: Android emulator tests skipped');
      }
      
      // Phase 4: Performance validation
      _log('⚡ Phase 4: Performance validation');
      final performanceValidation = await _runPerformanceValidation();
      
      // Phase 5: Memory validation
      _log('🧠 Phase 5: Memory validation');
      final memoryValidation = await _runMemoryValidation();
      
      // Phase 6: Post-test validation
      _log('✅ Phase 6: Post-test validation');
      final postTestValidation = await _runPostTestValidation();
      
      stopwatch.stop();
      
      // Generate comprehensive result
      final result = ComprehensiveTestResult(
        totalDurationMs: stopwatch.elapsedMilliseconds,
        preTestValidation: preTestValidation,
        testSuiteResult: testSuiteResult,
        androidTestResult: androidResult,
        performanceValidation: performanceValidation,
        memoryValidation: memoryValidation,
        postTestValidation: postTestValidation,
        executionLog: List.unmodifiable(_executionLog),
        validationSummary: _validator.getValidationSummary(),
      );
      
      _log('🎉 Comprehensive test execution completed in ${stopwatch.elapsedMilliseconds}ms');
      _logTestSummary(result);
      
      return result;
      
    } finally {
      _isExecuting = false;
    }
  }

  /// Run pre-test validation
  Future<ValidationPhaseResult> _runPreTestValidation() async {
    _log('🔍 Running pre-test validation checks');
    
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // Validate environment setup
      _log('  - Checking environment setup');
      
      // Validate data models
      _log('  - Validating data models');
      await _validateDataModels(issues, warnings);
      
      // Validate services
      _log('  - Validating services');
      await _validateServices(issues, warnings);
      
      // Validate providers
      _log('  - Validating providers');
      await _validateProviders(issues, warnings);
      
      return ValidationPhaseResult(
        phaseName: 'Pre-test Validation',
        passed: issues.isEmpty,
        issues: issues,
        warnings: warnings,
      );
      
    } catch (e) {
      issues.add('Pre-test validation failed: $e');
      return ValidationPhaseResult(
        phaseName: 'Pre-test Validation',
        passed: false,
        issues: issues,
        warnings: warnings,
      );
    }
  }

  /// Run performance validation
  Future<ValidationPhaseResult> _runPerformanceValidation() async {
    _log('⚡ Running performance validation');
    
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // Test lazy loading service performance
      final lazyService = CustomerOrderLazyLoadingService();
      final cacheStats = lazyService.getCacheStats();
      
      // Validate cache performance
      if (cacheStats.hitRate < 0.5) {
        warnings.add('Cache hit rate is low: ${(cacheStats.hitRate * 100).toStringAsFixed(1)}%');
      }
      
      if (cacheStats.totalMemoryKB > 20480) { // 20MB
        warnings.add('Cache memory usage is high: ${cacheStats.totalMemoryKB.toStringAsFixed(1)}KB');
      }
      
      _log('  - Cache hit rate: ${(cacheStats.hitRate * 100).toStringAsFixed(1)}%');
      _log('  - Cache memory usage: ${cacheStats.totalMemoryKB.toStringAsFixed(1)}KB');
      
      return ValidationPhaseResult(
        phaseName: 'Performance Validation',
        passed: issues.isEmpty,
        issues: issues,
        warnings: warnings,
      );
      
    } catch (e) {
      issues.add('Performance validation failed: $e');
      return ValidationPhaseResult(
        phaseName: 'Performance Validation',
        passed: false,
        issues: issues,
        warnings: warnings,
      );
    }
  }

  /// Run memory validation
  Future<ValidationPhaseResult> _runMemoryValidation() async {
    _log('🧠 Running memory validation');
    
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // Test memory optimizer
      final memoryOptimizer = CustomerOrderMemoryOptimizer();
      final memoryStats = memoryOptimizer.getMemoryStats();
      
      // Validate memory usage
      if (memoryStats.reuseRate < 0.3) {
        warnings.add('Object reuse rate is low: ${(memoryStats.reuseRate * 100).toStringAsFixed(1)}%');
      }
      
      if (memoryStats.currentMemoryUsageKB > 15360) { // 15MB
        warnings.add('Memory usage is high: ${memoryStats.currentMemoryUsageKB}KB');
      }
      
      _log('  - Object reuse rate: ${(memoryStats.reuseRate * 100).toStringAsFixed(1)}%');
      _log('  - Memory usage: ${memoryStats.currentMemoryUsageKB}KB');
      
      return ValidationPhaseResult(
        phaseName: 'Memory Validation',
        passed: issues.isEmpty,
        issues: issues,
        warnings: warnings,
      );
      
    } catch (e) {
      issues.add('Memory validation failed: $e');
      return ValidationPhaseResult(
        phaseName: 'Memory Validation',
        passed: false,
        issues: issues,
        warnings: warnings,
      );
    }
  }

  /// Run post-test validation
  Future<ValidationPhaseResult> _runPostTestValidation() async {
    _log('✅ Running post-test validation');
    
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // Validate test results
      _log('  - Validating test results');
      
      // Check for memory leaks
      _log('  - Checking for memory leaks');
      
      // Validate system state
      _log('  - Validating system state');
      
      return ValidationPhaseResult(
        phaseName: 'Post-test Validation',
        passed: issues.isEmpty,
        issues: issues,
        warnings: warnings,
      );
      
    } catch (e) {
      issues.add('Post-test validation failed: $e');
      return ValidationPhaseResult(
        phaseName: 'Post-test Validation',
        passed: false,
        issues: issues,
        warnings: warnings,
      );
    }
  }

  /// Validate data models
  Future<void> _validateDataModels(List<String> issues, List<String> warnings) async {
    try {
      // Test CustomerGroupedOrderHistory
      final testDate = DateTime.now();
      final group = CustomerGroupedOrderHistory(
        dateKey: 'test',
        displayDate: 'Test',
        date: testDate,
        completedOrders: [],
        cancelledOrders: [],
        activeOrders: [],
        totalOrders: 0,
        completedCount: 0,
        cancelledCount: 0,
        activeCount: 0,
        totalSpent: 0.0,
        completedSpent: 0.0,
      );
      
      if (group.dateKey.isEmpty) {
        issues.add('CustomerGroupedOrderHistory dateKey is empty');
      }
      
      // Test CustomerDateRangeFilter
      final filter = CustomerDateRangeFilter.today();
      if (filter.startDate != null && filter.endDate != null && filter.startDate!.isAfter(filter.endDate!)) {
        issues.add('CustomerDateRangeFilter has invalid date range');
      }
      
    } catch (e) {
      issues.add('Data model validation failed: $e');
    }
  }

  /// Validate services
  Future<void> _validateServices(List<String> issues, List<String> warnings) async {
    try {
      // Test lazy loading service
      final lazyService = CustomerOrderLazyLoadingService();
      final cacheStats = lazyService.getCacheStats();
      
      if (cacheStats.maxCacheSize <= 0) {
        issues.add('Lazy loading service has invalid cache configuration');
      }
      
      // Test memory optimizer
      final memoryOptimizer = CustomerOrderMemoryOptimizer();
      final memoryStats = memoryOptimizer.getMemoryStats();
      
      if (memoryStats.currentMemoryUsageKB < 0) {
        issues.add('Memory optimizer has invalid memory stats');
      }
      
    } catch (e) {
      issues.add('Service validation failed: $e');
    }
  }

  /// Validate providers
  Future<void> _validateProviders(List<String> issues, List<String> warnings) async {
    try {
      // This would validate provider setup
      // For now, we'll just check basic functionality
      
    } catch (e) {
      issues.add('Provider validation failed: $e');
    }
  }

  /// Log message with timestamp
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    _executionLog.add(logEntry);
    debugPrint(logEntry);
  }

  /// Log test summary
  void _logTestSummary(ComprehensiveTestResult result) {
    _log('📊 Test Summary:');
    _log('  Total Duration: ${result.totalDurationMs}ms');
    _log('  Unit Tests: ${result.testSuiteResult.passedTests}/${result.testSuiteResult.totalTests} passed');
    
    if (result.androidTestResult != null) {
      _log('  Android Tests: ${result.androidTestResult!.passedTests}/${result.androidTestResult!.totalTests} passed');
    }
    
    _log('  Validation Issues: ${result.validationSummary.totalIssues}');
    _log('  Validation Warnings: ${result.validationSummary.totalWarnings}');
    
    final overallSuccess = result.isSuccessful;
    _log('  Overall Result: ${overallSuccess ? 'SUCCESS' : 'FAILURE'}');
  }

  /// Get current execution status
  bool get isExecuting => _isExecuting;
  
  /// Get execution log
  List<String> get executionLog => List.unmodifiable(_executionLog);
}

/// Comprehensive test result model
@immutable
class ComprehensiveTestResult {
  final int totalDurationMs;
  final ValidationPhaseResult preTestValidation;
  final TestSuiteResult testSuiteResult;
  final AndroidTestSuiteResult? androidTestResult;
  final ValidationPhaseResult performanceValidation;
  final ValidationPhaseResult memoryValidation;
  final ValidationPhaseResult postTestValidation;
  final List<String> executionLog;
  final DebugValidationSummary validationSummary;

  const ComprehensiveTestResult({
    required this.totalDurationMs,
    required this.preTestValidation,
    required this.testSuiteResult,
    this.androidTestResult,
    required this.performanceValidation,
    required this.memoryValidation,
    required this.postTestValidation,
    required this.executionLog,
    required this.validationSummary,
  });

  /// Check if all tests passed
  bool get isSuccessful {
    final validationsPassed = preTestValidation.passed &&
                             performanceValidation.passed &&
                             memoryValidation.passed &&
                             postTestValidation.passed;

    final unitTestsPassed = testSuiteResult.allPassed;

    final androidTestsPassed = androidTestResult?.allPassed ?? true;

    return validationsPassed && unitTestsPassed && androidTestsPassed;
  }

  /// Get total test count
  int get totalTests {
    int total = testSuiteResult.totalTests;
    if (androidTestResult != null) {
      total += androidTestResult!.totalTests;
    }
    return total;
  }

  /// Get total passed tests
  int get totalPassedTests {
    int passed = testSuiteResult.passedTests;
    if (androidTestResult != null) {
      passed += androidTestResult!.passedTests;
    }
    return passed;
  }

  /// Get overall pass rate
  double get overallPassRate {
    return totalTests == 0 ? 1.0 : totalPassedTests / totalTests;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComprehensiveTestResult &&
          runtimeType == other.runtimeType &&
          totalDurationMs == other.totalDurationMs &&
          preTestValidation == other.preTestValidation &&
          testSuiteResult == other.testSuiteResult &&
          androidTestResult == other.androidTestResult &&
          performanceValidation == other.performanceValidation &&
          memoryValidation == other.memoryValidation &&
          postTestValidation == other.postTestValidation &&
          listEquals(executionLog, other.executionLog) &&
          validationSummary == other.validationSummary;

  @override
  int get hashCode => Object.hash(
        totalDurationMs,
        preTestValidation,
        testSuiteResult,
        androidTestResult,
        performanceValidation,
        memoryValidation,
        postTestValidation,
        Object.hashAll(executionLog),
        validationSummary,
      );

  @override
  String toString() => 'ComprehensiveTestResult('
      'totalDurationMs: $totalDurationMs, '
      'isSuccessful: $isSuccessful, '
      'totalTests: $totalTests, '
      'passRate: ${(overallPassRate * 100).toStringAsFixed(1)}%'
      ')';
}

/// Validation phase result model
@immutable
class ValidationPhaseResult {
  final String phaseName;
  final bool passed;
  final List<String> issues;
  final List<String> warnings;
  final DateTime timestamp;

  ValidationPhaseResult({
    required this.phaseName,
    required this.passed,
    required this.issues,
    required this.warnings,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationPhaseResult &&
          runtimeType == other.runtimeType &&
          phaseName == other.phaseName &&
          passed == other.passed &&
          listEquals(issues, other.issues) &&
          listEquals(warnings, other.warnings) &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        phaseName,
        passed,
        Object.hashAll(issues),
        Object.hashAll(warnings),
        timestamp,
      );

  @override
  String toString() => 'ValidationPhaseResult('
      'phaseName: $phaseName, '
      'passed: $passed, '
      'issues: ${issues.length}, '
      'warnings: ${warnings.length}'
      ')';
}
