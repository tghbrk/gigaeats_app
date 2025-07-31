import 'dart:io';

/// Complete Test Suite Execution Script for Driver Bank Withdrawal System
/// 
/// This script orchestrates the execution of all test suites in the correct order,
/// generates comprehensive reports, and provides a single entry point for complete
/// system validation.
/// 
/// Usage: dart test/scripts/run_complete_withdrawal_test_suite.dart [--verbose] [--skip-android]
class CompleteWithdrawalTestSuiteRunner {
  final bool verbose;
  final bool skipAndroid;
  final Map<String, TestResult> testResults = {};
  final List<String> executionLog = [];

  CompleteWithdrawalTestSuiteRunner({
    this.verbose = false,
    this.skipAndroid = false,
  });

  /// Run the complete test suite
  Future<void> runCompleteTestSuite() async {
    final startTime = DateTime.now();
    
    print('🚀 Starting Complete Driver Bank Withdrawal System Test Suite');
    print('=' * 80);
    print('Verbose Mode: ${verbose ? 'ON' : 'OFF'}');
    print('Skip Android: ${skipAndroid ? 'YES' : 'NO'}');
    print('Start Time: ${startTime.toIso8601String()}');
    print('=' * 80);

    try {
      // Phase 1: Environment Validation
      await _runEnvironmentValidation();
      
      // Phase 2: Unit Tests
      await _runUnitTests();
      
      // Phase 3: Security Tests
      await _runSecurityTests();
      
      // Phase 4: Integration Tests
      await _runIntegrationTests();
      
      // Phase 5: Backend Validation
      await _runBackendValidation();
      
      // Phase 6: End-to-End Tests
      await _runEndToEndTests();
      
      // Phase 7: Android Emulator Tests (optional)
      if (!skipAndroid) {
        await _runAndroidEmulatorTests();
      }
      
      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime);
      
      // Generate comprehensive report
      await _generateComprehensiveReport(totalDuration);
      
    } catch (e) {
      print('❌ Test suite execution failed: $e');
      await _generateFailureReport(e);
      exit(1);
    }
  }

  /// Phase 1: Environment Validation
  Future<void> _runEnvironmentValidation() async {
    print('\n🔍 Phase 1: Environment Validation');
    print('-' * 50);
    
    try {
      // Check Flutter environment
      final flutterDoctorResult = await Process.run('flutter', ['doctor', '--machine']);
      final isFlutterReady = flutterDoctorResult.exitCode == 0;
      
      testResults['environment_flutter'] = TestResult(
        name: 'Flutter Environment',
        passed: isFlutterReady,
        duration: Duration.zero,
        details: isFlutterReady ? 'Flutter environment ready' : 'Flutter environment issues detected',
      );
      
      _logResult('Flutter Environment', isFlutterReady);

      // Check dependencies
      final pubGetResult = await Process.run('flutter', ['pub', 'get']);
      final dependenciesReady = pubGetResult.exitCode == 0;
      
      testResults['environment_dependencies'] = TestResult(
        name: 'Dependencies',
        passed: dependenciesReady,
        duration: Duration.zero,
        details: dependenciesReady ? 'Dependencies resolved' : 'Dependency issues detected',
      );
      
      _logResult('Dependencies', dependenciesReady);

      // Check Android emulator (if not skipping)
      if (!skipAndroid) {
        final adbResult = await Process.run('adb', ['devices']);
        final emulatorReady = adbResult.stdout.toString().contains('emulator-5554');
        
        testResults['environment_android'] = TestResult(
          name: 'Android Emulator',
          passed: emulatorReady,
          duration: Duration.zero,
          details: emulatorReady ? 'Android emulator ready' : 'Android emulator not detected',
        );
        
        _logResult('Android Emulator', emulatorReady);
      }

      print('✅ Environment validation completed');
      
    } catch (e) {
      print('❌ Environment validation failed: $e');
      testResults['environment_validation'] = TestResult(
        name: 'Environment Validation',
        passed: false,
        duration: Duration.zero,
        details: 'Error: $e',
      );
    }
  }

  /// Phase 2: Unit Tests
  Future<void> _runUnitTests() async {
    print('\n🧪 Phase 2: Unit Tests');
    print('-' * 50);
    
    final startTime = DateTime.now();
    
    try {
      final result = await Process.run('flutter', [
        'test',
        'test/features/drivers/security/driver_withdrawal_security_test.dart',
        if (verbose) '--verbose',
      ]);
      
      final duration = DateTime.now().difference(startTime);
      final passed = result.exitCode == 0;
      
      testResults['unit_tests'] = TestResult(
        name: 'Unit Tests',
        passed: passed,
        duration: duration,
        details: passed ? 'All unit tests passed' : 'Unit test failures detected',
        output: result.stdout.toString(),
        error: result.stderr.toString(),
      );
      
      _logResult('Unit Tests', passed, duration);
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      testResults['unit_tests'] = TestResult(
        name: 'Unit Tests',
        passed: false,
        duration: duration,
        details: 'Error: $e',
      );
      _logResult('Unit Tests', false, duration);
    }
  }

  /// Phase 3: Security Tests
  Future<void> _runSecurityTests() async {
    print('\n🔒 Phase 3: Security Tests');
    print('-' * 50);
    
    final startTime = DateTime.now();
    
    try {
      final result = await Process.run('flutter', [
        'test',
        'test/features/drivers/security/',
        if (verbose) '--verbose',
      ]);
      
      final duration = DateTime.now().difference(startTime);
      final passed = result.exitCode == 0;
      
      testResults['security_tests'] = TestResult(
        name: 'Security Tests',
        passed: passed,
        duration: duration,
        details: passed ? 'All security tests passed' : 'Security test failures detected',
        output: result.stdout.toString(),
        error: result.stderr.toString(),
      );
      
      _logResult('Security Tests', passed, duration);
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      testResults['security_tests'] = TestResult(
        name: 'Security Tests',
        passed: false,
        duration: duration,
        details: 'Error: $e',
      );
      _logResult('Security Tests', false, duration);
    }
  }

  /// Phase 4: Integration Tests
  Future<void> _runIntegrationTests() async {
    print('\n🔗 Phase 4: Integration Tests');
    print('-' * 50);
    
    final startTime = DateTime.now();
    
    try {
      final result = await Process.run('flutter', [
        'test',
        'test/integration/driver_bank_withdrawal_system_integration_test.dart',
        if (verbose) '--verbose',
      ]);
      
      final duration = DateTime.now().difference(startTime);
      final passed = result.exitCode == 0;
      
      testResults['integration_tests'] = TestResult(
        name: 'Integration Tests',
        passed: passed,
        duration: duration,
        details: passed ? 'All integration tests passed' : 'Integration test failures detected',
        output: result.stdout.toString(),
        error: result.stderr.toString(),
      );
      
      _logResult('Integration Tests', passed, duration);
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      testResults['integration_tests'] = TestResult(
        name: 'Integration Tests',
        passed: false,
        duration: duration,
        details: 'Error: $e',
      );
      _logResult('Integration Tests', false, duration);
    }
  }

  /// Phase 5: Backend Validation
  Future<void> _runBackendValidation() async {
    print('\n⚡ Phase 5: Backend Validation');
    print('-' * 50);
    
    final startTime = DateTime.now();
    
    try {
      final result = await Process.run('dart', [
        'test/integration/driver_withdrawal_backend_validation_script.dart',
      ]);
      
      final duration = DateTime.now().difference(startTime);
      final passed = result.exitCode == 0;
      
      testResults['backend_validation'] = TestResult(
        name: 'Backend Validation',
        passed: passed,
        duration: duration,
        details: passed ? 'Backend validation passed' : 'Backend validation failures detected',
        output: result.stdout.toString(),
        error: result.stderr.toString(),
      );
      
      _logResult('Backend Validation', passed, duration);
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      testResults['backend_validation'] = TestResult(
        name: 'Backend Validation',
        passed: false,
        duration: duration,
        details: 'Error: $e',
      );
      _logResult('Backend Validation', false, duration);
    }
  }

  /// Phase 6: End-to-End Tests
  Future<void> _runEndToEndTests() async {
    print('\n🎯 Phase 6: End-to-End Tests');
    print('-' * 50);
    
    final startTime = DateTime.now();
    
    try {
      final result = await Process.run('flutter', [
        'test',
        'test/integration/driver_withdrawal_end_to_end_test.dart',
        if (verbose) '--verbose',
      ]);
      
      final duration = DateTime.now().difference(startTime);
      final passed = result.exitCode == 0;
      
      testResults['end_to_end_tests'] = TestResult(
        name: 'End-to-End Tests',
        passed: passed,
        duration: duration,
        details: passed ? 'All E2E tests passed' : 'E2E test failures detected',
        output: result.stdout.toString(),
        error: result.stderr.toString(),
      );
      
      _logResult('End-to-End Tests', passed, duration);
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      testResults['end_to_end_tests'] = TestResult(
        name: 'End-to-End Tests',
        passed: false,
        duration: duration,
        details: 'Error: $e',
      );
      _logResult('End-to-End Tests', false, duration);
    }
  }

  /// Phase 7: Android Emulator Tests
  Future<void> _runAndroidEmulatorTests() async {
    print('\n📱 Phase 7: Android Emulator Tests');
    print('-' * 50);
    
    final startTime = DateTime.now();
    
    try {
      final result = await Process.run('dart', [
        'test/scripts/driver_bank_withdrawal_android_emulator_test.dart',
        if (verbose) '--verbose',
      ]);
      
      final duration = DateTime.now().difference(startTime);
      final passed = result.exitCode == 0;
      
      testResults['android_emulator_tests'] = TestResult(
        name: 'Android Emulator Tests',
        passed: passed,
        duration: duration,
        details: passed ? 'Android emulator tests passed' : 'Android emulator test failures detected',
        output: result.stdout.toString(),
        error: result.stderr.toString(),
      );
      
      _logResult('Android Emulator Tests', passed, duration);
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      testResults['android_emulator_tests'] = TestResult(
        name: 'Android Emulator Tests',
        passed: false,
        duration: duration,
        details: 'Error: $e',
      );
      _logResult('Android Emulator Tests', false, duration);
    }
  }

  /// Generate comprehensive test report
  Future<void> _generateComprehensiveReport(Duration totalDuration) async {
    print('\n📊 Generating Comprehensive Test Report');
    print('=' * 80);

    final totalTests = testResults.length;
    final passedTests = testResults.values.where((result) => result.passed).length;
    final failedTests = totalTests - passedTests;
    final successRate = totalTests > 0 ? (passedTests / totalTests * 100).toStringAsFixed(1) : '0.0';

    print('🎯 Test Execution Summary');
    print('-' * 40);
    print('Total Test Suites: $totalTests');
    print('Passed: $passedTests');
    print('Failed: $failedTests');
    print('Success Rate: $successRate%');
    print('Total Execution Time: ${totalDuration.inMinutes}m ${totalDuration.inSeconds % 60}s');

    print('\n📋 Detailed Test Results');
    print('-' * 40);
    testResults.forEach((key, result) {
      final status = result.passed ? '✅ PASS' : '❌ FAIL';
      final duration = '${result.duration.inSeconds}s';
      print('$status ${result.name} ($duration): ${result.details}');
    });

    print('\n🎉 Test Suite Completion');
    print('=' * 80);
    
    if (failedTests == 0) {
      print('🎊 All test suites passed! Driver Bank Withdrawal System is ready for production.');
    } else {
      print('⚠️ $failedTests test suite(s) failed. Please review and fix issues before deployment.');
    }

    // Save comprehensive report
    await _saveComprehensiveReport(totalDuration, totalTests, passedTests, failedTests, successRate);
  }

  /// Save comprehensive report to file
  Future<void> _saveComprehensiveReport(Duration totalDuration, int totalTests, int passedTests, int failedTests, String successRate) async {
    try {
      final reportContent = StringBuffer();
      reportContent.writeln('# Driver Bank Withdrawal System - Complete Test Suite Report');
      reportContent.writeln('Generated: ${DateTime.now().toIso8601String()}');
      reportContent.writeln('');
      reportContent.writeln('## Test Execution Summary');
      reportContent.writeln('- Total Test Suites: $totalTests');
      reportContent.writeln('- Passed: $passedTests');
      reportContent.writeln('- Failed: $failedTests');
      reportContent.writeln('- Success Rate: $successRate%');
      reportContent.writeln('- Total Execution Time: ${totalDuration.inMinutes}m ${totalDuration.inSeconds % 60}s');
      reportContent.writeln('');
      reportContent.writeln('## Detailed Test Results');
      testResults.forEach((key, result) {
        final status = result.passed ? 'PASS' : 'FAIL';
        final duration = '${result.duration.inSeconds}s';
        reportContent.writeln('- [$status] ${result.name} ($duration): ${result.details}');
      });
      reportContent.writeln('');
      reportContent.writeln('## Execution Log');
      for (final logEntry in executionLog) {
        reportContent.writeln('- $logEntry');
      }

      final reportFile = File('test_reports/complete_withdrawal_test_suite_report.md');
      await reportFile.parent.create(recursive: true);
      await reportFile.writeAsString(reportContent.toString());
      
      print('📄 Comprehensive test report saved to: ${reportFile.path}');
    } catch (e) {
      print('❌ Failed to save comprehensive test report: $e');
    }
  }

  /// Generate failure report
  Future<void> _generateFailureReport(dynamic error) async {
    final reportContent = StringBuffer();
    reportContent.writeln('# Driver Bank Withdrawal System - Test Suite Failure Report');
    reportContent.writeln('Generated: ${DateTime.now().toIso8601String()}');
    reportContent.writeln('');
    reportContent.writeln('## Failure Summary');
    reportContent.writeln('Test suite execution failed with error: $error');
    reportContent.writeln('');
    reportContent.writeln('## Completed Tests');
    testResults.forEach((key, result) {
      final status = result.passed ? 'PASS' : 'FAIL';
      reportContent.writeln('- [$status] ${result.name}: ${result.details}');
    });

    final reportFile = File('test_reports/test_suite_failure_report.md');
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(reportContent.toString());
    
    print('📄 Failure report saved to: ${reportFile.path}');
  }

  /// Log test result
  void _logResult(String testName, bool passed, [Duration? duration]) {
    final status = passed ? '✅' : '❌';
    final durationStr = duration != null ? ' (${duration.inSeconds}s)' : '';
    final logEntry = '$status $testName$durationStr';
    print(logEntry);
    executionLog.add(logEntry);
  }
}

/// Test result model
class TestResult {
  final String name;
  final bool passed;
  final Duration duration;
  final String details;
  final String? output;
  final String? error;

  TestResult({
    required this.name,
    required this.passed,
    required this.duration,
    required this.details,
    this.output,
    this.error,
  });
}

/// Main entry point
Future<void> main(List<String> args) async {
  final verbose = args.contains('--verbose');
  final skipAndroid = args.contains('--skip-android');
  
  final testRunner = CompleteWithdrawalTestSuiteRunner(
    verbose: verbose,
    skipAndroid: skipAndroid,
  );
  
  await testRunner.runCompleteTestSuite();
}
