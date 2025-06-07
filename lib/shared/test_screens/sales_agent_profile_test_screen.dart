import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/sales_agent/data/repositories/sales_agent_repository.dart';
import '../../features/sales_agent/data/models/sales_agent_profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class SalesAgentProfileTestScreen extends ConsumerStatefulWidget {
  const SalesAgentProfileTestScreen({super.key});

  @override
  ConsumerState<SalesAgentProfileTestScreen> createState() => _SalesAgentProfileTestScreenState();
}

class _SalesAgentProfileTestScreenState extends ConsumerState<SalesAgentProfileTestScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;
  SalesAgentProfile? _profile;
  Map<String, dynamic>? _statistics;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal().toString().substring(11, 19)}: $message');
    });
    debugPrint('SalesAgentProfileTest: $message');
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('🔐 Testing authentication...');
      
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

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testProfileLoading() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('📋 Testing profile loading...');
      
      final repository = SalesAgentRepository();
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        _addLog('❌ No authenticated user for profile loading');
        return;
      }

      _addLog('🔍 Loading profile for user: ${currentUser.id}');
      final profile = await repository.getSalesAgentProfile(currentUser.id);
      
      if (profile != null) {
        _addLog('✅ Profile loaded successfully');
        _addLog('   Name: ${profile.fullName}');
        _addLog('   Email: ${profile.email}');
        _addLog('   Company: ${profile.companyName ?? 'Not set'}');
        _addLog('   Total Earnings: RM ${profile.totalEarnings.toStringAsFixed(2)}');
        _addLog('   Total Orders: ${profile.totalOrders}');
        _addLog('   Commission Rate: ${profile.formattedCommissionRate}');
        
        setState(() {
          _profile = profile;
        });
      } else {
        _addLog('❌ No profile found for user');
        _addLog('🔧 Attempting to create profile...');
        await _createTestProfile();
      }
    } catch (e) {
      _addLog('💥 Profile loading error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createTestProfile() async {
    try {
      _addLog('🔧 Creating test profile...');
      
      final repository = SalesAgentRepository();
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        _addLog('❌ No authenticated user for profile creation');
        return;
      }

      final profile = await repository.createSalesAgentProfile(
        supabaseUid: currentUser.id,
        email: currentUser.email ?? 'test@example.com',
        fullName: 'Test Sales Agent',
        phoneNumber: '+60123456789',
        companyName: 'Test Sales Company',
        businessRegistrationNumber: 'TEST123456',
        businessAddress: 'Test Address, Kuala Lumpur',
        businessType: 'Sales Agency',
        commissionRate: 0.07,
        assignedRegions: ['Kuala Lumpur', 'Selangor'],
      );

      _addLog('✅ Profile created successfully');
      _addLog('   Profile ID: ${profile.id}');
      
      setState(() {
        _profile = profile;
      });
    } catch (e) {
      _addLog('💥 Profile creation error: $e');
    }
  }

  Future<void> _testStatisticsLoading() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('📊 Testing statistics loading...');
      
      final repository = SalesAgentRepository();
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        _addLog('❌ No authenticated user for statistics loading');
        return;
      }

      final statistics = await repository.getSalesAgentStatistics(currentUser.id);
      
      _addLog('✅ Statistics loaded successfully');
      _addLog('   Total Customers: ${statistics['total_customers'] ?? 0}');
      _addLog('   Total Orders: ${statistics['total_orders'] ?? 0}');
      _addLog('   Completed Orders: ${statistics['completed_orders'] ?? 0}');
      _addLog('   Total Revenue: RM ${(statistics['total_revenue'] ?? 0.0).toStringAsFixed(2)}');
      _addLog('   Success Rate: ${(statistics['success_rate'] ?? 0.0).toStringAsFixed(1)}%');
      
      setState(() {
        _statistics = statistics;
      });
    } catch (e) {
      _addLog('💥 Statistics loading error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _runAllTests() async {
    _logs.clear();
    await _testAuthentication();
    await _testProfileLoading();
    await _testStatisticsLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Agent Profile Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Agent Profile Tests',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _runAllTests,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Run All Tests'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testAuthentication,
                          icon: const Icon(Icons.security),
                          label: const Text('Test Auth'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testProfileLoading,
                          icon: const Icon(Icons.person),
                          label: const Text('Test Profile'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testStatisticsLoading,
                          icon: const Icon(Icons.analytics),
                          label: const Text('Test Statistics'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _logs.clear()),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Logs'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loading Indicator
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Running tests...'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Test Logs',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color? textColor;
                          if (log.contains('✅')) textColor = Colors.green;
                          if (log.contains('❌') || log.contains('💥')) textColor = Colors.red;
                          if (log.contains('🔐') || log.contains('🔧')) textColor = Colors.blue;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: textColor,
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
          ],
        ),
      ),
    );
  }
}
