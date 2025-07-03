import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_favorite.freezed.dart';
part 'vendor_favorite.g.dart';

/// Customer's favorite vendor
@freezed
class VendorFavorite with _$VendorFavorite {
  const factory VendorFavorite({
    required String id,
    required String customerId,
    required String vendorId,
    required DateTime createdAt,
    
    // Related data
    VendorInfo? vendor,
  }) = _VendorFavorite;

  factory VendorFavorite.fromJson(Map<String, dynamic> json) => _$VendorFavoriteFromJson(json);
}

/// Vendor information for favorites
@freezed
class VendorInfo with _$VendorInfo {
  const factory VendorInfo({
    required String id,
    required String businessName,
    String? coverImageUrl,
    required List<String> cuisineTypes,
    required double rating,
    required int totalReviews,
    required bool isActive,
    String? description,
    double? deliveryFee,
    double? minimumOrderAmount,
  }) = _VendorInfo;

  factory VendorInfo.fromJson(Map<String, dynamic> json) => _$VendorInfoFromJson(json);
}
