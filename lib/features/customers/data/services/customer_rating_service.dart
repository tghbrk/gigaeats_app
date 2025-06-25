import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling customer order ratings and reviews
class CustomerRatingService {
  final SupabaseClient _supabase;

  CustomerRatingService(this._supabase);

  /// Submit a rating for an order
  Future<void> submitOrderRating({
    required String orderId,
    required String vendorId,
    required int overallRating,
    int? foodQualityRating,
    int? deliveryRating,
    int? serviceRating,
    bool wouldRecommend = false,
    String? reviewText,
  }) async {
    try {
      debugPrint('CustomerRatingService: Submitting rating for order $orderId');

      // Validate ratings
      if (overallRating < 1 || overallRating > 5) {
        throw Exception('Overall rating must be between 1 and 5');
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get customer profile ID
      final customerProfile = await _supabase
          .from('customer_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (customerProfile == null) {
        throw Exception('Customer profile not found');
      }

      final customerId = customerProfile['id'] as String;

      // Check if rating already exists for this order
      final existingRating = await _supabase
          .from('order_ratings')
          .select('id')
          .eq('order_id', orderId)
          .eq('customer_id', customerId)
          .maybeSingle();

      if (existingRating != null) {
        throw Exception('You have already rated this order');
      }

      // Prepare rating data
      final ratingData = {
        'order_id': orderId,
        'vendor_id': vendorId,
        'customer_id': customerId,
        'overall_rating': overallRating,
        'food_quality_rating': foodQualityRating,
        'delivery_rating': deliveryRating,
        'service_rating': serviceRating,
        'would_recommend': wouldRecommend,
        'review_text': reviewText,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert rating
      await _supabase
          .from('order_ratings')
          .insert(ratingData);

      // Update vendor's average rating
      await _updateVendorAverageRating(vendorId);

      debugPrint('CustomerRatingService: Rating submitted successfully');
    } catch (e) {
      debugPrint('CustomerRatingService: Error submitting rating: $e');
      rethrow;
    }
  }

  /// Get rating for a specific order
  Future<OrderRating?> getOrderRating(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Get customer profile ID
      final customerProfile = await _supabase
          .from('customer_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (customerProfile == null) return null;

      final customerId = customerProfile['id'] as String;

      final response = await _supabase
          .from('order_ratings')
          .select('*')
          .eq('order_id', orderId)
          .eq('customer_id', customerId)
          .maybeSingle();

      return response != null ? OrderRating.fromJson(response) : null;
    } catch (e) {
      debugPrint('CustomerRatingService: Error getting order rating: $e');
      return null;
    }
  }

  /// Check if an order can be rated
  Future<bool> canRateOrder(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get customer profile ID
      final customerProfile = await _supabase
          .from('customer_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (customerProfile == null) return false;

      final customerId = customerProfile['id'] as String;

      // Check if order exists and is delivered
      final order = await _supabase
          .from('orders')
          .select('status, customer_id')
          .eq('id', orderId)
          .eq('customer_id', customerId)
          .maybeSingle();

      if (order == null) return false;

      // Only allow rating for delivered orders
      if (order['status'] != 'delivered') return false;

      // Check if already rated
      final existingRating = await _supabase
          .from('order_ratings')
          .select('id')
          .eq('order_id', orderId)
          .eq('customer_id', customerId)
          .maybeSingle();

      return existingRating == null;
    } catch (e) {
      debugPrint('CustomerRatingService: Error checking if order can be rated: $e');
      return false;
    }
  }

  /// Get customer's ratings history
  Future<List<OrderRating>> getCustomerRatings({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Get customer profile ID
      final customerProfile = await _supabase
          .from('customer_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (customerProfile == null) return [];

      final customerId = customerProfile['id'] as String;

      final response = await _supabase
          .from('order_ratings')
          .select('''
            *,
            order:orders!order_ratings_order_id_fkey(
              order_number,
              vendor_name,
              total_amount,
              created_at
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((data) => OrderRating.fromJson(data)).toList();
    } catch (e) {
      debugPrint('CustomerRatingService: Error getting customer ratings: $e');
      return [];
    }
  }

  /// Update vendor's average rating
  Future<void> _updateVendorAverageRating(String vendorId) async {
    try {
      // Calculate new average rating
      final ratingsResponse = await _supabase
          .from('order_ratings')
          .select('overall_rating')
          .eq('vendor_id', vendorId);

      if (ratingsResponse.isEmpty) return;

      final ratings = ratingsResponse
          .map((r) => r['overall_rating'] as int)
          .toList();

      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      final totalRatings = ratings.length;

      // Update vendor rating
      await _supabase
          .from('vendors')
          .update({
            'rating': averageRating,
            'total_ratings': totalRatings,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      debugPrint('CustomerRatingService: Updated vendor $vendorId average rating to $averageRating ($totalRatings ratings)');
    } catch (e) {
      debugPrint('CustomerRatingService: Error updating vendor average rating: $e');
      // Don't rethrow as this is not critical for the rating submission
    }
  }
}

/// Order rating model
class OrderRating {
  final String id;
  final String orderId;
  final String vendorId;
  final String customerId;
  final int overallRating;
  final int? foodQualityRating;
  final int? deliveryRating;
  final int? serviceRating;
  final bool wouldRecommend;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? orderDetails;

  OrderRating({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.customerId,
    required this.overallRating,
    this.foodQualityRating,
    this.deliveryRating,
    this.serviceRating,
    required this.wouldRecommend,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.orderDetails,
  });

  factory OrderRating.fromJson(Map<String, dynamic> json) {
    return OrderRating(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      vendorId: json['vendor_id'] as String,
      customerId: json['customer_id'] as String,
      overallRating: json['overall_rating'] as int,
      foodQualityRating: json['food_quality_rating'] as int?,
      deliveryRating: json['delivery_rating'] as int?,
      serviceRating: json['service_rating'] as int?,
      wouldRecommend: json['would_recommend'] as bool? ?? false,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      orderDetails: json['order'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'vendor_id': vendorId,
      'customer_id': customerId,
      'overall_rating': overallRating,
      'food_quality_rating': foodQualityRating,
      'delivery_rating': deliveryRating,
      'service_rating': serviceRating,
      'would_recommend': wouldRecommend,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Provider for customer rating service
final customerRatingServiceProvider = Provider<CustomerRatingService>((ref) {
  return CustomerRatingService(Supabase.instance.client);
});

/// Provider for checking if an order can be rated
final canRateOrderProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  final ratingService = ref.watch(customerRatingServiceProvider);
  return await ratingService.canRateOrder(orderId);
});

/// Provider for getting order rating
final orderRatingProvider = FutureProvider.family<OrderRating?, String>((ref, orderId) async {
  final ratingService = ref.watch(customerRatingServiceProvider);
  return await ratingService.getOrderRating(orderId);
});
