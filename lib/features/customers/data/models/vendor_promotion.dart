import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_promotion.freezed.dart';
part 'vendor_promotion.g.dart';

/// Vendor promotion/offer
@freezed
class VendorPromotion with _$VendorPromotion {
  const factory VendorPromotion({
    required String id,
    required String vendorId,
    required String title,
    required String description,
    required PromotionType type,
    String? imageUrl,
    double? discountPercentage,
    double? discountAmount,
    double? minimumOrderAmount,
    double? maximumDiscountAmount,
    String? promoCode,
    required DateTime startDate,
    required DateTime endDate,
    required bool isActive,
    int? usageLimit,
    int? usedCount,
    @Default([]) List<String> applicableCategories,
    @Default([]) List<String> applicableMenuItems,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _VendorPromotion;

  factory VendorPromotion.fromJson(Map<String, dynamic> json) => _$VendorPromotionFromJson(json);
}

/// Promotion type enum
enum PromotionType {
  @JsonValue('percentage_discount')
  percentageDiscount,
  @JsonValue('fixed_discount')
  fixedDiscount,
  @JsonValue('free_delivery')
  freeDelivery,
  @JsonValue('buy_one_get_one')
  buyOneGetOne,
  @JsonValue('minimum_order_discount')
  minimumOrderDiscount,
  @JsonValue('category_discount')
  categoryDiscount,
  @JsonValue('item_discount')
  itemDiscount,
}
