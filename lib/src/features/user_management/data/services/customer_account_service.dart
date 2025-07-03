import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: Restore when customer_account_models is implemented
// import '../models/customer_account_models.dart';
import '../../../user_management/domain/user.dart' as app_user;
import '../../../../data/models/user_role.dart';

/// Service for managing customer account linking and invitations
class CustomerAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create invitation for customer to join the app
  // TODO: Restore when CustomerInvitationResult is implemented
  Future<dynamic> createCustomerInvitation({
    required String customerId,
    required String salesAgentId,
  }) async {
    try {
      debugPrint('CustomerAccountService: Creating invitation for customer: $customerId');

      final response = await _supabase.rpc('create_customer_invitation', params: {
        'p_customer_id': customerId,
        'p_sales_agent_id': salesAgentId,
      });

      if (response != null && response.isNotEmpty) {
        final result = response[0];
        final success = result['success'] as bool;
        
        if (success) {
          // TODO: Restore when CustomerInvitationResult is implemented
          // return CustomerInvitationResult.success(
          //   token: result['token'] as String,
          //   expiresAt: DateTime.parse(result['expires_at'] as String),
          //   message: result['message'] as String,
          // );
          return {'success': true, 'data': result}; // Placeholder
        } else {
          // TODO: Restore when CustomerInvitationResult is implemented
          // return CustomerInvitationResult.failure(result['message'] as String);
          return {'success': false, 'error': result['message'] as String}; // Placeholder
        }
      }

      // TODO: Restore when CustomerInvitationResult is implemented
      // return CustomerInvitationResult.failure('Failed to create invitation');
      return {'success': false, 'error': 'Failed to create invitation'}; // Placeholder
    } catch (e) {
      debugPrint('CustomerAccountService: Error creating invitation: $e');
      // TODO: Restore when CustomerInvitationResult is implemented
      // return CustomerInvitationResult.failure('Error creating invitation: ${e.toString()}');
      return {'success': false, 'error': 'Error creating invitation: ${e.toString()}'}; // Placeholder
    }
  }

  /// Validate invitation token and get customer details
  // TODO: Restore when InvitationValidationResult is implemented
  Future<dynamic> validateInvitationToken(String token) async {
    try {
      debugPrint('CustomerAccountService: Validating invitation token');

      final response = await _supabase.rpc('validate_invitation_token', params: {
        'p_token': token,
      });

      if (response != null && response.isNotEmpty) {
        final result = response[0];
        final valid = result['valid'] as bool;
        
        if (valid) {
          // TODO: Restore when InvitationValidationResult is implemented
          // return InvitationValidationResult.success(
          //   customerId: result['customer_id'] as String,
          //   customerEmail: result['customer_email'] as String,
          //   customerName: result['customer_name'] as String,
          //   expiresAt: DateTime.parse(result['expires_at'] as String),
          // );
          return {'success': true, 'data': result}; // Placeholder
        } else {
          // TODO: Restore when InvitationValidationResult is implemented
          // return InvitationValidationResult.failure(result['message'] as String);
          return {'success': false, 'error': result['message'] as String}; // Placeholder
        }
      }

      // TODO: Restore when InvitationValidationResult is implemented
      // return InvitationValidationResult.failure('Invalid invitation token');
      return {'success': false, 'error': 'Invalid invitation token'}; // Placeholder
    } catch (e) {
      debugPrint('CustomerAccountService: Error validating token: $e');
      // TODO: Restore when InvitationValidationResult is implemented
      // return InvitationValidationResult.failure('Error validating token: ${e.toString()}');
      return {'success': false, 'error': 'Error validating token: ${e.toString()}'}; // Placeholder
    }
  }

  /// Create customer account using invitation token
  // TODO: Restore when CustomerAccountCreationResult is implemented
  Future<dynamic> createCustomerAccount({
    required String invitationToken,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      debugPrint('CustomerAccountService: Creating customer account with invitation');

      // First validate the invitation token
      final validationResult = await validateInvitationToken(invitationToken);
      if (!validationResult['success']) {
        // TODO: Restore when CustomerAccountCreationResult is implemented
        // return CustomerAccountCreationResult.failure(validationResult.message);
        return {'success': false, 'error': validationResult['error']}; // Placeholder
      }

      // Create auth user using Supabase directly
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'customer',
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
        emailRedirectTo: 'gigaeats://auth/callback',
      );

      if (authResponse.user == null) {
        // TODO: Restore when CustomerAccountCreationResult is implemented
        // return CustomerAccountCreationResult.failure('Failed to create user account');
        return {'success': false, 'error': 'Failed to create user account'}; // Placeholder
      }

      // Link customer to auth user
      final linkResult = await linkCustomerToAuthUser(
        customerId: validationResult.customerId!,
        authUserId: authResponse.user!.id,
        invitationToken: invitationToken,
      );

      if (!linkResult['success']) {
        // If linking fails, we should clean up the auth user
        // Note: In production, you might want to implement a cleanup mechanism
        // TODO: Restore when CustomerAccountCreationResult is implemented
        // return CustomerAccountCreationResult.failure(linkResult.message);
        return {'success': false, 'error': linkResult['error']}; // Placeholder
      }

      // Create a User object from the auth response
      final user = app_user.User(
        id: authResponse.user!.id,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: UserRole.customer,
        isVerified: authResponse.user!.emailConfirmedAt != null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Restore when CustomerAccountCreationResult is implemented
      // return CustomerAccountCreationResult.success(
      //   user: user,
      //   customerProfileId: linkResult.customerProfileId!,
      //   message: 'Customer account created successfully',
      // );
      return {'success': true, 'data': {'user': user, 'customerProfileId': linkResult['data']['customer_profile_id']}}; // Placeholder
    } catch (e) {
      debugPrint('CustomerAccountService: Error creating customer account: $e');
      // TODO: Restore when CustomerAccountCreationResult is implemented
      // return CustomerAccountCreationResult.failure('Error creating account: ${e.toString()}');
      return {'success': false, 'error': 'Error creating account: ${e.toString()}'}; // Placeholder
    }
  }

  /// Link existing customer to auth user
  // TODO: Restore when CustomerLinkingResult is implemented
  // Future<CustomerLinkingResult> linkCustomerToAuthUser({
  Future<Map<String, dynamic>> linkCustomerToAuthUser({
    required String customerId,
    required String authUserId,
    String? invitationToken,
  }) async {
    try {
      debugPrint('CustomerAccountService: Linking customer $customerId to auth user $authUserId');

      final response = await _supabase.rpc('link_customer_to_auth_user', params: {
        'p_customer_id': customerId,
        'p_auth_user_id': authUserId,
        if (invitationToken != null) 'p_invitation_token': invitationToken,
      });

      if (response != null && response.isNotEmpty) {
        final result = response[0];
        final success = result['success'] as bool;
        
        if (success) {
          // TODO: Restore when CustomerLinkingResult is implemented
          // return CustomerLinkingResult.success(
          //   customerProfileId: result['customer_profile_id'] as String,
          //   message: result['message'] as String,
          // );
          return {'success': true, 'data': result}; // Placeholder
        } else {
          // TODO: Restore when CustomerLinkingResult is implemented
          // return CustomerLinkingResult.failure(result['message'] as String);
          return {'success': false, 'error': result['message'] as String}; // Placeholder
        }
      }

      // TODO: Restore when CustomerLinkingResult is implemented
      // return CustomerLinkingResult.failure('Failed to link customer to account');
      return {'success': false, 'error': 'Failed to link customer to account'}; // Placeholder
    } catch (e) {
      debugPrint('CustomerAccountService: Error linking customer: $e');
      // TODO: Restore when CustomerLinkingResult is implemented
      // return CustomerLinkingResult.failure('Error linking customer: ${e.toString()}');
      return {'success': false, 'error': 'Error linking customer: ${e.toString()}'}; // Placeholder
    }
  }

  /// Get customer invitation status
  // TODO: Restore when CustomerInvitation is implemented
  // Future<List<CustomerInvitation>> getCustomerInvitations({
  Future<List<Map<String, dynamic>>> getCustomerInvitations({
    required String salesAgentId,
    bool activeOnly = true,
  }) async {
    try {
      debugPrint('CustomerAccountService: Getting invitations for sales agent: $salesAgentId');

      var query = _supabase
          .from('customer_invitation_tokens')
          .select('''
            id,
            customer_id,
            token,
            email,
            expires_at,
            used_at,
            created_at,
            customers!inner(
              id,
              organization_name,
              contact_person_name,
              email
            )
          ''')
          .eq('invited_by', salesAgentId)
          .order('created_at', ascending: false);

      if (activeOnly) {
        // For now, we'll filter in the application layer
        // TODO: Fix Supabase query filtering once we determine the correct method
      }

      final response = await query;

      // TODO: Restore when CustomerInvitation is implemented
      // var invitations = response.map((json) => CustomerInvitation.fromJson(json)).toList();
      var invitations = response.cast<Map<String, dynamic>>(); // Placeholder

      // Apply active filter in application layer if needed
      if (activeOnly) {
        final now = DateTime.now();
        invitations = invitations.where((invitation) {
          // TODO: Restore when CustomerInvitation properties are available
          // invitation.expiresAt.isAfter(now) && !invitation.isUsed
          final expiresAt = invitation['expires_at'] != null
              ? DateTime.parse(invitation['expires_at'] as String)
              : null;
          final isUsed = invitation['is_used'] as bool? ?? false;
          return expiresAt?.isAfter(now) == true && !isUsed;
        }).toList();
      }

      return invitations;
    } catch (e) {
      debugPrint('CustomerAccountService: Error getting invitations: $e');
      return [];
    }
  }

  /// Check if customer has app account
  Future<bool> customerHasAppAccount(String customerId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('user_id')
          .eq('id', customerId)
          .single();

      return response['user_id'] != null;
    } catch (e) {
      debugPrint('CustomerAccountService: Error checking customer account: $e');
      return false;
    }
  }
}
