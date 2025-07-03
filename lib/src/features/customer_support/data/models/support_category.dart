import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_category.freezed.dart';
part 'support_category.g.dart';

/// Support category model
@freezed
class SupportCategory with _$SupportCategory {
  const factory SupportCategory({
    required String id,
    required String name,
    String? description,
    @Default('help_outline') String icon,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SupportCategory;

  factory SupportCategory.fromJson(Map<String, dynamic> json) => _$SupportCategoryFromJson(json);
}
