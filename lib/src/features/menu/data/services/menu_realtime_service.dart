import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/menu_exceptions.dart';
import '../../../../core/utils/logger.dart';

/// Comprehensive real-time service for menu management
/// Handles all menu-related real-time updates and synchronization
class MenuRealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  // Stream controllers for different types of real-time updates
  final StreamController<MenuRealtimeEvent> _menuItemUpdatesController = StreamController.broadcast();
  final StreamController<MenuRealtimeEvent> _categoryUpdatesController = StreamController.broadcast();
  final StreamController<MenuRealtimeEvent> _pricingUpdatesController = StreamController.broadcast();
  final StreamController<MenuRealtimeEvent> _organizationUpdatesController = StreamController.broadcast();
  final StreamController<MenuRealtimeEvent> _customizationUpdatesController = StreamController.broadcast();
  final StreamController<MenuRealtimeEvent> _analyticsUpdatesController = StreamController.broadcast();

  // Subscription references for cleanup
  RealtimeChannel? _menuItemsChannel;
  RealtimeChannel? _categoriesChannel;
  RealtimeChannel? _pricingChannel;
  RealtimeChannel? _organizationChannel;
  RealtimeChannel? _customizationChannel;
  RealtimeChannel? _analyticsChannel;

  // Connection state
  bool _isConnected = false;
  String? _currentVendorId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  // Stream getters
  Stream<MenuRealtimeEvent> get menuItemUpdates => _menuItemUpdatesController.stream;
  Stream<MenuRealtimeEvent> get categoryUpdates => _categoryUpdatesController.stream;
  Stream<MenuRealtimeEvent> get pricingUpdates => _pricingUpdatesController.stream;
  Stream<MenuRealtimeEvent> get organizationUpdates => _organizationUpdatesController.stream;
  Stream<MenuRealtimeEvent> get customizationUpdates => _customizationUpdatesController.stream;
  Stream<MenuRealtimeEvent> get analyticsUpdates => _analyticsUpdatesController.stream;

  // Combined stream for all menu updates
  Stream<MenuRealtimeEvent> get allMenuUpdates => StreamGroup.merge([
    menuItemUpdates,
    categoryUpdates,
    pricingUpdates,
    organizationUpdates,
    customizationUpdates,
    analyticsUpdates,
  ]);

  bool get isConnected => _isConnected;
  String? get currentVendorId => _currentVendorId;

  /// Initialize real-time subscriptions for a vendor
  Future<void> initializeForVendor(String vendorId) async {
    try {
      _logger.info('Initializing menu real-time service for vendor: $vendorId');

      // Cleanup existing connections
      await dispose();

      _currentVendorId = vendorId;
      _reconnectAttempts = 0;

      // Setup all subscriptions
      await _setupMenuItemsSubscription(vendorId);
      await _setupCategoriesSubscription(vendorId);
      await _setupPricingSubscription(vendorId);
      await _setupOrganizationSubscription(vendorId);
      await _setupCustomizationSubscription(vendorId);
      await _setupAnalyticsSubscription(vendorId);

      _isConnected = true;
      _logger.info('Menu real-time service initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize menu real-time service: $e');
      _scheduleReconnect();
      throw MenuRealtimeException('Failed to initialize real-time service: $e');
    }
  }

  /// Setup menu items real-time subscription
  Future<void> _setupMenuItemsSubscription(String vendorId) async {
    try {
      _menuItemsChannel = _supabase.channel('menu_items_$vendorId');

      // Subscribe to menu items table changes
      _menuItemsChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'menu_items',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'vendor_id',
              value: vendorId,
            ),
            callback: (payload) => _handleMenuItemUpdate(payload),
          )
          .subscribe();

      _logger.debug('Menu items subscription established');
    } catch (e) {
      _logger.error('Failed to setup menu items subscription: $e');
      rethrow;
    }
  }

  /// Setup categories real-time subscription
  Future<void> _setupCategoriesSubscription(String vendorId) async {
    try {
      _categoriesChannel = _supabase.channel('categories_$vendorId');

      // Subscribe to enhanced menu categories
      _categoriesChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'enhanced_menu_categories',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'vendor_id',
              value: vendorId,
            ),
            callback: (payload) => _handleCategoryUpdate(payload),
          )
          .subscribe();

      _logger.debug('Categories subscription established');
    } catch (e) {
      _logger.error('Failed to setup categories subscription: $e');
      rethrow;
    }
  }

  /// Setup pricing real-time subscription
  Future<void> _setupPricingSubscription(String vendorId) async {
    try {
      _pricingChannel = _supabase.channel('pricing_$vendorId');

      // Subscribe to bulk pricing tiers
      _pricingChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'enhanced_bulk_pricing_tiers',
            callback: (payload) => _handlePricingUpdate(payload, 'bulk_pricing'),
          );

      // Subscribe to promotional pricing
      _pricingChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'promotional_pricing',
            callback: (payload) => _handlePricingUpdate(payload, 'promotional_pricing'),
          );

      // Subscribe to time-based pricing rules
      _pricingChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'time_based_pricing_rules',
            callback: (payload) => _handlePricingUpdate(payload, 'time_based_pricing'),
          );

      _pricingChannel!.subscribe();
      _logger.debug('Pricing subscription established');
    } catch (e) {
      _logger.error('Failed to setup pricing subscription: $e');
      rethrow;
    }
  }

  /// Setup organization real-time subscription
  Future<void> _setupOrganizationSubscription(String vendorId) async {
    try {
      _organizationChannel = _supabase.channel('organization_$vendorId');

      // Subscribe to menu item positions
      _organizationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'menu_item_positions',
            callback: (payload) => _handleOrganizationUpdate(payload, 'item_positions'),
          );

      // Subscribe to organization config
      _organizationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'menu_organization_config',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'vendor_id',
              value: vendorId,
            ),
            callback: (payload) => _handleOrganizationUpdate(payload, 'organization_config'),
          );

      _organizationChannel!.subscribe();
      _logger.debug('Organization subscription established');
    } catch (e) {
      _logger.error('Failed to setup organization subscription: $e');
      rethrow;
    }
  }

  /// Setup customization real-time subscription
  Future<void> _setupCustomizationSubscription(String vendorId) async {
    try {
      _customizationChannel = _supabase.channel('customization_$vendorId');

      // Subscribe to customizations
      _customizationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'menu_item_customizations',
            callback: (payload) => _handleCustomizationUpdate(payload, 'customizations'),
          );

      // Subscribe to customization options
      _customizationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'customization_options',
            callback: (payload) => _handleCustomizationUpdate(payload, 'customization_options'),
          );

      // Subscribe to customization templates
      _customizationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'customization_templates',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'vendor_id',
              value: vendorId,
            ),
            callback: (payload) => _handleCustomizationUpdate(payload, 'templates'),
          );

      _customizationChannel!.subscribe();
      _logger.debug('Customization subscription established');
    } catch (e) {
      _logger.error('Failed to setup customization subscription: $e');
      rethrow;
    }
  }

  /// Setup analytics real-time subscription
  Future<void> _setupAnalyticsSubscription(String vendorId) async {
    try {
      _analyticsChannel = _supabase.channel('analytics_$vendorId');

      // Subscribe to menu item analytics
      _analyticsChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'menu_item_analytics',
            callback: (payload) => _handleAnalyticsUpdate(payload, 'item_analytics'),
          );

      // Subscribe to category analytics
      _analyticsChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'category_analytics',
            callback: (payload) => _handleAnalyticsUpdate(payload, 'category_analytics'),
          );

      _analyticsChannel!.subscribe();
      _logger.debug('Analytics subscription established');
    } catch (e) {
      _logger.error('Failed to setup analytics subscription: $e');
      rethrow;
    }
  }

  // ==================== EVENT HANDLERS ====================

  /// Handle menu item updates
  void _handleMenuItemUpdate(PostgresChangePayload payload) {
    try {
      final event = MenuRealtimeEvent(
        type: MenuRealtimeEventType.menuItem,
        action: _mapEventType(payload.eventType),
        data: payload.newRecord,
        timestamp: DateTime.now(),
        vendorId: _currentVendorId,
      );

      _menuItemUpdatesController.add(event);
      _logger.debug('Menu item update processed: ${event.action}');
    } catch (e) {
      _logger.error('Error handling menu item update: $e');
    }
  }

  /// Handle category updates
  void _handleCategoryUpdate(PostgresChangePayload payload) {
    try {
      final event = MenuRealtimeEvent(
        type: MenuRealtimeEventType.category,
        action: _mapEventType(payload.eventType),
        data: payload.newRecord,
        timestamp: DateTime.now(),
        vendorId: _currentVendorId,
      );

      _categoryUpdatesController.add(event);
      _logger.debug('Category update processed: ${event.action}');
    } catch (e) {
      _logger.error('Error handling category update: $e');
    }
  }

  /// Handle pricing updates
  void _handlePricingUpdate(PostgresChangePayload payload, String subType) {
    try {
      final event = MenuRealtimeEvent(
        type: MenuRealtimeEventType.pricing,
        action: _mapEventType(payload.eventType),
        data: payload.newRecord,
        subType: subType,
        timestamp: DateTime.now(),
        vendorId: _currentVendorId,
      );

      _pricingUpdatesController.add(event);
      _logger.debug('Pricing update processed: ${event.action} ($subType)');
    } catch (e) {
      _logger.error('Error handling pricing update: $e');
    }
  }

  /// Handle organization updates
  void _handleOrganizationUpdate(PostgresChangePayload payload, String subType) {
    try {
      final event = MenuRealtimeEvent(
        type: MenuRealtimeEventType.organization,
        action: _mapEventType(payload.eventType),
        data: payload.newRecord,
        subType: subType,
        timestamp: DateTime.now(),
        vendorId: _currentVendorId,
      );

      _organizationUpdatesController.add(event);
      _logger.debug('Organization update processed: ${event.action} ($subType)');
    } catch (e) {
      _logger.error('Error handling organization update: $e');
    }
  }

  /// Handle customization updates
  void _handleCustomizationUpdate(PostgresChangePayload payload, String subType) {
    try {
      final event = MenuRealtimeEvent(
        type: MenuRealtimeEventType.customization,
        action: _mapEventType(payload.eventType),
        data: payload.newRecord,
        subType: subType,
        timestamp: DateTime.now(),
        vendorId: _currentVendorId,
      );

      _customizationUpdatesController.add(event);
      _logger.debug('Customization update processed: ${event.action} ($subType)');
    } catch (e) {
      _logger.error('Error handling customization update: $e');
    }
  }

  /// Handle analytics updates
  void _handleAnalyticsUpdate(PostgresChangePayload payload, String subType) {
    try {
      final event = MenuRealtimeEvent(
        type: MenuRealtimeEventType.analytics,
        action: _mapEventType(payload.eventType),
        data: payload.newRecord,
        subType: subType,
        timestamp: DateTime.now(),
        vendorId: _currentVendorId,
      );

      _analyticsUpdatesController.add(event);
      _logger.debug('Analytics update processed: ${event.action} ($subType)');
    } catch (e) {
      _logger.error('Error handling analytics update: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Map PostgresChangeEvent to MenuRealtimeAction
  MenuRealtimeAction _mapEventType(PostgresChangeEvent eventType) {
    switch (eventType) {
      case PostgresChangeEvent.insert:
        return MenuRealtimeAction.created;
      case PostgresChangeEvent.update:
        return MenuRealtimeAction.updated;
      case PostgresChangeEvent.delete:
        return MenuRealtimeAction.deleted;
      default:
        return MenuRealtimeAction.updated;
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.error('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      _reconnectAttempts++;
      _logger.info('Attempting reconnection (attempt $_reconnectAttempts)');

      if (_currentVendorId != null) {
        try {
          await initializeForVendor(_currentVendorId!);
          _reconnectAttempts = 0; // Reset on successful reconnection
        } catch (e) {
          _logger.error('Reconnection failed: $e');
          _scheduleReconnect();
        }
      }
    });
  }

  /// Dispose all resources
  Future<void> dispose() async {
    try {
      _logger.info('Disposing menu real-time service');

      // Cancel reconnection timer
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Unsubscribe from all channels
      await _menuItemsChannel?.unsubscribe();
      await _categoriesChannel?.unsubscribe();
      await _pricingChannel?.unsubscribe();
      await _organizationChannel?.unsubscribe();
      await _customizationChannel?.unsubscribe();
      await _analyticsChannel?.unsubscribe();

      // Clear channel references
      _menuItemsChannel = null;
      _categoriesChannel = null;
      _pricingChannel = null;
      _organizationChannel = null;
      _customizationChannel = null;
      _analyticsChannel = null;

      // Close stream controllers
      await _menuItemUpdatesController.close();
      await _categoryUpdatesController.close();
      await _pricingUpdatesController.close();
      await _organizationUpdatesController.close();
      await _customizationUpdatesController.close();
      await _analyticsUpdatesController.close();

      _isConnected = false;
      _currentVendorId = null;
      _reconnectAttempts = 0;

      _logger.info('Menu real-time service disposed');
    } catch (e) {
      _logger.error('Error disposing menu real-time service: $e');
    }
  }
}

// ==================== EVENT MODELS ====================

/// Real-time event for menu updates
class MenuRealtimeEvent {
  final MenuRealtimeEventType type;
  final MenuRealtimeAction action;
  final Map<String, dynamic> data;
  final String? subType;
  final DateTime timestamp;
  final String? vendorId;

  const MenuRealtimeEvent({
    required this.type,
    required this.action,
    required this.data,
    this.subType,
    required this.timestamp,
    this.vendorId,
  });

  @override
  String toString() {
    return 'MenuRealtimeEvent(type: $type, action: $action, subType: $subType, vendorId: $vendorId)';
  }
}

/// Types of menu real-time events
enum MenuRealtimeEventType {
  menuItem,
  category,
  pricing,
  organization,
  customization,
  analytics,
}

/// Actions for menu real-time events
enum MenuRealtimeAction {
  created,
  updated,
  deleted,
}

/// Stream group utility for combining streams
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late StreamController<T> controller;
    final subscriptions = <StreamSubscription>[];

    controller = StreamController<T>.broadcast(
      onCancel: () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
        subscriptions.clear();
        controller.close();
      },
    );

    for (final stream in streams) {
      final subscription = stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          // Check if all streams are done
          if (subscriptions.every((sub) => sub.isPaused)) {
            controller.close();
          }
        },
      );
      subscriptions.add(subscription);
    }

    return controller.stream;
  }
}
