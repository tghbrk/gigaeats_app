import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enhanced_cart_models.dart';
import '../../../core/utils/logger.dart';
import 'cart_persistence_service.dart';

/// Cart synchronization service for cloud backup and multi-device sync
class CartSyncService {
  static const String _cartSyncTable = 'user_cart_sync';
  static const Duration _syncTimeout = Duration(seconds: 30);

  final SupabaseClient _supabase = Supabase.instance.client;
  final CartPersistenceService _persistenceService;
  final AppLogger _logger = AppLogger();

  CartSyncService(this._persistenceService);

  /// Sync cart to cloud
  Future<CartSyncResult> syncToCloud(EnhancedCartState cartState) async {
    try {
      _logger.info('☁️ [CART-SYNC] Syncing cart to cloud');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return CartSyncResult.failure('User not authenticated');
      }

      // Prepare sync data
      final syncData = {
        'user_id': user.id,
        'cart_data': cartState.toJson(),
        'device_id': await _getDeviceId(),
        'version': 3,
        'synced_at': DateTime.now().toIso8601String(),
        'checksum': _calculateChecksum(cartState),
      };

      // Upsert cart data
      await _supabase
          .from(_cartSyncTable)
          .upsert(syncData)
          .timeout(_syncTimeout);

      _logger.info('✅ [CART-SYNC] Cart synced to cloud successfully');
      return CartSyncResult.success();

    } catch (e) {
      _logger.error('❌ [CART-SYNC] Failed to sync cart to cloud', e);
      return CartSyncResult.failure('Failed to sync to cloud: $e');
    }
  }

  /// Sync cart from cloud
  Future<CartSyncResult> syncFromCloud() async {
    try {
      _logger.info('☁️ [CART-SYNC] Syncing cart from cloud');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return CartSyncResult.failure('User not authenticated');
      }

      // Fetch cart data from cloud
      final response = await _supabase
          .from(_cartSyncTable)
          .select()
          .eq('user_id', user.id)
          .order('synced_at', ascending: false)
          .limit(1)
          .timeout(_syncTimeout);

      if (response.isEmpty) {
        _logger.info('📱 [CART-SYNC] No cloud cart data found');
        return CartSyncResult.success();
      }

      final cloudData = response.first;
      final cartData = cloudData['cart_data'] as Map<String, dynamic>;
      final cloudCart = EnhancedCartState.fromJson(cartData);

      // Verify checksum
      final storedChecksum = cloudData['checksum'] as String?;
      final calculatedChecksum = _calculateChecksum(cloudCart);

      if (storedChecksum != calculatedChecksum) {
        _logger.warning('⚠️ [CART-SYNC] Cloud cart checksum mismatch');
        return CartSyncResult.failure('Cloud cart data corrupted');
      }

      // Check if cloud cart is newer than local
      final localResult = await _persistenceService.loadCart();
      if (localResult.isSuccess && localResult.cartState != null) {
        final localCart = localResult.cartState!;
        final cloudSyncTime = DateTime.parse(cloudData['synced_at']);

        if (localCart.lastUpdated.isAfter(cloudSyncTime)) {
          _logger.info('📱 [CART-SYNC] Local cart is newer, skipping cloud sync');
          return CartSyncResult.success();
        }
      }

      // Save cloud cart locally
      final saveResult = await _persistenceService.saveCart(cloudCart);
      if (saveResult.isSuccess) {
        _logger.info('✅ [CART-SYNC] Cart synced from cloud successfully');
        return CartSyncResult.successWithData(cloudCart);
      } else {
        return CartSyncResult.failure('Failed to save cloud cart locally');
      }

    } catch (e) {
      _logger.error('❌ [CART-SYNC] Failed to sync cart from cloud', e);
      return CartSyncResult.failure('Failed to sync from cloud: $e');
    }
  }

  /// Perform bidirectional sync
  Future<CartSyncResult> performBidirectionalSync(EnhancedCartState localCart) async {
    try {
      _logger.info('🔄 [CART-SYNC] Performing bidirectional sync');

      // First, try to sync from cloud
      final fromCloudResult = await syncFromCloud();
      if (!fromCloudResult.isSuccess) {
        return fromCloudResult;
      }

      // If cloud had newer data, use that
      if (fromCloudResult.cartState != null) {
        return fromCloudResult;
      }

      // Otherwise, sync local cart to cloud
      return await syncToCloud(localCart);

    } catch (e) {
      _logger.error('❌ [CART-SYNC] Bidirectional sync failed', e);
      return CartSyncResult.failure('Bidirectional sync failed: $e');
    }
  }

  /// Delete cart from cloud
  Future<CartSyncResult> deleteFromCloud() async {
    try {
      _logger.info('🗑️ [CART-SYNC] Deleting cart from cloud');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return CartSyncResult.failure('User not authenticated');
      }

      await _supabase
          .from(_cartSyncTable)
          .delete()
          .eq('user_id', user.id)
          .timeout(_syncTimeout);

      _logger.info('✅ [CART-SYNC] Cart deleted from cloud successfully');
      return CartSyncResult.success();

    } catch (e) {
      _logger.error('❌ [CART-SYNC] Failed to delete cart from cloud', e);
      return CartSyncResult.failure('Failed to delete from cloud: $e');
    }
  }

  /// Get sync status
  Future<CartSyncStatus> getSyncStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return CartSyncStatus.notAuthenticated();
      }

      // Check cloud cart
      final response = await _supabase
          .from(_cartSyncTable)
          .select('synced_at, device_id')
          .eq('user_id', user.id)
          .order('synced_at', ascending: false)
          .limit(1)
          .timeout(_syncTimeout);

      if (response.isEmpty) {
        return CartSyncStatus.noCloudData();
      }

      final cloudData = response.first;
      final cloudSyncTime = DateTime.parse(cloudData['synced_at']);
      final cloudDeviceId = cloudData['device_id'] as String;

      // Check local cart
      final localResult = await _persistenceService.loadCart();
      if (!localResult.isSuccess || localResult.cartState == null) {
        return CartSyncStatus.noLocalData(cloudSyncTime);
      }

      final localCart = localResult.cartState!;
      final currentDeviceId = await _getDeviceId();

      if (cloudDeviceId == currentDeviceId) {
        return CartSyncStatus.synced(cloudSyncTime);
      } else if (localCart.lastUpdated.isAfter(cloudSyncTime)) {
        return CartSyncStatus.localNewer(localCart.lastUpdated, cloudSyncTime);
      } else {
        return CartSyncStatus.cloudNewer(localCart.lastUpdated, cloudSyncTime);
      }

    } catch (e) {
      _logger.error('❌ [CART-SYNC] Failed to get sync status', e);
      return CartSyncStatus.error(e.toString());
    }
  }

  /// Calculate checksum for cart data
  String _calculateChecksum(EnhancedCartState cartState) {
    final dataString = json.encode(cartState.toJson());
    return dataString.hashCode.toString();
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    // TODO: Implement proper device ID generation
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Cart sync result
class CartSyncResult {
  final bool isSuccess;
  final String? error;
  final EnhancedCartState? cartState;

  CartSyncResult._(this.isSuccess, this.error, this.cartState);

  factory CartSyncResult.success() => CartSyncResult._(true, null, null);
  factory CartSyncResult.successWithData(EnhancedCartState cartState) => 
      CartSyncResult._(true, null, cartState);
  factory CartSyncResult.failure(String error) => CartSyncResult._(false, error, null);
}

/// Cart sync status
class CartSyncStatus {
  final CartSyncState state;
  final DateTime? localTime;
  final DateTime? cloudTime;
  final String? error;

  CartSyncStatus._(this.state, this.localTime, this.cloudTime, this.error);

  factory CartSyncStatus.synced(DateTime syncTime) => 
      CartSyncStatus._(CartSyncState.synced, syncTime, syncTime, null);
  factory CartSyncStatus.localNewer(DateTime localTime, DateTime cloudTime) => 
      CartSyncStatus._(CartSyncState.localNewer, localTime, cloudTime, null);
  factory CartSyncStatus.cloudNewer(DateTime localTime, DateTime cloudTime) => 
      CartSyncStatus._(CartSyncState.cloudNewer, localTime, cloudTime, null);
  factory CartSyncStatus.noLocalData(DateTime cloudTime) => 
      CartSyncStatus._(CartSyncState.noLocalData, null, cloudTime, null);
  factory CartSyncStatus.noCloudData() => 
      CartSyncStatus._(CartSyncState.noCloudData, null, null, null);
  factory CartSyncStatus.notAuthenticated() => 
      CartSyncStatus._(CartSyncState.notAuthenticated, null, null, null);
  factory CartSyncStatus.error(String error) => 
      CartSyncStatus._(CartSyncState.error, null, null, error);

  bool get needsSync => state == CartSyncState.localNewer || state == CartSyncState.cloudNewer;
  bool get canSync => state != CartSyncState.notAuthenticated && state != CartSyncState.error;
}

/// Cart sync state enum
enum CartSyncState {
  synced,
  localNewer,
  cloudNewer,
  noLocalData,
  noCloudData,
  notAuthenticated,
  error,
}

/// SQL for creating the cart sync table (to be added to Supabase migrations)
const String cartSyncTableSQL = '''
CREATE TABLE IF NOT EXISTS user_cart_sync (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  cart_data JSONB NOT NULL,
  device_id TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 3,
  checksum TEXT NOT NULL,
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, device_id)
);

-- Enable RLS
ALTER TABLE user_cart_sync ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage their own cart sync data" ON user_cart_sync
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_cart_sync_user_id ON user_cart_sync(user_id);
CREATE INDEX IF NOT EXISTS idx_user_cart_sync_synced_at ON user_cart_sync(synced_at);
''';

/// Cart sync service provider
final cartSyncServiceProvider = Provider<CartSyncService>((ref) {
  final persistenceService = ref.watch(cartPersistenceServiceProvider);
  return CartSyncService(persistenceService);
});
