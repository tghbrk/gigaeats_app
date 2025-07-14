import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'template_test_execution.dart';
import 'template_debug_logger.dart';
import 'debug_config.dart';

/// Test runner widget for template-only workflow testing
class TemplateTestRunner extends StatefulWidget {
  const TemplateTestRunner({super.key});

  @override
  State<TemplateTestRunner> createState() => _TemplateTestRunnerState();
}

class _TemplateTestRunnerState extends State<TemplateTestRunner> {
  bool _isRunning = false;
  String _status = 'Ready to run tests';
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(
          child: Text('Test runner only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Test Runner'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isRunning ? Icons.play_circle : Icons.check_circle,
                          color: _isRunning 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Test Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isRunning) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runComprehensiveTests,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run All Tests'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runQuickTests,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Quick Test'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Test Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildConfigItem('UI Logging', TemplateDebugConfig.enableUILogging),
                    _buildConfigItem('State Logging', TemplateDebugConfig.enableStateLogging),
                    _buildConfigItem('Database Logging', TemplateDebugConfig.enableDatabaseLogging),
                    _buildConfigItem('Performance Logging', TemplateDebugConfig.enablePerformanceLogging),
                    _buildConfigItem('Cache Logging', TemplateDebugConfig.enableCacheLogging),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Logs Section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.terminal,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Logs',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${_logs.length} entries',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      Expanded(
                        child: _logs.isEmpty
                            ? const Center(
                                child: Text('No logs yet. Run tests to see output.'),
                              )
                            : ListView.builder(
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      log,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: enabled 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _runComprehensiveTests() async {
    setState(() {
      _isRunning = true;
      _status = 'Running comprehensive test suite...';
      _logs.clear();
    });

    _addLog('🧪 Starting comprehensive template-only workflow tests');
    _addLog('📱 Platform: Android Emulator (emulator-5554)');
    _addLog('🔧 Debug Mode: ${kDebugMode ? "Enabled" : "Disabled"}');
    _addLog('⏰ Started at: ${DateTime.now().toIso8601String()}');
    _addLog('');

    try {
      // Execute comprehensive tests
      await TemplateTestExecution.executeComprehensiveTests();
      
      // Get results
      final results = TemplateTestExecution.getTestResults();
      final passed = results.where((r) => r.passed).length;
      final total = results.length;
      
      _addLog('');
      _addLog('📊 TEST RESULTS SUMMARY:');
      _addLog('   Total Tests: $total');
      _addLog('   Passed: $passed');
      _addLog('   Failed: ${total - passed}');
      _addLog('   Success Rate: ${(passed / total * 100).toStringAsFixed(1)}%');
      _addLog('');
      
      for (final result in results) {
        final status = result.passed ? '✅' : '❌';
        final duration = result.duration?.inMilliseconds ?? 0;
        _addLog('$status ${result.scenario.id}: ${result.scenario.title} (${duration}ms)');
        if (!result.passed && result.errors.isNotEmpty) {
          for (final error in result.errors) {
            _addLog('   Error: $error');
          }
        }
      }
      
      setState(() {
        _status = 'Tests completed: $passed/$total passed';
      });
      
    } catch (e) {
      _addLog('❌ Test execution failed: $e');
      setState(() {
        _status = 'Test execution failed';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
      _addLog('');
      _addLog('⏰ Completed at: ${DateTime.now().toIso8601String()}');
    }
  }

  Future<void> _runQuickTests() async {
    setState(() {
      _isRunning = true;
      _status = 'Running quick tests...';
      _logs.clear();
    });

    _addLog('⚡ Starting quick template tests');
    _addLog('📱 Platform: Android Emulator (emulator-5554)');
    _addLog('');

    try {
      // Quick test of debug logging
      TemplateDebugLogger.logInfo(
        operation: 'quick_test',
        message: 'Testing debug logging functionality',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': 'android_emulator',
        },
      );
      
      _addLog('✅ Debug logging test passed');
      
      // Quick test of template selection logging
      TemplateDebugLogger.logTemplateSelection(
        templateId: 'quick-test-template',
        templateName: 'Quick Test Template',
        menuItemId: 'quick-test-item',
        action: 'selected',
        metadata: {
          'testType': 'quick',
          'category': 'Test',
        },
      );
      
      _addLog('✅ Template selection logging test passed');
      
      // Quick test of UI interaction logging
      TemplateDebugLogger.logUIInteraction(
        component: 'TemplateTestRunner',
        action: 'quick_test',
        target: 'test_button',
        context: {
          'testMode': 'quick',
        },
      );
      
      _addLog('✅ UI interaction logging test passed');
      
      setState(() {
        _status = 'Quick tests completed successfully';
      });
      
    } catch (e) {
      _addLog('❌ Quick test failed: $e');
      setState(() {
        _status = 'Quick tests failed';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
      _addLog('');
      _addLog('⏰ Quick test completed at: ${DateTime.now().toIso8601String()}');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _status = 'Logs cleared - ready to run tests';
    });
    
    // Clear debug metrics
    TemplateDebugMetrics.clearMetrics();
    TemplateTestExecution.clearTestResults();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)} $message');
    });
    
    // Also print to debug console
    if (kDebugMode) {
      debugPrint('🧪 [TEST-RUNNER] $message');
    }
  }
}

/// Helper function to show test runner
void showTemplateTestRunner(BuildContext context) {
  if (!kDebugMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test runner only available in debug mode'),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const TemplateTestRunner(),
    ),
  );
}
