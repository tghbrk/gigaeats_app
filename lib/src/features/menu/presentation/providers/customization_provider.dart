import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/repositories/customization_repository.dart';
import '../../data/services/menu_service.dart';

// Repository provider
final customizationRepositoryProvider = Provider<CustomizationRepository>((ref) {
  return CustomizationRepository();
});

// Menu service provider
final menuServiceProvider = Provider<MenuService>((ref) {
  return MenuService();
});

// State classes for customization management
class CustomizationState {
  final List<MenuItemCustomization> customizations;
  final bool isLoading;
  final String? error;

  const CustomizationState({
    this.customizations = const [],
    this.isLoading = false,
    this.error,
  });

  CustomizationState copyWith({
    List<MenuItemCustomization>? customizations,
    bool? isLoading,
    String? error,
  }) {
    return CustomizationState(
      customizations: customizations ?? this.customizations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Customization notifier for managing menu item customizations
class CustomizationNotifier extends StateNotifier<CustomizationState> {
  final CustomizationRepository _repository;

  CustomizationNotifier(this._repository) : super(const CustomizationState());

  // Load customizations for a menu item
  Future<void> loadCustomizations(String menuItemId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final customizations = await _repository.getMenuItemCustomizations(menuItemId);
      state = state.copyWith(
        customizations: customizations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create a new customization group
  Future<MenuItemCustomization?> createCustomization({
    required String menuItemId,
    required String name,
    required String type,
    required bool isRequired,
    int displayOrder = 0,
  }) async {
    try {
      final customization = await _repository.createCustomization(
        menuItemId: menuItemId,
        name: name,
        type: type,
        isRequired: isRequired,
        displayOrder: displayOrder,
      );

      // Reload customizations to get updated list
      await loadCustomizations(menuItemId);
      
      return customization;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Update an existing customization group
  Future<MenuItemCustomization?> updateCustomization({
    required String customizationId,
    required String menuItemId,
    String? name,
    String? type,
    bool? isRequired,
    int? displayOrder,
  }) async {
    try {
      final customization = await _repository.updateCustomization(
        customizationId: customizationId,
        name: name,
        type: type,
        isRequired: isRequired,
        displayOrder: displayOrder,
      );

      // Reload customizations to get updated list
      await loadCustomizations(menuItemId);
      
      return customization;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Delete a customization group
  Future<bool> deleteCustomization(String customizationId, String menuItemId) async {
    try {
      await _repository.deleteCustomization(customizationId);
      
      // Reload customizations to get updated list
      await loadCustomizations(menuItemId);
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Create a new customization option
  Future<CustomizationOption?> createCustomizationOption({
    required String customizationId,
    required String menuItemId,
    required String name,
    required double additionalPrice,
    bool isDefault = false,
    bool isAvailable = true,
    int displayOrder = 0,
  }) async {
    try {
      final option = await _repository.createCustomizationOption(
        customizationId: customizationId,
        name: name,
        additionalPrice: additionalPrice,
        isDefault: isDefault,
        isAvailable: isAvailable,
        displayOrder: displayOrder,
      );

      // Reload customizations to get updated list
      await loadCustomizations(menuItemId);
      
      return option;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Update an existing customization option
  Future<CustomizationOption?> updateCustomizationOption({
    required String optionId,
    required String menuItemId,
    String? name,
    double? additionalPrice,
    bool? isDefault,
    bool? isAvailable,
    int? displayOrder,
  }) async {
    try {
      final option = await _repository.updateCustomizationOption(
        optionId: optionId,
        name: name,
        additionalPrice: additionalPrice,
        isDefault: isDefault,
        isAvailable: isAvailable,
        displayOrder: displayOrder,
      );

      // Reload customizations to get updated list
      await loadCustomizations(menuItemId);
      
      return option;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Delete a customization option
  Future<bool> deleteCustomizationOption(String optionId, String menuItemId) async {
    try {
      await _repository.deleteCustomizationOption(optionId);
      
      // Reload customizations to get updated list
      await loadCustomizations(menuItemId);
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Validate customizations for an order
  Future<bool> validateOrderCustomizations({
    required String menuItemId,
    required Map<String, dynamic> customizations,
  }) async {
    try {
      return await _repository.validateOrderCustomizations(
        menuItemId: menuItemId,
        customizations: customizations,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Bulk create customizations for a menu item
  Future<bool> bulkCreateCustomizations({
    required String menuItemId,
    required List<MenuItemCustomization> customizations,
  }) async {
    try {
      await _repository.bulkCreateCustomizations(
        menuItemId: menuItemId,
        customizations: customizations,
      );

      // Reload customizations to get updated list
      await loadCustomizations(menuItemId);
      
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for customization management
final customizationProvider = StateNotifierProvider.family<CustomizationNotifier, CustomizationState, String>(
  (ref, menuItemId) {
    final repository = ref.watch(customizationRepositoryProvider);
    final notifier = CustomizationNotifier(repository);
    
    // Auto-load customizations when provider is created
    Future.microtask(() => notifier.loadCustomizations(menuItemId));
    
    return notifier;
  },
);

// Provider for getting menu item with customizations
final menuItemWithCustomizationsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, menuItemId) async {
    final repository = ref.watch(customizationRepositoryProvider);
    return await repository.getMenuItemWithCustomizations(menuItemId);
  },
);

// Provider for validating order customizations
final orderCustomizationValidationProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, params) async {
    final repository = ref.watch(customizationRepositoryProvider);
    return await repository.validateOrderCustomizations(
      menuItemId: params['menuItemId'] as String,
      customizations: params['customizations'] as Map<String, dynamic>,
    );
  },
);
