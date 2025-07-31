import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/driver_document_verification.dart';
import 'driver_document_verification_realtime_providers.dart';
import 'driver_verification_notification_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

/// Logger for status monitor
final _logger = AppLogger();

/// Status monitoring configuration
class StatusMonitorConfig {
  final Duration pollingInterval;
  final Duration timeoutDuration;
  final int maxRetries;
  final bool enableNotifications;
  final bool enableAutoProcessing;

  const StatusMonitorConfig({
    this.pollingInterval = const Duration(seconds: 5),
    this.timeoutDuration = const Duration(minutes: 10),
    this.maxRetries = 3,
    this.enableNotifications = true,
    this.enableAutoProcessing = true,
  });
}

/// Status monitoring state
class StatusMonitorState {
  final bool isMonitoring;
  final bool isConnected;
  final DateTime? lastUpdate;
  final DateTime? lastHeartbeat;
  final Map<String, DateTime> documentProcessingStartTimes;
  final Map<String, int> retryAttempts;
  final List<String> processingQueue;
  final String? error;

  const StatusMonitorState({
    this.isMonitoring = false,
    this.isConnected = false,
    this.lastUpdate,
    this.lastHeartbeat,
    this.documentProcessingStartTimes = const {},
    this.retryAttempts = const {},
    this.processingQueue = const [],
    this.error,
  });

  StatusMonitorState copyWith({
    bool? isMonitoring,
    bool? isConnected,
    DateTime? lastUpdate,
    DateTime? lastHeartbeat,
    Map<String, DateTime>? documentProcessingStartTimes,
    Map<String, int>? retryAttempts,
    List<String>? processingQueue,
    String? error,
  }) {
    return StatusMonitorState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isConnected: isConnected ?? this.isConnected,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      documentProcessingStartTimes: documentProcessingStartTimes ?? this.documentProcessingStartTimes,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      processingQueue: processingQueue ?? this.processingQueue,
      error: error,
    );
  }

  /// Check if monitoring is healthy
  bool get isHealthy {
    if (!isMonitoring || !isConnected) return false;
    if (lastHeartbeat == null) return false;
    
    final timeSinceHeartbeat = DateTime.now().difference(lastHeartbeat!);
    return timeSinceHeartbeat.inMinutes < 2;
  }

  /// Get processing timeout documents
  List<String> getTimeoutDocuments(Duration timeout) {
    final now = DateTime.now();
    return documentProcessingStartTimes.entries
        .where((entry) => now.difference(entry.value) > timeout)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Status monitor notifier
class StatusMonitorNotifier extends StateNotifier<StatusMonitorState> {
  final String driverId;
  final String userId;
  final StatusMonitorConfig config;
  final Ref _ref;
  
  Timer? _heartbeatTimer;
  Timer? _timeoutCheckTimer;
  StreamSubscription? _verificationSubscription;
  StreamSubscription? _documentsSubscription;
  
  VerificationStatus? _lastVerificationStatus;
  final Map<String, String> _lastDocumentStatuses = {};

  StatusMonitorNotifier({
    required this.driverId,
    required this.userId,
    required this.config,
    required Ref ref,
  }) : _ref = ref, super(const StatusMonitorState());

  /// Start monitoring
  void startMonitoring() {
    if (state.isMonitoring) return;
    
    _logger.info('🔍 Starting verification status monitoring for driver: $driverId');
    
    state = state.copyWith(
      isMonitoring: true,
      isConnected: false,
      error: null,
    );
    
    _setupSubscriptions();
    _startHeartbeat();
    _startTimeoutChecks();
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (!state.isMonitoring) return;
    
    _logger.info('⏹️ Stopping verification status monitoring');
    
    _cleanup();
    
    state = state.copyWith(
      isMonitoring: false,
      isConnected: false,
    );
  }

  /// Setup real-time subscriptions
  void _setupSubscriptions() {
    _logger.info('🔄 Setting up real-time subscriptions');

    // Subscribe to verification changes using ref.listen
    _ref.listen(driverDocumentVerificationStreamProvider(driverId), (previous, next) {
      next.when(
        data: (verification) => _handleVerificationUpdate(verification),
        loading: () => _handleConnectionState(false),
        error: (error, stackTrace) => _handleError('Verification stream error: $error'),
      );
    });

    // Subscribe to documents changes
    _ref.listen(currentDriverDocumentVerificationProvider, (previous, next) {
      if (next.verification != null) {
        _subscribeToDocuments(next.verification!.id);
      }
    });

    state = state.copyWith(isConnected: true);
  }

  /// Subscribe to documents for a verification
  void _subscribeToDocuments(String verificationId) {
    // Use ref.listen for documents stream
    _ref.listen(driverVerificationDocumentsStreamProvider(verificationId), (previous, next) {
      next.when(
        data: (documents) => _handleDocumentsUpdate(documents),
        loading: () {},
        error: (error, stackTrace) => _handleError('Documents stream error: $error'),
      );
    });
  }

  /// Handle verification update
  void _handleVerificationUpdate(DriverDocumentVerification? verification) {
    _logger.info('📄 Verification update received: ${verification?.statusDisplayText}');
    
    state = state.copyWith(
      lastUpdate: DateTime.now(),
      error: null,
    );
    
    // Check for status changes
    if (verification != null && _lastVerificationStatus != null) {
      if (verification.overallStatus != _lastVerificationStatus) {
        _handleStatusChange(_lastVerificationStatus!, verification.overallStatus, verification);
      }
    }
    
    _lastVerificationStatus = verification?.overallStatus;
    
    // Auto-process documents if enabled
    if (config.enableAutoProcessing && verification != null) {
      _checkForAutoProcessing(verification);
    }
  }

  /// Handle documents update
  void _handleDocumentsUpdate(List<DriverVerificationDocument> documents) {
    _logger.info('📄 Documents update received: ${documents.length} documents');
    
    final now = DateTime.now();
    final updatedProcessingTimes = Map<String, DateTime>.from(state.documentProcessingStartTimes);
    final updatedQueue = List<String>.from(state.processingQueue);
    
    for (final document in documents) {
      final documentId = document.id;
      final currentStatus = document.processingStatus.name;
      final lastStatus = _lastDocumentStatuses[documentId];
      
      // Track processing start times
      if (currentStatus == 'processing' && lastStatus != 'processing') {
        updatedProcessingTimes[documentId] = now;
        _logger.info('⏱️ Started tracking processing time for document: $documentId');
      }
      
      // Remove from processing times when completed
      if (currentStatus != 'processing' && updatedProcessingTimes.containsKey(documentId)) {
        updatedProcessingTimes.remove(documentId);
        updatedQueue.remove(documentId);
        _logger.info('✅ Completed processing for document: $documentId');
      }
      
      // Handle status changes
      if (lastStatus != null && lastStatus != currentStatus) {
        _handleDocumentStatusChange(document, lastStatus, currentStatus);
      }
      
      _lastDocumentStatuses[documentId] = currentStatus;
    }
    
    state = state.copyWith(
      documentProcessingStartTimes: updatedProcessingTimes,
      processingQueue: updatedQueue,
      lastUpdate: now,
    );
  }

  /// Handle verification status change
  void _handleStatusChange(
    VerificationStatus oldStatus,
    VerificationStatus newStatus,
    DriverDocumentVerification verification,
  ) {
    _logger.info('🔄 Status change: $oldStatus → $newStatus');
    
    if (config.enableNotifications) {
      _ref.read(verificationNotificationProvider.notifier)
          .addVerificationStatusNotification(oldStatus, newStatus, verification);
    }
    
    // Handle specific status changes
    switch (newStatus) {
      case VerificationStatus.verified:
        _handleVerificationComplete(verification);
        break;
      case VerificationStatus.failed:
        _handleVerificationFailed(verification);
        break;
      case VerificationStatus.manualReview:
        _handleManualReviewRequired(verification);
        break;
      default:
        break;
    }
  }

  /// Handle document status change
  void _handleDocumentStatusChange(
    DriverVerificationDocument document,
    String oldStatus,
    String newStatus,
  ) {
    _logger.info('📄 Document ${document.documentTypeDisplayName} status: $oldStatus → $newStatus');
    
    if (config.enableNotifications) {
      _ref.read(verificationNotificationProvider.notifier)
          .addDocumentProcessingNotification(
            document.documentType.name,
            newStatus,
            documentSide: document.documentSide,
            data: {
              'document_id': document.id,
              'confidence_score': document.confidenceScore,
            },
          );
    }
  }

  /// Check for auto-processing opportunities
  void _checkForAutoProcessing(DriverDocumentVerification verification) {
    // Auto-trigger identity verification when all documents are processed
    if (verification.overallStatus == VerificationStatus.processing) {
      final verificationNotifier = _ref.read(
        driverDocumentVerificationNotifierProvider(
          (driverId: driverId, userId: userId)
        ).notifier
      );
      
      // Check if all documents are ready for identity verification
      final documents = _ref.read(driverDocumentVerificationNotifierProvider(
        (driverId: driverId, userId: userId)
      )).documents;
      
      final allProcessed = documents.isNotEmpty && 
          documents.every((doc) => doc.isProcessed);
      
      if (allProcessed && documents.length >= 2) {
        _logger.info('🤖 Auto-triggering identity verification');
        verificationNotifier.verifyIdentity();
      }
    }
  }

  /// Handle verification complete
  void _handleVerificationComplete(DriverDocumentVerification verification) {
    _logger.info('🎉 Verification completed successfully');
    
    if (config.enableNotifications) {
      _ref.read(verificationNotificationProvider.notifier)
          .addInfoNotification(
            'Wallet Access Enabled',
            'Your identity has been verified. You can now access wallet features.',
            data: {'verification_id': verification.id},
          );
    }
  }

  /// Handle verification failed
  void _handleVerificationFailed(DriverDocumentVerification verification) {
    _logger.warning('⚠️ Verification failed');
    
    if (config.enableNotifications) {
      final reasons = verification.failureReasons.isNotEmpty 
          ? verification.failureReasons.join(', ')
          : 'Please check your documents and try again.';
      
      _ref.read(verificationNotificationProvider.notifier)
          .addErrorNotification(
            'Verification Failed',
            reasons,
            data: {'verification_id': verification.id},
          );
    }
  }

  /// Handle manual review required
  void _handleManualReviewRequired(DriverDocumentVerification verification) {
    _logger.info('👥 Manual review required');
    
    if (config.enableNotifications) {
      _ref.read(verificationNotificationProvider.notifier)
          .addWarningNotification(
            'Manual Review Required',
            'Our team will review your documents within 1-2 business days.',
            data: {'verification_id': verification.id},
          );
    }
  }

  /// Handle connection state changes
  void _handleConnectionState(bool isConnected) {
    if (state.isConnected != isConnected) {
      _logger.info('🔗 Connection state changed: $isConnected');
      state = state.copyWith(isConnected: isConnected);
    }
  }

  /// Handle errors
  void _handleError(String error) {
    _logger.error('❌ Status monitor error: $error');
    
    state = state.copyWith(
      error: error,
      isConnected: false,
    );
    
    if (config.enableNotifications) {
      _ref.read(verificationNotificationProvider.notifier)
          .addErrorNotification(
            'Monitoring Error',
            'There was an issue monitoring your verification status.',
          );
    }
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(config.pollingInterval, (timer) {
      state = state.copyWith(lastHeartbeat: DateTime.now());
      
      // Check connection health
      if (!state.isHealthy) {
        _logger.warning('⚠️ Monitoring health check failed');
        _handleError('Connection health check failed');
      }
    });
  }

  /// Start timeout checks
  void _startTimeoutChecks() {
    _timeoutCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForTimeouts();
    });
  }

  /// Check for processing timeouts
  void _checkForTimeouts() {
    final timeoutDocuments = state.getTimeoutDocuments(config.timeoutDuration);
    
    for (final documentId in timeoutDocuments) {
      _logger.warning('⏰ Document processing timeout: $documentId');
      
      final retryCount = state.retryAttempts[documentId] ?? 0;
      if (retryCount < config.maxRetries) {
        _retryDocumentProcessing(documentId);
      } else {
        _handleProcessingTimeout(documentId);
      }
    }
  }

  /// Retry document processing
  void _retryDocumentProcessing(String documentId) {
    _logger.info('🔄 Retrying document processing: $documentId');
    
    final updatedRetries = Map<String, int>.from(state.retryAttempts);
    updatedRetries[documentId] = (updatedRetries[documentId] ?? 0) + 1;
    
    state = state.copyWith(retryAttempts: updatedRetries);
    
    // Trigger retry through verification notifier
    final verificationNotifier = _ref.read(
      driverDocumentVerificationNotifierProvider(
        (driverId: driverId, userId: userId)
      ).notifier
    );
    
    verificationNotifier.startDocumentProcessing(documentId);
  }

  /// Handle processing timeout
  void _handleProcessingTimeout(String documentId) {
    _logger.error('⏰ Document processing timeout exceeded: $documentId');
    
    if (config.enableNotifications) {
      _ref.read(verificationNotificationProvider.notifier)
          .addErrorNotification(
            'Processing Timeout',
            'Document processing is taking longer than expected. Please try uploading again.',
            data: {'document_id': documentId},
          );
    }
  }

  /// Cleanup resources
  void _cleanup() {
    _heartbeatTimer?.cancel();
    _timeoutCheckTimer?.cancel();
    _verificationSubscription?.cancel();
    _documentsSubscription?.cancel();
    
    _heartbeatTimer = null;
    _timeoutCheckTimer = null;
    _verificationSubscription = null;
    _documentsSubscription = null;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

/// Provider for status monitor
final statusMonitorProvider = StateNotifierProvider.family<
    StatusMonitorNotifier,
    StatusMonitorState,
    ({String driverId, String userId, StatusMonitorConfig config})>((ref, params) {
  return StatusMonitorNotifier(
    driverId: params.driverId,
    userId: params.userId,
    config: params.config,
    ref: ref,
  );
});

/// Provider for current user's status monitor
final currentDriverStatusMonitorProvider = StateNotifierProvider.autoDispose<
    StatusMonitorNotifier,
    StatusMonitorState>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return StatusMonitorNotifier(
    driverId: userId, // TODO: Get actual driver ID
    userId: userId,
    config: const StatusMonitorConfig(),
    ref: ref,
  );
});

/// Provider for monitoring health status
final monitoringHealthProvider = Provider<bool>((ref) {
  final monitorState = ref.watch(currentDriverStatusMonitorProvider);
  return monitorState.isHealthy;
});
