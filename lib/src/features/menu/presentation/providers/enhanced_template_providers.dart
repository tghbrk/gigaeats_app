import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/customization_template_repository.dart';
import '../../data/repositories/menu_item_repository.dart';
import '../../data/models/customization_template.dart';
import '../../data/services/template_integration_service.dart';
import 'customization_template_providers.dart';
import '../utils/template_debug_logger.dart';

/// Enhanced providers for template-only workflow with improved state management

// ==================== REPOSITORY PROVIDERS ====================

/// Menu item repository provider
final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  return MenuItemRepository();
});

/// Enhanced template integration service provider
final enhancedTemplateIntegrationServiceProvider = Provider<TemplateIntegrationService>((ref) {
  final templateRepository = ref.watch(customizationTemplateRepositoryProvider);
  final menuItemRepository = ref.watch(menuItemRepositoryProvider);
  return TemplateIntegrationService(
    templateRepository,
    menuItemRepository: menuItemRepository,
  );
});

// ==================== ENHANCED TEMPLATE PROVIDERS ====================

/// Enhanced template management state notifier with better caching and real-time updates
final enhancedTemplateManagementProvider = StateNotifierProvider<EnhancedTemplateManagementNotifier, EnhancedTemplateManagementState>((ref) {
  final repository = ref.watch(customizationTemplateRepositoryProvider);
  return EnhancedTemplateManagementNotifier(repository);
});

/// Provider for template-menu item relationships with caching
final templateMenuItemRelationshipsProvider = StateNotifierProvider<TemplateMenuItemRelationshipsNotifier, TemplateMenuItemRelationshipsState>((ref) {
  final templateRepository = ref.watch(customizationTemplateRepositoryProvider);
  final menuItemRepository = ref.watch(menuItemRepositoryProvider);
  return TemplateMenuItemRelationshipsNotifier(templateRepository, menuItemRepository);
});

// TODO: Add template usage statistics and ordering providers when needed

// ==================== STATE CLASSES ====================

/// Enhanced template management state with better caching
class EnhancedTemplateManagementState {
  final Map<String, List<CustomizationTemplate>> vendorTemplatesCache;
  final Map<String, CustomizationTemplate> templateCache;
  final Map<String, List<String>> templateCategoriesCache;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const EnhancedTemplateManagementState({
    this.vendorTemplatesCache = const {},
    this.templateCache = const {},
    this.templateCategoriesCache = const {},
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  EnhancedTemplateManagementState copyWith({
    Map<String, List<CustomizationTemplate>>? vendorTemplatesCache,
    Map<String, CustomizationTemplate>? templateCache,
    Map<String, List<String>>? templateCategoriesCache,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return EnhancedTemplateManagementState(
      vendorTemplatesCache: vendorTemplatesCache ?? this.vendorTemplatesCache,
      templateCache: templateCache ?? this.templateCache,
      templateCategoriesCache: templateCategoriesCache ?? this.templateCategoriesCache,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Template-menu item relationships state
class TemplateMenuItemRelationshipsState {
  final Map<String, List<CustomizationTemplate>> menuItemTemplatesCache;
  final Map<String, List<String>> templateMenuItemsCache;
  final Map<String, int> templateUsageCountCache;
  final bool isLoading;
  final String? errorMessage;

  const TemplateMenuItemRelationshipsState({
    this.menuItemTemplatesCache = const {},
    this.templateMenuItemsCache = const {},
    this.templateUsageCountCache = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  TemplateMenuItemRelationshipsState copyWith({
    Map<String, List<CustomizationTemplate>>? menuItemTemplatesCache,
    Map<String, List<String>>? templateMenuItemsCache,
    Map<String, int>? templateUsageCountCache,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TemplateMenuItemRelationshipsState(
      menuItemTemplatesCache: menuItemTemplatesCache ?? this.menuItemTemplatesCache,
      templateMenuItemsCache: templateMenuItemsCache ?? this.templateMenuItemsCache,
      templateUsageCountCache: templateUsageCountCache ?? this.templateUsageCountCache,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Template usage statistics state
class TemplateUsageStatsState {
  final Map<String, Map<String, dynamic>> vendorStatsCache;
  final Map<String, Map<String, dynamic>> templateStatsCache;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const TemplateUsageStatsState({
    this.vendorStatsCache = const {},
    this.templateStatsCache = const {},
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  TemplateUsageStatsState copyWith({
    Map<String, Map<String, dynamic>>? vendorStatsCache,
    Map<String, Map<String, dynamic>>? templateStatsCache,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return TemplateUsageStatsState(
      vendorStatsCache: vendorStatsCache ?? this.vendorStatsCache,
      templateStatsCache: templateStatsCache ?? this.templateStatsCache,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Template ordering state
class TemplateOrderingState {
  final Map<String, List<String>> vendorTemplateOrderCache;
  final bool isLoading;
  final String? errorMessage;

  const TemplateOrderingState({
    this.vendorTemplateOrderCache = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  TemplateOrderingState copyWith({
    Map<String, List<String>>? vendorTemplateOrderCache,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TemplateOrderingState(
      vendorTemplateOrderCache: vendorTemplateOrderCache ?? this.vendorTemplateOrderCache,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ==================== STATE NOTIFIERS ====================

/// Enhanced template management notifier with improved caching
class EnhancedTemplateManagementNotifier extends StateNotifier<EnhancedTemplateManagementState> {
  final CustomizationTemplateRepository _repository;

  EnhancedTemplateManagementNotifier(this._repository) : super(const EnhancedTemplateManagementState());

  /// Load templates for a vendor with caching
  Future<void> loadVendorTemplates(String vendorId, {bool forceRefresh = false}) async {
    final session = TemplateDebugLogger.createSession('load_vendor_templates');
    session.addEvent('Loading templates for vendor: $vendorId');

    TemplateDebugLogger.logStateChange(
      providerName: 'EnhancedTemplateManagementNotifier',
      changeType: 'loading_started',
      data: {
        'vendorId': vendorId,
        'forceRefresh': forceRefresh,
        'cacheSize': state.vendorTemplatesCache.length,
      },
    );

    // Check cache first
    if (!forceRefresh && state.vendorTemplatesCache.containsKey(vendorId)) {
      final lastUpdated = state.lastUpdated;
      if (lastUpdated != null && DateTime.now().difference(lastUpdated).inMinutes < 5) {
        TemplateDebugLogger.logCacheOperation(
          operation: 'hit',
          cacheKey: 'vendor_templates_$vendorId',
          additionalInfo: 'Cache age: ${DateTime.now().difference(lastUpdated).inMinutes} minutes',
        );
        session.complete('cache_hit');
        return;
      }
    }

    TemplateDebugLogger.logCacheOperation(
      operation: 'miss',
      cacheKey: 'vendor_templates_$vendorId',
      additionalInfo: forceRefresh ? 'Force refresh requested' : 'Cache expired or missing',
    );

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final stopwatch = Stopwatch()..start();
      final templates = await _repository.getVendorTemplates(vendorId);
      stopwatch.stop();

      TemplateDebugLogger.logDatabaseOperation(
        operation: 'read',
        entityType: 'vendor_templates',
        entityId: vendorId,
        additionalInfo: 'Retrieved ${templates.length} templates',
        duration: stopwatch.elapsed,
        success: true,
      );

      session.addEvent('Database query completed: ${templates.length} templates');

      // Update caches
      final updatedVendorCache = Map<String, List<CustomizationTemplate>>.from(state.vendorTemplatesCache);
      updatedVendorCache[vendorId] = templates;

      final updatedTemplateCache = Map<String, CustomizationTemplate>.from(state.templateCache);
      for (final template in templates) {
        updatedTemplateCache[template.id] = template;
      }

      // Generate categories cache
      final updatedCategoriesCache = Map<String, List<String>>.from(state.templateCategoriesCache);
      final categories = _generateCategories(templates);
      updatedCategoriesCache[vendorId] = categories;

      session.addEvent('Cache updated with ${templates.length} templates and ${categories.length} categories');

      state = state.copyWith(
        vendorTemplatesCache: updatedVendorCache,
        templateCache: updatedTemplateCache,
        templateCategoriesCache: updatedCategoriesCache,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      TemplateDebugLogger.logCacheOperation(
        operation: 'set',
        cacheKey: 'vendor_templates_$vendorId',
        additionalInfo: 'Cached ${templates.length} templates',
      );

      TemplateDebugLogger.logStateChange(
        providerName: 'EnhancedTemplateManagementNotifier',
        changeType: 'loaded',
        data: {
          'vendorId': vendorId,
          'templatesCount': templates.length,
          'categoriesCount': categories.length,
          'loadTime': stopwatch.elapsedMilliseconds,
        },
      );

      session.complete('success: ${templates.length} templates loaded');
    } catch (e, stackTrace) {
      TemplateDebugLogger.logError(
        operation: 'load_vendor_templates',
        error: e,
        stackTrace: stackTrace,
        context: {
          'vendorId': vendorId,
          'forceRefresh': forceRefresh,
        },
      );

      TemplateDebugLogger.logStateChange(
        providerName: 'EnhancedTemplateManagementNotifier',
        changeType: 'error',
        data: {
          'vendorId': vendorId,
          'error': e.toString(),
        },
      );

      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      session.complete('error: $e');
    }
  }

  /// Get templates for a vendor from cache or load if not cached
  List<CustomizationTemplate> getVendorTemplates(String vendorId) {
    return state.vendorTemplatesCache[vendorId] ?? [];
  }

  /// Get a specific template by ID from cache
  CustomizationTemplate? getTemplate(String templateId) {
    return state.templateCache[templateId];
  }

  /// Get categories for a vendor
  List<String> getVendorCategories(String vendorId) {
    return state.templateCategoriesCache[vendorId] ?? [];
  }

  /// Create a new template
  Future<bool> createTemplate(CustomizationTemplate template) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final createdTemplate = await _repository.createTemplate(template);
      
      // Update caches
      final updatedTemplateCache = Map<String, CustomizationTemplate>.from(state.templateCache);
      updatedTemplateCache[createdTemplate.id] = createdTemplate;

      final updatedVendorCache = Map<String, List<CustomizationTemplate>>.from(state.vendorTemplatesCache);
      if (updatedVendorCache.containsKey(template.vendorId)) {
        updatedVendorCache[template.vendorId] = [...updatedVendorCache[template.vendorId]!, createdTemplate];
      }

      state = state.copyWith(
        templateCache: updatedTemplateCache,
        vendorTemplatesCache: updatedVendorCache,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('🔧 [ENHANCED-TEMPLATE-PROVIDER] Created template: ${createdTemplate.id}');
      return true;
    } catch (e) {
      debugPrint('❌ [ENHANCED-TEMPLATE-PROVIDER] Error creating template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Update an existing template
  Future<bool> updateTemplate(CustomizationTemplate template) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedTemplate = await _repository.updateTemplate(template);
      
      // Update caches
      final updatedTemplateCache = Map<String, CustomizationTemplate>.from(state.templateCache);
      updatedTemplateCache[template.id] = updatedTemplate;

      final updatedVendorCache = Map<String, List<CustomizationTemplate>>.from(state.vendorTemplatesCache);
      if (updatedVendorCache.containsKey(template.vendorId)) {
        final templates = updatedVendorCache[template.vendorId]!;
        final index = templates.indexWhere((t) => t.id == template.id);
        if (index != -1) {
          templates[index] = updatedTemplate;
          updatedVendorCache[template.vendorId] = templates;
        }
      }

      state = state.copyWith(
        templateCache: updatedTemplateCache,
        vendorTemplatesCache: updatedVendorCache,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('🔧 [ENHANCED-TEMPLATE-PROVIDER] Updated template: ${template.id}');
      return true;
    } catch (e) {
      debugPrint('❌ [ENHANCED-TEMPLATE-PROVIDER] Error updating template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.deleteTemplate(templateId);
      
      // Update caches
      final updatedTemplateCache = Map<String, CustomizationTemplate>.from(state.templateCache);
      final deletedTemplate = updatedTemplateCache.remove(templateId);

      final updatedVendorCache = Map<String, List<CustomizationTemplate>>.from(state.vendorTemplatesCache);
      if (deletedTemplate != null && updatedVendorCache.containsKey(deletedTemplate.vendorId)) {
        updatedVendorCache[deletedTemplate.vendorId] = updatedVendorCache[deletedTemplate.vendorId]!
            .where((t) => t.id != templateId)
            .toList();
      }

      state = state.copyWith(
        templateCache: updatedTemplateCache,
        vendorTemplatesCache: updatedVendorCache,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('🔧 [ENHANCED-TEMPLATE-PROVIDER] Deleted template: $templateId');
      return true;
    } catch (e) {
      debugPrint('❌ [ENHANCED-TEMPLATE-PROVIDER] Error deleting template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Clear cache for a vendor
  void clearVendorCache(String vendorId) {
    final updatedVendorCache = Map<String, List<CustomizationTemplate>>.from(state.vendorTemplatesCache);
    updatedVendorCache.remove(vendorId);

    final updatedCategoriesCache = Map<String, List<String>>.from(state.templateCategoriesCache);
    updatedCategoriesCache.remove(vendorId);

    state = state.copyWith(
      vendorTemplatesCache: updatedVendorCache,
      templateCategoriesCache: updatedCategoriesCache,
    );
  }

  /// Clear all caches
  void clearAllCaches() {
    state = const EnhancedTemplateManagementState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Generate categories from templates
  List<String> _generateCategories(List<CustomizationTemplate> templates) {
    final categories = <String>{};
    for (final template in templates) {
      final category = _getCategoryFromTemplate(template);
      categories.add(category);
    }
    return categories.toList()..sort();
  }

  /// Get category from template name
  String _getCategoryFromTemplate(CustomizationTemplate template) {
    final name = template.name.toLowerCase();
    if (name.contains('size') || name.contains('portion')) return 'Size Options';
    if (name.contains('add') || name.contains('extra')) return 'Add-ons';
    if (name.contains('spice') || name.contains('level')) return 'Spice Level';
    if (name.contains('cook') || name.contains('style')) return 'Cooking Style';
    if (name.contains('diet') || name.contains('vegan') || name.contains('halal')) return 'Dietary';
    return 'Other';
  }
}

/// Template-menu item relationships notifier
class TemplateMenuItemRelationshipsNotifier extends StateNotifier<TemplateMenuItemRelationshipsState> {
  final CustomizationTemplateRepository _templateRepository;
  final MenuItemRepository _menuItemRepository;

  TemplateMenuItemRelationshipsNotifier(this._templateRepository, this._menuItemRepository)
      : super(const TemplateMenuItemRelationshipsState());

  /// Load templates for a menu item
  Future<void> loadMenuItemTemplates(String menuItemId, {bool forceRefresh = false}) async {
    debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Loading templates for menu item: $menuItemId');

    if (!forceRefresh && state.menuItemTemplatesCache.containsKey(menuItemId)) {
      debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Using cached templates for menu item: $menuItemId');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final templates = await _templateRepository.getMenuItemTemplates(menuItemId);

      final updatedCache = Map<String, List<CustomizationTemplate>>.from(state.menuItemTemplatesCache);
      updatedCache[menuItemId] = templates;

      state = state.copyWith(
        menuItemTemplatesCache: updatedCache,
        isLoading: false,
      );

      debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Loaded ${templates.length} templates for menu item: $menuItemId');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-RELATIONSHIPS] Error loading menu item templates: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Load menu items using a template
  Future<void> loadTemplateMenuItems(String templateId, {bool forceRefresh = false}) async {
    debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Loading menu items for template: $templateId');

    if (!forceRefresh && state.templateMenuItemsCache.containsKey(templateId)) {
      debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Using cached menu items for template: $templateId');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final menuItemIds = await _templateRepository.getMenuItemsUsingTemplate(templateId);

      final updatedCache = Map<String, List<String>>.from(state.templateMenuItemsCache);
      updatedCache[templateId] = menuItemIds;

      // Update usage count cache
      final updatedUsageCache = Map<String, int>.from(state.templateUsageCountCache);
      updatedUsageCache[templateId] = menuItemIds.length;

      state = state.copyWith(
        templateMenuItemsCache: updatedCache,
        templateUsageCountCache: updatedUsageCache,
        isLoading: false,
      );

      debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Loaded ${menuItemIds.length} menu items for template: $templateId');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-RELATIONSHIPS] Error loading template menu items: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Link templates to a menu item
  Future<bool> linkTemplatesToMenuItem({
    required String menuItemId,
    required List<String> templateIds,
  }) async {
    debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Linking ${templateIds.length} templates to menu item: $menuItemId');

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // First, get existing templates to unlink them
      final existingTemplates = await _templateRepository.getMenuItemTemplates(menuItemId);
      for (final template in existingTemplates) {
        await _templateRepository.unlinkTemplateFromMenuItem(
          menuItemId: menuItemId,
          templateId: template.id,
        );
      }

      // Then link the new templates
      for (int i = 0; i < templateIds.length; i++) {
        await _templateRepository.linkTemplateToMenuItem(
          menuItemId: menuItemId,
          templateId: templateIds[i],
          displayOrder: i,
        );
      }

      // Refresh cache for this menu item
      await loadMenuItemTemplates(menuItemId, forceRefresh: true);

      // Update usage counts for affected templates
      for (final templateId in templateIds) {
        await loadTemplateMenuItems(templateId, forceRefresh: true);
      }

      state = state.copyWith(isLoading: false);
      debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Successfully linked templates to menu item: $menuItemId');
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-RELATIONSHIPS] Error linking templates: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Unlink a template from a menu item
  Future<bool> unlinkTemplateFromMenuItem({
    required String menuItemId,
    required String templateId,
  }) async {
    debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Unlinking template $templateId from menu item: $menuItemId');

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _templateRepository.unlinkTemplateFromMenuItem(
        menuItemId: menuItemId,
        templateId: templateId,
      );

      // Refresh caches
      await loadMenuItemTemplates(menuItemId, forceRefresh: true);
      await loadTemplateMenuItems(templateId, forceRefresh: true);

      state = state.copyWith(isLoading: false);
      debugPrint('🔧 [TEMPLATE-RELATIONSHIPS] Successfully unlinked template from menu item');
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-RELATIONSHIPS] Error unlinking template: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Get templates for a menu item from cache
  List<CustomizationTemplate> getMenuItemTemplates(String menuItemId) {
    return state.menuItemTemplatesCache[menuItemId] ?? [];
  }

  /// Get menu items using a template from cache
  List<String> getTemplateMenuItems(String templateId) {
    return state.templateMenuItemsCache[templateId] ?? [];
  }

  /// Get usage count for a template from cache
  int getTemplateUsageCount(String templateId) {
    return state.templateUsageCountCache[templateId] ?? 0;
  }

  /// Clear cache for a menu item
  void clearMenuItemCache(String menuItemId) {
    final updatedCache = Map<String, List<CustomizationTemplate>>.from(state.menuItemTemplatesCache);
    updatedCache.remove(menuItemId);
    state = state.copyWith(menuItemTemplatesCache: updatedCache);
  }

  /// Clear cache for a template
  void clearTemplateCache(String templateId) {
    final updatedMenuItemsCache = Map<String, List<String>>.from(state.templateMenuItemsCache);
    updatedMenuItemsCache.remove(templateId);

    final updatedUsageCache = Map<String, int>.from(state.templateUsageCountCache);
    updatedUsageCache.remove(templateId);

    state = state.copyWith(
      templateMenuItemsCache: updatedMenuItemsCache,
      templateUsageCountCache: updatedUsageCache,
    );
  }

  /// Clear all caches
  void clearAllCaches() {
    state = const TemplateMenuItemRelationshipsState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
