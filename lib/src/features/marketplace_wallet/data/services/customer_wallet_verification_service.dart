import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/customer_wallet_verification.dart';
import 'customer_document_ai_verification_service.dart';
import '../../../../data/models/wallet_verification_document.dart';

/// Service for handling customer wallet verification operations
class CustomerWalletVerificationService {
  final SupabaseService _supabaseService;
  final CustomerDocumentAIVerificationService _aiService;

  CustomerWalletVerificationService(this._supabaseService)
    : _aiService = CustomerDocumentAIVerificationService();

  /// Get current verification status for a customer
  Future<CustomerWalletVerification> getVerificationStatus(String userId) async {
    debugPrint('🔍 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Getting verification status for user: $userId');

    try {
      // Check wallet verification status
      final walletResponse = await _supabaseService.client
          .from('stakeholder_wallets')
          .select('is_verified, verification_documents, updated_at')
          .eq('user_id', userId)
          .eq('user_role', 'customer')
          .maybeSingle();

      // Check bank account verification status
      final bankAccountResponse = await _supabaseService.client
          .from('customer_bank_accounts')
          .select('id, verification_status, verification_method, created_at, updated_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Wallet data: $walletResponse');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Bank account data: $bankAccountResponse');

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

      return CustomerWalletVerification(
        status: status,
        currentStep: currentStep,
        totalSteps: 3,
        lastUpdated: lastUpdated,
        canRetry: canRetry,
        data: data,
      );
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error getting verification status: $e');
      rethrow;
    }
  }

  /// Initiate unified verification with AI data extraction
  Future<Map<String, dynamic>> initiateUnifiedVerification({
    required String userId,
    required Map<String, dynamic> bankDetails,
    required Map<String, dynamic> documents,
    Map<String, dynamic>? instantVerificationDetails,
  }) async {
    debugPrint('🚀 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Starting unified verification with AI integration');
    debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Bank: ${bankDetails['bankName']}');
    debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Account: ${bankDetails['accountNumber']}');
    debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Instant verification: ${instantVerificationDetails != null ? 'included' : 'not included'}');

    try {
      // Validate required documents
      if (documents['icFrontImage'] == null || documents['icBackImage'] == null) {
        throw Exception('Both IC front and back images are required for unified verification');
      }

      // Process AI data extraction if instant verification is enabled
      Map<String, dynamic>? aiExtractedData;
      if (instantVerificationDetails != null &&
          instantVerificationDetails['enabled'] == true &&
          instantVerificationDetails['extractionMethod'] == 'ai_vision') {

        debugPrint('🤖 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Processing AI data extraction...');
        aiExtractedData = await _processAIDataExtraction(
          userId: userId,
          icFrontImage: documents['icFrontImage'],
          icBackImage: documents['icBackImage'],
          instantVerificationDetails: instantVerificationDetails,
        );
      }

      // Convert XFile documents to base64 for API transmission
      debugPrint('📄 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Converting documents to base64...');
      final icFrontImage = await _convertXFileToBase64(documents['icFrontImage']);
      final icBackImage = await _convertXFileToBase64(documents['icBackImage']);

      // Prepare verification payload
      final verificationPayload = {
        'action': 'initiate_verification',
        'verification_method': 'unified_verification',
        'user_role': 'customer',
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
          'initiated_from': 'customer_unified_verification_flow',
          'client_version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Add instant verification details if provided
      if (instantVerificationDetails != null) {
        if (aiExtractedData != null) {
          // Use AI-extracted data
          verificationPayload['instant_verification'] = {
            'ic_number': aiExtractedData['icNumber'],
            'full_name': aiExtractedData['fullName'],
            'verification_type': 'ai_extracted_kyc',
            'extraction_confidence': aiExtractedData['confidence'],
            'extraction_method': 'gemini_vision_ai',
            'extracted_at': aiExtractedData['extractedAt'],
          };
          debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] AI-extracted IC Number: ${aiExtractedData['icNumber']?.replaceAll(RegExp(r'\d'), '*')}');
          debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] AI-extracted Full Name: [EXTRACTED]');
          debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Extraction Confidence: ${(aiExtractedData['confidence'] * 100).toInt()}%');
        } else if (instantVerificationDetails['hasExtractedData'] == true) {
          // Use pre-extracted data from form
          final extractedData = instantVerificationDetails['extractedData'];
          verificationPayload['instant_verification'] = {
            'ic_number': extractedData['icNumber'],
            'full_name': extractedData['fullName'],
            'verification_type': 'pre_extracted_kyc',
            'extraction_confidence': extractedData['confidence'],
            'extraction_method': 'gemini_vision_ai',
            'extracted_at': extractedData['extractedAt'],
          };
          debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Pre-extracted IC Number: ${extractedData['icNumber']?.replaceAll(RegExp(r'\d'), '*')}');
          debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Pre-extracted Full Name: [EXTRACTED]');
        } else {
          // Fallback for manual verification (should not happen with new flow)
          verificationPayload['instant_verification'] = {
            'verification_type': 'manual_kyc_pending',
            'extraction_method': 'ai_vision_pending',
          };
          debugPrint('⚠️ [CUSTOMER-WALLET-VERIFICATION-SERVICE] No AI-extracted data available, verification pending');
        }
      }

      debugPrint('🔗 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Calling Edge Function...');
      final response = await _callEdgeFunctionWithRetry(
        'customer-wallet-verification',
        verificationPayload,
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Unified verification initiated');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Response status: ${response.status}');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Response data: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] ?? response.data;
      } else {
        final errorMessage = response.data?['error'] ?? 'Unified verification initiation failed';
        final errorCode = response.data?['error_code'] ?? 'UNKNOWN_ERROR';
        debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Edge Function error: $errorMessage (Code: $errorCode)');
        throw Exception('$errorMessage (Code: $errorCode)');
      }
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error initiating unified verification: $e');

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
    debugPrint('🔍 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Getting unified verification status');
    debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Account ID: $accountId');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'customer-wallet-verification',
        {
          'action': 'get_verification_status',
          'account_id': accountId,
          'user_role': 'customer',
        },
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Verification status retrieved');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Status: ${response.data}');

      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error getting verification status: $e');
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

      debugPrint('📄 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Converted file to base64: ${xFile.name}');
      return base64String;
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error converting file to base64: $e');
      rethrow;
    }
  }

  /// Call Edge Function with automatic token refresh on 401 errors
  Future<dynamic> _callEdgeFunctionWithRetry(String functionName, Map<String, dynamic> body) async {
    try {
      debugPrint('🔗 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Calling Edge Function: $functionName');

      // First attempt
      final response = await _supabaseService.client.functions.invoke(
        functionName,
        body: body,
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Edge Function call successful');
      return response;
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Edge Function call failed: $e');

      // Check if it's a 401 authentication error
      if (e.toString().contains('401') || e.toString().contains('Invalid JWT') || e.toString().contains('Unauthorized')) {
        debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Detected authentication error, attempting token refresh...');

        try {
          // Attempt to refresh the session
          await _supabaseService.client.auth.refreshSession();
          debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Session refreshed successfully');

          // Retry the Edge Function call
          debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Retrying Edge Function call after token refresh...');
          final retryResponse = await _supabaseService.client.functions.invoke(
            functionName,
            body: body,
          );

          debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Edge Function retry successful');
          return retryResponse;
        } catch (refreshError) {
          debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Token refresh failed: $refreshError');
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
    debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Resending verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'customer-wallet-verification',
        {
          'action': 'resend',
          'account_id': accountId,
          'user_role': 'customer',
        },
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Verification resent');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      return response.data ?? {};
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error resending verification: $e');
      rethrow;
    }
  }

  /// Start bank account verification only
  Future<Map<String, dynamic>> initiateBankAccountVerification({
    required String userId,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
    String? icNumber,
  }) async {
    debugPrint('🚀 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Initiating bank account verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'customer-wallet-verification',
        {
          'action': 'initiate_verification',
          'verification_method': 'bank_account',
          'user_role': 'customer',
          'bank_details': {
            'bank_code': bankCode,
            'account_number': accountNumber,
            'account_holder_name': accountHolderName,
            'account_type': 'savings',
          },
          'metadata': {
            'initiated_from': 'customer_bank_verification_flow',
            'client_version': '1.0.0',
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Bank account verification initiated');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] ?? response.data;
      } else {
        final errorMessage = response.data?['error'] ?? 'Bank account verification initiation failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error initiating bank account verification: $e');
      rethrow;
    }
  }

  /// Start document verification only
  Future<Map<String, dynamic>> initiateDocumentVerification({
    required String userId,
    required String icNumber,
    required String icFrontImage,
    required String icBackImage,
    required String selfieImage,
    String? bankStatement,
  }) async {
    debugPrint('🚀 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Starting document verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'customer-wallet-verification',
        {
          'action': 'initiate_verification',
          'verification_method': 'document',
          'user_role': 'customer',
          'identity_documents': {
            'ic_number': icNumber,
            'ic_front_image': icFrontImage,
            'ic_back_image': icBackImage,
            'selfie_image': selfieImage,
            'bank_statement': bankStatement,
            'verification_type': 'document_kyc',
          },
          'metadata': {
            'initiated_from': 'customer_document_verification_flow',
            'client_version': '1.0.0',
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Document verification initiated');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] ?? response.data;
      } else {
        final errorMessage = response.data?['error'] ?? 'Document verification initiation failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error initiating document verification: $e');
      rethrow;
    }
  }

  /// Start instant verification only
  Future<Map<String, dynamic>> initiateInstantVerification({
    required String userId,
    required String icNumber,
    required String fullName,
  }) async {
    debugPrint('🚀 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Starting instant verification');

    try {
      final response = await _callEdgeFunctionWithRetry(
        'customer-wallet-verification',
        {
          'action': 'initiate_verification',
          'verification_method': 'instant',
          'user_role': 'customer',
          'instant_verification': {
            'ic_number': icNumber,
            'full_name': fullName,
            'verification_type': 'instant_kyc',
          },
          'metadata': {
            'initiated_from': 'customer_instant_verification_flow',
            'client_version': '1.0.0',
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Instant verification initiated');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Response: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] ?? response.data;
      } else {
        final errorMessage = response.data?['error'] ?? 'Instant verification initiation failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Error initiating instant verification: $e');
      rethrow;
    }
  }

  /// Process AI data extraction from IC images
  Future<Map<String, dynamic>?> _processAIDataExtraction({
    required String userId,
    required XFile icFrontImage,
    required XFile icBackImage,
    required Map<String, dynamic> instantVerificationDetails,
  }) async {
    debugPrint('🤖 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Starting AI data extraction process');

    try {
      // Check if data is already extracted from the form
      if (instantVerificationDetails['hasExtractedData'] == true) {
        final extractedData = instantVerificationDetails['extractedData'];
        debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Using pre-extracted data from form');
        return {
          'icNumber': extractedData['icNumber'],
          'fullName': extractedData['fullName'],
          'confidence': extractedData['confidence'],
          'extractedAt': extractedData['extractedAt'],
          'source': 'form_pre_extracted',
        };
      }

      // If no pre-extracted data, process with AI service
      debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Processing documents with AI service...');

      // Generate a temporary verification ID for document processing
      final verificationId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      try {
        // Upload IC front image
        debugPrint('📤 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Uploading IC front image...');
        final frontUploadResult = await _aiService.uploadVerificationDocument(
          customerId: userId,
          userId: userId,
          verificationId: verificationId,
          documentType: DocumentType.icCard,
          documentFile: icFrontImage,
          documentSide: 'front',
        );

        if (!frontUploadResult.isSuccess) {
          throw Exception('Failed to upload IC front image: ${frontUploadResult.errorMessage}');
        }

        // Upload IC back image
        debugPrint('📤 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Uploading IC back image...');
        final backUploadResult = await _aiService.uploadVerificationDocument(
          customerId: userId,
          userId: userId,
          verificationId: verificationId,
          documentType: DocumentType.icCard,
          documentFile: icBackImage,
          documentSide: 'back',
        );

        if (!backUploadResult.isSuccess) {
          throw Exception('Failed to upload IC back image: ${backUploadResult.errorMessage}');
        }

        // Extract IC data using AI
        debugPrint('🤖 [CUSTOMER-WALLET-VERIFICATION-SERVICE] Extracting IC data with AI...');
        final extractionResult = await _aiService.extractICData(
          frontDocumentId: frontUploadResult.documentId!,
          backDocumentId: backUploadResult.documentId!,
          verificationId: verificationId,
        );

        if (!extractionResult.isSuccess) {
          throw Exception('AI extraction failed: ${extractionResult.errorMessage}');
        }

        debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-SERVICE] AI extraction completed successfully');
        return {
          'icNumber': extractionResult.icNumber,
          'fullName': extractionResult.fullName,
          'confidence': extractionResult.overallConfidence,
          'extractedAt': DateTime.now().toIso8601String(),
          'source': 'ai_service_extracted',
          'frontDocumentId': frontUploadResult.documentId,
          'backDocumentId': backUploadResult.documentId,
        };

      } catch (aiError) {
        debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] AI processing failed: $aiError');
        // Return null to allow fallback to manual processing
        return null;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] AI data extraction failed: $e');
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-SERVICE] Stack trace: $stackTrace');

      // Don't throw error, just return null to allow fallback
      return null;
    }
  }
}
