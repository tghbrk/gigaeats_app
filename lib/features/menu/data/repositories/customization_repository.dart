import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class CustomizationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all customizations for a menu item
  Future<List<MenuItemCustomization>> getMenuItemCustomizations(String menuItemId) async {
    try {
      final response = await _supabase
          .from('menu_item_customizations')
          .select('''
            id,
            name,
            type,
            is_required,
            display_order,
            customization_options (
              id,
              name,
              additional_price,
              is_default,
              is_available,
              display_order
            )
          ''')
          .eq('menu_item_id', menuItemId)
          .order('display_order');

      return response.map<MenuItemCustomization>((data) {
        final options = (data['customization_options'] as List?)
            ?.map((optionData) => CustomizationOption.fromJson(optionData))
            .toList() ?? [];

        return MenuItemCustomization(
          id: data['id'],
          name: data['name'],
          type: data['type'],
          isRequired: data['is_required'],
          options: options,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu item customizations: $e');
    }
  }

  // Create a new customization group
  Future<MenuItemCustomization> createCustomization({
    required String menuItemId,
    required String name,
    required String type,
    required bool isRequired,
    int displayOrder = 0,
  }) async {
    try {
      final response = await _supabase
          .from('menu_item_customizations')
          .insert({
            'menu_item_id': menuItemId,
            'name': name,
            'type': type,
            'is_required': isRequired,
            'display_order': displayOrder,
          })
          .select()
          .single();

      return MenuItemCustomization(
        id: response['id'],
        name: response['name'],
        type: response['type'],
        isRequired: response['is_required'],
        options: [],
      );
    } catch (e) {
      throw Exception('Failed to create customization: $e');
    }
  }

  // Update an existing customization group
  Future<MenuItemCustomization> updateCustomization({
    required String customizationId,
    String? name,
    String? type,
    bool? isRequired,
    int? displayOrder,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (type != null) updateData['type'] = type;
      if (isRequired != null) updateData['is_required'] = isRequired;
      if (displayOrder != null) updateData['display_order'] = displayOrder;

      final response = await _supabase
          .from('menu_item_customizations')
          .update(updateData)
          .eq('id', customizationId)
          .select()
          .single();

      // Fetch options separately
      final options = await getCustomizationOptions(customizationId);

      return MenuItemCustomization(
        id: response['id'],
        name: response['name'],
        type: response['type'],
        isRequired: response['is_required'],
        options: options,
      );
    } catch (e) {
      throw Exception('Failed to update customization: $e');
    }
  }

  // Delete a customization group (and all its options)
  Future<void> deleteCustomization(String customizationId) async {
    try {
      await _supabase
          .from('menu_item_customizations')
          .delete()
          .eq('id', customizationId);
    } catch (e) {
      throw Exception('Failed to delete customization: $e');
    }
  }

  // Get all options for a customization group
  Future<List<CustomizationOption>> getCustomizationOptions(String customizationId) async {
    try {
      final response = await _supabase
          .from('customization_options')
          .select()
          .eq('customization_id', customizationId)
          .order('display_order');

      return response.map<CustomizationOption>((data) => 
          CustomizationOption.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customization options: $e');
    }
  }

  // Create a new customization option
  Future<CustomizationOption> createCustomizationOption({
    required String customizationId,
    required String name,
    required double additionalPrice,
    bool isDefault = false,
    bool isAvailable = true,
    int displayOrder = 0,
  }) async {
    try {
      final response = await _supabase
          .from('customization_options')
          .insert({
            'customization_id': customizationId,
            'name': name,
            'additional_price': additionalPrice,
            'is_default': isDefault,
            'is_available': isAvailable,
            'display_order': displayOrder,
          })
          .select()
          .single();

      return CustomizationOption.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create customization option: $e');
    }
  }

  // Update an existing customization option
  Future<CustomizationOption> updateCustomizationOption({
    required String optionId,
    String? name,
    double? additionalPrice,
    bool? isDefault,
    bool? isAvailable,
    int? displayOrder,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (additionalPrice != null) updateData['additional_price'] = additionalPrice;
      if (isDefault != null) updateData['is_default'] = isDefault;
      if (isAvailable != null) updateData['is_available'] = isAvailable;
      if (displayOrder != null) updateData['display_order'] = displayOrder;

      final response = await _supabase
          .from('customization_options')
          .update(updateData)
          .eq('id', optionId)
          .select()
          .single();

      return CustomizationOption.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update customization option: $e');
    }
  }

  // Delete a customization option
  Future<void> deleteCustomizationOption(String optionId) async {
    try {
      await _supabase
          .from('customization_options')
          .delete()
          .eq('id', optionId);
    } catch (e) {
      throw Exception('Failed to delete customization option: $e');
    }
  }

  // Validate customizations for an order
  Future<bool> validateOrderCustomizations({
    required String menuItemId,
    required Map<String, dynamic> customizations,
  }) async {
    try {
      final response = await _supabase
          .rpc('validate_order_customizations', params: {
            'item_id': menuItemId,
            'customizations_data': customizations,
          });

      return response as bool;
    } catch (e) {
      throw Exception('Failed to validate customizations: $e');
    }
  }

  // Get menu item with all customizations (using database function)
  Future<Map<String, dynamic>> getMenuItemWithCustomizations(String menuItemId) async {
    try {
      final response = await _supabase
          .rpc('get_menu_item_with_customizations', params: {
            'item_id': menuItemId,
          });

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch menu item with customizations: $e');
    }
  }

  // Bulk create customizations for a menu item
  Future<List<MenuItemCustomization>> bulkCreateCustomizations({
    required String menuItemId,
    required List<MenuItemCustomization> customizations,
  }) async {
    try {
      final results = <MenuItemCustomization>[];

      for (int i = 0; i < customizations.length; i++) {
        final customization = customizations[i];
        
        // Create the customization group
        final createdCustomization = await createCustomization(
          menuItemId: menuItemId,
          name: customization.name,
          type: customization.type,
          isRequired: customization.isRequired,
          displayOrder: i,
        );

        // Create all options for this customization
        final createdOptions = <CustomizationOption>[];
        final customizationId = createdCustomization.id;
        if (customizationId != null) {
          for (int j = 0; j < customization.options.length; j++) {
            final option = customization.options[j];
            final createdOption = await createCustomizationOption(
              customizationId: customizationId,
              name: option.name,
              additionalPrice: option.additionalPrice,
              isDefault: option.isDefault,
              displayOrder: j,
            );
            createdOptions.add(createdOption);
          }
        }

        results.add(createdCustomization.copyWith(options: createdOptions));
      }

      return results;
    } catch (e) {
      throw Exception('Failed to bulk create customizations: $e');
    }
  }
}
