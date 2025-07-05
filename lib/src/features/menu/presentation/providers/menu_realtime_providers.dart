import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/services/menu_realtime_service.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/advanced_pricing.dart';
import '../../data/models/menu_organization.dart';
import '../../../../core/utils/logger.dart';

// ==================== REAL-TIME SERVICE PROVIDERS ====================

/// Menu real-time service provider
final menuRealtimeServiceProvider = Provider<MenuRealtimeService>((ref) {
  final service = MenuRealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Real-time connection state provider
final menuRealtimeConnectionProvider = StateNotifierProvider<MenuRealtimeConnectionNotifier, MenuRealtimeConnectionState>((ref) {
  final service = ref.watch(menuRealtimeServiceProvider);
  return MenuRealtimeConnectionNotifier(service);
});

// ==================== REAL-TIME STREAM PROVIDERS ====================

/// Real-time menu items stream provider
final menuItemsRealtimeProvider = StreamProvider.family<List<MenuItem>, String>((ref, vendorId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('menu_items')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((json) => json['vendor_id'] == vendorId)
          .map((json) => MenuItem.fromJson(json))
          .toList());
});

/// Real-time enhanced menu categories stream provider
final enhancedMenuCategoriesRealtimeProvider = StreamProvider.family<List<EnhancedMenuCategory>, String>((ref, vendorId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('enhanced_menu_categories')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((json) => json['vendor_id'] == vendorId && json['is_active'] == true)
          .map((json) => EnhancedMenuCategory.fromJson(json))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
});

/// Real-time bulk pricing tiers stream provider
final bulkPricingTiersRealtimeProvider = StreamProvider.family<List<EnhancedBulkPricingTier>, String>((ref, menuItemId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('enhanced_bulk_pricing_tiers')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((json) => json['menu_item_id'] == menuItemId && json['is_active'] == true)
          .map((json) => EnhancedBulkPricingTier.fromJson(json))
          .toList()
        ..sort((a, b) => a.minimumQuantity.compareTo(b.minimumQuantity)));
});

/// Real-time promotional pricing stream provider
final promotionalPricingRealtimeProvider = StreamProvider.family<List<PromotionalPricing>, String>((ref, menuItemId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('promotional_pricing')
      .stream(primaryKey: ['id'])
      .map((data) {
        final filtered = data
            .where((json) => json['menu_item_id'] == menuItemId && json['is_active'] == true)
            .map((json) => PromotionalPricing.fromJson(json))
            .toList();
        filtered.sort((a, b) => b.validFrom.compareTo(a.validFrom));
        return filtered;
      });
});

/// Real-time menu item positions stream provider
final menuItemPositionsRealtimeProvider = StreamProvider.family<List<MenuItemPosition>, String>((ref, categoryId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('menu_item_positions')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((json) => json['category_id'] == categoryId)
          .map((json) => MenuItemPosition.fromJson(json))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
});

/// Real-time menu organization config stream provider
final menuOrganizationConfigRealtimeProvider = StreamProvider.family<MenuOrganizationConfig?, String>((ref, vendorId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('menu_organization_config')
      .stream(primaryKey: ['id'])
      .map((data) {
        final filtered = data.where((json) => json['vendor_id'] == vendorId).toList();
        if (filtered.isEmpty) return null;
        return MenuOrganizationConfig.fromJson(filtered.first);
      });
});

// ==================== COMBINED REAL-TIME PROVIDERS ====================

/// Combined real-time menu data provider
final combinedMenuRealtimeProvider = StreamProvider.family<CombinedMenuData, String>((ref, vendorId) {
  final supabase = Supabase.instance.client;

  // Create individual streams
  final menuItemsStream = supabase
      .from('menu_items')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((json) => json['vendor_id'] == vendorId)
          .map((json) => MenuItem.fromJson(json))
          .toList());

  final categoriesStream = supabase
      .from('enhanced_menu_categories')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .where((json) => json['vendor_id'] == vendorId && json['is_active'] == true)
          .map((json) => EnhancedMenuCategory.fromJson(json))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  final organizationStream = supabase
      .from('menu_organization_config')
      .stream(primaryKey: ['id'])
      .map((data) {
        final filtered = data.where((json) => json['vendor_id'] == vendorId).toList();
        return filtered.isEmpty ? null : MenuOrganizationConfig.fromJson(filtered.first);
      });

  return Rx.combineLatest3(
    menuItemsStream,
    categoriesStream,
    organizationStream,
    (List<MenuItem> menuItems, List<EnhancedMenuCategory> categories, MenuOrganizationConfig? organization) => CombinedMenuData(
      menuItems: menuItems,
      categories: categories,
      organizationConfig: organization,
      lastUpdated: DateTime.now(),
    ),
  );
});

/// Real-time menu events stream provider
final menuEventsRealtimeProvider = StreamProvider.family<MenuRealtimeEvent, String>((ref, vendorId) {
  final service = ref.watch(menuRealtimeServiceProvider);
  
  // Initialize service for vendor if not already done
  Timer.run(() async {
    if (service.currentVendorId != vendorId) {
      await service.initializeForVendor(vendorId);
    }
  });
  
  return service.allMenuUpdates;
});

// ==================== REAL-TIME STATE NOTIFIERS ====================

/// Real-time connection state notifier
class MenuRealtimeConnectionNotifier extends StateNotifier<MenuRealtimeConnectionState> {
  final MenuRealtimeService _service;
  StreamSubscription? _connectionSubscription;

  MenuRealtimeConnectionNotifier(this._service) : super(const MenuRealtimeConnectionState()) {
    _monitorConnection();
  }

  void _monitorConnection() {
    // Monitor connection state changes
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        state = state.copyWith(
          isConnected: _service.isConnected,
          vendorId: _service.currentVendorId,
          lastChecked: DateTime.now(),
        );
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> initializeForVendor(String vendorId) async {
    state = state.copyWith(isConnecting: true, error: null);
    
    try {
      await _service.initializeForVendor(vendorId);
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        vendorId: vendorId,
        lastConnected: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        error: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    await _service.dispose();
    state = state.copyWith(
      isConnected: false,
      vendorId: null,
      lastDisconnected: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

/// Real-time menu synchronization notifier
final menuSynchronizationNotifierProvider = StateNotifierProvider.family<MenuSynchronizationNotifier, MenuSynchronizationState, String>((ref, vendorId) {
  final service = ref.watch(menuRealtimeServiceProvider);
  return MenuSynchronizationNotifier(service, vendorId);
});

class MenuSynchronizationNotifier extends StateNotifier<MenuSynchronizationState> {
  final MenuRealtimeService _realtimeService;
  final String _vendorId;
  final AppLogger _logger = AppLogger();
  
  StreamSubscription? _eventsSubscription;
  Timer? _syncTimer;

  MenuSynchronizationNotifier(this._realtimeService, this._vendorId)
      : super(const MenuSynchronizationState()) {
    _initializeSynchronization();
  }

  Future<void> _initializeSynchronization() async {
    try {
      state = state.copyWith(isInitializing: true);

      // Initialize real-time service
      await _realtimeService.initializeForVendor(_vendorId);

      // Setup event listening
      _eventsSubscription = _realtimeService.allMenuUpdates.listen(
        _handleRealtimeEvent,
        onError: _handleRealtimeError,
      );

      // Setup periodic sync
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => _performPeriodicSync());

      state = state.copyWith(
        isInitializing: false,
        isConnected: true,
        lastSyncTime: DateTime.now(),
      );

      _logger.info('Menu synchronization initialized for vendor: $_vendorId');
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        isConnected: false,
        lastError: e.toString(),
      );
      _logger.error('Failed to initialize menu synchronization: $e');
    }
  }

  void _handleRealtimeEvent(MenuRealtimeEvent event) {
    try {
      _logger.debug('Handling real-time event: ${event.type} - ${event.action}');

      state = state.copyWith(
        lastEventTime: event.timestamp,
        eventCount: state.eventCount + 1,
        lastEventType: '${event.type}_${event.action}',
      );

      // Trigger specific synchronization based on event type
      switch (event.type) {
        case MenuRealtimeEventType.menuItem:
          _handleMenuItemEvent(event);
          break;
        case MenuRealtimeEventType.category:
          _handleCategoryEvent(event);
          break;
        case MenuRealtimeEventType.pricing:
          _handlePricingEvent(event);
          break;
        case MenuRealtimeEventType.organization:
          _handleOrganizationEvent(event);
          break;
        case MenuRealtimeEventType.customization:
          _handleCustomizationEvent(event);
          break;
        case MenuRealtimeEventType.analytics:
          _handleAnalyticsEvent(event);
          break;
      }
    } catch (e) {
      _logger.error('Error handling real-time event: $e');
      state = state.copyWith(lastError: e.toString());
    }
  }

  void _handleMenuItemEvent(MenuRealtimeEvent event) {
    // Invalidate related providers to trigger refresh
    // This will be handled by the UI layer listening to these events
    _logger.debug('Menu item event processed: ${event.action}');
  }

  void _handleCategoryEvent(MenuRealtimeEvent event) {
    _logger.debug('Category event processed: ${event.action}');
  }

  void _handlePricingEvent(MenuRealtimeEvent event) {
    _logger.debug('Pricing event processed: ${event.action} (${event.subType})');
  }

  void _handleOrganizationEvent(MenuRealtimeEvent event) {
    _logger.debug('Organization event processed: ${event.action} (${event.subType})');
  }

  void _handleCustomizationEvent(MenuRealtimeEvent event) {
    _logger.debug('Customization event processed: ${event.action} (${event.subType})');
  }

  void _handleAnalyticsEvent(MenuRealtimeEvent event) {
    _logger.debug('Analytics event processed: ${event.action} (${event.subType})');
  }

  void _handleRealtimeError(dynamic error) {
    _logger.error('Real-time error: $error');
    state = state.copyWith(
      isConnected: false,
      lastError: error.toString(),
    );
  }

  Future<void> _performPeriodicSync() async {
    try {
      _logger.debug('Performing periodic sync for vendor: $_vendorId');
      
      state = state.copyWith(
        lastSyncTime: DateTime.now(),
        syncCount: state.syncCount + 1,
      );
    } catch (e) {
      _logger.error('Periodic sync failed: $e');
      state = state.copyWith(lastError: e.toString());
    }
  }

  Future<void> forceSynchronization() async {
    try {
      state = state.copyWith(isSyncing: true);
      
      // Force refresh of all menu data
      await _performPeriodicSync();
      
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}

// ==================== STATE MODELS ====================

/// Real-time connection state
class MenuRealtimeConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? vendorId;
  final String? error;
  final DateTime? lastConnected;
  final DateTime? lastDisconnected;
  final DateTime? lastChecked;

  const MenuRealtimeConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.vendorId,
    this.error,
    this.lastConnected,
    this.lastDisconnected,
    this.lastChecked,
  });

  MenuRealtimeConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? vendorId,
    String? error,
    DateTime? lastConnected,
    DateTime? lastDisconnected,
    DateTime? lastChecked,
  }) {
    return MenuRealtimeConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      vendorId: vendorId ?? this.vendorId,
      error: error ?? this.error,
      lastConnected: lastConnected ?? this.lastConnected,
      lastDisconnected: lastDisconnected ?? this.lastDisconnected,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

/// Menu synchronization state
class MenuSynchronizationState {
  final bool isInitializing;
  final bool isConnected;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final DateTime? lastEventTime;
  final String? lastEventType;
  final int eventCount;
  final int syncCount;
  final String? lastError;

  const MenuSynchronizationState({
    this.isInitializing = false,
    this.isConnected = false,
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastEventTime,
    this.lastEventType,
    this.eventCount = 0,
    this.syncCount = 0,
    this.lastError,
  });

  MenuSynchronizationState copyWith({
    bool? isInitializing,
    bool? isConnected,
    bool? isSyncing,
    DateTime? lastSyncTime,
    DateTime? lastEventTime,
    String? lastEventType,
    int? eventCount,
    int? syncCount,
    String? lastError,
  }) {
    return MenuSynchronizationState(
      isInitializing: isInitializing ?? this.isInitializing,
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastEventTime: lastEventTime ?? this.lastEventTime,
      lastEventType: lastEventType ?? this.lastEventType,
      eventCount: eventCount ?? this.eventCount,
      syncCount: syncCount ?? this.syncCount,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Combined menu data model
class CombinedMenuData {
  final List<MenuItem> menuItems;
  final List<EnhancedMenuCategory> categories;
  final MenuOrganizationConfig? organizationConfig;
  final DateTime lastUpdated;

  const CombinedMenuData({
    required this.menuItems,
    required this.categories,
    this.organizationConfig,
    required this.lastUpdated,
  });
}
