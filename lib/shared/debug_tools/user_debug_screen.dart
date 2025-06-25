import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_investigation_tool.dart';
import '../../core/utils/debug_logger.dart';

class UserDebugScreen extends StatefulWidget {
  const UserDebugScreen({super.key});

  @override
  State<UserDebugScreen> createState() => _UserDebugScreenState();
}

class _UserDebugScreenState extends State<UserDebugScreen> {
  final _emailController = TextEditingController(text: 'necros@gmail.com');
  Map<String, dynamic>? _investigationResults;
  Map<String, dynamic>? _fixScript;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _investigateUser() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _investigationResults = null;
      _fixScript = null;
    });

    try {
      final results = await UserInvestigationTool.investigateUser(_emailController.text.trim());
      final fixes = await UserInvestigationTool.generateFixScript(_emailController.text.trim());
      
      setState(() {
        _investigationResults = results;
        _fixScript = fixes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Investigation failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  Future<void> _checkCurrentAuth() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser != null) {
        DebugLogger.info('✅ Current user: ${currentUser.email}');
        DebugLogger.logObject('Current User Data', {
          'id': currentUser.id,
          'email': currentUser.email,
          'email_confirmed_at': currentUser.emailConfirmedAt,
          'created_at': currentUser.createdAt,
          'last_sign_in_at': currentUser.lastSignInAt,
          'user_metadata': currentUser.userMetadata,
          'app_metadata': currentUser.appMetadata,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Current user: ${currentUser.email}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        DebugLogger.warning('⚠️ No current user authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user currently authenticated'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      DebugLogger.error('❌ Auth check error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth check error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Debug Tool'),
        backgroundColor: Colors.red.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'DEBUG TOOL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This tool is for debugging authentication issues. Use only in development.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Email input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email to investigate',
                hintText: 'Enter user email address',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _investigateUser,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Investigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkCurrentAuth,
                    icon: const Icon(Icons.person),
                    label: const Text('Check Current Auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Investigation results
            if (_investigationResults != null) ...[
              Text(
                'Investigation Results',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              UserInvestigationWidget(email: _emailController.text.trim()),
              
              const SizedBox(height: 24),
            ],
            
            // Fix script
            if (_fixScript != null) ...[
              Text(
                'Suggested Fixes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              _buildFixScriptSection(),
              
              const SizedBox(height: 24),
            ],
            
            // Manual database query section
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Database Query',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can run this query in Supabase Studio to check the user manually:',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        'SELECT * FROM users WHERE email = \'${_emailController.text.trim()}\';',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'SELECT * FROM users WHERE email = \'${_emailController.text.trim()}\';',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Query copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Query'),
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

  Widget _buildFixScriptSection() {
    final fixes = _fixScript!['fixes_available'] as List<dynamic>;
    
    if (fixes.isEmpty) {
      return const Card(
        color: Colors.green,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '✅ No fixes needed - account appears to be in good state',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return Column(
      children: fixes.map<Widget>((fix) {
        return Card(
          color: Colors.orange.shade50,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fix['issue'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  fix['description'],
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    fix['sql'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: fix['sql']));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SQL copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy SQL'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
