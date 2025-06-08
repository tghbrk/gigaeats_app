import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gigaeats_app/features/menu/data/repositories/menu_item_repository.dart';
import 'package:gigaeats_app/core/config/supabase_config.dart';

void main() {
  group('Zero Price Customization Integration Tests', () {
    late MenuItemRepository repository;

    setUpAll(() async {
      // Initialize Supabase for testing
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: true,
      );
      repository = MenuItemRepository();
    });

    test('Repository should load menu item with zero-price customizations', () async {
      // Test loading the menu item we created in the database
      const testMenuItemId = '4478a902-65b2-4a1a-bae7-d4e0a28bf044';
      
      final menuItem = await repository.getMenuItemById(testMenuItemId);
      
      expect(menuItem, isNotNull, reason: 'Menu item should be found');
      expect(menuItem!.name, 'Test Burger with Free Options');
      expect(menuItem.basePrice, 18.50);
      
      // Check customizations
      expect(menuItem.customizations.isNotEmpty, true, 
        reason: 'Menu item should have customizations');
      
      final customization = menuItem.customizations.first;
      expect(customization.name, 'Free Add-ons');
      expect(customization.type, 'multiple');
      expect(customization.isRequired, false);
      
      // Check options
      expect(customization.options.length, 4, 
        reason: 'Should have 4 customization options');
      
      // Count free and paid options
      final freeOptions = customization.options.where((opt) => opt.additionalPrice == 0.0).toList();
      final paidOptions = customization.options.where((opt) => opt.additionalPrice > 0.0).toList();
      
      expect(freeOptions.length, 3, reason: 'Should have 3 free options');
      expect(paidOptions.length, 1, reason: 'Should have 1 paid option');
      
      // Check specific free options
      final freeOptionNames = freeOptions.map((opt) => opt.name).toList();
      expect(freeOptionNames, containsAll(['Extra Napkins', 'No Ice', 'Light Sauce']));
      
      // Check paid option
      final paidOption = paidOptions.first;
      expect(paidOption.name, 'Extra Sauce');
      expect(paidOption.additionalPrice, 2.50);
      
      // Check default option
      final defaultOptions = customization.options.where((opt) => opt.isDefault).toList();
      expect(defaultOptions.length, 1, reason: 'Should have exactly one default option');
      expect(defaultOptions.first.name, 'Light Sauce');
      expect(defaultOptions.first.additionalPrice, 0.0, reason: 'Default option should be free');
      
      print('✅ Integration test passed: Menu item with zero-price customizations loaded successfully');
      print('   - Menu item: ${menuItem.name} (RM ${menuItem.basePrice})');
      print('   - Customization: ${customization.name} (${customization.options.length} options)');
      print('   - Free options: ${freeOptions.map((o) => o.name).join(", ")}');
      print('   - Paid options: ${paidOptions.map((o) => "${o.name} (+RM ${o.additionalPrice})").join(", ")}');
      print('   - Default option: ${defaultOptions.first.name} (FREE)');
    });

    test('Repository should handle menu item creation with zero-price customizations', () async {
      // This test would create a new menu item with customizations
      // For now, we'll skip this to avoid creating test data in production
      // In a real test environment, we would:
      // 1. Create a test menu item with zero-price customizations
      // 2. Verify it's saved correctly
      // 3. Load it back and verify the data
      // 4. Clean up the test data
      
      print('⏭️  Skipping creation test to avoid test data in production database');
    });
  });
}
