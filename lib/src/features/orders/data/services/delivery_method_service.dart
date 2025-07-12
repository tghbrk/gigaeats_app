import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_delivery_method.dart';

import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';

/// Service for managing delivery method availability and configuration
class DeliveryMethodService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  /// Get available delivery methods for a vendor
  Future<List<CustomerDeliveryMethod>> getAvailableMethodsForVendor({
    required String vendorId,
    required double orderAmount,
    CustomerAddress? deliveryAddress,
  }) async {
    try {
      _logger.info('🚚 [DELIVERY-SERVICE] Getting available methods for vendor: $vendorId');

      // Get vendor delivery settings
      final vendorSettings = await _getVendorDeliverySettings(vendorId);
      
      final availableMethods = <CustomerDeliveryMethod>[];

      // Check each delivery method
      for (final method in CustomerDeliveryMethod.values) {
        if (await _isMethodAvailableForOrder(
          method: method,
          vendorSettings: vendorSettings,
          orderAmount: orderAmount,
          deliveryAddress: deliveryAddress,
        )) {
          availableMethods.add(method);
        }
      }

      _logger.info('✅ [DELIVERY-SERVICE] Found ${availableMethods.length} available methods');
      return availableMethods;

    } catch (e) {
      _logger.error('❌ [DELIVERY-SERVICE] Failed to get available methods', e);
      // Return default methods as fallback
      return [
        CustomerDeliveryMethod.pickup,
        CustomerDeliveryMethod.delivery,
      ];
    }
  }

  /// Check if a specific delivery method is available for an order
  Future<bool> isMethodAvailable({
    required CustomerDeliveryMethod method,
    required String vendorId,
    required double orderAmount,
    CustomerAddress? deliveryAddress,
  }) async {
    try {
      _logger.info('🔍 [DELIVERY-SERVICE] === CHECKING METHOD AVAILABILITY ===');
      _logger.info('🔍 [DELIVERY-SERVICE] Method: ${method.value}');
      _logger.info('🔍 [DELIVERY-SERVICE] Vendor ID: $vendorId');
      _logger.info('🔍 [DELIVERY-SERVICE] Order Amount: RM ${orderAmount.toStringAsFixed(2)}');
      _logger.info('🔍 [DELIVERY-SERVICE] Delivery Address: ${deliveryAddress != null ? 'Provided' : 'Not provided'}');

      final vendorSettings = await _getVendorDeliverySettings(vendorId);

      final isAvailable = await _isMethodAvailableForOrder(
        method: method,
        vendorSettings: vendorSettings,
        orderAmount: orderAmount,
        deliveryAddress: deliveryAddress,
      );

      _logger.info('🔍 [DELIVERY-SERVICE] === AVAILABILITY RESULT: ${isAvailable ? 'AVAILABLE' : 'NOT AVAILABLE'} ===');
      return isAvailable;
    } catch (e) {
      _logger.error('❌ [DELIVERY-SERVICE] Failed to check method availability', e);
      return false;
    }
  }

  /// Get delivery method recommendations based on order details
  Future<DeliveryMethodRecommendation> getMethodRecommendations({
    required String vendorId,
    required double orderAmount,
    CustomerAddress? deliveryAddress,
    DateTime? preferredTime,
  }) async {
    try {
      _logger.info('💡 [DELIVERY-SERVICE] Getting method recommendations');

      final availableMethods = await getAvailableMethodsForVendor(
        vendorId: vendorId,
        orderAmount: orderAmount,
        deliveryAddress: deliveryAddress,
      );

      if (availableMethods.isEmpty) {
        return DeliveryMethodRecommendation.noMethods();
      }

      // Calculate scores for each method
      final methodScores = <CustomerDeliveryMethod, double>{};
      
      for (final method in availableMethods) {
        methodScores[method] = await _calculateMethodScore(
          method: method,
          orderAmount: orderAmount,
          deliveryAddress: deliveryAddress,
          preferredTime: preferredTime,
        );
      }

      // Sort by score (highest first)
      final sortedMethods = methodScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final recommended = sortedMethods.first.key;
      final alternatives = sortedMethods.skip(1).map((e) => e.key).toList();

      return DeliveryMethodRecommendation(
        recommended: recommended,
        alternatives: alternatives,
        reasons: _getRecommendationReasons(recommended, orderAmount),
      );

    } catch (e) {
      _logger.error('❌ [DELIVERY-SERVICE] Failed to get recommendations', e);
      return DeliveryMethodRecommendation.error();
    }
  }

  /// Get vendor delivery settings
  Future<VendorDeliverySettings> _getVendorDeliverySettings(String vendorId) async {
    try {
      _logger.info('🔍 [DELIVERY-SERVICE] === FETCHING VENDOR DELIVERY SETTINGS ===');
      _logger.info('🔍 [DELIVERY-SERVICE] Vendor ID: $vendorId');
      _logger.info('🔍 [DELIVERY-SERVICE] Querying vendor_delivery_settings table...');

      final response = await _supabase
          .from('vendor_delivery_settings')
          .select()
          .eq('vendor_id', vendorId)
          .single();

      _logger.info('✅ [DELIVERY-SERVICE] Vendor settings found in database');
      _logger.info('🔍 [DELIVERY-SERVICE] Raw response: $response');

      final settings = VendorDeliverySettings.fromJson(response);

      _logger.info('🔍 [DELIVERY-SERVICE] === PARSED VENDOR SETTINGS ===');
      _logger.info('🔍 [DELIVERY-SERVICE] allows_customer_pickup: ${settings.allowsCustomerPickup}');
      _logger.info('🔍 [DELIVERY-SERVICE] has_own_fleet: ${settings.hasOwnFleet}');
      _logger.info('🔍 [DELIVERY-SERVICE] max_delivery_radius: ${settings.maxDeliveryRadius} km');
      _logger.info('🔍 [DELIVERY-SERVICE] own_fleet_minimum_order: RM ${settings.ownFleetMinimumOrder}');
      _logger.info('🔍 [DELIVERY-SERVICE] vendor_latitude: ${settings.latitude}');
      _logger.info('🔍 [DELIVERY-SERVICE] vendor_longitude: ${settings.longitude}');

      return settings;
    } catch (e) {
      _logger.error('❌ [DELIVERY-SERVICE] Failed to get vendor delivery settings: $e');
      _logger.warning('⚠️ [DELIVERY-SERVICE] Using default settings (has_own_fleet: false)');

      final defaults = VendorDeliverySettings.defaults();
      _logger.info('🔍 [DELIVERY-SERVICE] === DEFAULT SETTINGS ===');
      _logger.info('🔍 [DELIVERY-SERVICE] allows_customer_pickup: ${defaults.allowsCustomerPickup}');
      _logger.info('🔍 [DELIVERY-SERVICE] has_own_fleet: ${defaults.hasOwnFleet}');
      _logger.info('🔍 [DELIVERY-SERVICE] max_delivery_radius: ${defaults.maxDeliveryRadius} km');

      return defaults;
    }
  }

  /// Check if method is available for specific order
  Future<bool> _isMethodAvailableForOrder({
    required CustomerDeliveryMethod method,
    required VendorDeliverySettings vendorSettings,
    required double orderAmount,
    CustomerAddress? deliveryAddress,
  }) async {
    _logger.info('🔍 [DELIVERY-SERVICE] === CHECKING METHOD: ${method.value} ===');

    switch (method) {
      case CustomerDeliveryMethod.pickup:
        _logger.info('🔍 [DELIVERY-SERVICE] Checking PICKUP availability');
        _logger.info('🔍 [DELIVERY-SERVICE] allows_customer_pickup: ${vendorSettings.allowsCustomerPickup}');
        final isAvailable = vendorSettings.allowsCustomerPickup;
        _logger.info('🔍 [DELIVERY-SERVICE] PICKUP result: $isAvailable');
        return isAvailable;

      case CustomerDeliveryMethod.delivery:
        _logger.info('🔍 [DELIVERY-SERVICE] Checking DELIVERY availability');
        _logger.info('🔍 [DELIVERY-SERVICE] has_own_fleet: ${vendorSettings.hasOwnFleet}');
        _logger.info('🔍 [DELIVERY-SERVICE] delivery_address_provided: ${deliveryAddress != null}');

        if (!vendorSettings.hasOwnFleet) {
          _logger.warning('❌ [DELIVERY-SERVICE] DELIVERY not available: vendor has no own fleet');
          return false;
        }

        if (deliveryAddress == null) {
          _logger.warning('❌ [DELIVERY-SERVICE] DELIVERY not available: no delivery address provided');
          return false;
        }

        _logger.info('🔍 [DELIVERY-SERVICE] Checking delivery distance and minimum order...');
        _logger.info('🔍 [DELIVERY-SERVICE] vendor_location: (${vendorSettings.latitude}, ${vendorSettings.longitude})');
        _logger.info('🔍 [DELIVERY-SERVICE] delivery_location: (${deliveryAddress.latitude}, ${deliveryAddress.longitude})');

        // Check if address has valid coordinates
        if (deliveryAddress.latitude == null || deliveryAddress.longitude == null) {
          _logger.warning('❌ [DELIVERY-SERVICE] DELIVERY not available: delivery address missing coordinates');
          return false;
        }

        // Check delivery radius
        final distance = await _calculateDistance(
          vendorSettings.latitude,
          vendorSettings.longitude,
          deliveryAddress.latitude!,
          deliveryAddress.longitude!,
        );

        _logger.info('🔍 [DELIVERY-SERVICE] calculated_distance: ${distance.toStringAsFixed(2)} km');
        _logger.info('🔍 [DELIVERY-SERVICE] max_delivery_radius: ${vendorSettings.maxDeliveryRadius} km');
        _logger.info('🔍 [DELIVERY-SERVICE] order_amount: RM ${orderAmount.toStringAsFixed(2)}');
        _logger.info('🔍 [DELIVERY-SERVICE] minimum_order: RM ${vendorSettings.ownFleetMinimumOrder}');

        final withinRadius = distance <= vendorSettings.maxDeliveryRadius;
        final meetsMinimum = orderAmount >= vendorSettings.ownFleetMinimumOrder;

        _logger.info('🔍 [DELIVERY-SERVICE] within_radius: $withinRadius');
        _logger.info('🔍 [DELIVERY-SERVICE] meets_minimum: $meetsMinimum');

        final isAvailable = withinRadius && meetsMinimum;
        _logger.info('🔍 [DELIVERY-SERVICE] DELIVERY result: $isAvailable');
        return isAvailable;

      case CustomerDeliveryMethod.scheduled:
        _logger.info('🔍 [DELIVERY-SERVICE] Checking SCHEDULED DELIVERY availability');
        _logger.info('🔍 [DELIVERY-SERVICE] has_own_fleet: ${vendorSettings.hasOwnFleet}');
        _logger.info('🔍 [DELIVERY-SERVICE] delivery_address_provided: ${deliveryAddress != null}');

        if (!vendorSettings.hasOwnFleet) {
          _logger.warning('❌ [DELIVERY-SERVICE] SCHEDULED DELIVERY not available: vendor has no own fleet');
          return false;
        }

        if (deliveryAddress == null) {
          _logger.warning('❌ [DELIVERY-SERVICE] SCHEDULED DELIVERY not available: no delivery address provided');
          return false;
        }

        _logger.info('🔍 [DELIVERY-SERVICE] Checking scheduled delivery distance and minimum order...');

        // Check if address has valid coordinates
        if (deliveryAddress.latitude == null || deliveryAddress.longitude == null) {
          _logger.warning('❌ [DELIVERY-SERVICE] SCHEDULED DELIVERY not available: delivery address missing coordinates');
          return false;
        }

        // Check distance (same as delivery)
        final distance = await _calculateDistance(
          vendorSettings.latitude,
          vendorSettings.longitude,
          deliveryAddress.latitude!,
          deliveryAddress.longitude!,
        );

        _logger.info('🔍 [DELIVERY-SERVICE] calculated_distance: ${distance.toStringAsFixed(2)} km');
        _logger.info('🔍 [DELIVERY-SERVICE] max_delivery_radius: ${vendorSettings.maxDeliveryRadius} km');
        _logger.info('🔍 [DELIVERY-SERVICE] order_amount: RM ${orderAmount.toStringAsFixed(2)}');
        _logger.info('🔍 [DELIVERY-SERVICE] minimum_order: RM ${vendorSettings.ownFleetMinimumOrder}');

        final withinRadius = distance <= vendorSettings.maxDeliveryRadius;
        final meetsMinimum = orderAmount >= vendorSettings.ownFleetMinimumOrder;

        _logger.info('🔍 [DELIVERY-SERVICE] within_radius: $withinRadius');
        _logger.info('🔍 [DELIVERY-SERVICE] meets_minimum: $meetsMinimum');

        final isAvailable = withinRadius && meetsMinimum;
        _logger.info('🔍 [DELIVERY-SERVICE] SCHEDULED DELIVERY result: $isAvailable');
        return isAvailable;
    }
  }

  /// Calculate method recommendation score
  Future<double> _calculateMethodScore({
    required CustomerDeliveryMethod method,
    required double orderAmount,
    CustomerAddress? deliveryAddress,
    DateTime? preferredTime,
  }) async {
    double score = 0.0;

    // Base scores
    switch (method) {
      case CustomerDeliveryMethod.pickup:
        score = 70.0; // Good baseline
        break;
      case CustomerDeliveryMethod.delivery:
        score = 90.0; // Best control and tracking
        break;
      case CustomerDeliveryMethod.scheduled:
        score = 85.0; // Convenient timing
        break;
    }

    // Adjust for order amount
    if (orderAmount >= 100.0) {
      if (method == CustomerDeliveryMethod.delivery || method == CustomerDeliveryMethod.scheduled) {
        score += 10.0; // Reward high-value orders with premium service
      }
    }

    // Adjust for time preferences
    if (preferredTime != null) {
      final hour = preferredTime.hour;
      if (hour >= 11 && hour <= 14) { // Lunch rush
        if (method == CustomerDeliveryMethod.pickup) {
          score += 15.0; // Faster during peak times
        }
      }
    }

    // Adjust for delivery address
    if (deliveryAddress != null) {
      if (method.requiresDriver) {
        score += 5.0; // Bonus for delivery methods when address is available
      }
    } else {
      if (!method.requiresDriver) {
        score += 20.0; // Strong bonus for pickup when no address
      }
    }

    return score;
  }

  /// Calculate distance between two points
  Future<double> _calculateDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) async {
    // Simplified distance calculation (Haversine formula would be more accurate)
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get recommendation reasons
  List<String> _getRecommendationReasons(
    CustomerDeliveryMethod method,
    double orderAmount,
  ) {
    final reasons = <String>[];

    switch (method) {
      case CustomerDeliveryMethod.pickup:
        reasons.add('No delivery fee');
        reasons.add('Fastest option');
        if (orderAmount < 50.0) {
          reasons.add('Best for smaller orders');
        }
        break;

      case CustomerDeliveryMethod.delivery:
        reasons.add('Real-time tracking');
        reasons.add('Reliable delivery');
        reasons.add('Professional service');
        if (orderAmount >= 100.0) {
          reasons.add('Premium service for large orders');
        }
        break;

      case CustomerDeliveryMethod.scheduled:
        reasons.add('Convenient timing');
        reasons.add('Plan ahead');
        reasons.add('Guaranteed delivery time');
        break;
    }

    return reasons;
  }
}

/// Vendor delivery settings model
class VendorDeliverySettings {
  final String vendorId;
  final bool allowsCustomerPickup;
  final bool allowsSalesAgentPickup;
  final bool hasOwnFleet;
  final bool allowsThirdPartyDelivery;
  final double maxDeliveryRadius;
  final double salesAgentMinimumOrder;
  final double ownFleetMinimumOrder;
  final double thirdPartyMinimumOrder;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> businessHours;

  const VendorDeliverySettings({
    required this.vendorId,
    required this.allowsCustomerPickup,
    required this.allowsSalesAgentPickup,
    required this.hasOwnFleet,
    required this.allowsThirdPartyDelivery,
    required this.maxDeliveryRadius,
    required this.salesAgentMinimumOrder,
    required this.ownFleetMinimumOrder,
    required this.thirdPartyMinimumOrder,
    required this.latitude,
    required this.longitude,
    required this.businessHours,
  });

  factory VendorDeliverySettings.fromJson(Map<String, dynamic> json) {
    return VendorDeliverySettings(
      vendorId: json['vendor_id'],
      allowsCustomerPickup: json['allows_customer_pickup'] ?? true,
      allowsSalesAgentPickup: json['allows_sales_agent_pickup'] ?? true,
      hasOwnFleet: json['has_own_fleet'] ?? false,
      allowsThirdPartyDelivery: json['allows_third_party_delivery'] ?? false,
      maxDeliveryRadius: (json['max_delivery_radius'] ?? 10.0).toDouble(),
      salesAgentMinimumOrder: (json['sales_agent_minimum_order'] ?? 50.0).toDouble(),
      ownFleetMinimumOrder: (json['own_fleet_minimum_order'] ?? 30.0).toDouble(),
      thirdPartyMinimumOrder: (json['third_party_minimum_order'] ?? 25.0).toDouble(),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      businessHours: json['business_hours'] ?? {},
    );
  }

  factory VendorDeliverySettings.defaults() {
    return const VendorDeliverySettings(
      vendorId: '',
      allowsCustomerPickup: true,
      allowsSalesAgentPickup: true,
      hasOwnFleet: false,
      allowsThirdPartyDelivery: false,
      maxDeliveryRadius: 10.0,
      salesAgentMinimumOrder: 50.0,
      ownFleetMinimumOrder: 30.0,
      thirdPartyMinimumOrder: 25.0,
      latitude: 0.0,
      longitude: 0.0,
      businessHours: {},
    );
  }
}

/// Delivery method recommendation result
class DeliveryMethodRecommendation {
  final CustomerDeliveryMethod? recommended;
  final List<CustomerDeliveryMethod> alternatives;
  final List<String> reasons;
  final bool hasError;

  const DeliveryMethodRecommendation({
    this.recommended,
    this.alternatives = const [],
    this.reasons = const [],
    this.hasError = false,
  });

  factory DeliveryMethodRecommendation.noMethods() {
    return const DeliveryMethodRecommendation(
      reasons: ['No delivery methods available'],
      hasError: true,
    );
  }

  factory DeliveryMethodRecommendation.error() {
    return const DeliveryMethodRecommendation(
      reasons: ['Failed to get recommendations'],
      hasError: true,
    );
  }

  bool get hasRecommendation => recommended != null && !hasError;
}
