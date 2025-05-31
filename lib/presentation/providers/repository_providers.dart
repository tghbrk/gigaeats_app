import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

import '../../data/repositories/user_repository.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/menu_item_repository.dart';
import '../../core/services/file_upload_service.dart';
import '../../data/models/order.dart';
import '../../data/models/order_summary.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../data/models/vendor.dart';
import '../providers/order_provider.dart';
import '../providers/vendor_provider.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return UserRepository(
    client: supabase,
  );
});

// Vendor repository provider
final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return VendorRepository(
    client: supabase,
  );
});

// Order repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return OrderRepository(
    client: supabase,
  );
});

// Customer repository provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CustomerRepository(
    client: supabase,
  );
});

// Menu item repository provider
final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MenuItemRepository(
    client: supabase,
  );
});

// Current user provider
final currentUserProvider = FutureProvider((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getCurrentUserProfile();
});

// Vendors stream provider
final vendorsStreamProvider = StreamProvider.family<List<dynamic>, Map<String, dynamic>>((ref, filters) {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  return vendorRepository.getVendorsStream(
    searchQuery: filters['searchQuery'] as String?,
    cuisineTypes: filters['cuisineTypes'] as List<String>?,
    location: filters['location'] as String?,
  );
});

// Featured vendors provider (web-aware)
final featuredVendorsProvider = FutureProvider((ref) async {
  debugPrint('FeaturedVendorsProvider: Starting, kIsWeb: $kIsWeb');

  if (kIsWeb) {
    try {
      debugPrint('FeaturedVendorsProvider: Using web-specific provider');
      // Use web-specific provider and convert to Vendor objects
      final webVendors = await ref.read(webVendorsProvider.future);
      debugPrint('FeaturedVendorsProvider: Got ${webVendors.length} web vendors');

      final vendors = webVendors.take(5).map((data) {
        debugPrint('FeaturedVendorsProvider: Converting vendor data: $data');
        return Vendor.fromJson(data);
      }).toList();

      debugPrint('FeaturedVendorsProvider: Converted to ${vendors.length} Vendor objects');
      return vendors;
    } catch (e) {
      debugPrint('FeaturedVendorsProvider: Error in web flow: $e');
      rethrow;
    }
  } else {
    // Use mobile provider
    debugPrint('FeaturedVendorsProvider: Using mobile provider');
    final vendorRepository = ref.watch(vendorRepositoryProvider);
    return await vendorRepository.getFeaturedVendors(limit: 5);
  }
});

// Available cuisine types provider
final availableCuisineTypesProvider = FutureProvider<List<String>>((ref) async {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  return await vendorRepository.getAvailableCuisineTypes();
});

// Vendor by ID provider
final vendorByIdProvider = FutureProvider.family<dynamic, String>((ref, vendorId) async {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  return await vendorRepository.getVendorById(vendorId);
});

// Vendor products provider
final vendorProductsProvider = FutureProvider.family<List<Product>, Map<String, dynamic>>((ref, params) async {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  final vendorId = params['vendorId'] as String;
  return await vendorRepository.getVendorProducts(
    vendorId,
    category: params['category'] as String?,
    isVegetarian: params['isVegetarian'] as bool?,
    isHalal: params['isHalal'] as bool?,
    maxPrice: params['maxPrice'] as double?,
    isAvailable: params['isAvailable'] as bool?,
    limit: params['limit'] as int? ?? 50,
    offset: params['offset'] as int? ?? 0,
  );
});

// Orders stream provider
final ordersStreamProvider = StreamProvider.family<List<Order>, OrderStatus?>((ref, status) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository.getOrdersStream(status: status);
});

// Recent orders provider (web-aware)
final recentOrdersProvider = FutureProvider<List<Order>>((ref) async {
  // Use the repository method for both web and mobile - it handles authentication properly
  debugPrint('RecentOrdersProvider: Using repository method for both web and mobile');
  final orderRepository = ref.watch(orderRepositoryProvider);
  return await orderRepository.getRecentOrders(limit: 5);
});

// Simple order summaries provider for testing (web-aware)
final orderSummariesProvider = FutureProvider<List<OrderSummary>>((ref) async {
  if (!kIsWeb) return [];

  try {
    // Use authenticated client for web platform
    final orderRepository = ref.watch(orderRepositoryProvider);
    final authenticatedClient = await orderRepository.getAuthenticatedClient();

    debugPrint('OrderSummariesProvider: Fetching order summaries');

    // Use a simple query without complex joins
    final response = await authenticatedClient
        .from('orders')
        .select('''
          id,
          order_number,
          status,
          total_amount,
          created_at,
          vendors(business_name),
          customers(organization_name, contact_person_name)
        ''')
        .order('created_at', ascending: false)
        .limit(10);

    debugPrint('OrderSummariesProvider: Got ${response.length} orders');

    // Convert to OrderSummary objects
    final summaries = response.map((data) {
      // Extract vendor name
      String? vendorName;
      if (data['vendors'] != null) {
        vendorName = data['vendors']['business_name'];
      }

      // Extract customer name
      String? customerName;
      if (data['customers'] != null) {
        final customer = data['customers'];
        customerName = customer['organization_name'] ?? customer['contact_person_name'];
      }

      return OrderSummary(
        id: data['id'],
        orderNumber: data['order_number'],
        status: data['status'],
        totalAmount: (data['total_amount'] as num).toDouble(),
        vendorName: vendorName,
        customerName: customerName,
        createdAt: DateTime.parse(data['created_at']),
      );
    }).toList();

    debugPrint('OrderSummariesProvider: Converted ${summaries.length} order summaries');
    return summaries;
  } catch (e) {
    debugPrint('OrderSummariesProvider: Error: $e');
    return [];
  }
});

// Order statistics provider
final orderStatisticsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return await orderRepository.getOrderStatistics(
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
  );
});

// Customers stream provider
final customersStreamProvider = StreamProvider.family<List<Customer>, String?>((ref, searchQuery) {
  final customerRepository = ref.watch(customerRepositoryProvider);
  return customerRepository.getCustomersStream(searchQuery: searchQuery);
});

// Customer statistics provider (web-aware)
final customerStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (kIsWeb) {
    // For web, return mock data until we implement web-specific customer stats
    return {
      'total_customers': 0,
      'active_customers': 0,
      'total_revenue': 0.0,
    };
  } else {
    final customerRepository = ref.watch(customerRepositoryProvider);
    return await customerRepository.getCustomerStatistics();
  }
});

// Top customers provider
final topCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final customerRepository = ref.watch(customerRepositoryProvider);
  return await customerRepository.getTopCustomers(limit: 10);
});

// Menu items stream provider
final menuItemsStreamProvider = StreamProvider.family<List<Product>, String>((ref, vendorId) {
  final menuItemRepository = ref.watch(menuItemRepositoryProvider);
  return menuItemRepository.getMenuItemsStream(vendorId);
});

// Menu categories provider
final menuCategoriesProvider = FutureProvider.family<List<String>, String>((ref, vendorId) async {
  final menuItemRepository = ref.watch(menuItemRepositoryProvider);
  return await menuItemRepository.getMenuCategories(vendorId);
});

// Featured menu items provider
final featuredMenuItemsProvider = FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  final menuItemRepository = ref.watch(menuItemRepositoryProvider);
  return await menuItemRepository.getFeaturedMenuItems(vendorId, limit: 5);
});

// Real-time Order Details Provider
final orderDetailsStreamProvider = StreamProvider.family<Order?, String>((ref, orderId) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository.getOrderStream(orderId);
});

// Enhanced Orders Stream Provider with more filters
final enhancedOrdersStreamProvider = StreamProvider.family<List<Order>, Map<String, dynamic>>((ref, params) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return orderRepository.getOrdersStream(
    status: params['status'] as OrderStatus?,
    vendorId: params['vendorId'] as String?,
    customerId: params['customerId'] as String?,
  );
});

// File Upload Service Provider
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService();
});

// Web-specific data providers using authenticated Supabase client
final webOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (!kIsWeb) return [];

  try {
    // Use authenticated client for web platform
    final orderRepository = ref.watch(orderRepositoryProvider);
    final authenticatedClient = await orderRepository.getAuthenticatedClient();

    debugPrint('WebOrdersProvider: Fetching orders with authenticated client');
    debugPrint('WebOrdersProvider: Current user: ${authenticatedClient.auth.currentUser?.email}');
    debugPrint('WebOrdersProvider: Current user ID: ${authenticatedClient.auth.currentUser?.id}');

    // Use the same query structure as the repository method to get complete data
    final response = await authenticatedClient
        .from('orders')
        .select('''
          *,
          vendor:vendors!orders_vendor_id_fkey(business_name),
          customer:customers!orders_customer_id_fkey(organization_name),
          order_items:order_items(*)
        ''')
        .order('created_at', ascending: false)
        .limit(10);

    debugPrint('WebOrdersProvider: Query executed, response type: ${response.runtimeType}');
    debugPrint('WebOrdersProvider: Response length: ${response.length}');

    if (response.isNotEmpty) {
      debugPrint('WebOrdersProvider: First order: ${response.first}');
    }

    // Transform the data to match Order model expectations
    final orders = response.map((data) {
      final orderData = Map<String, dynamic>.from(data);

      // Extract vendor name from joined data
      if (orderData['vendor'] != null) {
        orderData['vendor_name'] = orderData['vendor']['business_name'] ?? 'Unknown Vendor';
      } else {
        orderData['vendor_name'] = 'Unknown Vendor';
      }

      // Extract customer name from joined data
      if (orderData['customer'] != null) {
        orderData['customer_name'] = orderData['customer']['organization_name'] ?? 'Unknown Customer';
      } else {
        orderData['customer_name'] = 'Unknown Customer';
      }

      // Ensure order_items is not null
      if (orderData['order_items'] == null) {
        orderData['order_items'] = [];
      }

      // Remove the nested objects to avoid conflicts
      orderData.remove('vendor');
      orderData.remove('customer');

      return orderData;
    }).toList();

    debugPrint('WebOrdersProvider: Returning ${orders.length} transformed orders');
    return orders;
  } catch (e, stackTrace) {
    debugPrint('WebOrdersProvider: Error fetching orders: $e');
    debugPrint('WebOrdersProvider: Stack trace: $stackTrace');
    // Return empty list instead of throwing to prevent UI crashes
    return [];
  }
});

final webVendorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (!kIsWeb) return [];

  try {
    // Use authenticated client for web platform
    final vendorRepository = ref.watch(vendorRepositoryProvider);
    final authenticatedClient = await vendorRepository.getAuthenticatedClient();

    debugPrint('WebVendorsProvider: Fetching vendors with authenticated client');
    debugPrint('WebVendorsProvider: Current user: ${authenticatedClient.auth.currentUser?.email}');

    // Select all required fields for the Vendor model
    final response = await authenticatedClient
        .from('vendors')
        .select('*')
        .eq('is_active', true)
        .eq('is_verified', true)
        .order('business_name', ascending: true)
        .limit(50);

    debugPrint('WebVendorsProvider: Successfully fetched ${response.length} vendors');

    // Map the data to match the Vendor model expectations
    final mappedVendors = response.map((vendor) {
      final mapped = Map<String, dynamic>.from(vendor);
      // The data already has user_id which matches the updated Vendor model
      debugPrint('WebVendorsProvider: Mapped vendor: ${mapped['business_name']}');
      return mapped;
    }).toList();

    debugPrint('WebVendorsProvider: Mapped ${mappedVendors.length} vendors');
    return mappedVendors;
  } catch (e) {
    debugPrint('WebVendorsProvider: Error fetching vendors: $e');
    // Return empty list instead of throwing to prevent UI crashes
    return [];
  }
});

// Platform-aware orders provider that automatically selects web or mobile implementation
final platformOrdersProvider = FutureProvider<List<Order>>((ref) async {
  if (kIsWeb) {
    // Use web-specific provider and convert to Order objects
    final webOrders = await ref.read(webOrdersProvider.future);
    return webOrders.map((data) => Order.fromJson(data)).toList();
  } else {
    // Use mobile provider - get orders from the notifier
    final ordersState = ref.watch(ordersProvider);
    return ordersState.orders;
  }
});

// Platform-aware vendors provider that automatically selects web or mobile implementation
final platformVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  if (kIsWeb) {
    // Use web-specific provider and convert to Vendor objects
    final webVendors = await ref.read(webVendorsProvider.future);
    return webVendors.map((data) => Vendor.fromJson(data)).toList();
  } else {
    // Use mobile provider - get vendors from the notifier
    final vendorsState = ref.watch(vendorsProvider);
    return vendorsState.vendors;
  }
});

final webConnectionTestProvider = FutureProvider<bool>((ref) async {
  if (!kIsWeb) return true;

  try {
    // Test authenticated connection for web platform
    final userRepository = ref.watch(userRepositoryProvider);
    final authenticatedClient = await userRepository.getAuthenticatedClient();

    debugPrint('WebConnectionTest: Testing authenticated connection');
    await authenticatedClient.from('users').select('id').limit(1);

    debugPrint('WebConnectionTest: Connection successful');
    return true;
  } catch (e) {
    debugPrint('WebConnectionTest: Connection failed: $e');
    return false;
  }
});

// Web-specific menu items provider
final webMenuItemsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  debugPrint('[WebMenuItemsProvider] Starting, kIsWeb: $kIsWeb');
  developer.log('Starting webMenuItemsProvider', name: 'WebMenuItemsProvider', time: DateTime.now());
  if (!kIsWeb) {
    debugPrint('[WebMenuItemsProvider] Not web platform, returning empty list');
    return [];
  }

  try {
    print('WebMenuItemsProvider: Getting menu item repository...');
    // Use authenticated client (authentication is bypassed in BaseRepository for testing)
    final menuItemRepository = ref.watch(menuItemRepositoryProvider);
    print('WebMenuItemsProvider: Got repository, getting authenticated client...');

    final authenticatedClient = await menuItemRepository.getAuthenticatedClient();
    print('WebMenuItemsProvider: Got authenticated client');

    final vendorId = params['vendorId'] as String;
    print('WebMenuItemsProvider: Fetching menu items for vendor $vendorId');
    print('WebMenuItemsProvider: Current user: ${authenticatedClient.auth.currentUser?.email}');
    print('WebMenuItemsProvider: Auth status: ${authenticatedClient.auth.currentUser != null ? "authenticated" : "not authenticated"}');

    print('WebMenuItemsProvider: Building query...');
    var query = authenticatedClient
        .from('menu_items')
        .select('*')
        .eq('vendor_id', vendorId);

    // Apply filters
    if (params['category'] != null) {
      print('WebMenuItemsProvider: Adding category filter: ${params['category']}');
      query = query.eq('category', params['category']);
    }
    if (params['isVegetarian'] == true) {
      print('WebMenuItemsProvider: Adding vegetarian filter');
      query = query.eq('is_vegetarian', true);
    }
    if (params['isHalal'] == true) {
      print('WebMenuItemsProvider: Adding halal filter');
      query = query.eq('is_halal', true);
    }
    if (params['maxPrice'] != null) {
      print('WebMenuItemsProvider: Adding max price filter: ${params['maxPrice']}');
      query = query.lte('base_price', params['maxPrice']);
    }
    if (params['isAvailable'] != null) {
      print('WebMenuItemsProvider: Adding availability filter: ${params['isAvailable']}');
      query = query.eq('is_available', params['isAvailable']);
    }

    print('WebMenuItemsProvider: Executing query...');
    final response = await query
        .order('is_featured', ascending: false)
        .order('rating', ascending: false)
        .limit(params['limit'] as int? ?? 50);

    print('WebMenuItemsProvider: Query completed successfully');
    print('WebMenuItemsProvider: Found ${response.length} menu items');
    if (response.isNotEmpty) {
      print('WebMenuItemsProvider: First item: ${response.first}');
    }

    return response.cast<Map<String, dynamic>>();
  } catch (e, stackTrace) {
    print('WebMenuItemsProvider: Error fetching menu items: $e');
    print('WebMenuItemsProvider: Stack trace: $stackTrace');
    rethrow; // Changed from return [] to rethrow to see the actual error
  }
});

// Platform-aware menu items provider that automatically selects web or mobile implementation
final platformMenuItemsProvider = FutureProvider.family<List<Product>, Map<String, dynamic>>((ref, params) async {
  final vendorId = params['vendorId'] as String;
  debugPrint('[PlatformMenuItemsProvider] *** PROVIDER CALLED *** for vendor $vendorId, platform: ${kIsWeb ? "web" : "mobile"}');
  developer.log('*** PROVIDER CALLED ***', name: 'PlatformMenuItemsProvider', time: DateTime.now(), sequenceNumber: DateTime.now().millisecondsSinceEpoch);

  if (kIsWeb) {
    try {
      print('PlatformMenuItemsProvider: Calling webMenuItemsProvider...');
      // Use web-specific provider and convert to Product objects
      final webMenuItems = await ref.read(webMenuItemsProvider(params).future);
      print('PlatformMenuItemsProvider: Got ${webMenuItems.length} web menu items, converting to Product objects');

      final products = webMenuItems.map((data) {
        try {
          final product = Product.fromJson(data);
          print('PlatformMenuItemsProvider: Successfully converted item: ${product.name}');
          return product;
        } catch (e) {
          print('PlatformMenuItemsProvider: Error converting menu item: $e');
          print('PlatformMenuItemsProvider: Data: $data');
          rethrow;
        }
      }).toList();

      print('PlatformMenuItemsProvider: Successfully converted ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      print('PlatformMenuItemsProvider: Error in web flow: $e');
      print('PlatformMenuItemsProvider: Stack trace: $stackTrace');
      rethrow;
    }
  } else {
    // Use mobile provider - check if we should use stream or future
    if (params['useStream'] == true) {
      print('PlatformMenuItemsProvider: Using stream provider for mobile');
      // For real-time updates, use stream provider (but convert to future for this provider)
      final streamProvider = ref.watch(menuItemsStreamProvider(vendorId));
      return streamProvider.when(
        data: (products) {
          print('PlatformMenuItemsProvider: Stream provider returned ${products.length} products');
          return products;
        },
        loading: () {
          print('PlatformMenuItemsProvider: Stream provider loading');
          return <Product>[];
        },
        error: (error, stack) {
          print('PlatformMenuItemsProvider: Stream provider error: $error');
          throw error;
        },
      );
    } else {
      print('PlatformMenuItemsProvider: Using future provider for mobile');
      // Use the existing vendorProductsProvider for mobile
      return await ref.read(vendorProductsProvider(params).future);
    }
  }
});

// Stable menu items provider with individual parameters to avoid Map recreation issues
@immutable
class MenuItemsParams {
  final String vendorId;
  final String? category;
  final bool isAvailable;
  final bool useStream;

  const MenuItemsParams({
    required this.vendorId,
    this.category,
    required this.isAvailable,
    required this.useStream,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemsParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          category == other.category &&
          isAvailable == other.isAvailable &&
          useStream == other.useStream;

  @override
  int get hashCode =>
      vendorId.hashCode ^
      category.hashCode ^
      isAvailable.hashCode ^
      useStream.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'category': category,
      'isAvailable': isAvailable,
      'useStream': useStream,
    };
  }
}

// Stable platform-aware menu items provider using immutable parameters
final stableMenuItemsProvider = FutureProvider.family<List<Product>, MenuItemsParams>((ref, params) async {
  debugPrint('[StableMenuItemsProvider] *** PROVIDER CALLED *** for vendor ${params.vendorId}, platform: ${kIsWeb ? "web" : "mobile"}');

  // Convert to Map for compatibility with existing providers
  final paramsMap = params.toMap();

  // Directly call the underlying provider logic instead of wrapping
  if (kIsWeb) {
    try {
      debugPrint('[StableMenuItemsProvider] Using web provider directly');
      final webMenuItems = await ref.watch(webMenuItemsProvider(paramsMap).future);
      debugPrint('[StableMenuItemsProvider] Got ${webMenuItems.length} web menu items, converting to Product objects');

      final products = webMenuItems.map((data) {
        try {
          final product = Product.fromJson(data);
          debugPrint('[StableMenuItemsProvider] Successfully converted item: ${product.name}');
          return product;
        } catch (e) {
          debugPrint('[StableMenuItemsProvider] Error converting menu item: $e');
          rethrow;
        }
      }).toList();

      debugPrint('[StableMenuItemsProvider] Successfully converted ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('[StableMenuItemsProvider] Error in web flow: $e');
      rethrow;
    }
  } else {
    // Use mobile provider - check if we should use stream or future
    if (params.useStream) {
      debugPrint('[StableMenuItemsProvider] Using stream provider for mobile');
      final streamProvider = ref.watch(menuItemsStreamProvider(params.vendorId));
      return streamProvider.when(
        data: (products) {
          debugPrint('[StableMenuItemsProvider] Stream provider returned ${products.length} products');
          return products;
        },
        loading: () {
          debugPrint('[StableMenuItemsProvider] Stream provider loading');
          return <Product>[];
        },
        error: (error, stack) {
          debugPrint('[StableMenuItemsProvider] Stream provider error: $error');
          throw error;
        },
      );
    } else {
      debugPrint('[StableMenuItemsProvider] Using future provider for mobile');
      return await ref.watch(vendorProductsProvider(paramsMap).future);
    }
  }
});
