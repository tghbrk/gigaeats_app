import 'dart:async';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer/vendor_promotion.dart';

class VendorPromotionService {
  final Logger _logger = Logger();

  /// Get the Supabase client instance
  SupabaseClient get supabase => Supabase.instance.client;

  /// Get active promotions for a vendor
  Future<List<VendorPromotion>> getVendorPromotions(
    String vendorId, {
    bool activeOnly = true,
  }) async {
    try {
      _logger.i('VendorPromotionService: Fetching promotions for vendor $vendorId');

      var query = supabase
          .from('vendor_promotions')
          .select('*')
          .eq('vendor_id', vendorId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      final promotions = response.map((json) {
        return VendorPromotion(
          id: json['id'],
          vendorId: json['vendor_id'],
          title: json['title'],
          description: json['description'],
          type: PromotionType.values.firstWhere(
            (t) => t.name == json['type'],
            orElse: () => PromotionType.percentageDiscount,
          ),
          imageUrl: json['image_url'],
          discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
          discountAmount: (json['discount_amount'] as num?)?.toDouble(),
          minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble(),
          maximumDiscountAmount: (json['maximum_discount_amount'] as num?)?.toDouble(),
          promoCode: json['promo_code'],
          startDate: DateTime.parse(json['start_date']),
          endDate: DateTime.parse(json['end_date']),
          isActive: json['is_active'] ?? false,
          usageLimit: json['usage_limit'],
          usedCount: json['used_count'] ?? 0,
          applicableCategories: List<String>.from(json['applicable_categories'] ?? []),
          applicableMenuItems: List<String>.from(json['applicable_menu_items'] ?? []),
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();

      _logger.i('VendorPromotionService: Found ${promotions.length} promotions');
      return promotions;
    } catch (e) {
      _logger.e('VendorPromotionService: Error fetching vendor promotions', error: e);
      rethrow;
    }
  }

  /// Get all active promotions across vendors
  Future<List<VendorPromotion>> getAllActivePromotions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _logger.i('VendorPromotionService: Fetching all active promotions');

      final now = DateTime.now().toIso8601String();
      final response = await supabase
          .from('vendor_promotions')
          .select('*')
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final promotions = response.map((json) {
        return VendorPromotion(
          id: json['id'],
          vendorId: json['vendor_id'],
          title: json['title'],
          description: json['description'],
          type: PromotionType.values.firstWhere(
            (t) => t.name == json['type'],
            orElse: () => PromotionType.percentageDiscount,
          ),
          imageUrl: json['image_url'],
          discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
          discountAmount: (json['discount_amount'] as num?)?.toDouble(),
          minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble(),
          maximumDiscountAmount: (json['maximum_discount_amount'] as num?)?.toDouble(),
          promoCode: json['promo_code'],
          startDate: DateTime.parse(json['start_date']),
          endDate: DateTime.parse(json['end_date']),
          isActive: json['is_active'] ?? false,
          usageLimit: json['usage_limit'],
          usedCount: json['used_count'] ?? 0,
          applicableCategories: List<String>.from(json['applicable_categories'] ?? []),
          applicableMenuItems: List<String>.from(json['applicable_menu_items'] ?? []),
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();

      _logger.i('VendorPromotionService: Found ${promotions.length} active promotions');
      return promotions;
    } catch (e) {
      _logger.e('VendorPromotionService: Error fetching active promotions', error: e);
      rethrow;
    }
  }

  /// Validate and apply promotion to order
  Future<Map<String, dynamic>> validatePromotion({
    required String promotionId,
    required double orderAmount,
    List<String>? orderCategories,
    List<String>? orderMenuItems,
  }) async {
    try {
      _logger.i('VendorPromotionService: Validating promotion $promotionId');

      final response = await supabase
          .from('vendor_promotions')
          .select('*')
          .eq('id', promotionId)
          .single();

      final promotion = VendorPromotion(
        id: response['id'],
        vendorId: response['vendor_id'],
        title: response['title'],
        description: response['description'],
        type: PromotionType.values.firstWhere(
          (t) => t.name == response['type'],
          orElse: () => PromotionType.percentageDiscount,
        ),
        imageUrl: response['image_url'],
        discountPercentage: (response['discount_percentage'] as num?)?.toDouble(),
        discountAmount: (response['discount_amount'] as num?)?.toDouble(),
        minimumOrderAmount: (response['minimum_order_amount'] as num?)?.toDouble(),
        maximumDiscountAmount: (response['maximum_discount_amount'] as num?)?.toDouble(),
        promoCode: response['promo_code'],
        startDate: DateTime.parse(response['start_date']),
        endDate: DateTime.parse(response['end_date']),
        isActive: response['is_active'] ?? false,
        usageLimit: response['usage_limit'],
        usedCount: response['used_count'] ?? 0,
        applicableCategories: List<String>.from(response['applicable_categories'] ?? []),
        applicableMenuItems: List<String>.from(response['applicable_menu_items'] ?? []),
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
      );

      // Validate promotion
      final now = DateTime.now();
      if (!promotion.isActive) {
        return {'isValid': false, 'error': 'Promotion is not active'};
      }

      if (now.isBefore(promotion.startDate) || now.isAfter(promotion.endDate)) {
        return {'isValid': false, 'error': 'Promotion has expired'};
      }

      if (promotion.usageLimit != null && (promotion.usedCount ?? 0) >= promotion.usageLimit!) {
        return {'isValid': false, 'error': 'Promotion usage limit reached'};
      }

      if (promotion.minimumOrderAmount != null && orderAmount < promotion.minimumOrderAmount!) {
        return {
          'isValid': false,
          'error': 'Minimum order amount of RM${promotion.minimumOrderAmount!.toStringAsFixed(2)} required'
        };
      }

      // Check category/item applicability
      if (promotion.applicableCategories.isNotEmpty && orderCategories != null) {
        final hasApplicableCategory = orderCategories
            .any((cat) => promotion.applicableCategories.contains(cat));
        if (!hasApplicableCategory) {
          return {'isValid': false, 'error': 'Promotion not applicable to selected items'};
        }
      }

      if (promotion.applicableMenuItems.isNotEmpty && orderMenuItems != null) {
        final hasApplicableItem = orderMenuItems
            .any((item) => promotion.applicableMenuItems.contains(item));
        if (!hasApplicableItem) {
          return {'isValid': false, 'error': 'Promotion not applicable to selected items'};
        }
      }

      // Calculate discount
      double discountAmount = 0.0;
      switch (promotion.type) {
        case PromotionType.percentageDiscount:
          if (promotion.discountPercentage != null) {
            discountAmount = orderAmount * (promotion.discountPercentage! / 100);
            if (promotion.maximumDiscountAmount != null) {
              discountAmount = discountAmount.clamp(0, promotion.maximumDiscountAmount!);
            }
          }
          break;
        case PromotionType.fixedDiscount:
          if (promotion.discountAmount != null) {
            discountAmount = promotion.discountAmount!;
          }
          break;
        case PromotionType.freeDelivery:
          // This would be handled in the delivery fee calculation
          discountAmount = 0.0;
          break;
        default:
          discountAmount = 0.0;
      }

      _logger.i('VendorPromotionService: Promotion validated successfully, discount: RM${discountAmount.toStringAsFixed(2)}');

      return {
        'isValid': true,
        'promotion': promotion,
        'discountAmount': discountAmount,
        'finalAmount': orderAmount - discountAmount,
      };
    } catch (e) {
      _logger.e('VendorPromotionService: Error validating promotion', error: e);
      return {'isValid': false, 'error': 'Failed to validate promotion'};
    }
  }
}
