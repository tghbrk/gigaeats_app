import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/customer/vendor_favorite.dart';

class VendorFavoriteService {
  final SupabaseClient _supabase;

  VendorFavoriteService({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  /// Get customer's favorite vendors
  Future<List<VendorFavorite>> getFavoriteVendors({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (kDebugMode) debugPrint('VendorFavoriteService: Fetching favorite vendors for customer ${user.id}');

      final response = await _supabase
          .from('vendor_favorites')
          .select('''
            *,
            vendors!vendor_id(
              id,
              business_name,
              cover_image_url,
              cuisine_types,
              rating,
              total_reviews,
              is_active,
              description,
              delivery_fee,
              minimum_order_amount
            )
          ''')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final favorites = response.map((json) {
        final vendorData = json['vendors'];
        VendorInfo? vendor;
        if (vendorData != null) {
          vendor = VendorInfo(
            id: vendorData['id'],
            businessName: vendorData['business_name'],
            coverImageUrl: vendorData['cover_image_url'],
            cuisineTypes: List<String>.from(vendorData['cuisine_types'] ?? []),
            rating: (vendorData['rating'] as num?)?.toDouble() ?? 0.0,
            totalReviews: vendorData['total_reviews'] ?? 0,
            isActive: vendorData['is_active'] ?? false,
            description: vendorData['description'],
            deliveryFee: (vendorData['delivery_fee'] as num?)?.toDouble(),
            minimumOrderAmount: (vendorData['minimum_order_amount'] as num?)?.toDouble(),
          );
        }

        return VendorFavorite(
          id: json['id'],
          customerId: json['customer_id'],
          vendorId: json['vendor_id'],
          createdAt: DateTime.parse(json['created_at']),
          vendor: vendor,
        );
      }).toList();

      if (kDebugMode) debugPrint('VendorFavoriteService: Found ${favorites.length} favorite vendors');
      return favorites;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorFavoriteService: Error fetching favorite vendors: $e');
      rethrow;
    }
  }

  /// Add vendor to favorites
  Future<VendorFavorite> addToFavorites(String vendorId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (kDebugMode) debugPrint('VendorFavoriteService: Adding vendor $vendorId to favorites');

      // Check if already favorited
      final existing = await _supabase
          .from('vendor_favorites')
          .select('id')
          .eq('customer_id', user.id)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Vendor is already in favorites');
      }

      final response = await _supabase
          .from('vendor_favorites')
          .insert({
            'customer_id': user.id,
            'vendor_id': vendorId,
          })
          .select()
          .single();

      final favorite = VendorFavorite(
        id: response['id'],
        customerId: response['customer_id'],
        vendorId: response['vendor_id'],
        createdAt: DateTime.parse(response['created_at']),
      );

      if (kDebugMode) debugPrint('VendorFavoriteService: Vendor added to favorites successfully');
      return favorite;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorFavoriteService: Error adding vendor to favorites: $e');
      rethrow;
    }
  }

  /// Remove vendor from favorites
  Future<void> removeFromFavorites(String vendorId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (kDebugMode) debugPrint('VendorFavoriteService: Removing vendor $vendorId from favorites');

      await _supabase
          .from('vendor_favorites')
          .delete()
          .eq('customer_id', user.id)
          .eq('vendor_id', vendorId);

      if (kDebugMode) debugPrint('VendorFavoriteService: Vendor removed from favorites successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('VendorFavoriteService: Error removing vendor from favorites: $e');
      rethrow;
    }
  }

  /// Check if vendor is in favorites
  Future<bool> isVendorFavorited(String vendorId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('vendor_favorites')
          .select('id')
          .eq('customer_id', user.id)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorFavoriteService: Error checking favorite status: $e');
      return false;
    }
  }

  /// Get favorite vendor IDs for quick lookup
  Future<Set<String>> getFavoriteVendorIds() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};

      final response = await _supabase
          .from('vendor_favorites')
          .select('vendor_id')
          .eq('customer_id', user.id);

      return response.map((item) => item['vendor_id'] as String).toSet();
    } catch (e) {
      if (kDebugMode) debugPrint('VendorFavoriteService: Error fetching favorite vendor IDs: $e');
      return {};
    }
  }

  /// Get favorites count for a customer
  Future<int> getFavoritesCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('vendor_favorites')
          .select('id')
          .eq('customer_id', user.id);

      return response.length;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorFavoriteService: Error getting favorites count: $e');
      return 0;
    }
  }
}
