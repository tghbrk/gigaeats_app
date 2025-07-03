import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/drivers/data/services/driver_dashboard_service.dart';
import '../../features/drivers/presentation/providers/driver_dashboard_provider.dart';
import '../../features/drivers/presentation/providers/driver_earnings_provider.dart';


/// Test screen to verify the driver dashboard fix
/// This screen tests the critical error that was occurring with user ID: 5af49a29-a845-4b70-a7ab-384ba2f93930
class DriverDashboardFixTestScreen extends ConsumerStatefulWidget {
  const DriverDashboardFixTestScreen({super.key});

  @override
  ConsumerState<DriverDashboardFixTestScreen> createState() => _DriverDashboardFixTestScreenState();
}

class _DriverDashboardFixTestScreenState extends ConsumerState<DriverDashboardFixTestScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DriverDashboardService _dashboardService = DriverDashboardService();
  
  String? _testResult;
  bool _isLoading = false;
  Color _resultColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard Fix Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Dashboard Critical Error Fix Test',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test verifies the fix for the critical error where driver dashboard failed to load due to missing driver records.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Test problematic user ID
            _buildTestSection(
              'Test Problematic User',
              'Test the specific user ID that was causing the error',
              () => _testProblematicUser(),
            ),
            
            const SizedBox(height: 16),
            
            // Test driver ID lookup
            _buildTestSection(
              'Test Driver ID Lookup',
              'Test the getDriverIdFromUserId method with auto-creation',
              () => _testDriverIdLookup(),
            ),
            
            const SizedBox(height: 16),
            
            // Test dashboard data loading
            _buildTestSection(
              'Test Dashboard Data',
              'Test loading dashboard data for the fixed user',
              () => _testDashboardData(),
            ),
            
            const SizedBox(height: 16),
            
            // Test provider integration
            _buildTestSection(
              'Test Provider Integration',
              'Test the Riverpod providers with the fixed data',
              () => _testProviderIntegration(),
            ),
            
            const SizedBox(height: 24),
            
            // Results section
            if (_testResult != null) ...[
              const Text(
                'Test Results:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _resultColor.withValues(alpha: 0.1),
                  border: Border.all(color: _resultColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _resultColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(String title, String description, VoidCallback onTest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : onTest,
              child: Text('Run Test'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testProblematicUser() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      const problematicUserId = '5af49a29-a845-4b70-a7ab-384ba2f93930';
      
      // Test 1: Check if user exists
      final userResponse = await _supabase
          .from('users')
          .select('id, email, role')
          .eq('id', problematicUserId)
          .single();
      
      // Test 2: Check if driver record exists
      final driverResponse = await _supabase
          .from('drivers')
          .select('id, user_id, name')
          .eq('user_id', problematicUserId)
          .single();
      
      setState(() {
        _testResult = '''✅ PROBLEMATIC USER TEST PASSED
User ID: $problematicUserId
Email: ${userResponse['email']}
Role: ${userResponse['role']}
Driver ID: ${driverResponse['id']}
Driver Name: ${driverResponse['name']}

The user now has a valid driver record!''';
        _resultColor = Colors.green;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '''❌ PROBLEMATIC USER TEST FAILED
Error: $e

The user still has issues that need to be resolved.''';
        _resultColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _testDriverIdLookup() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      const problematicUserId = '5af49a29-a845-4b70-a7ab-384ba2f93930';
      
      // Test the enhanced getDriverIdFromUserId method
      final driverId = await _dashboardService.getDriverIdFromUserId(problematicUserId);
      
      if (driverId != null) {
        setState(() {
          _testResult = '''✅ DRIVER ID LOOKUP TEST PASSED
User ID: $problematicUserId
Driver ID: $driverId

The getDriverIdFromUserId method now works correctly!''';
          _resultColor = Colors.green;
          _isLoading = false;
        });
      } else {
        setState(() {
          _testResult = '''❌ DRIVER ID LOOKUP TEST FAILED
User ID: $problematicUserId
Driver ID: null

The method still returns null for this user.''';
          _resultColor = Colors.red;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '''❌ DRIVER ID LOOKUP TEST FAILED
Error: $e''';
        _resultColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _testDashboardData() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      const problematicUserId = '5af49a29-a845-4b70-a7ab-384ba2f93930';
      
      // Get driver ID first
      final driverId = await _dashboardService.getDriverIdFromUserId(problematicUserId);
      
      if (driverId == null) {
        throw Exception('Driver ID not found');
      }
      
      // Test dashboard data loading
      final dashboardData = await _dashboardService.getDashboardData(driverId);
      
      setState(() {
        _testResult = '''✅ DASHBOARD DATA TEST PASSED
Driver ID: $driverId
Status: ${dashboardData.driverStatus.name}
Online: ${dashboardData.isOnline}
Active Orders: ${dashboardData.activeOrders.length}
Today's Deliveries: ${dashboardData.todaySummary.deliveriesCompleted}
Today's Earnings: RM${dashboardData.todaySummary.earningsToday.toStringAsFixed(2)}

Dashboard data loads successfully!''';
        _resultColor = Colors.green;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '''❌ DASHBOARD DATA TEST FAILED
Error: $e''';
        _resultColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  Future<void> _testProviderIntegration() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      // Test the currentDriverIdProvider
      final driverIdAsync = ref.read(currentDriverIdProvider.future);
      final driverId = await driverIdAsync;
      
      // Test the dashboard data provider
      final dashboardDataAsync = ref.read(driverDashboardDataProvider.future);
      final dashboardData = await dashboardDataAsync;
      
      setState(() {
        _testResult = '''✅ PROVIDER INTEGRATION TEST PASSED
Current Driver ID: $driverId
Dashboard Status: ${dashboardData.driverStatus.name}
Provider Integration: Working

All Riverpod providers are working correctly!''';
        _resultColor = Colors.green;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '''❌ PROVIDER INTEGRATION TEST FAILED
Error: $e

Provider integration still has issues.''';
        _resultColor = Colors.red;
        _isLoading = false;
      });
    }
  }
}
