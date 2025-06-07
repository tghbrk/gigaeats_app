/// Temporary stub for mock data service - to be implemented later
class MockData {
  static List<Map<String, dynamic>> getVendors() {
    return [
      {
        'id': '1',
        'name': 'Test Vendor 1',
        'business_name': 'Test Restaurant',
        'description': 'A test restaurant',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Test Vendor 2',
        'business_name': 'Another Test Restaurant',
        'description': 'Another test restaurant',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> getMenuItems() {
    return [
      {
        'id': '1',
        'name': 'Test Menu Item 1',
        'description': 'A test menu item',
        'price': 10.99,
        'is_available': true,
        'vendor_id': '1',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Test Menu Item 2',
        'description': 'Another test menu item',
        'price': 15.99,
        'is_available': true,
        'vendor_id': '1',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> getOrders() {
    return [
      {
        'id': '1',
        'order_number': 'ORD-001',
        'status': 'pending',
        'total_amount': 25.98,
        'vendor_id': '1',
        'customer_id': '1',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'order_number': 'ORD-002',
        'status': 'confirmed',
        'total_amount': 32.50,
        'vendor_id': '1',
        'customer_id': '2',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }
}
