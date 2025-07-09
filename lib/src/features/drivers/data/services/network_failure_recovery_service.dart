import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Network failure recovery service for driver workflow operations
/// Handles offline scenarios, queues operations, and syncs when connection is restored
class NetworkFailureRecoveryService {
  static const String _pendingOperationsKey = 'pending_driver_operations';
  static const String _offlineDataKey = 'offline_driver_data';
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();
  
  bool _isOnline = true;
  bool _isSyncing = false;

  /// Initialize the service and start monitoring connectivity
  Future<void> initialize() async {
    debugPrint('🔄 [NETWORK-RECOVERY] Initializing network failure recovery service');
    
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _onConnectivityChanged(results.isNotEmpty ? results.first : ConnectivityResult.none);
    });
    
    // Attempt to sync any pending operations
    if (_isOnline) {
      await syncPendingOperations();
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = !connectivityResult.contains(ConnectivityResult.none) && connectivityResult.isNotEmpty;
      
      if (!wasOnline && _isOnline) {
        debugPrint('🌐 [NETWORK-RECOVERY] Connection restored');
        await syncPendingOperations();
      } else if (wasOnline && !_isOnline) {
        debugPrint('📵 [NETWORK-RECOVERY] Connection lost - entering offline mode');
      }
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Error checking connectivity: $e');
      _isOnline = false;
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (!wasOnline && _isOnline) {
      debugPrint('🌐 [NETWORK-RECOVERY] Connection restored via listener');
      syncPendingOperations();
    } else if (wasOnline && !_isOnline) {
      debugPrint('📵 [NETWORK-RECOVERY] Connection lost via listener');
    }
  }

  /// Queue an operation for later execution when network is available
  Future<void> queueOperation({
    required String operationType,
    required Map<String, dynamic> operationData,
    required String orderId,
    String? driverId,
  }) async {
    try {
      debugPrint('📝 [NETWORK-RECOVERY] Queuing operation: $operationType for order: $orderId');
      
      final prefs = await SharedPreferences.getInstance();
      final existingOperations = prefs.getStringList(_pendingOperationsKey) ?? [];
      
      final operation = PendingOperation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: operationType,
        data: operationData,
        orderId: orderId,
        driverId: driverId,
        timestamp: DateTime.now(),
      );
      
      existingOperations.add(jsonEncode(operation.toJson()));
      await prefs.setStringList(_pendingOperationsKey, existingOperations);
      
      debugPrint('✅ [NETWORK-RECOVERY] Operation queued successfully');
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to queue operation: $e');
    }
  }

  /// Store data offline for later sync
  Future<void> storeOfflineData({
    required String dataType,
    required String dataId,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('💾 [NETWORK-RECOVERY] Storing offline data: $dataType/$dataId');
      
      final prefs = await SharedPreferences.getInstance();
      final offlineDataJson = prefs.getString(_offlineDataKey) ?? '{}';
      final offlineData = jsonDecode(offlineDataJson) as Map<String, dynamic>;
      
      if (offlineData[dataType] == null) {
        offlineData[dataType] = <String, dynamic>{};
      }
      
      offlineData[dataType][dataId] = {
        ...data,
        'stored_at': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_offlineDataKey, jsonEncode(offlineData));
      debugPrint('✅ [NETWORK-RECOVERY] Offline data stored successfully');
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to store offline data: $e');
    }
  }

  /// Get offline data
  Future<Map<String, dynamic>?> getOfflineData({
    required String dataType,
    required String dataId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataJson = prefs.getString(_offlineDataKey) ?? '{}';
      final offlineData = jsonDecode(offlineDataJson) as Map<String, dynamic>;
      
      return offlineData[dataType]?[dataId] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to get offline data: $e');
      return null;
    }
  }

  /// Sync all pending operations when network is restored
  Future<void> syncPendingOperations() async {
    if (_isSyncing || !_isOnline) return;
    
    _isSyncing = true;
    debugPrint('🔄 [NETWORK-RECOVERY] Starting sync of pending operations');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOperations = prefs.getStringList(_pendingOperationsKey) ?? [];
      
      if (pendingOperations.isEmpty) {
        debugPrint('✅ [NETWORK-RECOVERY] No pending operations to sync');
        return;
      }
      
      debugPrint('📊 [NETWORK-RECOVERY] Found ${pendingOperations.length} pending operations');
      
      final successfulOperations = <String>[];
      
      for (final operationJson in pendingOperations) {
        try {
          final operationData = jsonDecode(operationJson) as Map<String, dynamic>;
          final operation = PendingOperation.fromJson(operationData);
          
          debugPrint('🔄 [NETWORK-RECOVERY] Syncing operation: ${operation.type} for order: ${operation.orderId}');
          
          final success = await _executeOperation(operation);
          if (success) {
            successfulOperations.add(operationJson);
            debugPrint('✅ [NETWORK-RECOVERY] Successfully synced operation: ${operation.id}');
          } else {
            debugPrint('❌ [NETWORK-RECOVERY] Failed to sync operation: ${operation.id}');
          }
        } catch (e) {
          debugPrint('❌ [NETWORK-RECOVERY] Error processing operation: $e');
        }
      }
      
      // Remove successfully synced operations
      if (successfulOperations.isNotEmpty) {
        final remainingOperations = pendingOperations
            .where((op) => !successfulOperations.contains(op))
            .toList();
        
        await prefs.setStringList(_pendingOperationsKey, remainingOperations);
        debugPrint('✅ [NETWORK-RECOVERY] Removed ${successfulOperations.length} synced operations');
      }
      
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a pending operation
  Future<bool> _executeOperation(PendingOperation operation) async {
    try {
      switch (operation.type) {
        case 'status_update':
          return await _executeStatusUpdate(operation);
        case 'pickup_confirmation':
          return await _executePickupConfirmation(operation);
        case 'delivery_confirmation':
          return await _executeDeliveryConfirmation(operation);
        case 'location_update':
          return await _executeLocationUpdate(operation);
        default:
          debugPrint('❌ [NETWORK-RECOVERY] Unknown operation type: ${operation.type}');
          return false;
      }
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Error executing operation ${operation.id}: $e');
      return false;
    }
  }

  /// Execute status update operation
  Future<bool> _executeStatusUpdate(PendingOperation operation) async {
    try {
      await _supabase.rpc('update_driver_order_status_v2', params: {
        'p_order_id': operation.orderId,
        'p_new_status': operation.data['new_status'],
        'p_notes': operation.data['notes'] ?? 'Synced from offline operation',
      });
      return true;
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to execute status update: $e');
      return false;
    }
  }

  /// Execute pickup confirmation operation
  Future<bool> _executePickupConfirmation(PendingOperation operation) async {
    try {
      await _supabase.from('pickup_confirmations').insert(operation.data);
      return true;
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to execute pickup confirmation: $e');
      return false;
    }
  }

  /// Execute delivery confirmation operation
  Future<bool> _executeDeliveryConfirmation(PendingOperation operation) async {
    try {
      await _supabase.from('delivery_confirmations').insert(operation.data);
      return true;
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to execute delivery confirmation: $e');
      return false;
    }
  }

  /// Execute location update operation
  Future<bool> _executeLocationUpdate(PendingOperation operation) async {
    try {
      await _supabase.from('order_tracking').upsert(operation.data);
      return true;
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to execute location update: $e');
      return false;
    }
  }

  /// Get pending operations count
  Future<int> getPendingOperationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOperations = prefs.getStringList(_pendingOperationsKey) ?? [];
      return pendingOperations.length;
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to get pending operations count: $e');
      return 0;
    }
  }

  /// Clear all pending operations (use with caution)
  Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOperationsKey);
      debugPrint('✅ [NETWORK-RECOVERY] Cleared all pending operations');
    } catch (e) {
      debugPrint('❌ [NETWORK-RECOVERY] Failed to clear pending operations: $e');
    }
  }

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;
}

/// Represents a pending operation to be executed when network is restored
class PendingOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final String orderId;
  final String? driverId;
  final DateTime timestamp;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.orderId,
    this.driverId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'order_id': orderId,
      'driver_id': driverId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      orderId: json['order_id'],
      driverId: json['driver_id'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Provider for network failure recovery service
final networkFailureRecoveryServiceProvider = Provider<NetworkFailureRecoveryService>((ref) {
  return NetworkFailureRecoveryService();
});

/// Provider for network status
final networkStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map((results) =>
    !results.contains(ConnectivityResult.none) && results.isNotEmpty);
});

/// Provider for pending operations count
final pendingOperationsCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(networkFailureRecoveryServiceProvider);
  return service.getPendingOperationsCount();
});
