import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/customer_assignment/data/repositories/assignment_repository.dart';
import '../../features/customer_assignment/presentation/providers/assignment_provider.dart';

class AssignmentSystemTestScreen extends ConsumerStatefulWidget {
  const AssignmentSystemTestScreen({super.key});

  @override
  ConsumerState<AssignmentSystemTestScreen> createState() => _AssignmentSystemTestScreenState();
}

class _AssignmentSystemTestScreenState extends ConsumerState<AssignmentSystemTestScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addLog('🧪 Assignment System Test Screen Initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal().toString().substring(11, 19)} $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment System Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Test Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testAuthentication,
                        child: const Text('Test Auth'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testDatabaseTables,
                        child: const Text('Test Tables'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testRepository,
                        child: const Text('Test Repository'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testProviders,
                        child: const Text('Test Providers'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testFullWorkflow,
                        child: const Text('Test Full Workflow'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearLogs,
                        child: const Text('Clear Logs'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          
          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.white;
                  
                  if (log.contains('✅')) {
                    textColor = Colors.green;
                  } else if (log.contains('❌')) {
                    textColor = Colors.red;
                  } else if (log.contains('⚠️')) {
                    textColor = Colors.orange;
                  } else if (log.contains('🔐') || log.contains('🧪')) {
                    textColor = Colors.blue;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testAuthentication() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('🔐 Testing Authentication...');
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _addLog('✅ User authenticated: ${currentUser.email}');
        _addLog('   User ID: ${currentUser.id}');
        _addLog('   Email verified: ${currentUser.emailConfirmedAt != null}');
      } else {
        _addLog('❌ No authenticated user found');
        _addLog('🔐 Attempting to login test user...');
        
        final authResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: 'test6@gigaeats.com',
          password: 'testpass123',
        );

        if (authResponse.user != null) {
          _addLog('✅ Login successful: ${authResponse.user!.email}');
        } else {
          _addLog('❌ Login failed');
        }
      }
    } catch (e) {
      _addLog('💥 Authentication error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testDatabaseTables() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('📊 Testing Database Tables...');
      
      final supabase = Supabase.instance.client;
      
      // Test assignment requests table
      _addLog('Testing customer_assignment_requests table...');
      try {
        final requests = await supabase
            .from('customer_assignment_requests')
            .select('id, status, priority')
            .limit(1);
        _addLog('✅ customer_assignment_requests table accessible');
        _addLog('   Found ${requests.length} records');
      } catch (e) {
        _addLog('❌ customer_assignment_requests table error: $e');
      }
      
      // Test assignments table
      _addLog('Testing customer_assignments table...');
      try {
        final assignments = await supabase
            .from('customer_assignments')
            .select('id, is_active')
            .limit(1);
        _addLog('✅ customer_assignments table accessible');
        _addLog('   Found ${assignments.length} records');
      } catch (e) {
        _addLog('❌ customer_assignments table error: $e');
      }
      
      // Test history table
      _addLog('Testing assignment_history table...');
      try {
        final history = await supabase
            .from('assignment_history')
            .select('id, action')
            .limit(1);
        _addLog('✅ assignment_history table accessible');
        _addLog('   Found ${history.length} records');
      } catch (e) {
        _addLog('❌ assignment_history table error: $e');
      }
      
    } catch (e) {
      _addLog('💥 Database tables test error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testRepository() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('🏗️ Testing Assignment Repository...');
      
      final repository = AssignmentRepository();
      
      // Test getting sales agent requests
      _addLog('Testing getSalesAgentAssignmentRequests...');
      try {
        final requests = await repository.getSalesAgentAssignmentRequests(
          status: 'pending',
          limit: 5,
        );
        _addLog('✅ getSalesAgentAssignmentRequests works');
        _addLog('   Found ${requests.length} pending requests');
      } catch (e) {
        _addLog('❌ getSalesAgentAssignmentRequests error: $e');
      }
      
      // Test getting assignments
      _addLog('Testing getSalesAgentAssignments...');
      try {
        final assignments = await repository.getSalesAgentAssignments(
          activeOnly: true,
        );
        _addLog('✅ getSalesAgentAssignments works');
        _addLog('   Found ${assignments.length} active assignments');
      } catch (e) {
        _addLog('❌ getSalesAgentAssignments error: $e');
      }
      
    } catch (e) {
      _addLog('💥 Repository test error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testProviders() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('🎯 Testing Assignment Providers...');
      
      // Test loading requests
      _addLog('Testing loadSalesAgentRequests...');
      try {
        await ref.read(assignmentProvider.notifier).loadSalesAgentRequests();
        final state = ref.read(assignmentProvider);
        _addLog('✅ loadSalesAgentRequests works');
        _addLog('   Loaded ${state.requests.length} requests');
        _addLog('   Loading state: ${state.isLoading}');
        _addLog('   Error: ${state.errorMessage ?? 'None'}');
      } catch (e) {
        _addLog('❌ loadSalesAgentRequests error: $e');
      }

      // Test loading assignments
      _addLog('Testing loadSalesAgentAssignments...');
      try {
        await ref.read(assignmentProvider.notifier).loadSalesAgentAssignments();
        final state = ref.read(assignmentProvider);
        _addLog('✅ loadSalesAgentAssignments works');
        _addLog('   Loaded ${state.assignments.length} assignments');
      } catch (e) {
        _addLog('❌ loadSalesAgentAssignments error: $e');
      }
      
    } catch (e) {
      _addLog('💥 Providers test error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testFullWorkflow() async {
    setState(() => _isLoading = true);
    
    try {
      _addLog('🔄 Testing Full Assignment Workflow...');
      
      // This would test the complete workflow:
      // 1. Search for available customers
      // 2. Create assignment request
      // 3. Customer approval simulation
      // 4. Assignment creation
      // 5. History tracking
      
      _addLog('⚠️ Full workflow test not implemented yet');
      _addLog('   This would require test customer data');
      _addLog('   and proper authentication setup');
      
    } catch (e) {
      _addLog('💥 Full workflow test error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    _addLog('🧪 Assignment System Test Screen Initialized');
  }
}
