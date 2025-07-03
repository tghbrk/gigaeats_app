import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/debug_logger.dart';

/// Debug tool to investigate specific user accounts
class UserInvestigationTool {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Investigate a specific user account by email
  static Future<Map<String, dynamic>> investigateUser(String email) async {
    final results = <String, dynamic>{
      'email': email,
      'timestamp': DateTime.now().toIso8601String(),
      'supabase_auth': null,
      'database_record': null,
      'issues': <String>[],
      'recommendations': <String>[],
    };

    try {
      DebugLogger.info('🔍 Starting investigation for user: $email');

      // 1. Check Supabase Auth
      await _checkSupabaseAuth(email, results);

      // 2. Check Database Record
      await _checkDatabaseRecord(email, results);

      // 3. Analyze Issues
      _analyzeIssues(results);

      DebugLogger.info('✅ Investigation completed for: $email');
      return results;

    } catch (e) {
      DebugLogger.error('❌ Investigation failed for $email: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Check Supabase Auth status
  static Future<void> _checkSupabaseAuth(String email, Map<String, dynamic> results) async {
    try {
      DebugLogger.info('🔐 Checking Supabase Auth for: $email');

      // Note: We can't directly query auth.users from client side
      // We'll check if the current user matches the email
      final currentUser = _supabase.auth.currentUser;
      
      if (currentUser?.email == email) {
        results['supabase_auth'] = {
          'exists': true,
          'id': currentUser!.id,
          'email': currentUser.email,
          'email_confirmed_at': currentUser.emailConfirmedAt,
          'created_at': currentUser.createdAt,
          'last_sign_in_at': currentUser.lastSignInAt,
          'user_metadata': currentUser.userMetadata,
          'app_metadata': currentUser.appMetadata,
        };
        DebugLogger.info('✅ Found Supabase Auth user: ${currentUser.id}');
      } else {
        results['supabase_auth'] = {
          'exists': false,
          'current_user_email': currentUser?.email,
          'note': 'Cannot check other users auth status from client side'
        };
        DebugLogger.warning('⚠️ User not currently authenticated or different user');
      }

    } catch (e) {
      DebugLogger.error('❌ Error checking Supabase Auth: $e');
      results['supabase_auth'] = {'error': e.toString()};
    }
  }

  /// Check database record
  static Future<void> _checkDatabaseRecord(String email, Map<String, dynamic> results) async {
    try {
      DebugLogger.info('🗄️ Checking database record for: $email');

      // Try to find user by email
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        results['database_record'] = {
          'exists': true,
          'data': response,
        };
        DebugLogger.info('✅ Found database record for: $email');
        DebugLogger.logObject('User Data', response);
      } else {
        results['database_record'] = {
          'exists': false,
          'note': 'No database record found for this email'
        };
        DebugLogger.warning('⚠️ No database record found for: $email');
      }

    } catch (e) {
      DebugLogger.error('❌ Error checking database record: $e');
      results['database_record'] = {'error': e.toString()};
    }
  }

  /// Analyze issues and provide recommendations
  static void _analyzeIssues(Map<String, dynamic> results) {
    final issues = results['issues'] as List<String>;
    final recommendations = results['recommendations'] as List<String>;

    final authData = results['supabase_auth'] as Map<String, dynamic>?;
    final dbData = results['database_record'] as Map<String, dynamic>?;

    // Check for auth vs database mismatches
    if (authData?['exists'] == true && dbData?['exists'] == false) {
      issues.add('User exists in Supabase Auth but not in database');
      recommendations.add('Run user profile creation process or database trigger');
    }

    if (authData?['exists'] == false && dbData?['exists'] == true) {
      issues.add('User exists in database but not in Supabase Auth');
      recommendations.add('Check if user was deleted from auth but not database');
    }

    // Check email confirmation
    if (authData?['email_confirmed_at'] == null && authData?['exists'] == true) {
      issues.add('Email not confirmed in Supabase Auth');
      recommendations.add('User needs to verify their email address');
    }

    // Check role consistency
    if (authData?['exists'] == true && dbData?['exists'] == true) {
      final authRole = authData?['user_metadata']?['role'];
      final dbRole = dbData?['data']?['role'];
      
      if (authRole != null && dbRole != null && authRole != dbRole) {
        issues.add('Role mismatch: Auth has "$authRole", Database has "$dbRole"');
        recommendations.add('Sync role between auth metadata and database');
      }
    }

    // Check for missing required fields
    if (dbData?['exists'] == true) {
      final userData = dbData?['data'] as Map<String, dynamic>?;
      if (userData != null) {
        if (userData['supabase_user_id'] == null) {
          issues.add('Missing supabase_user_id in database record');
          recommendations.add('Update database record with correct supabase_user_id');
        }
        
        if (userData['role'] == null) {
          issues.add('Missing role in database record');
          recommendations.add('Set appropriate role for user');
        }

        if (userData['is_active'] == false) {
          issues.add('User account is marked as inactive');
          recommendations.add('Activate user account if appropriate');
        }
      }
    }

    DebugLogger.info('🔍 Analysis complete. Found ${issues.length} issues');
  }

  /// Create a fix script for common issues
  static Future<Map<String, dynamic>> generateFixScript(String email) async {
    final investigation = await investigateUser(email);
    final fixes = <String, dynamic>{
      'email': email,
      'fixes_available': <Map<String, dynamic>>[],
    };

    final authData = investigation['supabase_auth'] as Map<String, dynamic>?;
    final dbData = investigation['database_record'] as Map<String, dynamic>?;

    // Fix 1: Create missing database record
    if (authData?['exists'] == true && dbData?['exists'] == false) {
      fixes['fixes_available'].add({
        'issue': 'Missing database record',
        'sql': '''
INSERT INTO users (
  supabase_user_id,
  email,
  full_name,
  role,
  is_verified,
  is_active,
  created_at,
  updated_at
) VALUES (
  '${authData?['id']}',
  '${authData?['email']}',
  '${authData?['user_metadata']?['full_name'] ?? 'Unknown'}',
  '${authData?['user_metadata']?['role'] ?? 'customer'}',
  ${authData?['email_confirmed_at'] != null},
  true,
  NOW(),
  NOW()
);''',
        'description': 'Creates missing user record in database'
      });
    }

    // Fix 2: Update supabase_user_id
    if (dbData?['exists'] == true && dbData?['data']?['supabase_user_id'] == null) {
      fixes['fixes_available'].add({
        'issue': 'Missing supabase_user_id',
        'sql': '''
UPDATE users 
SET supabase_user_id = '${authData?['id']}',
    updated_at = NOW()
WHERE email = '$email';''',
        'description': 'Links database record to Supabase Auth user'
      });
    }

    // Fix 3: Sync roles
    if (authData?['user_metadata']?['role'] != null && 
        dbData?['data']?['role'] != authData?['user_metadata']?['role']) {
      fixes['fixes_available'].add({
        'issue': 'Role mismatch',
        'sql': '''
UPDATE users 
SET role = '${authData?['user_metadata']?['role']}',
    updated_at = NOW()
WHERE email = '$email';''',
        'description': 'Syncs role from auth metadata to database'
      });
    }

    return fixes;
  }
}

/// Widget to display investigation results
class UserInvestigationWidget extends StatefulWidget {
  final String email;

  const UserInvestigationWidget({
    super.key,
    required this.email,
  });

  @override
  State<UserInvestigationWidget> createState() => _UserInvestigationWidgetState();
}

class _UserInvestigationWidgetState extends State<UserInvestigationWidget> {
  Map<String, dynamic>? _results;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _investigate();
  }

  Future<void> _investigate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await UserInvestigationTool.investigateUser(widget.email);
      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _results = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_results == null) {
      return const Center(
        child: Text('No investigation results'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investigation Results for: ${widget.email}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          _buildSection('Supabase Auth Status', _results!['supabase_auth']),
          const SizedBox(height: 16),
          
          _buildSection('Database Record', _results!['database_record']),
          const SizedBox(height: 16),
          
          _buildIssuesSection(),
          const SizedBox(height: 16),
          
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, dynamic data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              data.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesSection() {
    final issues = _results!['issues'] as List<String>;
    
    return Card(
      color: issues.isEmpty ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issues Found (${issues.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (issues.isEmpty)
              const Text('✅ No issues found')
            else
              ...issues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('❌ $issue'),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _results!['recommendations'] as List<String>;
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations (${recommendations.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (recommendations.isEmpty)
              const Text('ℹ️ No recommendations')
            else
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('💡 $rec'),
              )),
          ],
        ),
      ),
    );
  }
}
