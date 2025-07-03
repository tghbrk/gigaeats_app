import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer/vendor_review.dart';

class VendorReviewService {
  /// Get the Supabase client instance
  SupabaseClient get supabase => Supabase.instance.client;

  /// Get reviews for a vendor
  Future<List<VendorReview>> getVendorReviews(
    String vendorId, {
    int limit = 20,
    int offset = 0,
    ReviewStatus? status,
  }) async {
    try {
      if (kDebugMode) debugPrint('VendorReviewService: Fetching reviews for vendor $vendorId');

      var query = supabase
          .from('vendor_reviews')
          .select('''
            *,
            customers!customer_id(
              id,
              contact_person_name,
              organization_name
            ),
            orders!order_id(
              id,
              order_number,
              created_at
            )
          ''')
          .eq('vendor_id', vendorId);

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      final reviews = response.map((json) {
        // Transform customer data
        final customerData = json['customers'];
        CustomerInfo? customer;
        if (customerData != null) {
          customer = CustomerInfo(
            id: customerData['id'],
            name: customerData['contact_person_name'] ?? customerData['organization_name'] ?? 'Anonymous',
          );
        }

        // Transform order data
        final orderData = json['orders'];
        OrderInfo? order;
        if (orderData != null) {
          order = OrderInfo(
            id: orderData['id'],
            orderNumber: orderData['order_number'],
            orderDate: DateTime.parse(orderData['created_at']),
          );
        }

        return VendorReview(
          id: json['id'],
          vendorId: json['vendor_id'],
          customerId: json['customer_id'],
          orderId: json['order_id'],
          rating: json['rating'],
          reviewText: json['review_text'],
          imageUrls: List<String>.from(json['image_urls'] ?? []),
          status: ReviewStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => ReviewStatus.active,
          ),
          vendorResponse: json['vendor_response'],
          vendorResponseDate: json['vendor_response_date'] != null
              ? DateTime.parse(json['vendor_response_date'])
              : null,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
          customer: customer,
          order: order,
        );
      }).toList();

      if (kDebugMode) debugPrint('VendorReviewService: Found ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorReviewService: Error fetching vendor reviews: $e');
      rethrow;
    }
  }

  /// Get review statistics for a vendor
  Future<VendorReviewStats> getVendorReviewStats(String vendorId) async {
    try {
      if (kDebugMode) debugPrint('VendorReviewService: Fetching review stats for vendor $vendorId');

      // Get basic stats
      final statsResponse = await supabase
          .from('vendor_reviews')
          .select('rating, review_text, image_urls')
          .eq('vendor_id', vendorId)
          .eq('status', 'active');

      if (statsResponse.isEmpty) {
        return const VendorReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
          totalWithText: 0,
          totalWithImages: 0,
        );
      }

      // Calculate statistics
      final ratings = statsResponse.map((r) => r['rating'] as int).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((r) => r == i).length;
      }

      final totalWithText = statsResponse
          .where((r) => r['review_text'] != null && (r['review_text'] as String).isNotEmpty)
          .length;

      final totalWithImages = statsResponse
          .where((r) => r['image_urls'] != null && (r['image_urls'] as List).isNotEmpty)
          .length;

      final stats = VendorReviewStats(
        averageRating: double.parse(averageRating.toStringAsFixed(1)),
        totalReviews: ratings.length,
        ratingDistribution: ratingDistribution,
        totalWithText: totalWithText,
        totalWithImages: totalWithImages,
      );

      if (kDebugMode) debugPrint('VendorReviewService: Calculated stats - avg: $averageRating, total: ${ratings.length}');
      return stats;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorReviewService: Error fetching review stats: $e');
      rethrow;
    }
  }

  /// Submit a new review
  Future<VendorReview> submitReview({
    required String vendorId,
    String? orderId,
    required int rating,
    String? reviewText,
    List<String>? imageUrls,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (kDebugMode) debugPrint('VendorReviewService: Submitting review for vendor $vendorId');

      final response = await supabase
          .from('vendor_reviews')
          .insert({
            'vendor_id': vendorId,
            'customer_id': user.id,
            'order_id': orderId,
            'rating': rating,
            'review_text': reviewText,
            'image_urls': imageUrls ?? [],
            'status': 'active',
          })
          .select()
          .single();

      final review = VendorReview(
        id: response['id'],
        vendorId: response['vendor_id'],
        customerId: response['customer_id'],
        orderId: response['order_id'],
        rating: response['rating'],
        reviewText: response['review_text'],
        imageUrls: List<String>.from(response['image_urls'] ?? []),
        status: ReviewStatus.active,
        vendorResponse: response['vendor_response'],
        vendorResponseDate: response['vendor_response_date'] != null
            ? DateTime.parse(response['vendor_response_date'])
            : null,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
      );

      if (kDebugMode) debugPrint('VendorReviewService: Review submitted successfully');
      return review;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorReviewService: Error submitting review: $e');
      rethrow;
    }
  }

  /// Check if customer can review a vendor (has completed orders)
  Future<bool> canReviewVendor(String vendorId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final response = await supabase
          .from('orders')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('customer_id', user.id)
          .eq('status', 'delivered')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('VendorReviewService: Error checking review eligibility: $e');
      return false;
    }
  }

  /// Get customer's review for a vendor
  Future<VendorReview?> getCustomerReview(String vendorId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('vendor_reviews')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('customer_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return VendorReview(
        id: response['id'],
        vendorId: response['vendor_id'],
        customerId: response['customer_id'],
        orderId: response['order_id'],
        rating: response['rating'],
        reviewText: response['review_text'],
        imageUrls: List<String>.from(response['image_urls'] ?? []),
        status: ReviewStatus.values.firstWhere(
          (s) => s.name == response['status'],
          orElse: () => ReviewStatus.active,
        ),
        vendorResponse: response['vendor_response'],
        vendorResponseDate: response['vendor_response_date'] != null
            ? DateTime.parse(response['vendor_response_date'])
            : null,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('VendorReviewService: Error fetching customer review: $e');
      rethrow;
    }
  }
}
