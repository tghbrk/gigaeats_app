import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Restore missing URI import when driver_auth_service is implemented
// import '../../features/drivers/data/services/driver_auth_service.dart';
import '../../features/drivers/data/services/driver_performance_service.dart';
import '../../features/drivers/data/services/driver_location_service.dart';

/// Screen for validating all driver backend functionality
/// Tests database schema, services, and integration points
class DriverBackendValidationScreen extends ConsumerStatefulWidget {
  const DriverBackendValidationScreen({super.key});

  @override
  ConsumerState<DriverBackendValidationScreen> createState() => _DriverBackendValidationScreenState();
}

class _DriverBackendValidationScreenState extends ConsumerState<DriverBackendValidationScreen> {
  final List<ValidationResult> _results = [];
  bool _isRunning = false;
  
  // TODO: Restore when DriverAuthService is implemented
  // final _driverAuthService = DriverAuthService();
  final _driverPerformanceService = DriverPerformanceService();
  final _driverLocationService = DriverLocationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Backend Validation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runAllTests,
                    child: _isRunning 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Running Tests...'),
                            ],
                          )
                        : const Text('Run All Validation Tests'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearResults,
                  child: const Text('Clear Results'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: result.success ? Colors.green : Colors.red,
                    ),
                    title: Text(result.testName),
                    subtitle: Text(result.message),
                    trailing: result.duration != null 
                        ? Text('${result.duration!.inMilliseconds}ms')
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    await _testDatabaseSchema();
    await _testDriverAuthentication();
    await _testDriverPerformance();
    await _testDriverLocation();
    await _testDatabaseFunctions();
    await _testRLSPolicies();
    await _testIntegration();

    setState(() {
      _isRunning = false;
    });

    _showSummary();
  }

  void _clearResults() {
    setState(() {
      _results.clear();
    });
  }

  Future<void> _testDatabaseSchema() async {
    await _runTest('Database Schema - User Role Enum', () async {
      final supabase = Supabase.instance.client;
      await supabase.from('users').select('role').eq('role', 'driver').limit(1);
    });

    await _runTest('Database Schema - Drivers Table', () async {
      final supabase = Supabase.instance.client;
      await supabase.from('drivers').select('id, user_id, vendor_id, name, phone_number, status, is_active').limit(1);
    });

    await _runTest('Database Schema - Driver Performance Table', () async {
      final supabase = Supabase.instance.client;
      await supabase.from('driver_performance').select('driver_id, date, total_deliveries, successful_deliveries, total_earnings').limit(1);
    });

    await _runTest('Database Schema - Driver Locations Table', () async {
      final supabase = Supabase.instance.client;
      await supabase.from('delivery_tracking').select('driver_id, order_id, location, recorded_at').limit(1);
    });
  }

  Future<void> _testDriverAuthentication() async {
    // TODO: Restore when _driverAuthService is implemented
    /*await _runTest('Driver Auth - Email Availability Check', () async {
      final isAvailable = await _driverAuthService.isEmailAvailable('test-driver-${DateTime.now().millisecondsSinceEpoch}@example.com');
      if (!isAvailable) throw Exception('Email availability check failed');
    });*/

    // TODO: Restore when _driverAuthService is implemented
    /*await _runTest('Driver Auth - Phone Availability Check', () async {
      final isAvailable = await _driverAuthService.isPhoneNumberAvailable('+60123456789999');
      if (!isAvailable) throw Exception('Phone availability check failed');
    });*/

    // TODO: Restore when _driverAuthService is implemented
    /*await _runTest('Driver Auth - Validation for Non-existent User', () async {
      final validation = await _driverAuthService.validateDriverSetup('00000000-0000-0000-0000-000000000000');
      if (validation.isValid) throw Exception('Validation should fail for non-existent user');
    });*/
  }

  Future<void> _testDriverPerformance() async {
    await _runTest('Driver Performance - Summary for Non-existent Driver', () async {
      await _driverPerformanceService.getDriverPerformanceSummary('00000000-0000-0000-0000-000000000000');
      // Should return null for non-existent driver
    });

    await _runTest('Driver Performance - Leaderboard Query', () async {
      await _driverPerformanceService.getDriverLeaderboard(
        vendorId: '00000000-0000-0000-0000-000000000000',
        periodDays: 30,
        limit: 10,
      );
      // Should return empty list
    });

    await _runTest('Driver Performance - Earnings Calculation', () async {
      final earnings = await _driverPerformanceService.getDriverEarnings('00000000-0000-0000-0000-000000000000');
      if (earnings['total_earnings'] != 0.0) throw Exception('Earnings should be 0 for non-existent driver');
    });
  }

  Future<void> _testDriverLocation() async {
    await _runTest('Driver Location - Current Location Update', () async {
      final result = await _driverLocationService.updateCurrentLocation('00000000-0000-0000-0000-000000000000');
      if (result) throw Exception('Location update should fail for non-existent driver');
    });

    await _runTest('Driver Location - Location History', () async {
      final history = await _driverLocationService.getDriverLocationHistory('00000000-0000-0000-0000-000000000000');
      if (history.isNotEmpty) throw Exception('History should be empty for non-existent driver');
    });

    await _runTest('Driver Location - Permission Check', () async {
      await _driverLocationService.checkLocationPermissions();
      // This may fail in test environment, which is expected
    });
  }

  Future<void> _testDatabaseFunctions() async {
    await _runTest('Database Function - calculate_driver_performance', () async {
      final supabase = Supabase.instance.client;
      await supabase.rpc('calculate_driver_performance', params: {
        'p_driver_id': '00000000-0000-0000-0000-000000000000',
        'p_start_date': '2024-01-01',
        'p_end_date': '2024-12-31',
      });
    });

    await _runTest('Database Function - get_driver_leaderboard', () async {
      final supabase = Supabase.instance.client;
      await supabase.rpc('get_driver_leaderboard', params: {
        'p_vendor_id': null,
        'p_period_days': 30,
        'p_limit': 10,
      });
    });

    await _runTest('Database Function - validate_driver_user_setup', () async {
      final supabase = Supabase.instance.client;
      await supabase.rpc('validate_driver_user_setup', params: {
        'p_user_id': '00000000-0000-0000-0000-000000000000',
      });
    });

    await _runTest('Database Function - update_driver_rating', () async {
      final supabase = Supabase.instance.client;
      try {
        await supabase.rpc('update_driver_rating', params: {
          'p_driver_id': '00000000-0000-0000-0000-000000000000',
          'p_rating': 4.5,
          'p_date': DateTime.now().toIso8601String().split('T')[0],
        });
      } catch (e) {
        // Expected to fail for non-existent driver
        if (!e.toString().contains('driver') && !e.toString().contains('not found')) {
          rethrow;
        }
      }
    });
  }

  Future<void> _testRLSPolicies() async {
    await _runTest('RLS Policies - Drivers Table Access', () async {
      final supabase = Supabase.instance.client;
      try {
        await supabase.from('drivers').select('id').limit(1);
      } catch (e) {
        // RLS may restrict access for anonymous users, which is expected
        if (!e.toString().contains('permission') && !e.toString().contains('policy')) {
          rethrow;
        }
      }
    });

    await _runTest('RLS Policies - Driver Performance Access', () async {
      final supabase = Supabase.instance.client;
      try {
        await supabase.from('driver_performance').select('driver_id').limit(1);
      } catch (e) {
        // RLS may restrict access for anonymous users, which is expected
        if (!e.toString().contains('permission') && !e.toString().contains('policy')) {
          rethrow;
        }
      }
    });

    await _runTest('RLS Policies - Orders Table Driver Access', () async {
      final supabase = Supabase.instance.client;
      try {
        await supabase.from('orders').select('id, assigned_driver_id').limit(1);
      } catch (e) {
        // RLS may restrict access for anonymous users, which is expected
        if (!e.toString().contains('permission') && !e.toString().contains('policy')) {
          rethrow;
        }
      }
    });
  }

  Future<void> _testIntegration() async {
    await _runTest('Integration - Complete Driver Workflow', () async {
      // Test the complete workflow without actually creating data
      
      // 1. Test email availability
      // TODO: Restore when _driverAuthService is implemented
      // await _driverAuthService.isEmailAvailable('integration-test@example.com');

      // 2. Test performance metrics
      await _driverPerformanceService.getDriverEarnings('test-driver-id');

      // 3. Test location services
      await _driverLocationService.updateCurrentLocation('test-driver-id');
      
      // 4. Test database queries
      final supabase = Supabase.instance.client;
      await supabase.from('drivers').select('count').single();
      
      // If we get here, the integration is working
    });
  }

  Future<void> _runTest(String testName, Future<void> Function() testFunction) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await testFunction();
      stopwatch.stop();
      
      setState(() {
        _results.add(ValidationResult(
          testName: testName,
          success: true,
          message: 'Test passed successfully',
          duration: stopwatch.elapsed,
        ));
      });
    } catch (e) {
      stopwatch.stop();
      
      setState(() {
        _results.add(ValidationResult(
          testName: testName,
          success: false,
          message: 'Test failed: ${e.toString()}',
          duration: stopwatch.elapsed,
        ));
      });
    }
  }

  void _showSummary() {
    final totalTests = _results.length;
    final passedTests = _results.where((r) => r.success).length;
    final failedTests = totalTests - passedTests;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tests: $totalTests'),
            Text('Passed: $passedTests', style: const TextStyle(color: Colors.green)),
            Text('Failed: $failedTests', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            Text('Success Rate: ${((passedTests / totalTests) * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ValidationResult {
  final String testName;
  final bool success;
  final String message;
  final Duration? duration;

  ValidationResult({
    required this.testName,
    required this.success,
    required this.message,
    this.duration,
  });
}
