import 'package:freezed_annotation/freezed_annotation.dart';

part 'faq_item.freezed.dart';
part 'faq_item.g.dart';

/// FAQ item model
@freezed
class FAQItem with _$FAQItem {
  const factory FAQItem({
    required String id,
    required String categoryId,
    required String question,
    required String answer,
    @Default([]) List<String> keywords,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    @Default(0) int viewCount,
    @Default(0) int helpfulCount,
    @Default(0) int notHelpfulCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // Related data
    FAQCategoryInfo? category,
  }) = _FAQItem;

  factory FAQItem.fromJson(Map<String, dynamic> json) => _$FAQItemFromJson(json);
}

/// FAQ category model
@freezed
class FAQCategory with _$FAQCategory {
  const factory FAQCategory({
    required String id,
    required String name,
    String? description,
    @Default('help_outline') String icon,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // Related data
    @Default([]) List<FAQItem> faqItems,
  }) = _FAQCategory;

  factory FAQCategory.fromJson(Map<String, dynamic> json) => _$FAQCategoryFromJson(json);
}

/// FAQ category info for FAQ items
@freezed
class FAQCategoryInfo with _$FAQCategoryInfo {
  const factory FAQCategoryInfo({
    required String name,
  }) = _FAQCategoryInfo;

  factory FAQCategoryInfo.fromJson(Map<String, dynamic> json) => _$FAQCategoryInfoFromJson(json);
}
