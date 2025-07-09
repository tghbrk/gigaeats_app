// Import models
import '../../features/vendors/data/models/vendor.dart';

// Import core services
import '../../core/utils/logger.dart';

// Import base repository
import 'base_repository.dart';

/// Repository for vendor management operations
class VendorRepository extends BaseRepository {
  final AppLogger _logger = AppLogger();

  VendorRepository() : super();

  /// Get vendor by ID
  Future<Vendor?> getVendorById(String vendorId) async {
    return executeQuery(() async {
      _logger.info('🏪 [VENDOR-REPO] Getting vendor: $vendorId');

      final response = await client
          .from('vendors')
          .select('*')
          .eq('id', vendorId)
          .maybeSingle();

      if (response == null) {
        _logger.warning('⚠️ [VENDOR-REPO] Vendor not found: $vendorId');
        return null;
      }

      final vendor = Vendor.fromJson(response);
      _logger.info('✅ [VENDOR-REPO] Retrieved vendor: ${vendor.businessName}');
      return vendor;
    });
  }

  /// Get vendor by user ID
  Future<Vendor?> getVendorByUserId(String userId) async {
    return executeQuery(() async {
      _logger.info('🏪 [VENDOR-REPO] Getting vendor by user ID: $userId');

      final response = await client
          .from('vendors')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        _logger.warning('⚠️ [VENDOR-REPO] Vendor not found for user: $userId');
        return null;
      }

      final vendor = Vendor.fromJson(response);
      _logger.info('✅ [VENDOR-REPO] Retrieved vendor: ${vendor.businessName}');
      return vendor;
    });
  }

  /// Get all active vendors
  Future<List<Vendor>> getActiveVendors({
    int? limit,
    int? offset,
    String? searchQuery,
    List<CuisineType>? cuisineTypes,
    bool? isVerified,
  }) async {
    return executeQuery(() async {
      _logger.info('📋 [VENDOR-REPO] Getting active vendors');

      dynamic query = client
          .from('vendors')
          .select('*')
          .eq('status', VendorStatus.active.name);

      // Apply filters
      if (isVerified != null) {
        query = query.eq('is_verified', isVerified);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('business_name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
        final cuisineNames = cuisineTypes.map((c) => c.name).toList();
        query = query.overlaps('cuisine_types', cuisineNames);
      }

      // Apply ordering first
      query = query.order('created_at', ascending: false);

      // Apply pagination
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      final vendors = response.map((json) => Vendor.fromJson(json)).toList();
      
      _logger.info('✅ [VENDOR-REPO] Retrieved ${vendors.length} active vendors');
      return vendors;
    });
  }

  /// Get vendors by cuisine type
  Future<List<Vendor>> getVendorsByCuisine(CuisineType cuisine) async {
    return executeQuery(() async {
      _logger.info('🍽️ [VENDOR-REPO] Getting vendors for cuisine: ${cuisine.name}');

      final response = await client
          .from('vendors')
          .select('*')
          .eq('status', VendorStatus.active.name)
          .contains('cuisine_types', [cuisine.name])
          .order('rating', ascending: false);

      final vendors = response.map((json) => Vendor.fromJson(json)).toList();
      _logger.info('✅ [VENDOR-REPO] Retrieved ${vendors.length} vendors for ${cuisine.name}');
      return vendors;
    });
  }

  /// Get nearby vendors
  Future<List<Vendor>> getNearbyVendors(double latitude, double longitude, double radiusKm) async {
    return executeQuery(() async {
      _logger.info('📍 [VENDOR-REPO] Getting nearby vendors within ${radiusKm}km');

      final response = await client
          .rpc('get_nearby_vendors', params: {
            'user_lat': latitude,
            'user_lng': longitude,
            'radius_km': radiusKm,
          });

      final vendors = (response as List).map((json) => Vendor.fromJson(json)).toList();
      _logger.info('✅ [VENDOR-REPO] Retrieved ${vendors.length} nearby vendors');
      return vendors;
    });
  }

  /// Get top rated vendors
  Future<List<Vendor>> getTopRatedVendors(int limit) async {
    return executeQuery(() async {
      _logger.info('⭐ [VENDOR-REPO] Getting top $limit rated vendors');

      final response = await client
          .from('vendors')
          .select('*')
          .eq('status', VendorStatus.active.name)
          .eq('is_verified', true)
          .gte('rating', 4.0)
          .order('rating', ascending: false)
          .order('total_reviews', ascending: false)
          .limit(limit);

      final vendors = response.map((json) => Vendor.fromJson(json)).toList();
      _logger.info('✅ [VENDOR-REPO] Retrieved ${vendors.length} top rated vendors');
      return vendors;
    });
  }

  /// Get featured vendors
  Future<List<Vendor>> getFeaturedVendors() async {
    return executeQuery(() async {
      _logger.info('🌟 [VENDOR-REPO] Getting featured vendors');

      final response = await client
          .from('vendors')
          .select('*')
          .eq('status', VendorStatus.active.name)
          .eq('is_verified', true)
          .eq('is_featured', true)
          .order('rating', ascending: false);

      final vendors = response.map((json) => Vendor.fromJson(json)).toList();
      _logger.info('✅ [VENDOR-REPO] Retrieved ${vendors.length} featured vendors');
      return vendors;
    });
  }

  /// Create new vendor
  Future<String?> createVendor(Map<String, dynamic> vendorData) async {
    return executeQuery(() async {
      _logger.info('➕ [VENDOR-REPO] Creating new vendor');

      final vendorPayload = {
        'user_id': vendorData['user_id'],
        'business_name': vendorData['business_name'],
        'business_registration_number': vendorData['business_registration_number'],
        'business_address': vendorData['business_address'],
        'business_type': vendorData['business_type'],
        'cuisine_types': vendorData['cuisine_types'] ?? [],
        'contact_person': vendorData['contact_person'],
        'contact_email': vendorData['contact_email'],
        'contact_phone': vendorData['contact_phone'],
        'is_halal_certified': vendorData['is_halal_certified'] ?? false,
        'halal_certification_number': vendorData['halal_certification_number'],
        'description': vendorData['description'],
        'status': VendorStatus.pendingVerification.name,
        'is_verified': false,
        'minimum_order_amount': vendorData['minimum_order_amount'],
        'delivery_fee': vendorData['delivery_fee'],
        'free_delivery_threshold': vendorData['free_delivery_threshold'],
        'preparation_time': vendorData['preparation_time'],
        'accepts_online_payment': vendorData['accepts_online_payment'] ?? true,
        'accepts_cash_payment': vendorData['accepts_cash_payment'] ?? true,
        'supports_customer_pickup': vendorData['supports_customer_pickup'] ?? true,
        'supports_sales_agent_pickup': vendorData['supports_sales_agent_pickup'] ?? true,
        'supports_own_fleet': vendorData['supports_own_fleet'] ?? false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('vendors')
          .insert(vendorPayload)
          .select('id')
          .single();

      final vendorId = response['id'] as String;

      // Create business hours if provided
      if (vendorData['business_hours'] != null) {
        await _createBusinessHours(vendorId, vendorData['business_hours']);
      }

      // Create service areas if provided
      if (vendorData['service_areas'] != null) {
        await _createServiceAreas(vendorId, vendorData['service_areas']);
      }

      // Initialize vendor stats
      await _initializeVendorStats(vendorId);

      _logger.info('✅ [VENDOR-REPO] Vendor created successfully: $vendorId');
      return vendorId;
    });
  }

  /// Update vendor
  Future<void> updateVendor(String vendorId, Map<String, dynamic> updates) async {
    return executeQuery(() async {
      _logger.info('🔄 [VENDOR-REPO] Updating vendor: $vendorId');

      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client
          .from('vendors')
          .update(updateData)
          .eq('id', vendorId);

      _logger.info('✅ [VENDOR-REPO] Vendor updated successfully');
    });
  }

  /// Update vendor status
  Future<void> updateVendorStatus(String vendorId, VendorStatus newStatus) async {
    return executeQuery(() async {
      _logger.info('🔄 [VENDOR-REPO] Updating vendor $vendorId status to ${newStatus.name}');

      final updateData = <String, dynamic>{
        'status': _mapVendorStatusToDbString(newStatus),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == VendorStatus.active) {
        updateData['verification_date'] = DateTime.now().toIso8601String();
        updateData['is_verified'] = true;
      }

      await client
          .from('vendors')
          .update(updateData)
          .eq('id', vendorId);

      _logger.info('✅ [VENDOR-REPO] Vendor status updated successfully');
    });
  }

  /// Watch vendor status for real-time updates
  Stream<Map<String, dynamic>?> watchVendorStatus(String vendorId) {
    _logger.info('👁️ [VENDOR-REPO] Watching vendor status: $vendorId');

    return client
        .from('vendors')
        .stream(primaryKey: ['id'])
        .eq('id', vendorId)
        .map((data) {
          if (data.isEmpty) return null;
          return data.first;
        });
  }

  /// Create business hours
  Future<void> _createBusinessHours(String vendorId, List<dynamic> businessHours) async {
    final hoursData = businessHours.map((hours) => {
      'vendor_id': vendorId,
      'day': hours['day'],
      'open_time': hours['open_time'],
      'close_time': hours['close_time'],
      'is_closed': hours['is_closed'] ?? false,
    }).toList();

    await client.from('business_hours').insert(hoursData);
    _logger.info('✅ [VENDOR-REPO] Created business hours');
  }

  /// Create service areas
  Future<void> _createServiceAreas(String vendorId, List<dynamic> serviceAreas) async {
    final areasData = serviceAreas.map((area) => {
      'vendor_id': vendorId,
      'name': area['name'],
      'postal_codes': area['postal_codes'],
      'delivery_fee': area['delivery_fee'],
      'minimum_order': area['minimum_order'],
      'estimated_delivery_time': area['estimated_delivery_time'],
    }).toList();

    await client.from('service_areas').insert(areasData);
    _logger.info('✅ [VENDOR-REPO] Created service areas');
  }

  /// Initialize vendor stats
  Future<void> _initializeVendorStats(String vendorId) async {
    final statsPayload = {
      'vendor_id': vendorId,
      'total_orders': 0,
      'total_revenue': 0.0,
      'average_order_value': 0.0,
      'rating': 0.0,
      'total_reviews': 0,
      'completion_rate': 0.0,
      'average_preparation_time': 30,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from('vendor_stats').insert(statsPayload);
    _logger.info('✅ [VENDOR-REPO] Vendor stats initialized');
  }

  /// Map VendorStatus enum to database string value
  String _mapVendorStatusToDbString(VendorStatus status) {
    switch (status) {
      case VendorStatus.active:
        return 'active';
      case VendorStatus.inactive:
        return 'inactive';
      case VendorStatus.suspended:
        return 'suspended';
      case VendorStatus.pendingVerification:
        return 'pending_verification';
    }
  }
}
