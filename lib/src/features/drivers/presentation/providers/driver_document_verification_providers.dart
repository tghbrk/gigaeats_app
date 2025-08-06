import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/driver_document_verification_service.dart';
import '../../domain/models/driver_document_verification.dart';
import 'driver_document_verification_realtime_providers.dart';
import 'driver_verification_notification_provider.dart';
import 'driver_verification_status_monitor_provider.dart';
import '../../../../core/utils/logger.dart';

/// Logger for verification providers
final _logger = AppLogger();

/// Enhanced provider for driver document verification service with real-time integration
final enhancedDriverDocumentVerificationServiceProvider = Provider<DriverDocumentVerificationService>((ref) {
  return DriverDocumentVerificationService();
});

/// Enhanced provider for driver document verification with real-time updates
final enhancedDriverDocumentVerificationProvider = StateNotifierProvider.family<
    EnhancedDriverDocumentVerificationNotifier,
    AsyncValue<DriverDocumentVerification?>,
    String>((ref, driverId) {
  return EnhancedDriverDocumentVerificationNotifier(
    ref.read(enhancedDriverDocumentVerificationServiceProvider),
    driverId,
    ref,
  );
});

/// Enhanced state notifier with real-time integration
class EnhancedDriverDocumentVerificationNotifier extends StateNotifier<AsyncValue<DriverDocumentVerification?>> {
  // ignore: unused_field
  final DriverDocumentVerificationService _service;
  final String _driverId;
  final Ref _ref;

  EnhancedDriverDocumentVerificationNotifier(this._service, this._driverId, this._ref)
      : super(const AsyncValue.loading()) {
    _initializeRealTimeIntegration();
  }

  /// Initialize real-time integration
  void _initializeRealTimeIntegration() {
    _logger.info('🔄 Initializing real-time integration for driver: $_driverId');

    // Listen to real-time verification updates
    _ref.listen(driverDocumentVerificationStreamProvider(_driverId), (previous, next) {
      next.when(
        data: (verification) {
          _logger.info('📄 Real-time verification update: ${verification?.statusDisplayText}');
          state = AsyncValue.data(verification);

          // Trigger notifications for status changes
          if (previous?.value != null && verification != null) {
            final oldStatus = previous!.value!.overallStatus;
            final newStatus = verification.overallStatus;

            if (oldStatus != newStatus) {
              _ref.read(verificationNotificationProvider.notifier)
                  .addVerificationStatusNotification(oldStatus, newStatus, verification);
            }
          }
        },
        loading: () {
          if (state is! AsyncLoading) {
            state = const AsyncValue.loading();
          }
        },
        error: (error, stackTrace) {
          _logger.error('❌ Real-time verification error', error, stackTrace);
          state = AsyncValue.error(error, stackTrace);

          _ref.read(verificationNotificationProvider.notifier)
              .addErrorNotification(
                'Connection Error',
                'Failed to load verification status: $error',
              );
        },
      );
    });
  }

  /// Create new verification with real-time monitoring
  Future<void> createVerification() async {
    try {
      _logger.info('🆕 Creating verification for driver: $_driverId');

      state = const AsyncValue.loading();

      // Call service to create verification
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('driver_document_verifications')
          .insert({
            'driver_id': _driverId,
            'user_id': _driverId, // TODO: Get actual user ID
            'verification_type': 'wallet_kyc',
            'overall_status': 'pending',
            'current_step': 1,
            'total_steps': 3,
            'completion_percentage': 0.0,
            'verification_method': 'ocr_ai',
            'kyc_compliance_status': 'pending',
          })
          .select()
          .single();

      final verification = DriverDocumentVerification.fromJson(response);
      state = AsyncValue.data(verification);

      _logger.info('✅ Verification created: ${verification.id}');

      // Start status monitoring
      _ref.read(currentDriverStatusMonitorProvider.notifier).startMonitoring();

      // Add success notification
      _ref.read(verificationNotificationProvider.notifier)
          .addInfoNotification(
            'Verification Started',
            'Your document verification process has been initiated.',
          );

    } catch (e, stackTrace) {
      _logger.error('❌ Failed to create verification', e, stackTrace);

      state = AsyncValue.error(e, stackTrace);

      _ref.read(verificationNotificationProvider.notifier)
          .addErrorNotification(
            'Creation Failed',
            'Failed to start verification process: $e',
          );
    }
  }

  /// Upload document with real-time processing
  /// TODO: Implement actual file upload integration
  Future<void> uploadDocument({
    required String verificationId,
    required DocumentType documentType,
    required String filePath,
    String? documentSide,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.info('📤 Uploading document: $documentType');

      // TODO: Implement actual upload service integration
      // For now, simulate successful upload
      await Future.delayed(const Duration(seconds: 1));

      final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';

      _logger.info('✅ Document uploaded: $documentId');

      // Add upload notification
      _ref.read(verificationNotificationProvider.notifier)
          .addDocumentProcessingNotification(
            documentType.name,
            'uploaded',
            documentSide: documentSide,
            data: {'document_id': documentId},
          );

      // Auto-start processing
      await _startDocumentProcessing(documentId);

    } catch (e, stackTrace) {
      _logger.error('❌ Document upload failed', e, stackTrace);

      _ref.read(verificationNotificationProvider.notifier)
          .addErrorNotification(
            'Upload Failed',
            'Failed to upload document: $e',
          );

      rethrow;
    }
  }

  /// Start document processing via Edge Function
  Future<void> _startDocumentProcessing(String documentId) async {
    try {
      _logger.info('🔄 Starting document processing: $documentId');

      // Add processing notification
      _ref.read(verificationNotificationProvider.notifier)
          .addDocumentProcessingNotification(
            'document',
            'processing',
            data: {'document_id': documentId},
          );

      // Call Edge Function
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'driver-document-ai-verification',
        body: {
          'action': 'process_document',
          'document_id': documentId,
          'verification_id': state.value?.id,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Processing failed');
      }

      _logger.info('✅ Document processing started successfully');

    } catch (e, stackTrace) {
      _logger.error('❌ Document processing failed', e, stackTrace);

      _ref.read(verificationNotificationProvider.notifier)
          .addErrorNotification(
            'Processing Failed',
            'Failed to process document: $e',
          );
    }
  }

  /// Refresh verification data
  Future<void> refreshVerification() async {
    _logger.info('🔄 Refreshing verification data');

    // The real-time stream will automatically update
    // Just trigger a manual refresh if needed
    state = const AsyncValue.loading();

    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Legacy providers for backward compatibility
final driverDocumentVerificationServiceProvider = enhancedDriverDocumentVerificationServiceProvider;
final driverDocumentVerificationProvider = enhancedDriverDocumentVerificationProvider;

/// Provider for driver verification documents with real-time updates
final enhancedDriverVerificationDocumentsProvider = StateNotifierProvider.family<
    EnhancedDriverVerificationDocumentsNotifier,
    AsyncValue<List<DriverVerificationDocument>>,
    String>((ref, verificationId) {
  return EnhancedDriverVerificationDocumentsNotifier(
    ref.read(enhancedDriverDocumentVerificationServiceProvider),
    verificationId,
    ref,
  );
});

/// Enhanced documents notifier with real-time updates
class EnhancedDriverVerificationDocumentsNotifier extends StateNotifier<AsyncValue<List<DriverVerificationDocument>>> {
  // ignore: unused_field
  final DriverDocumentVerificationService _service;
  final String _verificationId;
  final Ref _ref;

  EnhancedDriverVerificationDocumentsNotifier(this._service, this._verificationId, this._ref)
      : super(const AsyncValue.loading()) {
    _initializeRealTimeDocuments();
  }

  /// Initialize real-time documents stream
  void _initializeRealTimeDocuments() {
    _logger.info('📄 Initializing real-time documents for verification: $_verificationId');

    _ref.listen(driverVerificationDocumentsStreamProvider(_verificationId), (previous, next) {
      next.when(
        data: (documents) {
          _logger.info('📄 Real-time documents update: ${documents.length} documents');
          state = AsyncValue.data(documents);

          // Check for status changes and trigger notifications
          if (previous?.value != null) {
            _checkForDocumentStatusChanges(previous!.value!, documents);
          }
        },
        loading: () {
          if (state is! AsyncLoading) {
            state = const AsyncValue.loading();
          }
        },
        error: (error, stackTrace) {
          _logger.error('❌ Real-time documents error', error, stackTrace);
          state = AsyncValue.error(error, stackTrace);
        },
      );
    });
  }

  /// Check for document status changes
  void _checkForDocumentStatusChanges(
    List<DriverVerificationDocument> oldDocuments,
    List<DriverVerificationDocument> newDocuments,
  ) {
    final oldStatusMap = {for (var doc in oldDocuments) doc.id: doc.processingStatus};

    for (final newDoc in newDocuments) {
      final oldStatus = oldStatusMap[newDoc.id];
      if (oldStatus != null && oldStatus != newDoc.processingStatus) {
        _ref.read(verificationNotificationProvider.notifier)
            .addDocumentProcessingNotification(
              newDoc.documentType.name,
              newDoc.processingStatus.name,
              documentSide: newDoc.documentSide,
              data: {
                'document_id': newDoc.id,
                'confidence_score': newDoc.confidenceScore,
              },
            );
      }
    }
  }

  /// Refresh documents
  Future<void> refreshDocuments() async {
    _logger.info('🔄 Refreshing documents');

    // The real-time stream will automatically update
    state = const AsyncValue.loading();

    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Legacy provider for backward compatibility
final driverVerificationDocumentsProvider = enhancedDriverVerificationDocumentsProvider;
