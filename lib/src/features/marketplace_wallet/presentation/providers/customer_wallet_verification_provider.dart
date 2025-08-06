import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../data/services/customer_wallet_verification_service.dart';
import 'customer_wallet_provider.dart';

/// Provider for managing customer wallet verification state and operations
final customerWalletVerificationStateProvider = StateNotifierProvider<CustomerWalletVerificationNotifier, CustomerWalletVerificationState>((ref) {
  final authState = ref.watch(authStateProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);

  return CustomerWalletVerificationNotifier(
    userId: authState.user?.id,
    verificationService: CustomerWalletVerificationService(supabaseService),
    ref: ref, // Pass ref to the notifier
  );
});

/// Progress tracking for unified verification
class UnifiedVerificationProgress {
  final bool bankAccountSubmitted;
  final bool documentsSubmitted;
  final bool instantVerificationSubmitted;
  final bool bankAccountVerified;
  final bool documentsVerified;
  final bool instantVerificationVerified;
  final String? bankVerificationStatus; // 'pending', 'processing', 'verified', 'failed'
  final String? documentVerificationStatus; // 'pending', 'processing', 'verified', 'failed'
  final String? instantVerificationStatus; // 'pending', 'processing', 'verified', 'failed'
  final double overallProgress; // 0.0 to 1.0
  final List<String> completedSteps;
  final String? nextStep;
  final Map<String, dynamic>? processingDetails;

  const UnifiedVerificationProgress({
    this.bankAccountSubmitted = false,
    this.documentsSubmitted = false,
    this.instantVerificationSubmitted = false,
    this.bankAccountVerified = false,
    this.documentsVerified = false,
    this.instantVerificationVerified = false,
    this.bankVerificationStatus,
    this.documentVerificationStatus,
    this.instantVerificationStatus,
    this.overallProgress = 0.0,
    this.completedSteps = const [],
    this.nextStep,
    this.processingDetails,
  });

  UnifiedVerificationProgress copyWith({
    bool? bankAccountSubmitted,
    bool? documentsSubmitted,
    bool? instantVerificationSubmitted,
    bool? bankAccountVerified,
    bool? documentsVerified,
    bool? instantVerificationVerified,
    String? bankVerificationStatus,
    String? documentVerificationStatus,
    String? instantVerificationStatus,
    double? overallProgress,
    List<String>? completedSteps,
    String? nextStep,
    Map<String, dynamic>? processingDetails,
  }) {
    return UnifiedVerificationProgress(
      bankAccountSubmitted: bankAccountSubmitted ?? this.bankAccountSubmitted,
      documentsSubmitted: documentsSubmitted ?? this.documentsSubmitted,
      instantVerificationSubmitted: instantVerificationSubmitted ?? this.instantVerificationSubmitted,
      bankAccountVerified: bankAccountVerified ?? this.bankAccountVerified,
      documentsVerified: documentsVerified ?? this.documentsVerified,
      instantVerificationVerified: instantVerificationVerified ?? this.instantVerificationVerified,
      bankVerificationStatus: bankVerificationStatus ?? this.bankVerificationStatus,
      documentVerificationStatus: documentVerificationStatus ?? this.documentVerificationStatus,
      instantVerificationStatus: instantVerificationStatus ?? this.instantVerificationStatus,
      overallProgress: overallProgress ?? this.overallProgress,
      completedSteps: completedSteps ?? this.completedSteps,
      nextStep: nextStep ?? this.nextStep,
      processingDetails: processingDetails ?? this.processingDetails,
    );
  }

  /// Check if all verification methods are verified
  bool get isFullyVerified => bankAccountVerified && documentsVerified && instantVerificationVerified;

  /// Check if verification is in progress
  bool get isInProgress => (bankAccountSubmitted || documentsSubmitted || instantVerificationSubmitted) && !isFullyVerified;

  /// Get human-readable status message
  String get statusMessage {
    if (isFullyVerified) return 'Verification completed successfully';
    if (!bankAccountSubmitted && !documentsSubmitted && !instantVerificationSubmitted) return 'Ready to start verification';
    if (bankAccountSubmitted && documentsSubmitted && instantVerificationSubmitted && !isFullyVerified) return 'Processing verification';
    return 'Verification in progress';
  }
}

/// State class for customer wallet verification with unified verification support
class CustomerWalletVerificationState {
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
  final Map<String, dynamic>? instantVerificationDetails;

  const CustomerWalletVerificationState({
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
    this.instantVerificationDetails,
  });

  CustomerWalletVerificationState copyWith({
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
    Map<String, dynamic>? instantVerificationDetails,
  }) {
    return CustomerWalletVerificationState(
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
      instantVerificationDetails: instantVerificationDetails ?? this.instantVerificationDetails,
    );
  }
}

/// Notifier for managing customer wallet verification operations
class CustomerWalletVerificationNotifier extends StateNotifier<CustomerWalletVerificationState> {
  final String? userId;
  final CustomerWalletVerificationService verificationService;
  final Ref ref;

  CustomerWalletVerificationNotifier({
    required this.userId,
    required this.verificationService,
    required this.ref,
  }) : super(const CustomerWalletVerificationState());

  /// Load current verification status
  Future<void> loadVerificationStatus() async {
    if (userId == null) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] No user ID available');
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    debugPrint('🔍 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Loading verification status for user: $userId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final verificationStatus = await verificationService.getVerificationStatus(userId!);

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Verification status loaded: ${verificationStatus.status}');

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
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Error loading verification status: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load verification status: $e',
      );
    }
  }

  /// Start unified verification (combines bank account, document, and instant verification)
  Future<bool> startUnifiedVerification(Map<String, dynamic> verificationData) async {
    if (userId == null) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] No user ID available');
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    debugPrint('🚀 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Starting unified verification');

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
      final instantDetails = verificationData['instantVerification'] as Map<String, dynamic>?;

      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Bank: ${bankDetails['bankName']}');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Account: ${bankDetails['accountNumber']}');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Documents: ${documents.keys.length} files provided');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Instant verification: ${instantDetails != null ? 'included' : 'not included'}');

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
        instantVerificationDetails: instantDetails,
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Unified verification initiated');
      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Service response: $result');

      // Update progress - submitted successfully
      final submittedProgress = UnifiedVerificationProgress(
        bankAccountSubmitted: true,
        documentsSubmitted: true,
        instantVerificationSubmitted: instantDetails != null,
        bankVerificationStatus: 'pending',
        documentVerificationStatus: 'pending',
        instantVerificationStatus: instantDetails != null ? 'pending' : null,
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
        instantVerificationDetails: instantDetails,
        verificationData: {
          'method': 'unified_verification',
          'bank_details': bankDetails,
          'documents_submitted': true,
          'instant_verification_submitted': instantDetails != null,
          'submitted_at': DateTime.now().toIso8601String(),
          'service_response': result,
        },
      );

      // Trigger wallet provider refresh to ensure state synchronization
      _refreshWalletProvider();

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Unified verification submitted successfully');

      // Start periodic status checking
      _startStatusPolling();

      return true;
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Error starting unified verification: $e');

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
    debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Retrying verification');
    await loadVerificationStatus();
  }

  /// Reset verification state
  void resetState() {
    debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Resetting verification state');
    state = const CustomerWalletVerificationState();
  }

  /// Start periodic status polling for unified verification
  void _startStatusPolling() {
    if (state.accountId == null) {
      debugPrint('⚠️ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] No account ID for status polling');
      return;
    }

    debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Starting status polling for account: ${state.accountId}');

    // Poll every 10 seconds for status updates
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        // Stop polling if verification is complete or failed
        if (state.status == 'verified' || state.status == 'failed' || state.accountId == null) {
          debugPrint('🛑 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Stopping status polling - Status: ${state.status}');
          timer.cancel();
          return;
        }

        await _checkUnifiedVerificationStatus();
      } catch (e) {
        debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Error during status polling: $e');
        // Continue polling despite errors
      }
    });
  }

  /// Check unified verification status
  Future<void> _checkUnifiedVerificationStatus() async {
    if (state.accountId == null || userId == null) return;

    try {
      debugPrint('🔍 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Checking verification status for account: ${state.accountId}');

      final statusResult = await verificationService.getUnifiedVerificationStatus(
        userId: userId!,
        accountId: state.accountId!,
      );

      debugPrint('📊 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Status result: $statusResult');

      // Update progress based on status
      final currentProgress = state.unifiedProgress ?? UnifiedVerificationProgress();
      UnifiedVerificationProgress updatedProgress;
      String newStatus = state.status;
      int newCurrentStep = state.currentStep ?? 2;

      if (statusResult['bank_verification_status'] == 'verified' &&
          statusResult['document_verification_status'] == 'verified' &&
          (statusResult['instant_verification_status'] == 'verified' || statusResult['instant_verification_status'] == null)) {
        // All verifications complete
        updatedProgress = currentProgress.copyWith(
          bankAccountVerified: true,
          documentsVerified: true,
          instantVerificationVerified: statusResult['instant_verification_status'] == 'verified',
          bankVerificationStatus: 'verified',
          documentVerificationStatus: 'verified',
          instantVerificationStatus: statusResult['instant_verification_status'],
          overallProgress: 1.0,
          completedSteps: ['Initiated', 'Data validated', 'Submitted for processing', 'Bank verified', 'Documents verified', 'Verification complete'],
          nextStep: null,
          processingDetails: statusResult,
        );
        newStatus = 'verified';
        newCurrentStep = 3;

        // 🔄 CRITICAL FIX: Refresh wallet provider when verification is complete
        debugPrint('🎉 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Verification completed! Refreshing wallet state...');
        _refreshWalletProvider();
      } else if (statusResult['bank_verification_status'] == 'failed' ||
                 statusResult['document_verification_status'] == 'failed' ||
                 statusResult['instant_verification_status'] == 'failed') {
        // Verification failed
        updatedProgress = currentProgress.copyWith(
          bankVerificationStatus: statusResult['bank_verification_status'],
          documentVerificationStatus: statusResult['document_verification_status'],
          instantVerificationStatus: statusResult['instant_verification_status'],
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
          progress += 0.1;
          steps.add('Bank verification in progress');
        }
        if (statusResult['document_verification_status'] == 'processing') {
          progress += 0.1;
          steps.add('Document verification in progress');
        }
        if (statusResult['instant_verification_status'] == 'processing') {
          progress += 0.1;
          steps.add('Instant verification in progress');
        }

        // 🔄 ADDITIONAL FIX: Refresh wallet when bank verification succeeds (even if documents pending)
        if (statusResult['bank_verification_status'] == 'verified' &&
            (statusResult['document_verification_status'] != 'verified' || statusResult['instant_verification_status'] != 'verified')) {
          debugPrint('🏦 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Bank verification completed! Refreshing wallet state...');
          _refreshWalletProvider();
          progress += 0.1; // Bank verified adds more progress
          steps.add('Bank account verified');
        }

        updatedProgress = currentProgress.copyWith(
          bankVerificationStatus: statusResult['bank_verification_status'],
          documentVerificationStatus: statusResult['document_verification_status'],
          instantVerificationStatus: statusResult['instant_verification_status'],
          overallProgress: progress,
          completedSteps: steps,
          nextStep: 'Processing verification',
          processingDetails: statusResult,
        );
      }

      // Update state with new progress
      final previousStatus = state.status;
      state = state.copyWith(
        status: newStatus,
        currentStep: newCurrentStep,
        lastUpdated: DateTime.now(),
        unifiedProgress: updatedProgress,
        canRetry: newStatus == 'failed',
      );

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Status updated - Progress: ${updatedProgress.overallProgress}');

      // If verification status changed, refresh wallet provider
      if (previousStatus != newStatus) {
        debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Verification status changed from $previousStatus to $newStatus');
        _refreshWalletProvider();
      }
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Error checking verification status: $e');
    }
  }

  /// Refresh wallet provider to update isVerified status after verification completion
  void _refreshWalletProvider() {
    try {
      debugPrint('🔄 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Triggering wallet provider refresh...');

      // Get the customer wallet provider from the ref
      final walletNotifier = ref.read(customerWalletProvider.notifier);

      // For immediate UI feedback, use optimistic update if verification is completed
      if (state.status == 'verified') {
        debugPrint('🎉 [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Verification completed - applying optimistic update');
        walletNotifier.updateVerificationStatusOptimistically(true);
      }

      // Use the enhanced verification status update method for database sync
      walletNotifier.handleVerificationStatusUpdate(state.status);

      debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Wallet provider verification status update triggered');
    } catch (e) {
      debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Error refreshing wallet provider: $e');

      // Fallback to simple refresh if the enhanced method fails
      try {
        final walletNotifier = ref.read(customerWalletProvider.notifier);
        walletNotifier.loadWallet(forceRefresh: true);
        debugPrint('✅ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Fallback wallet refresh completed');
      } catch (fallbackError) {
        debugPrint('❌ [CUSTOMER-WALLET-VERIFICATION-PROVIDER] Fallback refresh also failed: $fallbackError');
      }
    }
  }
}
