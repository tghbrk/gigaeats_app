import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/customization_template_repository.dart';
import '../../data/models/customization_template.dart';
import '../../data/models/template_usage_analytics.dart';

// ==================== REPOSITORY PROVIDERS ====================

/// Customization template repository provider
final customizationTemplateRepositoryProvider = Provider<CustomizationTemplateRepository>((ref) {
  return CustomizationTemplateRepository();
});

// ==================== TEMPLATE CRUD PROVIDERS ====================

/// Provider for vendor templates
final vendorTemplatesProvider = FutureProvider.family<List<CustomizationTemplate>, VendorTemplatesParams>((ref, params) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getVendorTemplates(
    params.vendorId,
    isActive: params.isActive,
    searchQuery: params.searchQuery,
    limit: params.limit,
    offset: params.offset,
  );
});

/// Provider for a specific template by ID
final templateByIdProvider = FutureProvider.family<CustomizationTemplate?, String>((ref, templateId) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getTemplateById(templateId);
});

/// Provider for templates linked to a menu item
final menuItemTemplatesProvider = FutureProvider.family<List<CustomizationTemplate>, String>((ref, menuItemId) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getMenuItemTemplates(menuItemId);
});

/// Provider for menu items using a specific template
final menuItemsUsingTemplateProvider = FutureProvider.family<List<String>, String>((ref, templateId) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getMenuItemsUsingTemplate(templateId);
});

/// Provider for searching templates
final searchTemplatesProvider = FutureProvider.family<List<CustomizationTemplate>, SearchTemplatesParams>((ref, params) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.searchTemplates(
    vendorId: params.vendorId,
    query: params.query,
    limit: params.limit,
  );
});

/// Provider for popular templates
final popularTemplatesProvider = FutureProvider.family<List<CustomizationTemplate>, PopularTemplatesParams>((ref, params) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getPopularTemplates(
    vendorId: params.vendorId,
    limit: params.limit,
  );
});

// ==================== ANALYTICS PROVIDERS ====================

/// Provider for template analytics
final templateAnalyticsProvider = FutureProvider.family<List<TemplateUsageAnalytics>, TemplateAnalyticsParams>((ref, params) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getTemplateAnalytics(
    vendorId: params.vendorId,
    startDate: params.startDate,
    endDate: params.endDate,
    limit: params.limit,
  );
});

/// Provider for analytics summary
final templateAnalyticsSummaryProvider = FutureProvider.family<TemplateAnalyticsSummary, AnalyticsSummaryParams>((ref, params) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getAnalyticsSummary(
    vendorId: params.vendorId,
    periodStart: params.periodStart,
    periodEnd: params.periodEnd,
  );
});

/// Provider for template performance metrics
final templatePerformanceMetricsProvider = FutureProvider.family<List<TemplatePerformanceMetrics>, PerformanceMetricsParams>((ref, params) async {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return repository.getTemplatePerformanceMetrics(
    vendorId: params.vendorId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// ==================== STATE MANAGEMENT PROVIDERS ====================

/// State notifier for template management
final templateManagementProvider = StateNotifierProvider<TemplateManagementNotifier, TemplateManagementState>((ref) {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return TemplateManagementNotifier(repository);
});

/// State notifier for template linking
final templateLinkingProvider = StateNotifierProvider<TemplateLinkingNotifier, TemplateLinkingState>((ref) {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return TemplateLinkingNotifier(repository);
});

// ==================== PARAMETER CLASSES ====================

/// Parameters for vendor templates provider
class VendorTemplatesParams {
  final String vendorId;
  final bool? isActive;
  final String? searchQuery;
  final int limit;
  final int offset;

  const VendorTemplatesParams({
    required this.vendorId,
    this.isActive,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorTemplatesParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          isActive == other.isActive &&
          searchQuery == other.searchQuery &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      vendorId.hashCode ^
      isActive.hashCode ^
      searchQuery.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}

/// Parameters for search templates provider
class SearchTemplatesParams {
  final String vendorId;
  final String query;
  final int limit;

  const SearchTemplatesParams({
    required this.vendorId,
    required this.query,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchTemplatesParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          query == other.query &&
          limit == other.limit;

  @override
  int get hashCode => vendorId.hashCode ^ query.hashCode ^ limit.hashCode;
}

/// Parameters for popular templates provider
class PopularTemplatesParams {
  final String vendorId;
  final int limit;

  const PopularTemplatesParams({
    required this.vendorId,
    this.limit = 10,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PopularTemplatesParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          limit == other.limit;

  @override
  int get hashCode => vendorId.hashCode ^ limit.hashCode;
}

/// Parameters for template analytics provider
class TemplateAnalyticsParams {
  final String vendorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  const TemplateAnalyticsParams({
    required this.vendorId,
    this.startDate,
    this.endDate,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateAnalyticsParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          limit == other.limit;

  @override
  int get hashCode =>
      vendorId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      limit.hashCode;
}

/// Parameters for analytics summary provider
class AnalyticsSummaryParams {
  final String vendorId;
  final DateTime periodStart;
  final DateTime periodEnd;

  const AnalyticsSummaryParams({
    required this.vendorId,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSummaryParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd;

  @override
  int get hashCode =>
      vendorId.hashCode ^ periodStart.hashCode ^ periodEnd.hashCode;
}

/// Parameters for performance metrics provider
class PerformanceMetricsParams {
  final String vendorId;
  final DateTime? startDate;
  final DateTime? endDate;

  const PerformanceMetricsParams({
    required this.vendorId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceMetricsParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      vendorId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

// ==================== STATE NOTIFIERS ====================

/// State for template management
class TemplateManagementState {
  final List<CustomizationTemplate> templates;
  final bool isLoading;
  final String? errorMessage;
  final CustomizationTemplate? selectedTemplate;

  const TemplateManagementState({
    this.templates = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedTemplate,
  });

  TemplateManagementState copyWith({
    List<CustomizationTemplate>? templates,
    bool? isLoading,
    String? errorMessage,
    CustomizationTemplate? selectedTemplate,
  }) {
    return TemplateManagementState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}

/// State notifier for template management
class TemplateManagementNotifier extends StateNotifier<TemplateManagementState> {
  final CustomizationTemplateRepository _repository;

  TemplateManagementNotifier(this._repository) : super(const TemplateManagementState());

  /// Load templates for a vendor
  Future<void> loadTemplates(String vendorId, {bool? isActive}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final templates = await _repository.getVendorTemplates(vendorId, isActive: isActive);
      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error loading templates: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Create a new template
  Future<bool> createTemplate(CustomizationTemplate template) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final createdTemplate = await _repository.createTemplate(template);
      final updatedTemplates = [...state.templates, createdTemplate];
      state = state.copyWith(templates: updatedTemplates, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error creating template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Update an existing template
  Future<bool> updateTemplate(CustomizationTemplate template) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedTemplate = await _repository.updateTemplate(template);
      final updatedTemplates = state.templates.map((t) {
        return t.id == updatedTemplate.id ? updatedTemplate : t;
      }).toList();
      state = state.copyWith(templates: updatedTemplates, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error updating template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.deleteTemplate(templateId);
      final updatedTemplates = state.templates.where((t) => t.id != templateId).toList();
      state = state.copyWith(templates: updatedTemplates, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error deleting template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Select a template
  void selectTemplate(CustomizationTemplate? template) {
    state = state.copyWith(selectedTemplate: template);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// State for template linking
class TemplateLinkingState {
  final List<MenuItemTemplateLink> links;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, List<CustomizationTemplate>> menuItemTemplates;

  const TemplateLinkingState({
    this.links = const [],
    this.isLoading = false,
    this.errorMessage,
    this.menuItemTemplates = const {},
  });

  TemplateLinkingState copyWith({
    List<MenuItemTemplateLink>? links,
    bool? isLoading,
    String? errorMessage,
    Map<String, List<CustomizationTemplate>>? menuItemTemplates,
  }) {
    return TemplateLinkingState(
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      menuItemTemplates: menuItemTemplates ?? this.menuItemTemplates,
    );
  }
}

/// State notifier for template linking
class TemplateLinkingNotifier extends StateNotifier<TemplateLinkingState> {
  final CustomizationTemplateRepository _repository;

  TemplateLinkingNotifier(this._repository) : super(const TemplateLinkingState());

  /// Link a template to a menu item
  Future<bool> linkTemplate({
    required String menuItemId,
    required String templateId,
    int displayOrder = 0,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final link = await _repository.linkTemplateToMenuItem(
        menuItemId: menuItemId,
        templateId: templateId,
        displayOrder: displayOrder,
      );

      final updatedLinks = [...state.links, link];
      state = state.copyWith(links: updatedLinks, isLoading: false);

      // Refresh menu item templates cache
      await _refreshMenuItemTemplates(menuItemId);
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error linking template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Unlink a template from a menu item
  Future<bool> unlinkTemplate({
    required String menuItemId,
    required String templateId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.unlinkTemplateFromMenuItem(
        menuItemId: menuItemId,
        templateId: templateId,
      );

      final updatedLinks = state.links.where((link) =>
          !(link.menuItemId == menuItemId && link.templateId == templateId)
      ).toList();
      state = state.copyWith(links: updatedLinks, isLoading: false);

      // Refresh menu item templates cache
      await _refreshMenuItemTemplates(menuItemId);
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error unlinking template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Bulk link templates to multiple menu items
  Future<bool> bulkLinkTemplates({
    required List<String> menuItemIds,
    required List<String> templateIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await _repository.bulkLinkTemplates(
        menuItemIds: menuItemIds,
        templateIds: templateIds,
      );

      final successCount = results.values.where((success) => success).length;
      final totalCount = results.length;

      state = state.copyWith(isLoading: false);

      // Refresh menu item templates cache for all affected items
      for (final menuItemId in menuItemIds) {
        await _refreshMenuItemTemplates(menuItemId);
      }

      // Return true if all operations succeeded
      return successCount == totalCount;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error bulk linking templates: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Bulk unlink templates from multiple menu items
  Future<bool> bulkUnlinkTemplates({
    required List<String> menuItemIds,
    required List<String> templateIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await _repository.bulkUnlinkTemplates(
        menuItemIds: menuItemIds,
        templateIds: templateIds,
      );

      final successCount = results.values.where((success) => success).length;
      final totalCount = results.length;

      state = state.copyWith(isLoading: false);

      // Refresh menu item templates cache for all affected items
      for (final menuItemId in menuItemIds) {
        await _refreshMenuItemTemplates(menuItemId);
      }

      // Return true if all operations succeeded
      return successCount == totalCount;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error bulk unlinking templates: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Load templates for a menu item
  Future<void> loadMenuItemTemplates(String menuItemId) async {
    try {
      final templates = await _repository.getMenuItemTemplates(menuItemId);
      final updatedCache = Map<String, List<CustomizationTemplate>>.from(state.menuItemTemplates);
      updatedCache[menuItemId] = templates;
      state = state.copyWith(menuItemTemplates: updatedCache);
    } catch (e) {
      debugPrint('❌ [TEMPLATE-PROVIDER] Error loading menu item templates: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Refresh menu item templates cache
  Future<void> _refreshMenuItemTemplates(String menuItemId) async {
    await loadMenuItemTemplates(menuItemId);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
