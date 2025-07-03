import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_cart_models.dart';
import '../models/customer_delivery_method.dart';
import '../../../core/utils/logger.dart';
import '../../../../core/constants/app_constants.dart';

/// Comprehensive cart persistence service with versioning and migration support
class CartPersistenceService {
  static const String _cartKey = 'enhanced_cart_v3';
  static const String _cartBackupKey = 'enhanced_cart_backup_v3';
  static const String _cartHistoryKey = 'cart_history_v3';
  static const String _cartMetadataKey = 'cart_metadata_v3';

  static const int _currentVersion = 3;
  static const int _maxHistoryEntries = 50;
  static const Duration _cartExpirationDuration = Duration(days: 7);

  final AppLogger _logger = AppLogger();
  final SharedPreferences _prefs;

  CartPersistenceService(this._prefs);

  /// Save cart state with versioning and backup
  Future<CartPersistenceResult> saveCart(EnhancedCartState cartState) async {
    try {
      _logger.info('💾 [CART-PERSISTENCE] Saving cart with ${cartState.items.length} items');

      // Create backup of current cart before saving new one
      await _createBackup();

      // Prepare cart data with metadata
      final cartData = {
        'version': _currentVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': await _getCurrentUserId(),
        'deviceId': await _getDeviceId(),
        'cartState': cartState.toJson(),
        'checksum': _calculateChecksum(cartState),
      };

      // Save main cart data
      final cartJson = json.encode(cartData);
      await _prefs.setString(_cartKey, cartJson);

      // Update metadata
      await _updateMetadata(cartState);

      // Add to history
      await _addToHistory(cartState);

      _logger.info('✅ [CART-PERSISTENCE] Cart saved successfully');
      return CartPersistenceResult.success();

    } catch (e) {
      _logger.error('❌ [CART-PERSISTENCE] Failed to save cart', e);
      return CartPersistenceResult.failure('Failed to save cart: $e');
    }
  }

  /// Load cart state with validation and migration
  Future<CartLoadResult> loadCart() async {
    try {
      _logger.info('📱 [CART-PERSISTENCE] Loading persisted cart');

      final cartJson = _prefs.getString(_cartKey);
      if (cartJson == null) {
        _logger.info('📱 [CART-PERSISTENCE] No persisted cart found');
        return CartLoadResult.empty();
      }

      final cartData = json.decode(cartJson) as Map<String, dynamic>;

      // Check version and migrate if necessary
      final version = cartData['version'] as int? ?? 1;
      if (version < _currentVersion) {
        _logger.info('🔄 [CART-PERSISTENCE] Migrating cart from version $version to $_currentVersion');
        final migratedData = await _migrateCart(cartData, version);
        if (migratedData != null) {
          cartData.addAll(migratedData);
        }
      }

      // Validate cart data
      final validationResult = await _validateCartData(cartData);
      if (!validationResult.isValid) {
        _logger.warning('⚠️ [CART-PERSISTENCE] Cart validation failed: ${validationResult.errors}');
        
        // Try to load backup
        final backupResult = await _loadBackup();
        if (backupResult.isSuccess) {
          return backupResult;
        }
        
        return CartLoadResult.failure('Cart validation failed: ${validationResult.errors.join(', ')}');
      }

      // Check expiration
      final timestamp = DateTime.parse(cartData['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > _cartExpirationDuration) {
        _logger.info('⏰ [CART-PERSISTENCE] Cart expired, clearing');
        await clearCart();
        return CartLoadResult.empty();
      }

      // Verify checksum
      final storedChecksum = cartData['checksum'] as String?;
      final cartStateData = cartData['cartState'] as Map<String, dynamic>;
      final cartState = EnhancedCartState.fromJson(cartStateData);
      final calculatedChecksum = _calculateChecksum(cartState);

      if (storedChecksum != calculatedChecksum) {
        _logger.warning('⚠️ [CART-PERSISTENCE] Cart checksum mismatch, data may be corrupted');
        // Continue loading but mark as potentially corrupted
      }

      // Validate cart items are still available
      final validatedCartState = await _validateCartItems(cartState);

      _logger.info('✅ [CART-PERSISTENCE] Cart loaded successfully with ${validatedCartState.items.length} items');
      return CartLoadResult.success(validatedCartState);

    } catch (e) {
      _logger.error('❌ [CART-PERSISTENCE] Failed to load cart', e);
      
      // Try to load backup on error
      final backupResult = await _loadBackup();
      if (backupResult.isSuccess) {
        return backupResult;
      }
      
      return CartLoadResult.failure('Failed to load cart: $e');
    }
  }

  /// Clear cart and all related data
  Future<void> clearCart() async {
    try {
      _logger.info('🧹 [CART-PERSISTENCE] Clearing cart');

      await _prefs.remove(_cartKey);
      await _prefs.remove(_cartBackupKey);
      await _updateMetadata(null);

      _logger.info('✅ [CART-PERSISTENCE] Cart cleared successfully');
    } catch (e) {
      _logger.error('❌ [CART-PERSISTENCE] Failed to clear cart', e);
    }
  }

  /// Get cart history for analytics
  Future<List<CartHistoryEntry>> getCartHistory() async {
    try {
      final historyJson = _prefs.getString(_cartHistoryKey);
      if (historyJson == null) return [];

      final historyData = json.decode(historyJson) as List<dynamic>;
      return historyData
          .map((entry) => CartHistoryEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('❌ [CART-PERSISTENCE] Failed to get cart history', e);
      return [];
    }
  }

  /// Get cart metadata
  Future<CartMetadata?> getCartMetadata() async {
    try {
      final metadataJson = _prefs.getString(_cartMetadataKey);
      if (metadataJson == null) return null;

      final metadataData = json.decode(metadataJson) as Map<String, dynamic>;
      return CartMetadata.fromJson(metadataData);
    } catch (e) {
      _logger.error('❌ [CART-PERSISTENCE] Failed to get cart metadata', e);
      return null;
    }
  }

  /// Create backup of current cart
  Future<void> _createBackup() async {
    try {
      final currentCart = _prefs.getString(_cartKey);
      if (currentCart != null) {
        await _prefs.setString(_cartBackupKey, currentCart);
        _logger.debug('💾 [CART-PERSISTENCE] Backup created');
      }
    } catch (e) {
      _logger.warning('Failed to create cart backup: $e');
    }
  }

  /// Load backup cart
  Future<CartLoadResult> _loadBackup() async {
    try {
      _logger.info('🔄 [CART-PERSISTENCE] Loading backup cart');

      final backupJson = _prefs.getString(_cartBackupKey);
      if (backupJson == null) {
        return CartLoadResult.failure('No backup available');
      }

      final cartData = json.decode(backupJson) as Map<String, dynamic>;
      final cartStateData = cartData['cartState'] as Map<String, dynamic>;
      final cartState = EnhancedCartState.fromJson(cartStateData);

      _logger.info('✅ [CART-PERSISTENCE] Backup cart loaded successfully');
      return CartLoadResult.success(cartState);

    } catch (e) {
      _logger.error('❌ [CART-PERSISTENCE] Failed to load backup', e);
      return CartLoadResult.failure('Failed to load backup: $e');
    }
  }

  /// Migrate cart data between versions
  Future<Map<String, dynamic>?> _migrateCart(Map<String, dynamic> cartData, int fromVersion) async {
    try {
      _logger.info('🔄 [CART-PERSISTENCE] Migrating cart from version $fromVersion');

      // Add migration logic here for different versions
      switch (fromVersion) {
        case 1:
          // Migrate from v1 to v2
          cartData = await _migrateFromV1ToV2(cartData);
          continue v2Migration;
        
        v2Migration:
        case 2:
          // Migrate from v2 to v3
          cartData = await _migrateFromV2ToV3(cartData);
          break;
      }

      cartData['version'] = _currentVersion;
      return cartData;

    } catch (e) {
      _logger.error('❌ [CART-PERSISTENCE] Migration failed', e);
      return null;
    }
  }

  /// Migrate from version 1 to version 2
  Future<Map<String, dynamic>> _migrateFromV1ToV2(Map<String, dynamic> cartData) async {
    // Add migration logic for v1 to v2
    // For example: add new fields, restructure data, etc.
    return cartData;
  }

  /// Migrate from version 2 to version 3
  Future<Map<String, dynamic>> _migrateFromV2ToV3(Map<String, dynamic> cartData) async {
    // Add migration logic for v2 to v3
    // For example: add enhanced cart features, new validation, etc.
    return cartData;
  }

  /// Validate cart data integrity
  Future<CartValidationResult> _validateCartData(Map<String, dynamic> cartData) async {
    final errors = <String>[];

    // Check required fields
    if (!cartData.containsKey('cartState')) {
      errors.add('Missing cart state data');
    }

    if (!cartData.containsKey('timestamp')) {
      errors.add('Missing timestamp');
    }

    // Validate timestamp format
    try {
      DateTime.parse(cartData['timestamp'] as String);
    } catch (e) {
      errors.add('Invalid timestamp format');
    }

    // Validate cart state structure
    try {
      final cartStateData = cartData['cartState'] as Map<String, dynamic>;
      EnhancedCartState.fromJson(cartStateData);
    } catch (e) {
      errors.add('Invalid cart state structure: $e');
    }

    return errors.isEmpty 
        ? CartValidationResult.valid()
        : CartValidationResult.invalid(errors);
  }

  /// Validate cart items are still available
  Future<EnhancedCartState> _validateCartItems(EnhancedCartState cartState) async {
    // TODO: Implement real-time validation against database
    // For now, return cart as-is
    // In a real implementation, you would:
    // 1. Check item availability
    // 2. Validate pricing
    // 3. Update quantities if needed
    // 4. Remove unavailable items
    
    return cartState;
  }

  /// Calculate checksum for cart data integrity
  String _calculateChecksum(EnhancedCartState cartState) {
    final dataString = json.encode(cartState.toJson());
    return dataString.hashCode.toString();
  }

  /// Update cart metadata
  Future<void> _updateMetadata(EnhancedCartState? cartState) async {
    try {
      final metadata = CartMetadata(
        lastUpdated: DateTime.now(),
        itemCount: cartState?.items.length ?? 0,
        totalAmount: cartState?.totalAmount ?? 0.0,
        version: _currentVersion,
      );

      final metadataJson = json.encode(metadata.toJson());
      await _prefs.setString(_cartMetadataKey, metadataJson);
    } catch (e) {
      _logger.warning('Failed to update cart metadata: $e');
    }
  }

  /// Add cart state to history
  Future<void> _addToHistory(EnhancedCartState cartState) async {
    try {
      if (cartState.isEmpty) return;

      final historyJson = _prefs.getString(_cartHistoryKey);
      List<Map<String, dynamic>> history = [];
      
      if (historyJson != null) {
        history = List<Map<String, dynamic>>.from(json.decode(historyJson));
      }

      // Add new entry
      final entry = CartHistoryEntry(
        timestamp: DateTime.now(),
        itemCount: cartState.items.length,
        totalAmount: cartState.totalAmount,
        vendorIds: cartState.itemsByVendor.keys.toList(),
        deliveryMethod: cartState.deliveryMethod.value,
      );

      history.add(entry.toJson());

      // Keep only recent entries
      if (history.length > _maxHistoryEntries) {
        history = history.sublist(history.length - _maxHistoryEntries);
      }

      await _prefs.setString(_cartHistoryKey, json.encode(history));
    } catch (e) {
      _logger.warning('Failed to add cart to history: $e');
    }
  }

  /// Get current user ID
  Future<String?> _getCurrentUserId() async {
    return _prefs.getString(AppConstants.keyUserId);
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    // TODO: Implement proper device ID generation
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Cart persistence result
class CartPersistenceResult {
  final bool isSuccess;
  final String? error;

  CartPersistenceResult._(this.isSuccess, this.error);

  factory CartPersistenceResult.success() => CartPersistenceResult._(true, null);
  factory CartPersistenceResult.failure(String error) => CartPersistenceResult._(false, error);
}

/// Cart load result
class CartLoadResult {
  final bool isSuccess;
  final EnhancedCartState? cartState;
  final String? error;

  CartLoadResult._(this.isSuccess, this.cartState, this.error);

  factory CartLoadResult.success(EnhancedCartState cartState) => 
      CartLoadResult._(true, cartState, null);
  factory CartLoadResult.empty() => 
      CartLoadResult._(true, EnhancedCartState.empty(), null);
  factory CartLoadResult.failure(String error) => 
      CartLoadResult._(false, null, error);
}

/// Cart history entry
class CartHistoryEntry {
  final DateTime timestamp;
  final int itemCount;
  final double totalAmount;
  final List<String> vendorIds;
  final String deliveryMethod;

  CartHistoryEntry({
    required this.timestamp,
    required this.itemCount,
    required this.totalAmount,
    required this.vendorIds,
    required this.deliveryMethod,
  });

  factory CartHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CartHistoryEntry(
      timestamp: DateTime.parse(json['timestamp']),
      itemCount: json['itemCount'],
      totalAmount: json['totalAmount'],
      vendorIds: List<String>.from(json['vendorIds']),
      deliveryMethod: json['deliveryMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'itemCount': itemCount,
      'totalAmount': totalAmount,
      'vendorIds': vendorIds,
      'deliveryMethod': deliveryMethod,
    };
  }
}

/// Cart metadata
class CartMetadata {
  final DateTime lastUpdated;
  final int itemCount;
  final double totalAmount;
  final int version;

  CartMetadata({
    required this.lastUpdated,
    required this.itemCount,
    required this.totalAmount,
    required this.version,
  });

  factory CartMetadata.fromJson(Map<String, dynamic> json) {
    return CartMetadata(
      lastUpdated: DateTime.parse(json['lastUpdated']),
      itemCount: json['itemCount'],
      totalAmount: json['totalAmount'],
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated.toIso8601String(),
      'itemCount': itemCount,
      'totalAmount': totalAmount,
      'version': version,
    };
  }
}

/// Cart persistence service provider
final cartPersistenceServiceProvider = Provider<CartPersistenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CartPersistenceService(prefs);
});

/// Shared preferences provider (if not already defined)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});
