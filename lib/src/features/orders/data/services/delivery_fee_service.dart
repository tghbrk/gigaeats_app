import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_method.dart';
import '../models/delivery_fee_calculation.dart';
import '../../../../core/utils/debug_logger.dart';

/// Service for calculating delivery fees based on various factors
class DeliveryFeeService {
  static const String _tag = 'DeliveryFeeService';
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache for delivery fee calculations to prevent redundant API calls
  final Map<String, DeliveryFeeCalculation> _calculationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5); // Cache for 5 minutes

  // Track ongoing calculations to prevent duplicate requests
  final Map<String, Future<DeliveryFeeCalculation>> _ongoingCalculations = {};

  /// Calculate delivery fee for an order with caching and deduplication
  Future<DeliveryFeeCalculation> calculateDeliveryFee({
    required DeliveryMethod deliveryMethod,
    required String vendorId,
    required double subtotal,
    double? deliveryLatitude,
    double? deliveryLongitude,
    DateTime? deliveryTime,
  }) async {
    // Create cache key based on calculation parameters
    final cacheKey = _generateCacheKey(
      deliveryMethod: deliveryMethod,
      vendorId: vendorId,
      subtotal: subtotal,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
    );

    // Check if calculation is already in progress
    if (_ongoingCalculations.containsKey(cacheKey)) {
      DebugLogger.info('⏳ [DELIVERY-FEE] Reusing ongoing calculation for ${deliveryMethod.value}', tag: _tag);
      return await _ongoingCalculations[cacheKey]!;
    }

    // Check cache first and cleanup expired entries
    _cleanupCache();
    if (_isCacheValid(cacheKey)) {
      DebugLogger.info('💾 [DELIVERY-FEE] Using cached result for ${deliveryMethod.value}', tag: _tag);
      return _calculationCache[cacheKey]!;
    }

    // Start new calculation and track it
    final calculationFuture = _performCalculation(
      deliveryMethod: deliveryMethod,
      vendorId: vendorId,
      subtotal: subtotal,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryTime: deliveryTime,
    );

    _ongoingCalculations[cacheKey] = calculationFuture;

    try {
      final result = await calculationFuture;

      // Cache the result
      _calculationCache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();

      DebugLogger.info('✅ [DELIVERY-FEE] Calculated and cached result for ${deliveryMethod.value}: RM${result.finalFee.toStringAsFixed(2)}', tag: _tag);

      return result;
    } finally {
      // Remove from ongoing calculations
      _ongoingCalculations.remove(cacheKey);
    }
  }

  /// Perform the actual calculation without caching logic
  Future<DeliveryFeeCalculation> _performCalculation({
    required DeliveryMethod deliveryMethod,
    required String vendorId,
    required double subtotal,
    double? deliveryLatitude,
    double? deliveryLongitude,
    DateTime? deliveryTime,
  }) async {
    try {
      DebugLogger.info('🔄 [DELIVERY-FEE] Performing calculation for method: ${deliveryMethod.value}', tag: _tag);

      // For pickup methods, return zero fee immediately
      if (deliveryMethod.isPickup) {
        return DeliveryFeeCalculation(
          finalFee: 0.0,
          baseFee: 0.0,
          distanceFee: 0.0,
          surgeMultiplier: 1.0,
          discountAmount: 0.0,
          distanceKm: 0.0,
          breakdown: {
            'method': deliveryMethod.value,
            'reason': 'No delivery fee for pickup methods',
          },
        );
      }

      // Try database function for calculation first
      try {
        final response = await _supabase.rpc('calculate_delivery_fee', params: {
          'p_delivery_method': deliveryMethod.value,
          'p_vendor_id': vendorId,
          'p_delivery_latitude': deliveryLatitude,
          'p_delivery_longitude': deliveryLongitude,
          'p_subtotal': subtotal,
          'p_delivery_time': (deliveryTime ?? DateTime.now()).toIso8601String(),
        });

        if (response != null) {
          DebugLogger.info('Database calculation result: $response', tag: _tag);
          return DeliveryFeeCalculation.fromJson(response);
        }
      } catch (e) {
        DebugLogger.warning('Database function not available, using fallback calculation: $e', tag: _tag);
      }

      // Fallback to local calculation (always used if database function fails)
      DebugLogger.info('Using fallback delivery fee calculation for method: ${deliveryMethod.value}', tag: _tag);
      return _calculateFallbackDeliveryFee(
        deliveryMethod: deliveryMethod,
        subtotal: subtotal,
        distanceKm: _estimateDistance(deliveryLatitude, deliveryLongitude),
      );
    } catch (e) {
      DebugLogger.error('Error in delivery fee calculation: $e', tag: _tag);

      // Final fallback with default values
      return _calculateFallbackDeliveryFee(
        deliveryMethod: deliveryMethod,
        subtotal: subtotal,
        distanceKm: 5.0, // Default distance
      );
    }
  }

  /// Get delivery fee configurations for a vendor
  Future<List<Map<String, dynamic>>> getDeliveryFeeConfigs({
    String? vendorId,
    DeliveryMethod? deliveryMethod,
  }) async {
    try {
      var query = _supabase
          .from('delivery_fee_configs')
          .select('*')
          .eq('is_active', true);

      if (vendorId != null) {
        query = query.or('vendor_id.eq.$vendorId,vendor_id.is.null');
      }

      if (deliveryMethod != null) {
        query = query.eq('delivery_method', deliveryMethod.value);
      }

      final response = await query.order('priority', ascending: false);
      
      DebugLogger.info('Retrieved ${response.length} delivery fee configs', tag: _tag);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      DebugLogger.error('Error fetching delivery fee configs: $e', tag: _tag);
      return [];
    }
  }

  /// Get available delivery zones
  Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    try {
      final response = await _supabase
          .from('delivery_zones')
          .select('*')
          .eq('is_active', true)
          .order('name');

      DebugLogger.info('Retrieved ${response.length} delivery zones', tag: _tag);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      DebugLogger.error('Error fetching delivery zones: $e', tag: _tag);
      return [];
    }
  }

  /// Create or update delivery fee configuration
  Future<Map<String, dynamic>?> upsertDeliveryFeeConfig({
    required DeliveryMethod deliveryMethod,
    String? vendorId,
    String? zoneId,
    required double baseFee,
    required double perKmRate,
    required double minimumFee,
    double? maximumFee,
    double? freeDeliveryThreshold,
    double? maximumDeliveryRadiusKm,
    int? estimatedDeliveryTimeMinutes,
    List<Map<String, dynamic>>? distanceTiers,
    List<Map<String, dynamic>>? discountTiers,
    Map<String, dynamic>? surgeMultipliers,
    List<Map<String, dynamic>>? peakHours,
    int priority = 0,
  }) async {
    try {
      final configData = {
        'delivery_method': deliveryMethod.value,
        'vendor_id': vendorId,
        'zone_id': zoneId,
        'base_fee': baseFee,
        'per_km_rate': perKmRate,
        'minimum_fee': minimumFee,
        'maximum_fee': maximumFee,
        'free_delivery_threshold': freeDeliveryThreshold ?? 200.0,
        'maximum_delivery_radius_km': maximumDeliveryRadiusKm ?? 15.0,
        'estimated_delivery_time_minutes': estimatedDeliveryTimeMinutes ?? 60,
        'distance_tiers': distanceTiers ?? [],
        'discount_tiers': discountTiers ?? [],
        'surge_multipliers': surgeMultipliers ?? {},
        'peak_hours': peakHours ?? [],
        'priority': priority,
        'is_active': true,
      };

      final response = await _supabase
          .from('delivery_fee_configs')
          .upsert(configData)
          .select()
          .single();

      DebugLogger.success('Delivery fee config upserted successfully', tag: _tag);
      return response;
    } catch (e) {
      DebugLogger.error('Error upserting delivery fee config: $e', tag: _tag);
      return null;
    }
  }

  /// Get delivery fee calculation history for an order
  Future<List<Map<String, dynamic>>> getDeliveryFeeHistory(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_fee_calculations')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      DebugLogger.info('Retrieved ${response.length} delivery fee calculations for order $orderId', tag: _tag);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      DebugLogger.error('Error fetching delivery fee history: $e', tag: _tag);
      return [];
    }
  }

  /// Fallback delivery fee calculation when database function fails
  DeliveryFeeCalculation _calculateFallbackDeliveryFee({
    required DeliveryMethod deliveryMethod,
    required double subtotal,
    double distanceKm = 5.0,
  }) {
    DebugLogger.warning('Using fallback delivery fee calculation', tag: _tag);

    double baseFee = 0.0;
    double distanceFee = 0.0;
    double finalFee = 0.0;

    switch (deliveryMethod) {
      case DeliveryMethod.thirdParty:
        // Premium pricing for Lalamove
        if (subtotal >= 200) {
          baseFee = 0.0;
        } else if (subtotal >= 100) {
          baseFee = 15.0;
        } else {
          baseFee = 20.0;
        }
        distanceFee = distanceKm * 3.0; // RM 3 per km
        break;

      case DeliveryMethod.ownFleet:
        // Standard pricing for own fleet
        if (subtotal >= 200) {
          baseFee = 0.0;
        } else if (subtotal >= 100) {
          baseFee = 5.0;
        } else {
          baseFee = 10.0;
        }
        distanceFee = distanceKm * 2.0; // RM 2 per km
        break;

      case DeliveryMethod.customerPickup:
      case DeliveryMethod.salesAgentPickup:
        baseFee = 0.0;
        distanceFee = 0.0;
        break;
    }

    finalFee = baseFee + distanceFee;

    // Apply minimum fee constraint
    if (finalFee > 0 && finalFee < 5.0) {
      finalFee = 5.0;
    }

    // Apply maximum fee constraint
    if (finalFee > 50.0) {
      finalFee = 50.0;
    }

    return DeliveryFeeCalculation(
      finalFee: finalFee,
      baseFee: baseFee,
      distanceFee: distanceFee,
      surgeMultiplier: 1.0,
      discountAmount: 0.0,
      distanceKm: distanceKm,
      breakdown: {
        'method': deliveryMethod.value,
        'calculation_type': 'fallback',
        'subtotal': subtotal,
        'distance_km': distanceKm,
      },
    );
  }

  /// Estimate distance based on coordinates (simplified calculation)
  double _estimateDistance(double? lat, double? lng) {
    // If no coordinates provided, use default distance
    if (lat == null || lng == null) {
      return 5.0; // Default 5km
    }

    // For now, return a random distance between 2-15km
    // In production, this would use proper geospatial calculation
    final random = Random();
    return 2.0 + (random.nextDouble() * 13.0);
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get delivery fee breakdown for display
  Map<String, dynamic> getDeliveryFeeBreakdown(DeliveryFeeCalculation calculation) {
    return {
      'base_fee': calculation.baseFee,
      'distance_fee': calculation.distanceFee,
      'surge_fee': (calculation.finalFee - calculation.baseFee - calculation.distanceFee).clamp(0.0, double.infinity),
      'discount': calculation.discountAmount,
      'final_fee': calculation.finalFee,
      'distance_km': calculation.distanceKm,
      'surge_multiplier': calculation.surgeMultiplier,
    };
  }

  /// Format delivery fee for display
  String formatDeliveryFee(double fee) {
    if (fee == 0.0) {
      return 'Free';
    }
    return 'RM${fee.toStringAsFixed(2)}';
  }

  /// Check if delivery is available to a location
  Future<bool> isDeliveryAvailable({
    required String vendorId,
    required DeliveryMethod deliveryMethod,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // For pickup methods, always available
      if (deliveryMethod.isPickup) {
        return true;
      }

      // Get vendor's delivery radius configuration
      final configs = await getDeliveryFeeConfigs(
        vendorId: vendorId,
        deliveryMethod: deliveryMethod,
      );

      if (configs.isEmpty) {
        // No specific config, use default availability
        return true;
      }

      final config = configs.first;
      final maxRadius = config['maximum_delivery_radius_km'] as double? ?? 15.0;

      // If no coordinates provided, assume available
      if (latitude == null || longitude == null) {
        return true;
      }

      // Get vendor location (simplified - would need vendor coordinates)
      // For now, assume delivery is available within the configured radius
      final estimatedDistance = _estimateDistance(latitude, longitude);
      
      return estimatedDistance <= maxRadius;
    } catch (e) {
      DebugLogger.error('Error checking delivery availability: $e', tag: _tag);
      return true; // Default to available on error
    }
  }

  /// Generate cache key for delivery fee calculation
  String _generateCacheKey({
    required DeliveryMethod deliveryMethod,
    required String vendorId,
    required double subtotal,
    double? deliveryLatitude,
    double? deliveryLongitude,
  }) {
    // Round coordinates to reduce cache key variations
    final lat = deliveryLatitude?.toStringAsFixed(3) ?? 'null';
    final lng = deliveryLongitude?.toStringAsFixed(3) ?? 'null';
    final roundedSubtotal = (subtotal / 10).round() * 10; // Round to nearest 10

    return '${deliveryMethod.value}_${vendorId}_$roundedSubtotal}_${lat}_$lng';
  }

  /// Check if cached result is still valid
  bool _isCacheValid(String cacheKey) {
    if (!_calculationCache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();

    return now.difference(cacheTime) < _cacheExpiry;
  }

  /// Clear expired cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _calculationCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      DebugLogger.info('🧹 [DELIVERY-FEE] Cleaned up ${expiredKeys.length} expired cache entries', tag: _tag);
    }
  }

  /// Clear all cached calculations (useful for testing or when data changes)
  void clearCache() {
    _calculationCache.clear();
    _cacheTimestamps.clear();
    _ongoingCalculations.clear();
    DebugLogger.info('🗑️ [DELIVERY-FEE] Cache cleared', tag: _tag);
  }
}
