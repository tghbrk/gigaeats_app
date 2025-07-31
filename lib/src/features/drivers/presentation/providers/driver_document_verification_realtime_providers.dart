import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/driver_document_verification_service.dart';
import '../../domain/models/driver_document_verification.dart';
import '../../../../core/utils/logger.dart';

/// Logger for verification providers
final _logger = AppLogger();

// ==================== SERVICE PROVIDERS ====================

/// Provider for driver document verification service
final driverDocumentVerificationServiceProvider = Provider<DriverDocumentVerificationService>((ref) {
  return DriverDocumentVerificationService();
});

// ==================== REAL-TIME STREAM PROVIDERS ====================

/// Real-time stream provider for driver document verification
final driverDocumentVerificationStreamProvider = StreamProvider.family<DriverDocumentVerification?, String>((ref, driverId) {
  _logger.info('🔄 Creating verification stream for driver: $driverId');
  
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('driver_document_verifications')
      .stream(primaryKey: ['id'])
      .eq('driver_id', driverId)
      .map((data) {
        if (data.isEmpty) {
          _logger.info('📄 No verification found for driver: $driverId');
          return null;
        }
        
        final verificationData = data.first;
        _logger.info('📄 Verification data received: ${verificationData['overall_status']}');
        
        return DriverDocumentVerification.fromJson(verificationData);
      });
});

/// Real-time stream provider for driver verification documents
final driverVerificationDocumentsStreamProvider = StreamProvider.family<List<DriverVerificationDocument>, String>((ref, verificationId) {
  _logger.info('📄 Creating documents stream for verification: $verificationId');
  
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('driver_verification_documents')
      .stream(primaryKey: ['id'])
      .eq('verification_id', verificationId)
      .order('created_at', ascending: true)
      .map((data) {
        _logger.info('📄 Documents data received: ${data.length} documents');
        
        return data.map((json) => DriverVerificationDocument.fromJson(json)).toList();
      });
});

/// Real-time stream provider for verification processing logs
final driverVerificationProcessingLogsStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, verificationId) {
  _logger.info('📋 Creating processing logs stream for verification: $verificationId');
  
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('driver_verification_processing_logs')
      .stream(primaryKey: ['id'])
      .eq('verification_id', verificationId)
      .order('created_at', ascending: false)
      .limit(20)
      .map((data) {
        _logger.info('📋 Processing logs received: ${data.length} logs');
        return data;
      });
});

/// Real-time stream provider for current user's driver verification
final currentDriverVerificationStreamProvider = StreamProvider.autoDispose<DriverDocumentVerification?>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  
  if (userId == null) {
    _logger.warning('⚠️ No authenticated user for verification stream');
    return Stream.value(null);
  }
  
  _logger.info('🔄 Creating current driver verification stream for user: $userId');
  
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('driver_document_verifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) {
        if (data.isEmpty) {
          _logger.info('📄 No verification found for current user');
          return null;
        }
        
        final verificationData = data.first;
        _logger.info('📄 Current user verification: ${verificationData['overall_status']}');
        
        return DriverDocumentVerification.fromJson(verificationData);
      });
});

// ==================== STATE NOTIFIER PROVIDERS ====================

/// State for driver document verification management
class DriverDocumentVerificationState {
  final DriverDocumentVerification? verification;
  final List<DriverVerificationDocument> documents;
  final List<Map<String, dynamic>> processingLogs;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final DateTime lastUpdated;

  const DriverDocumentVerificationState({
    this.verification,
    this.documents = const [],
    this.processingLogs = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    required this.lastUpdated,
  });

  DriverDocumentVerificationState copyWith({
    DriverDocumentVerification? verification,
    List<DriverVerificationDocument>? documents,
    List<Map<String, dynamic>>? processingLogs,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DriverDocumentVerificationState(
      verification: verification ?? this.verification,
      documents: documents ?? this.documents,
      processingLogs: processingLogs ?? this.processingLogs,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper getters
  bool get hasVerification => verification != null;
  bool get isVerified => verification?.isComplete ?? false;
  bool get hasFailed => verification?.hasFailed ?? false;
  bool get requiresManualReview => verification?.requiresManualReview ?? false;
  bool get hasError => error != null;
  
  double get completionPercentage => verification?.completionPercentage ?? 0.0;
  String get statusDisplayText => verification?.statusDisplayText ?? 'Not Started';
  
  int get totalDocuments => documents.length;
  int get verifiedDocuments => documents.where((doc) => doc.isProcessed).length;
  int get pendingDocuments => documents.where((doc) => !doc.isProcessed && !doc.isProcessing).length;
  int get processingDocuments => documents.where((doc) => doc.isProcessing).length;
}

/// State notifier for driver document verification management
class DriverDocumentVerificationNotifier extends StateNotifier<DriverDocumentVerificationState> {
  final String driverId;
  final String userId;
  final DriverDocumentVerificationService _service;
  final Ref _ref;

  DriverDocumentVerificationNotifier({
    required this.driverId,
    required this.userId,
    required DriverDocumentVerificationService service,
    required Ref ref,
  }) : _service = service, _ref = ref, super(DriverDocumentVerificationState(lastUpdated: DateTime.now())) {
    _initializeRealTimeSubscriptions();
  }

  /// Initialize real-time subscriptions
  void _initializeRealTimeSubscriptions() {
    _logger.info('🔄 Initializing real-time subscriptions for driver: $driverId');
    
    // Listen to verification changes
    _ref.listen(driverDocumentVerificationStreamProvider(driverId), (previous, next) {
      next.when(
        data: (verification) {
          _logger.info('📄 Verification update received: ${verification?.statusDisplayText}');
          state = state.copyWith(
            verification: verification,
            lastUpdated: DateTime.now(),
            error: null,
          );
        },
        loading: () {
          if (!state.isLoading) {
            state = state.copyWith(isLoading: true);
          }
        },
        error: (error, stackTrace) {
          _logger.error('❌ Verification stream error', error, stackTrace);
          state = state.copyWith(
            error: 'Failed to load verification: $error',
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
        },
      );
    });

    // Listen to documents changes if verification exists
    if (state.verification != null) {
      _subscribeToDocuments(state.verification!.id);
    }
  }

  /// Subscribe to documents stream
  void _subscribeToDocuments(String verificationId) {
    _logger.info('📄 Subscribing to documents for verification: $verificationId');
    
    _ref.listen(driverVerificationDocumentsStreamProvider(verificationId), (previous, next) {
      next.when(
        data: (documents) {
          _logger.info('📄 Documents update received: ${documents.length} documents');
          state = state.copyWith(
            documents: documents,
            lastUpdated: DateTime.now(),
          );
        },
        loading: () {
          // Don't show loading for documents if we already have verification
        },
        error: (error, stackTrace) {
          _logger.error('❌ Documents stream error', error, stackTrace);
        },
      );
    });

    // Listen to processing logs
    _ref.listen(driverVerificationProcessingLogsStreamProvider(verificationId), (previous, next) {
      next.when(
        data: (logs) {
          _logger.info('📋 Processing logs update received: ${logs.length} logs');
          state = state.copyWith(
            processingLogs: logs,
            lastUpdated: DateTime.now(),
          );
        },
        loading: () {},
        error: (error, stackTrace) {
          _logger.error('❌ Processing logs stream error', error, stackTrace);
        },
      );
    });
  }

  /// Create new verification
  Future<void> createVerification() async {
    try {
      _logger.info('🆕 Creating new verification for driver: $driverId');
      
      state = state.copyWith(isLoading: true, error: null);
      
      // TODO: Call service to create verification
      // For now, simulate creation
      await Future.delayed(const Duration(seconds: 1));
      
      _logger.info('✅ Verification created successfully');
      
      state = state.copyWith(
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
    } catch (error, stackTrace) {
      _logger.error('❌ Failed to create verification', error, stackTrace);
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create verification: $error',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Start document processing
  Future<void> startDocumentProcessing(String documentId) async {
    try {
      _logger.info('🔄 Starting document processing: $documentId');
      
      state = state.copyWith(isProcessing: true, error: null);
      
      // Call Edge Function to process document
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'driver-document-ai-verification',
        body: {
          'action': 'process_document',
          'document_id': documentId,
          'verification_id': state.verification?.id,
        },
      );
      
      if (response.data['success'] == true) {
        _logger.info('✅ Document processing started successfully');
      } else {
        throw Exception(response.data['error'] ?? 'Processing failed');
      }
      
      state = state.copyWith(
        isProcessing: false,
        lastUpdated: DateTime.now(),
      );
      
    } catch (error, stackTrace) {
      _logger.error('❌ Failed to start document processing', error, stackTrace);
      
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to process document: $error',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Verify identity across documents
  Future<void> verifyIdentity() async {
    try {
      _logger.info('🔍 Starting identity verification');
      
      state = state.copyWith(isProcessing: true, error: null);
      
      // Call Edge Function for identity verification
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'driver-document-ai-verification',
        body: {
          'action': 'verify_identity',
          'verification_id': state.verification?.id,
        },
      );
      
      if (response.data['success'] == true) {
        _logger.info('✅ Identity verification completed');
      } else {
        throw Exception(response.data['error'] ?? 'Identity verification failed');
      }
      
      state = state.copyWith(
        isProcessing: false,
        lastUpdated: DateTime.now(),
      );
      
    } catch (error, stackTrace) {
      _logger.error('❌ Identity verification failed', error, stackTrace);
      
      state = state.copyWith(
        isProcessing: false,
        error: 'Identity verification failed: $error',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Refresh verification data
  Future<void> refresh() async {
    _logger.info('🔄 Refreshing verification data');
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastUpdated: DateTime.now(),
    );
    
    // The real-time streams will automatically update the state
    await Future.delayed(const Duration(milliseconds: 500));
    
    state = state.copyWith(isLoading: false);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for driver document verification state notifier
final driverDocumentVerificationNotifierProvider = StateNotifierProvider.family<
    DriverDocumentVerificationNotifier,
    DriverDocumentVerificationState,
    ({String driverId, String userId})>((ref, params) {
  final service = ref.watch(driverDocumentVerificationServiceProvider);
  
  return DriverDocumentVerificationNotifier(
    driverId: params.driverId,
    userId: params.userId,
    service: service,
    ref: ref,
  );
});

/// Provider for current user's verification state
final currentDriverDocumentVerificationProvider = StateNotifierProvider.autoDispose<
    DriverDocumentVerificationNotifier,
    DriverDocumentVerificationState>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  // For now, use userId as driverId (this should be fetched from driver profile)
  final service = ref.watch(driverDocumentVerificationServiceProvider);
  
  return DriverDocumentVerificationNotifier(
    driverId: userId, // TODO: Get actual driver ID
    userId: userId,
    service: service,
    ref: ref,
  );
});
