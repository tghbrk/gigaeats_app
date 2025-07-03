

import '../models/cross_role_provisioning_models.dart';
import '../../../customers/data/repositories/base_repository.dart';

class CrossRoleProvisioningService extends BaseRepository {
  CrossRoleProvisioningService() : super();

  // Create driver invitation
  Future<DriverInvitationResult> createDriverInvitation({
    required String vendorId,
    required String email,
    String? phoneNumber,
    required String driverName,
    Map<String, dynamic>? vehicleDetails,
  }) async {
    try {
      final response = await client.rpc('create_driver_invitation', params: {
        'p_vendor_id': vendorId,
        'p_email': email,
        'p_phone_number': phoneNumber,
        'p_driver_name': driverName,
        'p_vehicle_details': vehicleDetails ?? {},
      });

      final result = response.first;
      return DriverInvitationResult(
        success: result['success'] ?? false,
        token: result['token'],
        expiresAt: result['expires_at'] != null 
            ? DateTime.parse(result['expires_at'])
            : null,
        message: result['message'] ?? '',
      );
    } catch (e) {
      return DriverInvitationResult(
        success: false,
        message: 'Failed to create driver invitation: $e',
      );
    }
  }

  // Validate driver invitation token
  Future<DriverInvitationValidation> validateDriverInvitationToken(String token) async {
    try {
      final response = await client.rpc('validate_driver_invitation_token', params: {
        'p_token': token,
      });

      final result = response.first;
      return DriverInvitationValidation(
        valid: result['valid'] ?? false,
        vendorId: result['vendor_id'],
        email: result['email'] ?? '',
        driverName: result['driver_name'] ?? '',
        vehicleDetails: result['vehicle_details'] ?? {},
        expiresAt: result['expires_at'] != null 
            ? DateTime.parse(result['expires_at'])
            : null,
        message: result['message'] ?? '',
      );
    } catch (e) {
      return DriverInvitationValidation(
        valid: false,
        email: '',
        driverName: '',
        vehicleDetails: {},
        message: 'Failed to validate invitation token: $e',
      );
    }
  }

  // Create driver account from invitation
  Future<DriverAccountCreationResult> createDriverAccountFromInvitation({
    required String invitationToken,
    required String authUserId,
  }) async {
    try {
      final response = await client.rpc('create_driver_account_from_invitation', params: {
        'p_invitation_token': invitationToken,
        'p_auth_user_id': authUserId,
      });

      final result = response.first;
      return DriverAccountCreationResult(
        success: result['success'] ?? false,
        driverId: result['driver_id'],
        message: result['message'] ?? '',
      );
    } catch (e) {
      return DriverAccountCreationResult(
        success: false,
        message: 'Failed to create driver account: $e',
      );
    }
  }

  // Get driver invitations for vendor
  Future<List<DriverInvitation>> getDriverInvitations({
    String? vendorId,
    bool activeOnly = true,
    int limit = 50,
  }) async {
    try {
      var query = client
          .from('driver_invitation_tokens')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      // TODO: Fix Supabase API - .eq() and .is_() method issues
      // if (vendorId != null) {
      //   query = query.eq('vendor_id', vendorId);
      // }

      // if (activeOnly) {
      //   query = query.is_('used_at', null).gt('expires_at', DateTime.now().toIso8601String());
      // }

      final response = await query;
      return response.map((json) => DriverInvitation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch driver invitations: $e');
    }
  }

  // Request role transition
  Future<RoleTransitionResult> requestRoleTransition({
    required String userId,
    required String requestedRole,
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await client.rpc('request_role_transition', params: {
        'p_user_id': userId,
        'p_requested_role': requestedRole,
        'p_reason': reason,
        'p_additional_data': additionalData ?? {},
      });

      final result = response.first;
      return RoleTransitionResult(
        success: result['success'] ?? false,
        requestId: result['request_id'],
        message: result['message'] ?? '',
      );
    } catch (e) {
      return RoleTransitionResult(
        success: false,
        message: 'Failed to request role transition: $e',
      );
    }
  }

  // Approve role transition (admin only)
  Future<RoleTransitionResult> approveRoleTransition({
    required String requestId,
    required String reviewerId,
    String? reviewNotes,
  }) async {
    try {
      final response = await client.rpc('approve_role_transition', params: {
        'p_request_id': requestId,
        'p_reviewer_id': reviewerId,
        'p_review_notes': reviewNotes,
      });

      final result = response.first;
      return RoleTransitionResult(
        success: result['success'] ?? false,
        message: result['message'] ?? '',
      );
    } catch (e) {
      return RoleTransitionResult(
        success: false,
        message: 'Failed to approve role transition: $e',
      );
    }
  }

  // Get role transition requests
  Future<List<RoleTransitionRequest>> getRoleTransitionRequests({
    String? userId,
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = client
          .from('role_transition_requests')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      // TODO: Fix Supabase API - .eq() method issues
      // if (userId != null) {
      //   query = query.eq('user_id', userId);
      // }

      // if (status != null) {
      //   query = query.eq('status', status);
      // }

      final response = await query;
      return response.map((json) => RoleTransitionRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch role transition requests: $e');
    }
  }

  // Get account provisioning audit logs
  Future<List<AccountProvisioningAudit>> getAccountProvisioningAudit({
    String? operationType,
    String? entityType,
    String? userId,
    int limit = 100,
  }) async {
    try {
      var query = client
          .from('account_provisioning_audit')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      // TODO: Fix Supabase API - .eq() method issues
      // if (operationType != null) {
      //   query = query.eq('operation_type', operationType);
      // }

      // if (entityType != null) {
      //   query = query.eq('entity_type', entityType);
      // }

      // if (userId != null) {
      //   query = query.eq('user_id', userId);
      // }

      final response = await query;
      return response.map((json) => AccountProvisioningAudit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch audit logs: $e');
    }
  }

  // Get account provisioning statistics
  Future<AccountProvisioningStats> getAccountProvisioningStats() async {
    try {
      final response = await client.rpc('get_account_provisioning_stats');
      final result = response.first;
      
      return AccountProvisioningStats(
        totalCustomerInvitations: result['total_customer_invitations'] ?? 0,
        totalDriverInvitations: result['total_driver_invitations'] ?? 0,
        totalRoleTransitions: result['total_role_transitions'] ?? 0,
        pendingRoleTransitions: result['pending_role_transitions'] ?? 0,
        totalAuditEntries: result['total_audit_entries'] ?? 0,
        statsByOperation: Map<String, int>.from(result['stats_by_operation'] ?? {}),
      );
    } catch (e) {
      throw Exception('Failed to fetch provisioning stats: $e');
    }
  }

  // Check if user can transition to role
  bool canTransitionToRole(String currentRole, String requestedRole) {
    final validTransitions = {
      'customer': ['sales_agent', 'vendor', 'driver'],
      'driver': ['vendor', 'sales_agent'],
      'sales_agent': ['vendor', 'admin'],
      'vendor': ['admin'],
    };

    return validTransitions[currentRole]?.contains(requestedRole) ?? false;
  }

  // Get available role transitions for user
  List<String> getAvailableRoleTransitions(String currentRole) {
    final validTransitions = {
      'customer': ['sales_agent', 'vendor', 'driver'],
      'driver': ['vendor', 'sales_agent'],
      'sales_agent': ['vendor', 'admin'],
      'vendor': ['admin'],
    };

    return validTransitions[currentRole] ?? [];
  }

  // Get role transition requirements
  Map<String, dynamic> getRoleTransitionRequirements(String fromRole, String toRole) {
    final requirements = {
      'customer_to_sales_agent': {
        'verification_required': true,
        'business_info_required': true,
        'approval_required': true,
        'description': 'Requires business verification and admin approval',
      },
      'customer_to_vendor': {
        'verification_required': true,
        'business_registration_required': true,
        'approval_required': true,
        'description': 'Requires business registration and admin approval',
      },
      'customer_to_driver': {
        'verification_required': true,
        'vehicle_info_required': true,
        'approval_required': false,
        'description': 'Requires identity verification and vehicle information',
      },
      'driver_to_vendor': {
        'verification_required': true,
        'business_registration_required': true,
        'approval_required': true,
        'description': 'Requires business registration and admin approval',
      },
      'driver_to_sales_agent': {
        'verification_required': true,
        'business_info_required': true,
        'approval_required': true,
        'description': 'Requires business verification and admin approval',
      },
      'sales_agent_to_vendor': {
        'verification_required': true,
        'business_registration_required': true,
        'approval_required': true,
        'description': 'Requires business registration and admin approval',
      },
      'sales_agent_to_admin': {
        'verification_required': true,
        'approval_required': true,
        'special_approval_required': true,
        'description': 'Requires special admin approval and verification',
      },
      'vendor_to_admin': {
        'verification_required': true,
        'approval_required': true,
        'special_approval_required': true,
        'description': 'Requires special admin approval and verification',
      },
    };

    final key = '${fromRole}_to_$toRole';
    return requirements[key] ?? {
      'verification_required': true,
      'approval_required': true,
      'description': 'Standard role transition requirements apply',
    };
  }
}
