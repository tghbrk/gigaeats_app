import 'package:freezed_annotation/freezed_annotation.dart';


part 'vendor_review.freezed.dart';
part 'vendor_review.g.dart';

/// Customer review for a vendor
@freezed
class VendorReview with _$VendorReview {
  const factory VendorReview({
    required String id,
    required String vendorId,
    required String customerId,
    String? orderId,
    required int rating,
    String? reviewText,
    @Default([]) List<String> imageUrls,
    @Default(ReviewStatus.active) ReviewStatus status,
    String? vendorResponse,
    DateTime? vendorResponseDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // Related data
    CustomerInfo? customer,
    OrderInfo? order,
  }) = _VendorReview;

  factory VendorReview.fromJson(Map<String, dynamic> json) => _$VendorReviewFromJson(json);
}

/// Review status enum
enum ReviewStatus {
  @JsonValue('active')
  active,
  @JsonValue('hidden')
  hidden,
  @JsonValue('flagged')
  flagged,
  @JsonValue('deleted')
  deleted,
}

/// Customer information for reviews
@freezed
class CustomerInfo with _$CustomerInfo {
  const factory CustomerInfo({
    required String id,
    required String name,
    String? avatarUrl,
  }) = _CustomerInfo;

  factory CustomerInfo.fromJson(Map<String, dynamic> json) => _$CustomerInfoFromJson(json);
}

/// Order information for reviews
@freezed
class OrderInfo with _$OrderInfo {
  const factory OrderInfo({
    required String id,
    required String orderNumber,
    required DateTime orderDate,
  }) = _OrderInfo;

  factory OrderInfo.fromJson(Map<String, dynamic> json) => _$OrderInfoFromJson(json);
}

/// Review statistics for a vendor
@freezed
class VendorReviewStats with _$VendorReviewStats {
  const factory VendorReviewStats({
    required double averageRating,
    required int totalReviews,
    required Map<int, int> ratingDistribution,
    required int totalWithText,
    required int totalWithImages,
  }) = _VendorReviewStats;

  factory VendorReviewStats.fromJson(Map<String, dynamic> json) => _$VendorReviewStatsFromJson(json);
}
