import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/repositories/base_repository.dart';
import '../models/assignment_request.dart';
import '../models/customer_assignment.dart';
import '../models/assignment_history.dart';

/// Repository for managing customer assignments
class AssignmentRepository extends BaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new assignment request
  Future<Map<String, dynamic>> createAssignmentRequest({
    required String customerId,
    required String salesAgentId,
    String? message,
    AssignmentRequestPriority priority = AssignmentRequestPriority.normal,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Creating assignment request');
      debugPrint('Customer ID: $customerId');
      debugPrint('Sales Agent ID: $salesAgentId');
      debugPrint('Priority: ${priority.name}');

      final authenticatedClient = await getAuthenticatedClient();

      final response = await authenticatedClient.functions.invoke(
        'manage-customer-assignment',
        body: {
          'action': 'create_request',
          'customer_id': customerId,
          'sales_agent_id': salesAgentId,
          'message': message,
          'priority': priority.name,
        },
      );

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final result = response.data as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create assignment request');
      }

      debugPrint('AssignmentRepository: Assignment request created successfully');
      return result;
    });
  }

  /// Respond to an assignment request (approve/reject)
  Future<Map<String, dynamic>> respondToAssignmentRequest({
    required String requestId,
    required String response, // 'approve' or 'reject'
    String? message,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Responding to assignment request');
      debugPrint('Request ID: $requestId');
      debugPrint('Response: $response');

      final authenticatedClient = await getAuthenticatedClient();

      final functionResponse = await authenticatedClient.functions.invoke(
        'manage-customer-assignment',
        body: {
          'action': 'respond_to_request',
          'request_id': requestId,
          'response': response,
          'message': message,
        },
      );

      if (functionResponse.data == null) {
        throw Exception('No response data received');
      }

      final result = functionResponse.data as Map<String, dynamic>;
      if (result['success'] != true && response == 'approve') {
        throw Exception(result['error'] ?? 'Failed to respond to assignment request');
      }

      debugPrint('AssignmentRepository: Assignment request response processed');
      return result;
    });
  }

  /// Cancel an assignment request
  Future<Map<String, dynamic>> cancelAssignmentRequest({
    required String requestId,
    String? reason,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Cancelling assignment request');
      debugPrint('Request ID: $requestId');

      final authenticatedClient = await getAuthenticatedClient();

      final response = await authenticatedClient.functions.invoke(
        'manage-customer-assignment',
        body: {
          'action': 'cancel_request',
          'request_id': requestId,
          'reason': reason,
        },
      );

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final result = response.data as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to cancel assignment request');
      }

      debugPrint('AssignmentRepository: Assignment request cancelled successfully');
      return result;
    });
  }

  /// Deactivate an assignment
  Future<Map<String, dynamic>> deactivateAssignment({
    required String assignmentId,
    required String reason,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Deactivating assignment');
      debugPrint('Assignment ID: $assignmentId');

      final authenticatedClient = await getAuthenticatedClient();

      final response = await authenticatedClient.functions.invoke(
        'manage-customer-assignment',
        body: {
          'action': 'deactivate_assignment',
          'assignment_id': assignmentId,
          'reason': reason,
        },
      );

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final result = response.data as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to deactivate assignment');
      }

      debugPrint('AssignmentRepository: Assignment deactivated successfully');
      return result;
    });
  }

  /// Get customer assignment status
  Future<Map<String, dynamic>> getCustomerAssignmentStatus(String customerId) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Getting customer assignment status');
      debugPrint('Customer ID: $customerId');

      final authenticatedClient = await getAuthenticatedClient();

      final response = await authenticatedClient.functions.invoke(
        'manage-customer-assignment',
        body: {
          'action': 'get_status',
          'customer_id': customerId,
        },
      );

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final result = response.data as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to get assignment status');
      }

      debugPrint('AssignmentRepository: Assignment status retrieved successfully');
      return result;
    });
  }

  /// Get assignment requests for sales agent
  Future<List<AssignmentRequest>> getSalesAgentAssignmentRequests({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Getting sales agent assignment requests');

      final authenticatedClient = await getAuthenticatedClient();

      // Get current user's sales agent ID
      final userResponse = await authenticatedClient
          .from('users')
          .select('id')
          .eq('supabase_user_id', _supabase.auth.currentUser!.id)
          .eq('role', 'sales_agent')
          .single();

      final salesAgentId = userResponse['id'] as String;

      // Build query with conditional status filter
      PostgrestFilterBuilder query = authenticatedClient
          .from('customer_assignment_requests')
          .select('''
            *,
            customers!customer_assignment_requests_customer_id_fkey(
              contact_person_name,
              email,
              organization_name
            )
          ''')
          .eq('sales_agent_id', salesAgentId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) {
        final customerData = json['customers'] as Map<String, dynamic>?;
        return AssignmentRequest.fromJson({
          ...json,
          'customer_name': customerData?['contact_person_name'],
          'customer_email': customerData?['email'],
          'customer_organization': customerData?['organization_name'],
        });
      }).toList();
    });
  }

  /// Get assignment requests for customer
  Future<List<AssignmentRequest>> getCustomerAssignmentRequests({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Getting customer assignment requests');

      final authenticatedClient = await getAuthenticatedClient();

      // Get customer record linked to this profile
      final customerResponse = await authenticatedClient
          .from('customers')
          .select('id')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .single();

      final customerId = customerResponse['id'] as String;

      // Build query with conditional status filter
      PostgrestFilterBuilder query = authenticatedClient
          .from('customer_assignment_requests')
          .select('''
            *,
            users!customer_assignment_requests_sales_agent_id_fkey(
              full_name,
              email
            )
          ''')
          .eq('customer_id', customerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) {
        final salesAgentData = json['users'] as Map<String, dynamic>?;
        return AssignmentRequest.fromJson({
          ...json,
          'sales_agent_name': salesAgentData?['full_name'],
          'sales_agent_email': salesAgentData?['email'],
        });
      }).toList();
    });
  }

  /// Get active assignments for sales agent
  Future<List<CustomerAssignment>> getSalesAgentAssignments({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Getting sales agent assignments');

      final authenticatedClient = await getAuthenticatedClient();

      // Get current user's sales agent ID
      final userResponse = await authenticatedClient
          .from('users')
          .select('id')
          .eq('supabase_user_id', _supabase.auth.currentUser!.id)
          .eq('role', 'sales_agent')
          .single();

      final salesAgentId = userResponse['id'] as String;

      // Build query with conditional active filter
      PostgrestFilterBuilder query = authenticatedClient
          .from('customer_assignments')
          .select('''
            *,
            customers!customer_assignments_customer_id_fkey(
              contact_person_name,
              email,
              organization_name,
              phone_number
            )
          ''')
          .eq('sales_agent_id', salesAgentId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query
          .order('assigned_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) {
        final customerData = json['customers'] as Map<String, dynamic>?;
        return CustomerAssignment.fromJson({
          ...json,
          'customer_name': customerData?['contact_person_name'],
          'customer_email': customerData?['email'],
          'customer_organization': customerData?['organization_name'],
          'customer_phone': customerData?['phone_number'],
        });
      }).toList();
    });
  }

  /// Get assignment history
  Future<List<AssignmentHistory>> getAssignmentHistory({
    String? customerId,
    String? salesAgentId,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Getting assignment history');

      final authenticatedClient = await getAuthenticatedClient();

      // Build query with conditional filters
      PostgrestFilterBuilder query = authenticatedClient
          .from('customer_assignment_history')
          .select('''
            *,
            customers!customer_assignment_history_customer_id_fkey(
              contact_person_name,
              organization_name
            ),
            users!customer_assignment_history_sales_agent_id_fkey(
              full_name
            )
          ''');

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      if (salesAgentId != null) {
        query = query.eq('sales_agent_id', salesAgentId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) {
        final customerData = json['customers'] as Map<String, dynamic>?;
        final salesAgentData = json['users'] as Map<String, dynamic>?;
        return AssignmentHistory.fromJson({
          ...json,
          'customer_name': customerData?['contact_person_name'],
          'customer_organization': customerData?['organization_name'],
          'sales_agent_name': salesAgentData?['full_name'],
        });
      }).toList();
    });
  }

  /// Search for customers available for assignment
  Future<List<Map<String, dynamic>>> searchAvailableCustomers({
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Searching available customers');

      final authenticatedClient = await getAuthenticatedClient();

      PostgrestFilterBuilder query = authenticatedClient
          .from('customers')
          .select('''
            id,
            contact_person_name,
            organization_name,
            email,
            phone_number,
            address,
            total_orders,
            total_spent,
            last_order_date,
            created_at,
            user_id
          ''')
          .isFilter('sales_agent_id', null) // Not assigned to any sales agent
          .not('user_id', 'is', null) // Has app account
          .eq('is_active', true);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'contact_person_name.ilike.%$searchQuery%,'
          'organization_name.ilike.%$searchQuery%,'
          'email.ilike.%$searchQuery%'
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Get assignment statistics for sales agent
  Future<Map<String, dynamic>> getSalesAgentAssignmentStats() async {
    return executeQuery(() async {
      debugPrint('AssignmentRepository: Getting sales agent assignment statistics');

      final authenticatedClient = await getAuthenticatedClient();

      // Get current user's sales agent ID
      final userResponse = await authenticatedClient
          .from('users')
          .select('id')
          .eq('supabase_user_id', _supabase.auth.currentUser!.id)
          .eq('role', 'sales_agent')
          .single();

      final salesAgentId = userResponse['id'] as String;

      // Get assignment statistics
      final assignmentStats = await authenticatedClient
          .from('customer_assignments')
          .select('total_orders, total_commission_earned')
          .eq('sales_agent_id', salesAgentId)
          .eq('is_active', true);

      // Get request statistics
      final requestStats = await authenticatedClient
          .from('customer_assignment_requests')
          .select('status')
          .eq('sales_agent_id', salesAgentId);

      // Calculate totals
      int totalActiveAssignments = assignmentStats.length;
      int totalOrders = 0;
      double totalCommission = 0.0;

      for (final assignment in assignmentStats) {
        totalOrders += (assignment['total_orders'] as int? ?? 0);
        totalCommission += (assignment['total_commission_earned'] as double? ?? 0.0);
      }

      // Calculate request statistics
      int pendingRequests = 0;
      int approvedRequests = 0;
      int rejectedRequests = 0;

      for (final request in requestStats) {
        final status = request['status'] as String;
        switch (status) {
          case 'pending':
            pendingRequests++;
            break;
          case 'approved':
            approvedRequests++;
            break;
          case 'rejected':
            rejectedRequests++;
            break;
        }
      }

      return {
        'total_active_assignments': totalActiveAssignments,
        'total_orders': totalOrders,
        'total_commission_earned': totalCommission,
        'pending_requests': pendingRequests,
        'approved_requests': approvedRequests,
        'rejected_requests': rejectedRequests,
        'total_requests': requestStats.length,
        'approval_rate': requestStats.isNotEmpty
            ? (approvedRequests / requestStats.length * 100).round()
            : 0,
      };
    });
  }
}
