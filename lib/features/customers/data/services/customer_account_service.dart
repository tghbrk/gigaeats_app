import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_account_models.dart';
import '../../../../data/models/user.dart' as app_user;
import '../../../../data/models/user_role.dart';

/// Service for managing customer account linking and invitations
class CustomerAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create invitation for customer to join the app
  Future<CustomerInvitationResult> createCustomerInvitation({
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
          return CustomerInvitationResult.success(
            token: result['token'] as String,
            expiresAt: DateTime.parse(result['expires_at'] as String),
            message: result['message'] as String,
          );
        } else {
          return CustomerInvitationResult.failure(result['message'] as String);
        }
      }

      return CustomerInvitationResult.failure('Failed to create invitation');
    } catch (e) {
      debugPrint('CustomerAccountService: Error creating invitation: $e');
      return CustomerInvitationResult.failure('Error creating invitation: ${e.toString()}');
    }
  }

  /// Validate invitation token and get customer details
  Future<InvitationValidationResult> validateInvitationToken(String token) async {
    try {
      debugPrint('CustomerAccountService: Validating invitation token');

      final response = await _supabase.rpc('validate_invitation_token', params: {
        'p_token': token,
      });

      if (response != null && response.isNotEmpty) {
        final result = response[0];
        final valid = result['valid'] as bool;
        
        if (valid) {
          return InvitationValidationResult.success(
            customerId: result['customer_id'] as String,
            customerEmail: result['customer_email'] as String,
            customerName: result['customer_name'] as String,
            expiresAt: DateTime.parse(result['expires_at'] as String),
          );
        } else {
          return InvitationValidationResult.failure(result['message'] as String);
        }
      }

      return InvitationValidationResult.failure('Invalid invitation token');
    } catch (e) {
      debugPrint('CustomerAccountService: Error validating token: $e');
      return InvitationValidationResult.failure('Error validating token: ${e.toString()}');
    }
  }

  /// Create customer account using invitation token
  Future<CustomerAccountCreationResult> createCustomerAccount({
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
      if (!validationResult.success) {
        return CustomerAccountCreationResult.failure(validationResult.message);
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
        return CustomerAccountCreationResult.failure('Failed to create user account');
      }

      // Link customer to auth user
      final linkResult = await linkCustomerToAuthUser(
        customerId: validationResult.customerId!,
        authUserId: authResponse.user!.id,
        invitationToken: invitationToken,
      );

      if (!linkResult.success) {
        // If linking fails, we should clean up the auth user
        // Note: In production, you might want to implement a cleanup mechanism
        return CustomerAccountCreationResult.failure(linkResult.message);
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

      return CustomerAccountCreationResult.success(
        user: user,
        customerProfileId: linkResult.customerProfileId!,
        message: 'Customer account created successfully',
      );
    } catch (e) {
      debugPrint('CustomerAccountService: Error creating customer account: $e');
      return CustomerAccountCreationResult.failure('Error creating account: ${e.toString()}');
    }
  }

  /// Link existing customer to auth user
  Future<CustomerLinkingResult> linkCustomerToAuthUser({
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
          return CustomerLinkingResult.success(
            customerProfileId: result['customer_profile_id'] as String,
            message: result['message'] as String,
          );
        } else {
          return CustomerLinkingResult.failure(result['message'] as String);
        }
      }

      return CustomerLinkingResult.failure('Failed to link customer to account');
    } catch (e) {
      debugPrint('CustomerAccountService: Error linking customer: $e');
      return CustomerLinkingResult.failure('Error linking customer: ${e.toString()}');
    }
  }

  /// Get customer invitation status
  Future<List<CustomerInvitation>> getCustomerInvitations({
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

      var invitations = response.map((json) => CustomerInvitation.fromJson(json)).toList();

      // Apply active filter in application layer if needed
      if (activeOnly) {
        final now = DateTime.now();
        invitations = invitations.where((invitation) =>
          invitation.expiresAt.isAfter(now) && !invitation.isUsed
        ).toList();
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
