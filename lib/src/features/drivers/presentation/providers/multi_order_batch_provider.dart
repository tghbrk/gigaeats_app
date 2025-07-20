import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/delivery_batch.dart';
import '../../data/models/batch_operation_results.dart';
import '../../data/services/multi_order_batch_service.dart';

/// Multi-order batch state
@immutable
class MultiOrderBatchState {
  final DeliveryBatch? activeBatch;
  final List<BatchOrderWithDetails> batchOrders;
  final BatchSummary? batchSummary;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const MultiOrderBatchState({
    this.activeBatch,
    this.batchOrders = const [],
    this.batchSummary,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  MultiOrderBatchState copyWith({
    DeliveryBatch? activeBatch,
    List<BatchOrderWithDetails>? batchOrders,
    BatchSummary? batchSummary,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return MultiOrderBatchState(
      activeBatch: activeBatch ?? this.activeBatch,
      batchOrders: batchOrders ?? this.batchOrders,
      batchSummary: batchSummary ?? this.batchSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Check if there's an active batch
  bool get hasActiveBatch => activeBatch != null;

  /// Check if batch is currently active
  bool get isBatchActive => activeBatch?.status == BatchStatus.active;

  /// Check if batch can be started
  bool get canStartBatch => activeBatch?.status == BatchStatus.planned;

  /// Check if batch can be paused
  bool get canPauseBatch => activeBatch?.status == BatchStatus.active;

  /// Check if batch can be resumed
  bool get canResumeBatch => activeBatch?.status == BatchStatus.paused;

  /// Check if batch can be completed
  bool get canCompleteBatch => 
      activeBatch?.status == BatchStatus.active || 
      activeBatch?.status == BatchStatus.paused;

  /// Get total orders count
  int get totalOrders => batchOrders.length;

  /// Get completed pickups count
  int get completedPickups => 
      batchOrders.where((bo) => bo.isPickupCompleted).length;

  /// Get completed deliveries count
  int get completedDeliveries => 
      batchOrders.where((bo) => bo.isDeliveryCompleted).length;

  /// Get pickup progress percentage
  double get pickupProgress {
    if (totalOrders == 0) return 0.0;
    return (completedPickups / totalOrders) * 100;
  }

  /// Get delivery progress percentage
  double get deliveryProgress {
    if (totalOrders == 0) return 0.0;
    return (completedDeliveries / totalOrders) * 100;
  }

  /// Get overall progress percentage
  double get overallProgress {
    if (totalOrders == 0) return 0.0;
    final totalSteps = totalOrders * 2; // pickup + delivery for each order
    final completedSteps = completedPickups + completedDeliveries;
    return (completedSteps / totalSteps) * 100;
  }
}

/// Multi-order batch provider
class MultiOrderBatchNotifier extends StateNotifier<MultiOrderBatchState> {
  final MultiOrderBatchService _batchService = MultiOrderBatchService();
  Timer? _refreshTimer;

  MultiOrderBatchNotifier() : super(const MultiOrderBatchState());

  /// Load active batch for driver
  Future<void> loadActiveBatch(String driverId) async {
    try {
      debugPrint('🚛 [BATCH-PROVIDER] Loading active batch for driver: $driverId');
      
      state = state.copyWith(isLoading: true, error: null);

      final batch = await _batchService.getActiveBatchForDriver(driverId);
      
      if (batch != null) {
        final batchOrders = await _batchService.getBatchOrdersWithDetails(batch.id);
        final summary = _calculateBatchSummary(batch, batchOrders);
        
        state = state.copyWith(
          activeBatch: batch,
          batchOrders: batchOrders,
          batchSummary: summary,
          isLoading: false,
        );
        
        // Start periodic refresh if batch is active
        if (batch.isActive) {
          _startPeriodicRefresh(driverId);
        }
      } else {
        state = state.copyWith(
          activeBatch: null,
          batchOrders: [],
          batchSummary: null,
          isLoading: false,
        );
      }

      debugPrint('🚛 [BATCH-PROVIDER] Active batch loaded: ${batch?.id ?? 'none'}');
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error loading active batch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load active batch: ${e.toString()}',
      );
    }
  }

  /// Create optimized batch
  Future<bool> createOptimizedBatch({
    required String driverId,
    required List<String> orderIds,
    int maxOrders = 3,
    double maxDeviationKm = 5.0,
  }) async {
    try {
      debugPrint('🚛 [BATCH-PROVIDER] Creating optimized batch for driver: $driverId');
      
      state = state.copyWith(isLoading: true, error: null);

      final result = await _batchService.createOptimizedBatch(
        driverId: driverId,
        orderIds: orderIds,
        maxOrders: maxOrders,
        maxDeviationKm: maxDeviationKm,
      );

      if (result.isSuccess && result.batch != null) {
        final batchOrders = await _batchService.getBatchOrdersWithDetails(result.batch!.id);
        final summary = _calculateBatchSummary(result.batch!, batchOrders);
        
        state = state.copyWith(
          activeBatch: result.batch,
          batchOrders: batchOrders,
          batchSummary: summary,
          isLoading: false,
          successMessage: 'Batch created successfully',
        );

        debugPrint('✅ [BATCH-PROVIDER] Batch created successfully: ${result.batch!.id}');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage ?? 'Failed to create batch',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error creating batch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create batch: ${e.toString()}',
      );
      return false;
    }
  }

  /// Start batch execution
  Future<bool> startBatch() async {
    if (state.activeBatch == null) return false;

    try {
      debugPrint('🚛 [BATCH-PROVIDER] Starting batch: ${state.activeBatch!.id}');
      
      state = state.copyWith(isLoading: true, error: null);

      final result = await _batchService.startBatch(state.activeBatch!.id);

      if (result.isSuccess) {
        final updatedBatch = state.activeBatch!.copyWith(
          status: BatchStatus.active,
          actualStartTime: DateTime.now(),
        );
        
        state = state.copyWith(
          activeBatch: updatedBatch,
          isLoading: false,
          successMessage: result.message,
        );

        // Start periodic refresh
        _startPeriodicRefresh(updatedBatch.driverId);

        debugPrint('✅ [BATCH-PROVIDER] Batch started successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error starting batch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start batch: ${e.toString()}',
      );
      return false;
    }
  }

  /// Pause batch execution
  Future<bool> pauseBatch() async {
    if (state.activeBatch == null) return false;

    try {
      debugPrint('🚛 [BATCH-PROVIDER] Pausing batch: ${state.activeBatch!.id}');
      
      state = state.copyWith(isLoading: true, error: null);

      final result = await _batchService.pauseBatch(state.activeBatch!.id);

      if (result.isSuccess) {
        final updatedBatch = state.activeBatch!.copyWith(status: BatchStatus.paused);
        
        state = state.copyWith(
          activeBatch: updatedBatch,
          isLoading: false,
          successMessage: result.message,
        );

        _stopPeriodicRefresh();

        debugPrint('✅ [BATCH-PROVIDER] Batch paused successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error pausing batch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to pause batch: ${e.toString()}',
      );
      return false;
    }
  }

  /// Resume batch execution
  Future<bool> resumeBatch() async {
    if (state.activeBatch == null) return false;

    try {
      debugPrint('🚛 [BATCH-PROVIDER] Resuming batch: ${state.activeBatch!.id}');
      
      state = state.copyWith(isLoading: true, error: null);

      final result = await _batchService.resumeBatch(state.activeBatch!.id);

      if (result.isSuccess) {
        final updatedBatch = state.activeBatch!.copyWith(status: BatchStatus.active);
        
        state = state.copyWith(
          activeBatch: updatedBatch,
          isLoading: false,
          successMessage: result.message,
        );

        // Restart periodic refresh
        _startPeriodicRefresh(updatedBatch.driverId);

        debugPrint('✅ [BATCH-PROVIDER] Batch resumed successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error resuming batch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to resume batch: ${e.toString()}',
      );
      return false;
    }
  }

  /// Complete batch execution
  Future<bool> completeBatch() async {
    if (state.activeBatch == null) return false;

    try {
      debugPrint('🚛 [BATCH-PROVIDER] Completing batch: ${state.activeBatch!.id}');
      
      state = state.copyWith(isLoading: true, error: null);

      final result = await _batchService.completeBatch(state.activeBatch!.id);

      if (result.isSuccess) {
        final updatedBatch = state.activeBatch!.copyWith(
          status: BatchStatus.completed,
          actualCompletionTime: DateTime.now(),
        );
        
        state = state.copyWith(
          activeBatch: updatedBatch,
          isLoading: false,
          successMessage: result.message,
        );

        _stopPeriodicRefresh();

        debugPrint('✅ [BATCH-PROVIDER] Batch completed successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error completing batch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete batch: ${e.toString()}',
      );
      return false;
    }
  }

  /// Cancel batch execution
  Future<bool> cancelBatch(String reason) async {
    if (state.activeBatch == null) return false;

    try {
      debugPrint('🚛 [BATCH-PROVIDER] Cancelling batch: ${state.activeBatch!.id}');
      
      state = state.copyWith(isLoading: true, error: null);

      final result = await _batchService.cancelBatch(state.activeBatch!.id, reason);

      if (result.isSuccess) {
        state = state.copyWith(
          activeBatch: null,
          batchOrders: [],
          batchSummary: null,
          isLoading: false,
          successMessage: result.message,
        );

        _stopPeriodicRefresh();

        debugPrint('✅ [BATCH-PROVIDER] Batch cancelled successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error cancelling batch: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel batch: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update batch order pickup status
  Future<bool> updatePickupStatus({
    required String orderId,
    required BatchOrderPickupStatus status,
  }) async {
    if (state.activeBatch == null) return false;

    try {
      debugPrint('🚛 [BATCH-PROVIDER] Updating pickup status for order $orderId to ${status.displayName}');

      final result = await _batchService.updateBatchOrderPickupStatus(
        batchId: state.activeBatch!.id,
        orderId: orderId,
        status: status,
      );

      if (result.isSuccess) {
        // Refresh batch orders to get updated status
        await _refreshBatchOrders();
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error updating pickup status: $e');
      state = state.copyWith(error: 'Failed to update pickup status: ${e.toString()}');
      return false;
    }
  }

  /// Update batch order delivery status
  Future<bool> updateDeliveryStatus({
    required String orderId,
    required BatchOrderDeliveryStatus status,
  }) async {
    if (state.activeBatch == null) return false;

    try {
      debugPrint('🚛 [BATCH-PROVIDER] Updating delivery status for order $orderId to ${status.displayName}');

      final result = await _batchService.updateBatchOrderDeliveryStatus(
        batchId: state.activeBatch!.id,
        orderId: orderId,
        status: status,
      );

      if (result.isSuccess) {
        // Refresh batch orders to get updated status
        await _refreshBatchOrders();
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error updating delivery status: $e');
      state = state.copyWith(error: 'Failed to update delivery status: ${e.toString()}');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Start periodic refresh of batch data
  void _startPeriodicRefresh(String driverId) {
    _stopPeriodicRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _refreshBatchData(driverId);
    });
  }

  /// Stop periodic refresh
  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Refresh batch data
  Future<void> _refreshBatchData(String driverId) async {
    if (state.activeBatch == null) return;

    try {
      final batch = await _batchService.getActiveBatchForDriver(driverId);
      if (batch != null) {
        await _refreshBatchOrders();
      } else {
        // Batch no longer exists, clear state
        state = state.copyWith(
          activeBatch: null,
          batchOrders: [],
          batchSummary: null,
        );
        _stopPeriodicRefresh();
      }
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error refreshing batch data: $e');
    }
  }

  /// Refresh batch orders
  Future<void> _refreshBatchOrders() async {
    if (state.activeBatch == null) return;

    try {
      final batchOrders = await _batchService.getBatchOrdersWithDetails(state.activeBatch!.id);
      final summary = _calculateBatchSummary(state.activeBatch!, batchOrders);

      state = state.copyWith(
        batchOrders: batchOrders,
        batchSummary: summary,
      );
    } catch (e) {
      debugPrint('❌ [BATCH-PROVIDER] Error refreshing batch orders: $e');
    }
  }

  /// Calculate batch summary
  BatchSummary _calculateBatchSummary(DeliveryBatch batch, List<BatchOrderWithDetails> batchOrders) {
    final completedPickups = batchOrders.where((bo) => bo.isPickupCompleted).length;
    final completedDeliveries = batchOrders.where((bo) => bo.isDeliveryCompleted).length;

    return BatchSummary(
      totalOrders: batchOrders.length,
      completedPickups: completedPickups,
      completedDeliveries: completedDeliveries,
      totalDistanceKm: batch.totalDistanceKm ?? 0.0,
      estimatedDurationMinutes: batch.estimatedDurationMinutes ?? 0,
      optimizationScore: batch.optimizationScore ?? 0.0,
      startTime: batch.actualStartTime,
      estimatedCompletionTime: batch.estimatedCompletionTime,
    );
  }

  @override
  void dispose() {
    debugPrint('🚛 [BATCH-PROVIDER] Disposing multi-order batch provider');
    _stopPeriodicRefresh();
    super.dispose();
  }
}

/// Multi-order batch provider
final multiOrderBatchProvider = StateNotifierProvider<MultiOrderBatchNotifier, MultiOrderBatchState>((ref) {
  return MultiOrderBatchNotifier();
});

/// Active batch provider
final activeBatchProvider = Provider<DeliveryBatch?>((ref) {
  return ref.watch(multiOrderBatchProvider).activeBatch;
});

/// Batch orders provider
final batchOrdersProvider = Provider<List<BatchOrderWithDetails>>((ref) {
  return ref.watch(multiOrderBatchProvider).batchOrders;
});

/// Batch summary provider
final batchSummaryProvider = Provider<BatchSummary?>((ref) {
  return ref.watch(multiOrderBatchProvider).batchSummary;
});

/// Batch progress provider
final batchProgressProvider = Provider<double>((ref) {
  return ref.watch(multiOrderBatchProvider).overallProgress;
});

/// Batch can start provider
final batchCanStartProvider = Provider<bool>((ref) {
  return ref.watch(multiOrderBatchProvider).canStartBatch;
});

/// Batch can pause provider
final batchCanPauseProvider = Provider<bool>((ref) {
  return ref.watch(multiOrderBatchProvider).canPauseBatch;
});

/// Batch can resume provider
final batchCanResumeProvider = Provider<bool>((ref) {
  return ref.watch(multiOrderBatchProvider).canResumeBatch;
});

/// Batch can complete provider
final batchCanCompleteProvider = Provider<bool>((ref) {
  return ref.watch(multiOrderBatchProvider).canCompleteBatch;
});
