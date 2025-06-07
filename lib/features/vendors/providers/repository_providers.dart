import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/vendor_repository.dart';
import '../../menu/data/repositories/menu_item_repository.dart';

/// Provider for vendor repository
final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository();
});

/// Provider for menu item repository
final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  return MenuItemRepository();
});

/// Provider for current vendor (stub)
final currentVendorProvider = FutureProvider((ref) async {
  // This is a stub - implement actual vendor fetching logic
  return null;
});
