import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/customer/vendor_review_service.dart';
import '../../../data/services/customer/vendor_favorite_service.dart';
import '../../../data/services/customer/vendor_promotion_service.dart';
import '../../../data/models/customer/vendor_review.dart';
import '../../../data/models/customer/vendor_favorite.dart';
import '../../../data/models/customer/vendor_promotion.dart';

/// Provider for VendorReviewService
final vendorReviewServiceProvider = Provider<VendorReviewService>((ref) {
  return VendorReviewService();
});

/// Provider for VendorFavoriteService
final vendorFavoriteServiceProvider = Provider<VendorFavoriteService>((ref) {
  return VendorFavoriteService();
});

/// Provider for VendorPromotionService
final vendorPromotionServiceProvider = Provider<VendorPromotionService>((ref) {
  return VendorPromotionService();
});

/// Provider for vendor reviews
final vendorReviewsProvider = FutureProvider.family<List<VendorReview>, String>((ref, vendorId) async {
  final reviewService = ref.watch(vendorReviewServiceProvider);
  return reviewService.getVendorReviews(vendorId);
});

/// Provider for vendor review statistics
final vendorReviewStatsProvider = FutureProvider.family<VendorReviewStats, String>((ref, vendorId) async {
  final reviewService = ref.watch(vendorReviewServiceProvider);
  return reviewService.getVendorReviewStats(vendorId);
});

/// Provider for checking if customer can review vendor
final canReviewVendorProvider = FutureProvider.family<bool, String>((ref, vendorId) async {
  final reviewService = ref.watch(vendorReviewServiceProvider);
  return reviewService.canReviewVendor(vendorId);
});

/// Provider for customer's review of a vendor
final customerReviewProvider = FutureProvider.family<VendorReview?, String>((ref, vendorId) async {
  final reviewService = ref.watch(vendorReviewServiceProvider);
  return reviewService.getCustomerReview(vendorId);
});

/// Provider for vendor promotions
final vendorPromotionsProvider = FutureProvider.family<List<VendorPromotion>, String>((ref, vendorId) async {
  final promotionService = ref.watch(vendorPromotionServiceProvider);
  return promotionService.getVendorPromotions(vendorId);
});

/// Provider for all active promotions
final allActivePromotionsProvider = FutureProvider<List<VendorPromotion>>((ref) async {
  final promotionService = ref.watch(vendorPromotionServiceProvider);
  return promotionService.getAllActivePromotions();
});

/// Provider for favorite vendors
final favoriteVendorsProvider = FutureProvider<List<VendorFavorite>>((ref) async {
  final favoriteService = ref.watch(vendorFavoriteServiceProvider);
  return favoriteService.getFavoriteVendors();
});

/// Provider for checking if vendor is favorited
final isVendorFavoritedProvider = FutureProvider.family<bool, String>((ref, vendorId) async {
  final favoriteService = ref.watch(vendorFavoriteServiceProvider);
  return favoriteService.isVendorFavorited(vendorId);
});

/// Provider for favorite vendor IDs
final favoriteVendorIdsProvider = FutureProvider<Set<String>>((ref) async {
  final favoriteService = ref.watch(vendorFavoriteServiceProvider);
  return favoriteService.getFavoriteVendorIds();
});

/// State notifier for managing vendor favorite status
class VendorFavoriteNotifier extends StateNotifier<AsyncValue<bool>> {
  final VendorFavoriteService _favoriteService;
  final String vendorId;

  VendorFavoriteNotifier(this._favoriteService, this.vendorId) : super(const AsyncValue.loading()) {
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorited = await _favoriteService.isVendorFavorited(vendorId);
      state = AsyncValue.data(isFavorited);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = const AsyncValue.loading();

    try {
      if (currentState) {
        await _favoriteService.removeFromFavorites(vendorId);
        state = const AsyncValue.data(false);
      } else {
        await _favoriteService.addToFavorites(vendorId);
        state = const AsyncValue.data(true);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      // Revert to previous state on error
      state = AsyncValue.data(currentState);
    }
  }
}

/// Provider for vendor favorite notifier
final vendorFavoriteNotifierProvider = StateNotifierProvider.family<VendorFavoriteNotifier, AsyncValue<bool>, String>((ref, vendorId) {
  final favoriteService = ref.watch(vendorFavoriteServiceProvider);
  return VendorFavoriteNotifier(favoriteService, vendorId);
});

/// State notifier for submitting reviews
class ReviewSubmissionNotifier extends StateNotifier<AsyncValue<VendorReview?>> {
  final VendorReviewService _reviewService;

  ReviewSubmissionNotifier(this._reviewService) : super(const AsyncValue.data(null));

  Future<void> submitReview({
    required String vendorId,
    String? orderId,
    required int rating,
    String? reviewText,
    List<String>? imageUrls,
  }) async {
    state = const AsyncValue.loading();

    try {
      final review = await _reviewService.submitReview(
        vendorId: vendorId,
        orderId: orderId,
        rating: rating,
        reviewText: reviewText,
        imageUrls: imageUrls,
      );
      state = AsyncValue.data(review);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for review submission notifier
final reviewSubmissionNotifierProvider = StateNotifierProvider<ReviewSubmissionNotifier, AsyncValue<VendorReview?>>((ref) {
  final reviewService = ref.watch(vendorReviewServiceProvider);
  return ReviewSubmissionNotifier(reviewService);
});

/// Enhanced vendor search filters
class VendorSearchFilters {
  final String? searchQuery;
  final List<String> cuisineTypes;
  final double? minRating;
  final bool? isHalalOnly;
  final bool? hasPromotions;
  final bool? favoritesOnly;
  final double? maxDeliveryFee;
  final double? maxDistance;
  final bool? isOpen;

  const VendorSearchFilters({
    this.searchQuery,
    this.cuisineTypes = const [],
    this.minRating,
    this.isHalalOnly,
    this.hasPromotions,
    this.favoritesOnly,
    this.maxDeliveryFee,
    this.maxDistance,
    this.isOpen,
  });

  VendorSearchFilters copyWith({
    String? searchQuery,
    List<String>? cuisineTypes,
    double? minRating,
    bool? isHalalOnly,
    bool? hasPromotions,
    bool? favoritesOnly,
    double? maxDeliveryFee,
    double? maxDistance,
    bool? isOpen,
  }) {
    return VendorSearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      minRating: minRating ?? this.minRating,
      isHalalOnly: isHalalOnly ?? this.isHalalOnly,
      hasPromotions: hasPromotions ?? this.hasPromotions,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      maxDeliveryFee: maxDeliveryFee ?? this.maxDeliveryFee,
      maxDistance: maxDistance ?? this.maxDistance,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorSearchFilters &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          cuisineTypes == other.cuisineTypes &&
          minRating == other.minRating &&
          isHalalOnly == other.isHalalOnly &&
          hasPromotions == other.hasPromotions &&
          favoritesOnly == other.favoritesOnly &&
          maxDeliveryFee == other.maxDeliveryFee &&
          maxDistance == other.maxDistance &&
          isOpen == other.isOpen;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      cuisineTypes.hashCode ^
      minRating.hashCode ^
      isHalalOnly.hashCode ^
      hasPromotions.hashCode ^
      favoritesOnly.hashCode ^
      maxDeliveryFee.hashCode ^
      maxDistance.hashCode ^
      isOpen.hashCode;
}
