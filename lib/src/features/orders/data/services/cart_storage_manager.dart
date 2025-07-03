import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../models/enhanced_cart_models.dart';
import '../../../core/utils/logger.dart';

import 'cart_persistence_service.dart';

/// Comprehensive cart storage manager with automatic sync and conflict resolution
class CartStorageManager {

  static const Duration _autoSaveInterval = Duration(seconds: 30);
  static const Duration _syncInterval = Duration(minutes: 5);

  final CartPersistenceService _persistenceService;
  final AppLogger _logger = AppLogger();
  
  Timer? _autoSaveTimer;
  Timer? _syncTimer;
  StreamController<CartStorageEvent>? _eventController;
  
  bool _isInitialized = false;
  bool _isSyncing = false;

  CartStorageManager(this._persistenceService);

  /// Initialize the storage manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('🔧 [CART-STORAGE] Initializing cart storage manager');

      // Initialize event stream
      _eventController = StreamController<CartStorageEvent>.broadcast();

      // Start auto-save timer
      _startAutoSaveTimer();

      // Start sync timer
      _startSyncTimer();

      _isInitialized = true;
      _logger.info('✅ [CART-STORAGE] Cart storage manager initialized');

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to initialize storage manager', e);
      rethrow;
    }
  }

  /// Dispose the storage manager
  void dispose() {
    _autoSaveTimer?.cancel();
    _syncTimer?.cancel();
    _eventController?.close();
    _isInitialized = false;
    _logger.info('🔧 [CART-STORAGE] Cart storage manager disposed');
  }

  /// Get storage events stream
  Stream<CartStorageEvent> get events => _eventController?.stream ?? const Stream.empty();

  /// Save cart with automatic conflict resolution
  Future<CartStorageResult> saveCart(EnhancedCartState cartState, {bool force = false}) async {
    if (!_isInitialized) await initialize();

    try {
      _logger.debug('💾 [CART-STORAGE] Saving cart with ${cartState.items.length} items');

      // Check for conflicts if not forced
      if (!force) {
        final conflictResult = await _checkForConflicts(cartState);
        if (conflictResult.hasConflict) {
          _eventController?.add(CartStorageEvent.conflict(conflictResult));
          return CartStorageResult.conflict(conflictResult);
        }
      }

      // Save cart
      final saveResult = await _persistenceService.saveCart(cartState);
      
      if (saveResult.isSuccess) {
        _eventController?.add(CartStorageEvent.saved(cartState));
        _logger.debug('✅ [CART-STORAGE] Cart saved successfully');
        return CartStorageResult.success();
      } else {
        _eventController?.add(CartStorageEvent.error(saveResult.error ?? 'Unknown error'));
        return CartStorageResult.failure(saveResult.error ?? 'Failed to save cart');
      }

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to save cart', e);
      _eventController?.add(CartStorageEvent.error(e.toString()));
      return CartStorageResult.failure('Failed to save cart: $e');
    }
  }

  /// Load cart with validation
  Future<CartLoadResult> loadCart() async {
    if (!_isInitialized) await initialize();

    try {
      _logger.debug('📱 [CART-STORAGE] Loading cart');

      final loadResult = await _persistenceService.loadCart();
      
      if (loadResult.isSuccess) {
        _eventController?.add(CartStorageEvent.loaded(loadResult.cartState!));
        _logger.debug('✅ [CART-STORAGE] Cart loaded successfully');
      } else if (loadResult.error != null) {
        _eventController?.add(CartStorageEvent.error(loadResult.error!));
      }

      return loadResult;

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to load cart', e);
      _eventController?.add(CartStorageEvent.error(e.toString()));
      return CartLoadResult.failure('Failed to load cart: $e');
    }
  }

  /// Clear cart storage
  Future<void> clearCart() async {
    if (!_isInitialized) await initialize();

    try {
      _logger.info('🧹 [CART-STORAGE] Clearing cart storage');

      await _persistenceService.clearCart();
      _eventController?.add(CartStorageEvent.cleared());

      _logger.info('✅ [CART-STORAGE] Cart storage cleared');

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to clear cart', e);
      _eventController?.add(CartStorageEvent.error(e.toString()));
    }
  }

  /// Get cart storage statistics
  Future<CartStorageStats> getStorageStats() async {
    try {
      final metadata = await _persistenceService.getCartMetadata();
      final history = await _persistenceService.getCartHistory();

      return CartStorageStats(
        lastUpdated: metadata?.lastUpdated,
        itemCount: metadata?.itemCount ?? 0,
        totalAmount: metadata?.totalAmount ?? 0.0,
        historyEntries: history.length,
        version: metadata?.version ?? 1,
      );

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to get storage stats', e);
      return CartStorageStats(
        lastUpdated: null,
        itemCount: 0,
        totalAmount: 0.0,
        historyEntries: 0,
        version: 1,
      );
    }
  }

  /// Export cart data for backup
  Future<Map<String, dynamic>?> exportCartData() async {
    try {
      final loadResult = await _persistenceService.loadCart();
      if (loadResult.isSuccess && loadResult.cartState != null) {
        return {
          'version': 3,
          'exportedAt': DateTime.now().toIso8601String(),
          'cartState': loadResult.cartState!.toJson(),
          'metadata': (await _persistenceService.getCartMetadata())?.toJson(),
          'history': (await _persistenceService.getCartHistory())
              .map((entry) => entry.toJson())
              .toList(),
        };
      }
      return null;
    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to export cart data', e);
      return null;
    }
  }

  /// Import cart data from backup
  Future<CartStorageResult> importCartData(Map<String, dynamic> data) async {
    try {
      _logger.info('📥 [CART-STORAGE] Importing cart data');

      // Validate import data
      if (!data.containsKey('cartState')) {
        return CartStorageResult.failure('Invalid import data: missing cart state');
      }

      final cartStateData = data['cartState'] as Map<String, dynamic>;
      final cartState = EnhancedCartState.fromJson(cartStateData);

      // Save imported cart
      return await saveCart(cartState, force: true);

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to import cart data', e);
      return CartStorageResult.failure('Failed to import cart data: $e');
    }
  }

  /// Start auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
      // Auto-save logic would go here
      // For now, we'll just emit a periodic event
      _eventController?.add(CartStorageEvent.autoSaveTriggered());
    });
  }

  /// Start sync timer
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performSync();
    });
  }

  /// Perform background sync
  Future<void> _performSync() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      _logger.debug('🔄 [CART-STORAGE] Performing background sync');

      // TODO: Implement cloud sync logic here
      // For now, just emit sync event
      _eventController?.add(CartStorageEvent.syncCompleted());

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Sync failed', e);
      _eventController?.add(CartStorageEvent.syncFailed(e.toString()));
    } finally {
      _isSyncing = false;
    }
  }

  /// Check for storage conflicts
  Future<CartConflictResult> _checkForConflicts(EnhancedCartState newCartState) async {
    try {
      // Load current cart
      final currentResult = await _persistenceService.loadCart();
      if (!currentResult.isSuccess || currentResult.cartState == null) {
        return CartConflictResult.noConflict();
      }

      final currentCart = currentResult.cartState!;

      // Check for conflicts
      final conflicts = <String>[];

      // Check if items have been modified
      if (currentCart.lastUpdated.isAfter(newCartState.lastUpdated)) {
        conflicts.add('Cart has been modified since last update');
      }

      // Check for item conflicts
      final currentItemIds = currentCart.items.map((item) => item.id).toSet();
      final newItemIds = newCartState.items.map((item) => item.id).toSet();

      if (currentItemIds != newItemIds) {
        conflicts.add('Cart items have changed');
      }

      return conflicts.isEmpty
          ? CartConflictResult.noConflict()
          : CartConflictResult.conflict(conflicts, currentCart, newCartState);

    } catch (e) {
      _logger.error('❌ [CART-STORAGE] Failed to check conflicts', e);
      return CartConflictResult.noConflict();
    }
  }
}

/// Cart storage result
class CartStorageResult {
  final bool isSuccess;
  final String? error;
  final CartConflictResult? conflict;

  CartStorageResult._(this.isSuccess, this.error, this.conflict);

  factory CartStorageResult.success() => CartStorageResult._(true, null, null);
  factory CartStorageResult.failure(String error) => CartStorageResult._(false, error, null);
  factory CartStorageResult.conflict(CartConflictResult conflict) => 
      CartStorageResult._(false, 'Conflict detected', conflict);

  bool get hasConflict => conflict != null;
}

/// Cart conflict result
class CartConflictResult {
  final bool hasConflict;
  final List<String> conflicts;
  final EnhancedCartState? currentCart;
  final EnhancedCartState? newCart;

  CartConflictResult._(this.hasConflict, this.conflicts, this.currentCart, this.newCart);

  factory CartConflictResult.noConflict() => CartConflictResult._(false, [], null, null);
  factory CartConflictResult.conflict(
    List<String> conflicts,
    EnhancedCartState currentCart,
    EnhancedCartState newCart,
  ) => CartConflictResult._(true, conflicts, currentCart, newCart);
}

/// Cart storage statistics
class CartStorageStats {
  final DateTime? lastUpdated;
  final int itemCount;
  final double totalAmount;
  final int historyEntries;
  final int version;

  CartStorageStats({
    required this.lastUpdated,
    required this.itemCount,
    required this.totalAmount,
    required this.historyEntries,
    required this.version,
  });
}

/// Cart storage events
abstract class CartStorageEvent {
  const CartStorageEvent();

  factory CartStorageEvent.saved(EnhancedCartState cartState) = CartSavedEvent;
  factory CartStorageEvent.loaded(EnhancedCartState cartState) = CartLoadedEvent;
  factory CartStorageEvent.cleared() = CartClearedEvent;
  factory CartStorageEvent.error(String error) = CartErrorEvent;
  factory CartStorageEvent.conflict(CartConflictResult conflict) = CartConflictEvent;
  factory CartStorageEvent.syncCompleted() = CartSyncCompletedEvent;
  factory CartStorageEvent.syncFailed(String error) = CartSyncFailedEvent;
  factory CartStorageEvent.autoSaveTriggered() = CartAutoSaveTriggeredEvent;
}

class CartSavedEvent extends CartStorageEvent {
  final EnhancedCartState cartState;
  const CartSavedEvent(this.cartState);
}

class CartLoadedEvent extends CartStorageEvent {
  final EnhancedCartState cartState;
  const CartLoadedEvent(this.cartState);
}

class CartClearedEvent extends CartStorageEvent {
  const CartClearedEvent();
}

class CartErrorEvent extends CartStorageEvent {
  final String error;
  const CartErrorEvent(this.error);
}

class CartConflictEvent extends CartStorageEvent {
  final CartConflictResult conflict;
  const CartConflictEvent(this.conflict);
}

class CartSyncCompletedEvent extends CartStorageEvent {
  const CartSyncCompletedEvent();
}

class CartSyncFailedEvent extends CartStorageEvent {
  final String error;
  const CartSyncFailedEvent(this.error);
}

class CartAutoSaveTriggeredEvent extends CartStorageEvent {
  const CartAutoSaveTriggeredEvent();
}

/// Cart storage manager provider
final cartStorageManagerProvider = Provider<CartStorageManager>((ref) {
  final persistenceService = ref.watch(cartPersistenceServiceProvider);
  return CartStorageManager(persistenceService);
});
