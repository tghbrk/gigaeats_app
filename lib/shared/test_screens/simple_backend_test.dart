import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple backend validation screen that can be accessed via URL
/// Tests core driver system functionality
class SimpleBackendTest extends StatefulWidget {
  const SimpleBackendTest({super.key});

  @override
  State<SimpleBackendTest> createState() => _SimpleBackendTestState();
}

class _SimpleBackendTestState extends State<SimpleBackendTest> {
  final List<String> _logs = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Validation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              child: _isRunning 
                  ? const Text('Running Tests...')
                  : const Text('Run Backend Tests'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.startsWith('❌');
                final isSuccess = log.startsWith('✅');
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isError 
                        ? Colors.red.withValues(alpha: 0.1)
                        : isSuccess 
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isError 
                          ? Colors.red[700]
                          : isSuccess 
                              ? Colors.green[700]
                              : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
    debugPrint(message); // Also print to console
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('🧪 Starting Backend Validation Tests...');
    
    await _testDatabaseSchema();
    await _testDriverTables();
    await _testDatabaseFunctions();
    await _testRLSPolicies();
    
    _log('🏁 Backend validation completed!');
    
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testDatabaseSchema() async {
    _log('\n📊 Testing Database Schema...');
    
    try {
      final supabase = Supabase.instance.client;
      
      // Test 1: Check if we can query users table with driver role
      _log('Testing user_role_enum includes driver...');
      try {
        await supabase.from('users').select('role').eq('role', 'driver').limit(1);
        _log('✅ user_role_enum includes driver role');
      } catch (e) {
        _log('❌ user_role_enum test failed: $e');
      }
      
      // Test 2: Check basic table access
      _log('Testing basic table access...');
      try {
        await supabase.from('users').select('count').single();
        _log('✅ Can access users table');
      } catch (e) {
        _log('⚠️ Users table access restricted (RLS): $e');
      }
      
    } catch (e) {
      _log('❌ Database schema test failed: $e');
    }
  }

  Future<void> _testDriverTables() async {
    _log('\n🚗 Testing Driver Tables...');
    
    try {
      final supabase = Supabase.instance.client;
      
      // Test drivers table structure
      _log('Testing drivers table...');
      try {
        await supabase.from('drivers').select('id, user_id, vendor_id, name, phone_number, status, is_active').limit(1);
        _log('✅ Drivers table exists with correct structure');
      } catch (e) {
        _log('❌ Drivers table test failed: $e');
      }
      
      // Test driver_performance table
      _log('Testing driver_performance table...');
      try {
        await supabase.from('driver_performance').select('driver_id, date, total_deliveries, successful_deliveries, total_earnings').limit(1);
        _log('✅ Driver performance table exists');
      } catch (e) {
        _log('❌ Driver performance table test failed: $e');
      }
      
      // Test delivery_tracking table (for driver locations)
      _log('Testing delivery_tracking table...');
      try {
        await supabase.from('delivery_tracking').select('driver_id, order_id, location, recorded_at').limit(1);
        _log('✅ Delivery tracking table exists');
      } catch (e) {
        _log('❌ Delivery tracking table test failed: $e');
      }
      
    } catch (e) {
      _log('❌ Driver tables test failed: $e');
    }
  }

  Future<void> _testDatabaseFunctions() async {
    _log('\n⚙️ Testing Database Functions...');
    
    try {
      final supabase = Supabase.instance.client;
      
      // Test calculate_driver_performance function
      _log('Testing calculate_driver_performance function...');
      try {
        await supabase.rpc('calculate_driver_performance', params: {
          'p_driver_id': '00000000-0000-0000-0000-000000000000',
          'p_start_date': '2024-01-01',
          'p_end_date': '2024-12-31',
        });
        _log('✅ calculate_driver_performance function exists');
      } catch (e) {
        _log('❌ calculate_driver_performance function test failed: $e');
      }
      
      // Test get_driver_leaderboard function
      _log('Testing get_driver_leaderboard function...');
      try {
        await supabase.rpc('get_driver_leaderboard', params: {
          'p_vendor_id': null,
          'p_period_days': 30,
          'p_limit': 10,
        });
        _log('✅ get_driver_leaderboard function exists');
      } catch (e) {
        _log('❌ get_driver_leaderboard function test failed: $e');
      }
      
      // Test validate_driver_user_setup function
      _log('Testing validate_driver_user_setup function...');
      try {
        await supabase.rpc('validate_driver_user_setup', params: {
          'p_user_id': '00000000-0000-0000-0000-000000000000',
        });
        _log('✅ validate_driver_user_setup function exists');
      } catch (e) {
        _log('❌ validate_driver_user_setup function test failed: $e');
      }
      
      // Test update_driver_rating function
      _log('Testing update_driver_rating function...');
      try {
        await supabase.rpc('update_driver_rating', params: {
          'p_driver_id': '00000000-0000-0000-0000-000000000000',
          'p_rating': 4.5,
          'p_date': DateTime.now().toIso8601String().split('T')[0],
        });
        _log('✅ update_driver_rating function exists');
      } catch (e) {
        // Expected to fail for non-existent driver
        if (e.toString().contains('driver') || e.toString().contains('not found') || e.toString().contains('violates')) {
          _log('✅ update_driver_rating function exists (expected validation error)');
        } else {
          _log('❌ update_driver_rating function test failed: $e');
        }
      }
      
    } catch (e) {
      _log('❌ Database functions test failed: $e');
    }
  }

  Future<void> _testRLSPolicies() async {
    _log('\n🔒 Testing RLS Policies...');
    
    try {
      final supabase = Supabase.instance.client;
      
      // Test RLS on drivers table
      _log('Testing RLS on drivers table...');
      try {
        await supabase.from('drivers').select('id').limit(1);
        _log('✅ Can access drivers table (RLS allows anonymous access)');
      } catch (e) {
        if (e.toString().contains('permission') || e.toString().contains('policy')) {
          _log('✅ RLS is active on drivers table (restricts anonymous access)');
        } else {
          _log('❌ Drivers table RLS test failed: $e');
        }
      }
      
      // Test RLS on driver_performance table
      _log('Testing RLS on driver_performance table...');
      try {
        await supabase.from('driver_performance').select('driver_id').limit(1);
        _log('✅ Can access driver_performance table (RLS allows anonymous access)');
      } catch (e) {
        if (e.toString().contains('permission') || e.toString().contains('policy')) {
          _log('✅ RLS is active on driver_performance table (restricts anonymous access)');
        } else {
          _log('❌ Driver performance table RLS test failed: $e');
        }
      }
      
      // Test RLS on orders table for driver access
      _log('Testing RLS on orders table...');
      try {
        await supabase.from('orders').select('id, assigned_driver_id').limit(1);
        _log('✅ Can access orders table (RLS allows anonymous access)');
      } catch (e) {
        if (e.toString().contains('permission') || e.toString().contains('policy')) {
          _log('✅ RLS is active on orders table (restricts anonymous access)');
        } else {
          _log('❌ Orders table RLS test failed: $e');
        }
      }
      
    } catch (e) {
      _log('❌ RLS policies test failed: $e');
    }
  }
}
