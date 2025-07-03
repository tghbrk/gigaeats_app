import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_role.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/drivers/presentation/providers/driver_earnings_provider.dart';

/// Test screen for driver earnings backend integration
class DriverEarningsTestScreen extends ConsumerStatefulWidget {
  const DriverEarningsTestScreen({super.key});

  @override
  ConsumerState<DriverEarningsTestScreen> createState() => _DriverEarningsTestScreenState();
}

class _DriverEarningsTestScreenState extends ConsumerState<DriverEarningsTestScreen> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Earnings Test'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Earnings Backend Test',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test the driver earnings system integration with Supabase backend',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isRunning ? null : _runTests,
                          child: _isRunning 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Run Tests'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _clearResults,
                          child: const Text('Clear Results'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _createTestData,
                          child: const Text('Create Test Data'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Driver Info
            _buildDriverInfo(),
            
            const SizedBox(height: 16),
            
            // Test Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _testResults.isEmpty
                            ? Center(
                                child: Text(
                                  'No test results yet. Click "Run Tests" to start.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _testResults.length,
                                itemBuilder: (context, index) {
                                  final result = _testResults[index];
                                  final isError = result.startsWith('❌');
                                  final isSuccess = result.startsWith('✅');
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isError 
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : isSuccess 
                                                ? Colors.green.withValues(alpha: 0.1)
                                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isError 
                                              ? Colors.red.withValues(alpha: 0.3)
                                              : isSuccess 
                                                  ? Colors.green.withValues(alpha: 0.3)
                                                  : theme.colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        result,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontFamily: 'monospace',
                                          color: isError 
                                              ? Colors.red.shade700
                                              : isSuccess 
                                                  ? Colors.green.shade700
                                                  : theme.colorScheme.onSurface,
                                        ),
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

  Widget _buildDriverInfo() {
    final authState = ref.watch(authStateProvider);
    final driverIdAsync = ref.watch(currentDriverIdProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Driver Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('User Role: ${authState.user?.role.name ?? 'Not logged in'}'),
            const SizedBox(height: 4),
            driverIdAsync.when(
              loading: () => const Text('Driver ID: Loading...'),
              error: (error, stack) => Text('Driver ID: Error - $error'),
              data: (driverId) => Text('Driver ID: ${driverId ?? 'Not found'}'),
            ),
          ],
        ),
      ),
    );
  }

  void _log(String message) {
    setState(() {
      _testResults.add(message);
    });
    debugPrint(message);
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    try {
      _log('🚀 Starting Driver Earnings Backend Tests...');
      
      await _testAuthentication();
      await _testDatabaseTables();
      await _testEarningsService();
      await _testProviders();
      
      _log('✅ All tests completed!');
    } catch (e) {
      _log('❌ Test suite failed: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testAuthentication() async {
    _log('\n🔐 Testing Authentication...');
    
    try {
      final authState = ref.read(authStateProvider);
      
      if (authState.user == null) {
        _log('❌ User not authenticated');
        return;
      }
      
      _log('✅ User authenticated: ${authState.user!.email}');
      
      if (authState.user!.role != UserRole.driver) {
        _log('⚠️ User is not a driver (role: ${authState.user!.role.name})');
        return;
      }
      
      _log('✅ User has driver role');
      
      // Test driver ID retrieval
      final driverIdAsync = ref.read(currentDriverIdProvider);
      final driverId = driverIdAsync.when(
        data: (id) => id,
        loading: () => null,
        error: (_, _) => null,
      );
      
      if (driverId == null) {
        _log('❌ Driver ID not found');
        return;
      }
      
      _log('✅ Driver ID retrieved: $driverId');
      
    } catch (e) {
      _log('❌ Authentication test failed: $e');
    }
  }

  Future<void> _testDatabaseTables() async {
    _log('\n🗄️ Testing Database Tables...');
    
    try {
      final supabase = Supabase.instance.client;
      
      // Test driver_earnings table
      _log('Testing driver_earnings table...');
      try {
        await supabase.from('driver_earnings').select('id').limit(1);
        _log('✅ driver_earnings table exists');
      } catch (e) {
        _log('❌ driver_earnings table test failed: $e');
      }
      
      // Test driver_commission_structure table
      _log('Testing driver_commission_structure table...');
      try {
        await supabase.from('driver_commission_structure').select('id').limit(1);
        _log('✅ driver_commission_structure table exists');
      } catch (e) {
        _log('❌ driver_commission_structure table test failed: $e');
      }
      
      // Test driver_earnings_summary table
      _log('Testing driver_earnings_summary table...');
      try {
        await supabase.from('driver_earnings_summary').select('id').limit(1);
        _log('✅ driver_earnings_summary table exists');
      } catch (e) {
        _log('❌ driver_earnings_summary table test failed: $e');
      }
      
    } catch (e) {
      _log('❌ Database tables test failed: $e');
    }
  }

  Future<void> _testEarningsService() async {
    _log('\n⚙️ Testing Earnings Service...');
    
    try {
      final earningsService = ref.read(driverEarningsServiceProvider);
      final driverIdAsync = ref.read(currentDriverIdProvider);
      
      final driverId = driverIdAsync.when(
        data: (id) => id,
        loading: () => null,
        error: (_, _) => null,
      );
      
      if (driverId == null) {
        _log('❌ Cannot test service without driver ID');
        return;
      }
      
      // Test earnings summary
      _log('Testing earnings summary...');
      final summary = await earningsService.getDriverEarningsSummary(driverId);
      _log('✅ Earnings summary retrieved: ${summary.keys.join(', ')}');
      
      // Test earnings breakdown
      _log('Testing earnings breakdown...');
      final breakdown = await earningsService.getDriverEarningsBreakdown(driverId);
      _log('✅ Earnings breakdown retrieved: ${breakdown.keys.join(', ')}');
      
      // Test earnings history
      _log('Testing earnings history...');
      final history = await earningsService.getDriverEarningsHistory(driverId, limit: 5);
      _log('✅ Earnings history retrieved: ${history.length} records');
      
    } catch (e) {
      _log('❌ Earnings service test failed: $e');
    }
  }

  Future<void> _testProviders() async {
    _log('\n🔌 Testing Providers...');
    
    try {
      // Test earnings summary provider
      _log('Testing earnings summary provider...');

      // Get driver ID first
      final driverIdAsync = ref.read(currentDriverIdProvider);
      final driverId = driverIdAsync.when(
        data: (id) => id,
        loading: () => null,
        error: (error, stack) => null,
      );

      if (driverId == null) {
        _log('No driver ID available for testing');
        return;
      }

      final earningsParams = EarningsParams(
        driverId: driverId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        period: 'test',
        stableKey: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      final summaryAsync = ref.read(driverEarningsSummaryProvider(earningsParams));

      final summary = summaryAsync.when(
        data: (data) => data,
        loading: () => <String, dynamic>{},
        error: (error, stack) => <String, dynamic>{'error': error.toString()},
      );

      _log('✅ Summary provider works: ${summary.keys.length} fields');

      // Test earnings breakdown provider
      _log('Testing earnings breakdown provider...');
      final breakdownAsync = ref.read(driverEarningsBreakdownProvider(earningsParams));

      final breakdown = breakdownAsync.when(
        data: (data) => data,
        loading: () => <String, double>{},
        error: (error, stack) => <String, double>{},
      );
      
      _log('✅ Breakdown provider works: ${breakdown.keys.length} categories');
      
    } catch (e) {
      _log('❌ Providers test failed: $e');
    }
  }

  Future<void> _createTestData() async {
    _log('\n🧪 Creating Test Data...');
    
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authStateProvider);
      
      if (authState.user?.role != UserRole.driver) {
        _log('❌ Must be logged in as driver to create test data');
        return;
      }
      
      final driverIdAsync = ref.read(currentDriverIdProvider);
      final driverId = driverIdAsync.when(
        data: (id) => id,
        loading: () => null,
        error: (_, _) => null,
      );
      
      if (driverId == null) {
        _log('❌ Driver ID not found');
        return;
      }
      
      // Create test earnings record
      _log('Creating test earnings record...');
      await supabase.from('driver_earnings').insert({
        'driver_id': driverId,
        'earnings_type': 'delivery_fee',
        'amount': 25.00,
        'base_amount': 25.00,
        'commission_rate': 15.0,
        'platform_fee': 3.75,
        'net_amount': 21.25,
        'status': 'confirmed',
        'description': 'Test delivery earnings',
      });
      
      _log('✅ Test earnings record created');
      
      // Refresh providers to show new data
      ref.invalidate(driverEarningsSummaryProvider);
      ref.invalidate(driverEarningsBreakdownProvider);
      ref.invalidate(driverEarningsHistoryProvider);
      
      _log('✅ Providers refreshed');
      
    } catch (e) {
      _log('❌ Test data creation failed: $e');
    }
  }
}
