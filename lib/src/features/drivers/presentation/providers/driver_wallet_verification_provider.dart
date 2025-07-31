import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/driver_wallet_verification_service.dart';
import 'driver_wallet_provider.dart';

/// Provider for managing driver wallet verification state and operations
final driverWalletVerificationStateProvider = StateNotifierProvider<DriverWalletVerificationNotifier, DriverWalletVerificationState>((ref) {
  final authState = ref.watch(authStateProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);

  return DriverWalletVerificationNotifier(
    userId: authState.user?.id,
    verificationService: DriverWalletVerificationService(supabaseService),
    ref: ref, // Pass ref to the notifier
  );
});

/// Progress tracking for unified verification
class UnifiedVerificationProgress {
  final bool bankAccountSubmitted;
  final bool documentsSubmitted;
  final bool bankAccountVerified;
  final bool documentsVerified;
  final String? bankVerificationStatus; // 'pending', 'processing', 'verified', 'failed'
  final String? documentVerificationStatus; // 'pending', 'processing', 'verified', 'failed'
  final double overallProgress; // 0.0 to 1.0
  final List<String> completedSteps;
  final String? nextStep;
  final Map<String, dynamic>? processingDetails;

  const UnifiedVerificationProgress({
    this.bankAccountSubmitted = false,
    this.documentsSubmitted = false,
    this.bankAccountVerified = false,
    this.documentsVerified = false,
    this.bankVerificationStatus,
    this.documentVerificationStatus,
    this.overallProgress = 0.0,
    this.completedSteps = const [],
    this.nextStep,
    this.processingDetails,
  });

  UnifiedVerificationProgress copyWith({
    bool? bankAccountSubmitted,
    bool? documentsSubmitted,
    bool? bankAccountVerified,
    bool? documentsVerified,
    String? bankVerificationStatus,
    String? documentVerificationStatus,
    double? overallProgress,
    List<String>? completedSteps,
    String? nextStep,
    Map<String, dynamic>? processingDetails,
  }) {
    return UnifiedVerificationProgress(
      bankAccountSubmitted: bankAccountSubmitted ?? this.bankAccountSubmitted,
      documentsSubmitted: documentsSubmitted ?? this.documentsSubmitted,
      bankAccountVerified: bankAccountVerified ?? this.bankAccountVerified,
      documentsVerified: documentsVerified ?? this.documentsVerified,
      bankVerificationStatus: bankVerificationStatus ?? this.bankVerificationStatus,
      documentVerificationStatus: documentVerificationStatus ?? this.documentVerificationStatus,
      overallProgress: overallProgress ?? this.overallProgress,
      completedSteps: completedSteps ?? this.completedSteps,
      nextStep: nextStep ?? this.nextStep,
      processingDetails: processingDetails ?? this.processingDetails,
    );
  }

  /// Check if both bank account and documents are verified
  bool get isFullyVerified => bankAccountVerified && documentsVerified;

  /// Check if verification is in progress
  bool get isInProgress => (bankAccountSubmitted || documentsSubmitted) && !isFullyVerified;

  /// Get human-readable status message
  String get statusMessage {
    if (isFullyVerified) return 'Verification completed successfully';
    if (!bankAccountSubmitted && !documentsSubmitted) return 'Ready to start verification';
    if (bankAccountSubmitted && !documentsSubmitted) return 'Bank account submitted, documents pending';
    if (!bankAccountSubmitted && documentsSubmitted) return 'Documents submitted, bank account pending';
    if (bankAccountSubmitted && documentsSubmitted && !isFullyVerified) return 'Processing verification';
    return 'Verification in progress';
  }
}

/// State class for driver wallet verification with unified verification support
class DriverWalletVerificationState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final String status; // 'unverified', 'pending', 'verified', 'failed'
  final int? currentStep;
  final int totalSteps;
  final DateTime? lastUpdated;
  final bool canRetry;
  final Map<String, dynamic>? verificationData;

  // Unified verification specific fields
  final String? verificationMethod; // 'unified_verification', 'bank_account', 'document', 'instant'
  final UnifiedVerificationProgress? unifiedProgress;
  final String? accountId; // For tracking the verification account
  final Map<String, dynamic>? bankDetails;
  final Map<String, dynamic>? documentStatus;

  const DriverWalletVerificationState({
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.status = 'unverified',
    this.currentStep,
    this.totalSteps = 3,
    this.lastUpdated,
    this.canRetry = false,
    this.verificationData,
    this.verificationMethod,
    this.unifiedProgress,
    this.accountId,
    this.bankDetails,
    this.documentStatus,
  });

  DriverWalletVerificationState copyWith({
    bool? isLoading,
    bool? isProcessing,
    String? error,
    String? status,
    int? currentStep,
    int? totalSteps,
    DateTime? lastUpdated,
    bool? canRetry,
    Map<String, dynamic>? verificationData,
    String? verificationMethod,
    UnifiedVerificationProgress? unifiedProgress,
    String? accountId,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? documentStatus,
  }) {
    return DriverWalletVerificationState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      canRetry: canRetry ?? this.canRetry,
      verificationData: verificationData ?? this.verificationData,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      unifiedProgress: unifiedProgress ?? this.unifiedProgress,
      accountId: accountId ?? this.accountId,
      bankDetails: bankDetails ?? this.bankDetails,
      documentStatus: documentStatus ?? this.documentStatus,
    );
  }
}

/// Notifier for managing driver wallet verification operations
class DriverWalletVerificationNotifier extends StateNotifier<DriverWalletVerificationState> {
  final String? userId;
  final DriverWalletVerificationService verificationService;
  final Ref ref;

  DriverWalletVerificationNotifier({
    required this.userId,
    required this.verificationService,
    required this.ref,
  }) : super(const DriverWalletVerificationState());

  /// Load current verification status
  Future<void> loadVerificationStatus() async {
    if (userId == null) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] No user ID available');
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    debugPrint('🔍 [WALLET-VERIFICATION-PROVIDER] Loading verification status for user: $userId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final verificationStatus = await verificationService.getVerificationStatus(userId!);
      
      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Verification status loaded: ${verificationStatus.status}');
      
      state = state.copyWith(
        isLoading: false,
        status: verificationStatus.status,
        currentStep: verificationStatus.currentStep,
        totalSteps: verificationStatus.totalSteps,
        lastUpdated: verificationStatus.lastUpdated,
        canRetry: verificationStatus.canRetry,
        verificationData: verificationStatus.data,
      );
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error loading verification status: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load verification status: $e',
      );
    }
  }

  /// Start bank account verification
  Future<bool> startBankAccountVerification({
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
    String? icNumber,
  }) async {
    if (userId == null) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] No user ID available');
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    debugPrint('🚀 [WALLET-VERIFICATION-PROVIDER] Starting bank account verification');
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final result = await verificationService.initiateBankAccountVerification(
        userId: userId!,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        icNumber: icNumber,
      );

      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Bank account verification initiated');
      
      state = state.copyWith(
        isProcessing: false,
        status: 'pending',
        currentStep: 1,
        verificationData: result,
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error starting bank account verification: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to start verification: $e',
      );
      return false;
    }
  }

  /// Submit micro deposit verification
  Future<bool> submitMicroDepositVerification({
    required String accountId,
    required List<double> amounts,
  }) async {
    if (userId == null) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] No user ID available');
      return false;
    }

    debugPrint('🔍 [WALLET-VERIFICATION-PROVIDER] Submitting micro deposit verification');
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final result = await verificationService.submitMicroDepositVerification(
        userId: userId!,
        accountId: accountId,
        amounts: amounts,
      );

      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Micro deposit verification submitted');
      
      if (result['success'] == true) {
        state = state.copyWith(
          isProcessing: false,
          status: 'verified',
          currentStep: 3,
        );
        return true;
      } else {
        state = state.copyWith(
          isProcessing: false,
          error: result['error'] ?? 'Verification failed',
          canRetry: result['attempts_remaining'] > 0,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error submitting micro deposit verification: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to submit verification: $e',
      );
      return false;
    }
  }

  /// Start document verification
  Future<bool> startDocumentVerification({
    required String icNumber,
    required String icFrontImage,
    required String icBackImage,
    required String selfieImage,
    String? bankStatement,
  }) async {
    if (userId == null) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] No user ID available');
      return false;
    }

    debugPrint('🚀 [WALLET-VERIFICATION-PROVIDER] Starting document verification');
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final result = await verificationService.initiateDocumentVerification(
        userId: userId!,
        icNumber: icNumber,
        icFrontImage: icFrontImage,
        icBackImage: icBackImage,
        selfieImage: selfieImage,
        bankStatement: bankStatement,
      );

      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Document verification initiated');
      
      state = state.copyWith(
        isProcessing: false,
        status: 'pending',
        currentStep: 2,
        verificationData: result,
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error starting document verification: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to start document verification: $e',
      );
      return false;
    }
  }

  /// Start unified verification (combines bank account and document verification)
  Future<bool> startUnifiedVerification(Map<String, dynamic> verificationData) async {
    if (userId == null) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] No user ID available');
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    debugPrint('🚀 [WALLET-VERIFICATION-PROVIDER] Starting unified verification');

    // Initialize unified progress tracking
    final initialProgress = UnifiedVerificationProgress(
      overallProgress: 0.1,
      completedSteps: ['Initiated'],
      nextStep: 'Submitting verification data',
    );

    state = state.copyWith(
      isProcessing: true,
      error: null,
      verificationMethod: 'unified_verification',
      unifiedProgress: initialProgress,
    );

    try {
      final bankDetails = verificationData['bankDetails'] as Map<String, dynamic>;
      final documents = verificationData['documents'] as Map<String, dynamic>;

      debugPrint('📊 [WALLET-VERIFICATION-PROVIDER] Bank: ${bankDetails['bankName']}');
      debugPrint('📊 [WALLET-VERIFICATION-PROVIDER] Account: ${bankDetails['accountNumber']}');
      debugPrint('📊 [WALLET-VERIFICATION-PROVIDER] Documents: ${documents.keys.length} files provided');

      // Update progress - submitting data
      state = state.copyWith(
        unifiedProgress: state.unifiedProgress?.copyWith(
          overallProgress: 0.3,
          completedSteps: ['Initiated', 'Validating data'],
          nextStep: 'Submitting to verification service',
        ),
      );

      // Call the unified verification service
      final result = await verificationService.initiateUnifiedVerification(
        userId: userId!,
        bankDetails: bankDetails,
        documents: documents,
      );

      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Unified verification initiated');
      debugPrint('📊 [WALLET-VERIFICATION-PROVIDER] Service response: $result');

      // Update progress - submitted successfully
      final submittedProgress = UnifiedVerificationProgress(
        bankAccountSubmitted: true,
        documentsSubmitted: true,
        bankVerificationStatus: 'pending',
        documentVerificationStatus: 'pending',
        overallProgress: 0.6,
        completedSteps: ['Initiated', 'Data validated', 'Submitted for processing'],
        nextStep: 'Processing verification',
        processingDetails: result,
      );

      // Update state to show verification is in progress
      state = state.copyWith(
        isProcessing: false,
        status: 'pending',
        currentStep: 2,
        lastUpdated: DateTime.now(),
        verificationMethod: 'unified_verification',
        unifiedProgress: submittedProgress,
        accountId: result['account_id']?.toString(),
        bankDetails: bankDetails,
        documentStatus: {
          'ic_front_submitted': true,
          'ic_back_submitted': true,
          'processing_started': DateTime.now().toIso8601String(),
        },
        verificationData: {
          'method': 'unified_verification',
          'bank_details': bankDetails,
          'documents_submitted': true,
          'submitted_at': DateTime.now().toIso8601String(),
          'service_response': result,
        },
      );

      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Unified verification submitted successfully');

      // Start periodic status checking
      _startStatusPolling();

      return true;
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error starting unified verification: $e');

      // Update progress to show error
      final errorProgress = state.unifiedProgress?.copyWith(
        overallProgress: 0.0,
        completedSteps: ['Initiated', 'Error occurred'],
        nextStep: 'Retry verification',
      );

      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to start unified verification: $e',
        canRetry: true,
        unifiedProgress: errorProgress,
      );
      return false;
    }
  }

  /// Retry verification process
  Future<void> retryVerification() async {
    debugPrint('🔄 [WALLET-VERIFICATION-PROVIDER] Retrying verification');
    await loadVerificationStatus();
  }

  /// Reset verification state
  void resetState() {
    debugPrint('🔄 [WALLET-VERIFICATION-PROVIDER] Resetting verification state');
    state = const DriverWalletVerificationState();
  }

  /// Start periodic status polling for unified verification
  void _startStatusPolling() {
    if (state.accountId == null) {
      debugPrint('⚠️ [WALLET-VERIFICATION-PROVIDER] No account ID for status polling');
      return;
    }

    debugPrint('🔄 [WALLET-VERIFICATION-PROVIDER] Starting status polling for account: ${state.accountId}');

    // Poll every 10 seconds for status updates
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        // Stop polling if verification is complete or failed
        if (state.status == 'verified' || state.status == 'failed' || state.accountId == null) {
          debugPrint('🛑 [WALLET-VERIFICATION-PROVIDER] Stopping status polling - Status: ${state.status}');
          timer.cancel();
          return;
        }

        await _checkUnifiedVerificationStatus();
      } catch (e) {
        debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error during status polling: $e');
        // Continue polling despite errors
      }
    });
  }

  /// Check unified verification status
  Future<void> _checkUnifiedVerificationStatus() async {
    if (state.accountId == null || userId == null) return;

    try {
      debugPrint('🔍 [WALLET-VERIFICATION-PROVIDER] Checking verification status for account: ${state.accountId}');

      final statusResult = await verificationService.getUnifiedVerificationStatus(
        userId: userId!,
        accountId: state.accountId!,
      );

      debugPrint('📊 [WALLET-VERIFICATION-PROVIDER] Status result: $statusResult');

      // Update progress based on status
      final currentProgress = state.unifiedProgress ?? UnifiedVerificationProgress();
      UnifiedVerificationProgress updatedProgress;
      String newStatus = state.status;
      int newCurrentStep = state.currentStep ?? 2;

      if (statusResult['bank_verification_status'] == 'verified' &&
          statusResult['document_verification_status'] == 'verified') {
        // Both verifications complete
        updatedProgress = currentProgress.copyWith(
          bankAccountVerified: true,
          documentsVerified: true,
          bankVerificationStatus: 'verified',
          documentVerificationStatus: 'verified',
          overallProgress: 1.0,
          completedSteps: ['Initiated', 'Data validated', 'Submitted for processing', 'Bank verified', 'Documents verified', 'Verification complete'],
          nextStep: null,
          processingDetails: statusResult,
        );
        newStatus = 'verified';
        newCurrentStep = 3;

        // 🔄 CRITICAL FIX: Refresh wallet provider when verification is complete
        debugPrint('🎉 [WALLET-VERIFICATION-PROVIDER] Verification completed! Refreshing wallet state...');
        _refreshWalletProvider();
      } else if (statusResult['bank_verification_status'] == 'failed' ||
                 statusResult['document_verification_status'] == 'failed') {
        // Verification failed
        updatedProgress = currentProgress.copyWith(
          bankVerificationStatus: statusResult['bank_verification_status'],
          documentVerificationStatus: statusResult['document_verification_status'],
          overallProgress: 0.0,
          completedSteps: ['Initiated', 'Data validated', 'Submitted for processing', 'Verification failed'],
          nextStep: 'Retry verification',
          processingDetails: statusResult,
        );
        newStatus = 'failed';
      } else {
        // Still processing
        double progress = 0.6; // Base progress after submission
        List<String> steps = ['Initiated', 'Data validated', 'Submitted for processing'];

        if (statusResult['bank_verification_status'] == 'processing') {
          progress += 0.15;
          steps.add('Bank verification in progress');
        }
        if (statusResult['document_verification_status'] == 'processing') {
          progress += 0.15;
          steps.add('Document verification in progress');
        }

        // 🔄 ADDITIONAL FIX: Refresh wallet when bank verification succeeds (even if documents pending)
        if (statusResult['bank_verification_status'] == 'verified' &&
            statusResult['document_verification_status'] != 'verified') {
          debugPrint('🏦 [WALLET-VERIFICATION-PROVIDER] Bank verification completed! Refreshing wallet state...');
          _refreshWalletProvider();
          progress += 0.2; // Bank verified adds more progress
          steps.add('Bank account verified');
        }

        updatedProgress = currentProgress.copyWith(
          bankVerificationStatus: statusResult['bank_verification_status'],
          documentVerificationStatus: statusResult['document_verification_status'],
          overallProgress: progress,
          completedSteps: steps,
          nextStep: 'Processing verification',
          processingDetails: statusResult,
        );
      }

      // Update state with new progress
      state = state.copyWith(
        status: newStatus,
        currentStep: newCurrentStep,
        lastUpdated: DateTime.now(),
        unifiedProgress: updatedProgress,
        canRetry: newStatus == 'failed',
      );

      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Status updated - Progress: ${updatedProgress.overallProgress}');
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error checking verification status: $e');
    }
  }

  /// Refresh wallet provider to update isVerified status after verification completion
  void _refreshWalletProvider() {
    try {
      debugPrint('🔄 [WALLET-VERIFICATION-PROVIDER] Triggering wallet provider refresh...');

      // Get the wallet provider from the ref and trigger a refresh
      final walletNotifier = ref.read(driverWalletProvider.notifier);
      walletNotifier.loadWallet(refresh: true);

      debugPrint('✅ [WALLET-VERIFICATION-PROVIDER] Wallet provider refresh triggered');
    } catch (e) {
      debugPrint('❌ [WALLET-VERIFICATION-PROVIDER] Error refreshing wallet provider: $e');
    }
  }
}
