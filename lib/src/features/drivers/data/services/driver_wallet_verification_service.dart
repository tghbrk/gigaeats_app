import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/driver_wallet_verification.dart';

/// Service for handling driver wallet verification operations
class DriverWalletVerificationService {
  final SupabaseService _supabaseService;

  DriverWalletVerificationService(this._supabaseService);

  /// Get current verification status for a driver
  Future<DriverWalletVerification> getVerificationStatus(String userId) async {
    debugPrint('🔍 [WALLET-VERIFICATION-SERVICE] Getting verification status for user: $userId');

    try {
      // Check wallet verification status
      final walletResponse = await _supabaseService.client
          .from('stakeholder_wallets')
          .select('is_verified, verification_documents, updated_at')
          .eq('user_id', userId)
          .eq('user_role', 'driver')
          .maybeSingle();

      // Check bank account verification status
      final bankAccountResponse = await _supabaseService.client
          .from('driver_bank_accounts')
          .select('id, verification_status, verification_method, created_at, updated_at')
          .eq('driver_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Wallet data: $walletResponse');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Bank account data: $bankAccountResponse');

      // Determine verification status and progress
      String status = 'unverified';
      int? currentStep;
      bool canRetry = true;
      Map<String, dynamic>? data;

      if (walletResponse?['is_verified'] == true) {
        status = 'verified';
        currentStep = 3;
        canRetry = false;
      } else if (bankAccountResponse != null) {
        final bankStatus = bankAccountResponse['verification_status'];
        switch (bankStatus) {
          case 'pending':
            status = 'pending';
            currentStep = 2;
            break;
          case 'verified':
            status = 'verified';
            currentStep = 3;
            canRetry = false;
            break;
          case 'failed':
            status = 'failed';
            currentStep = 1;
            canRetry = true;
            break;
          default:
            status = 'unverified';
            currentStep = 1;
        }
        data = bankAccountResponse;
      }

      final lastUpdated = walletResponse?['updated_at'] != null
          ? DateTime.parse(walletResponse!['updated_at'])
          : bankAccountResponse?['updated_at'] != null
              ? DateTime.parse(bankAccountResponse!['updated_at'])
              : null;

      return DriverWalletVerification(
        status: status,
        currentStep: currentStep,
        totalSteps: 3,
        lastUpdated: lastUpdated,
        canRetry: canRetry,
        data: data,
      );
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error getting verification status: $e');
      rethrow;
    }
  }

  /// Initiate bank account verification
  Future<Map<String, dynamic>> initiateBankAccountVerification({
    required String userId,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
    String? icNumber,
  }) async {
    debugPrint('🚀 [WALLET-VERIFICATION-SERVICE] Initiating bank account verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'bank-account-verification',
        {
          'action': 'initiate',
          'bank_details': {
            'bank_code': bankCode,
            'account_number': accountNumber,
            'account_holder_name': accountHolderName,
          },
          'verification_method': 'micro_deposit',
          if (icNumber != null)
            'identity_documents': {
              'ic_number': icNumber,
            },
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Bank account verification initiated');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      } else {
        throw Exception(response.data['error'] ?? 'Verification initiation failed');
      }
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error initiating bank account verification: $e');
      rethrow;
    }
  }

  /// Submit micro deposit verification
  Future<Map<String, dynamic>> submitMicroDepositVerification({
    required String userId,
    required String accountId,
    required List<double> amounts,
  }) async {
    debugPrint('🔍 [WALLET-VERIFICATION-SERVICE] Submitting micro deposit verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'bank-account-verification',
        {
          'action': 'submit',
          'account_id': accountId,
          'verification_amounts': amounts,
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Micro deposit verification submitted');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error submitting micro deposit verification: $e');
      rethrow;
    }
  }

  /// Initiate document verification
  Future<Map<String, dynamic>> initiateDocumentVerification({
    required String userId,
    required String icNumber,
    required String icFrontImage,
    required String icBackImage,
    required String selfieImage,
    String? bankStatement,
  }) async {
    debugPrint('🚀 [WALLET-VERIFICATION-SERVICE] Initiating document verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'bank-account-verification',
        {
          'action': 'initiate',
          'verification_method': 'document_verification',
          'identity_documents': {
            'ic_number': icNumber,
            'ic_front_image': icFrontImage,
            'ic_back_image': icBackImage,
            'selfie_image': selfieImage,
            if (bankStatement != null) 'bank_statement': bankStatement,
          },
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Document verification initiated');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      } else {
        throw Exception(response.data['error'] ?? 'Document verification initiation failed');
      }
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error initiating document verification: $e');
      rethrow;
    }
  }

  /// Initiate instant verification
  Future<Map<String, dynamic>> initiateInstantVerification({
    required String userId,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
    required String icNumber,
  }) async {
    debugPrint('🚀 [WALLET-VERIFICATION-SERVICE] Initiating instant verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'bank-account-verification',
        {
          'action': 'initiate',
          'bank_details': {
            'bank_code': bankCode,
            'account_number': accountNumber,
            'account_holder_name': accountHolderName,
          },
          'verification_method': 'instant_verification',
          'identity_documents': {
            'ic_number': icNumber,
          },
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Instant verification initiated');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      } else {
        throw Exception(response.data['error'] ?? 'Instant verification initiation failed');
      }
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error initiating instant verification: $e');
      rethrow;
    }
  }

  /// Initiate unified verification (combines bank account and document verification)
  Future<Map<String, dynamic>> initiateUnifiedVerification({
    required String userId,
    required Map<String, dynamic> bankDetails,
    required Map<String, dynamic> documents,
  }) async {
    debugPrint('🚀 [WALLET-VERIFICATION-SERVICE] Starting unified verification');
    debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Bank: ${bankDetails['bankName']}');
    debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Account: ${bankDetails['accountNumber']}');

    try {
      // Validate required documents
      if (documents['icFrontImage'] == null || documents['icBackImage'] == null) {
        throw Exception('Both IC front and back images are required for unified verification');
      }

      // Convert XFile documents to base64 for API transmission
      debugPrint('📄 [WALLET-VERIFICATION-SERVICE] Converting documents to base64...');
      final icFrontImage = await _convertXFileToBase64(documents['icFrontImage']);
      final icBackImage = await _convertXFileToBase64(documents['icBackImage']);

      debugPrint('🔗 [WALLET-VERIFICATION-SERVICE] Calling Edge Function...');
      final response = await _callEdgeFunctionWithRetry(
        'bank-account-verification',
        {
          'action': 'initiate_verification',
          'verification_method': 'unified_verification',
          'bank_details': {
            'bank_code': bankDetails['bankCode'],
            'bank_name': bankDetails['bankName'],
            'account_number': bankDetails['accountNumber'],
            'account_holder_name': bankDetails['accountHolderName'],
            'account_type': 'savings', // Default to savings account
          },
          'identity_documents': {
            'ic_front_image': icFrontImage,
            'ic_back_image': icBackImage,
            'verification_type': 'unified_kyc',
          },
          'metadata': {
            'initiated_from': 'unified_verification_flow',
            'client_version': '1.0.0',
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Unified verification initiated');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Response status: ${response.status}');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Response data: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] ?? response.data;
      } else {
        final errorMessage = response.data?['error'] ?? 'Unified verification initiation failed';
        final errorCode = response.data?['error_code'] ?? 'UNKNOWN_ERROR';
        debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Edge Function error: $errorMessage (Code: $errorCode)');
        throw Exception('$errorMessage (Code: $errorCode)');
      }
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error initiating unified verification: $e');

      // Provide more specific error messages based on error type
      if (e.toString().contains('base64')) {
        throw Exception('Failed to process document images. Please ensure images are valid.');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw Exception('Network error. Please check your connection and try again.');
      } else if (e.toString().contains('auth')) {
        throw Exception('Authentication error. Please log in again.');
      }

      rethrow;
    }
  }

  /// Get unified verification status
  Future<Map<String, dynamic>> getUnifiedVerificationStatus({
    required String userId,
    required String accountId,
  }) async {
    debugPrint('🔍 [WALLET-VERIFICATION-SERVICE] Getting unified verification status');
    debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Account ID: $accountId');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'bank-account-verification',
        {
          'action': 'get_verification_status',
          'account_id': accountId,
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Verification status retrieved');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Status: ${response.data}');

      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error getting verification status: $e');
      rethrow;
    }
  }

  /// Convert XFile to base64 string for API transmission
  Future<String> _convertXFileToBase64(dynamic xFile) async {
    try {
      if (xFile == null) {
        throw Exception('File is null');
      }

      final bytes = await xFile.readAsBytes();
      final base64String = base64Encode(bytes);

      debugPrint('📄 [WALLET-VERIFICATION-SERVICE] Converted file to base64: ${xFile.name}');
      return base64String;
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error converting file to base64: $e');
      rethrow;
    }
  }

  /// Call Edge Function with automatic token refresh on 401 errors
  Future<dynamic> _callEdgeFunctionWithRetry(String functionName, Map<String, dynamic> body) async {
    try {
      debugPrint('🔗 [WALLET-VERIFICATION-SERVICE] Calling Edge Function: $functionName');

      // First attempt
      final response = await _supabaseService.client.functions.invoke(
        functionName,
        body: body,
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Edge Function call successful');
      return response;
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Edge Function call failed: $e');

      // Check if it's a 401 authentication error
      if (e.toString().contains('401') || e.toString().contains('Invalid JWT') || e.toString().contains('Unauthorized')) {
        debugPrint('🔄 [WALLET-VERIFICATION-SERVICE] Detected authentication error, attempting token refresh...');

        try {
          // Attempt to refresh the session
          await _supabaseService.client.auth.refreshSession();
          debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Session refreshed successfully');

          // Retry the Edge Function call
          debugPrint('🔄 [WALLET-VERIFICATION-SERVICE] Retrying Edge Function call after token refresh...');
          final retryResponse = await _supabaseService.client.functions.invoke(
            functionName,
            body: body,
          );

          debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Edge Function retry successful');
          return retryResponse;
        } catch (refreshError) {
          debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Token refresh failed: $refreshError');
          throw Exception('Authentication error. Please log in again.');
        }
      }

      // If it's not a 401 error, rethrow the original error
      rethrow;
    }
  }

  /// Resend verification (for micro deposits or documents)
  Future<Map<String, dynamic>> resendVerification({
    required String userId,
    required String accountId,
  }) async {
    debugPrint('🔄 [WALLET-VERIFICATION-SERVICE] Resending verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'bank-account-verification',
        {
          'action': 'resend',
          'account_id': accountId,
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-SERVICE] Verification resent');
      debugPrint('📊 [WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-SERVICE] Error resending verification: $e');
      rethrow;
    }
  }
}
