import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/user_repository.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/menu_item_repository.dart';
import '../../core/services/file_upload_service.dart';
import '../../data/models/order.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../core/services/auth_sync_service.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Firebase Auth provider
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

// Auth sync service provider
final authSyncServiceProvider = Provider<AuthSyncService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthSyncService(
    supabase: supabase,
    firebaseAuth: firebaseAuth,
  );
});

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return UserRepository(
    client: supabase,
    firebaseAuth: firebaseAuth,
  );
});

// Vendor repository provider
final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return VendorRepository(
    client: supabase,
    firebaseAuth: firebaseAuth,
  );
});

// Order repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return OrderRepository(
    client: supabase,
    firebaseAuth: firebaseAuth,
  );
});

// Customer repository provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return CustomerRepository(
    client: supabase,
    firebaseAuth: firebaseAuth,
  );
});

// Menu item repository provider
final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return MenuItemRepository(
    client: supabase,
    firebaseAuth: firebaseAuth,
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

// Featured vendors provider
final featuredVendorsProvider = FutureProvider((ref) async {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  return await vendorRepository.getFeaturedVendors(limit: 5);
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
final vendorProductsProvider = FutureProvider.family<List<dynamic>, Map<String, dynamic>>((ref, params) async {
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

// Recent orders provider
final recentOrdersProvider = FutureProvider((ref) async {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return await orderRepository.getRecentOrders(limit: 5);
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

// Customer statistics provider
final customerStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final customerRepository = ref.watch(customerRepositoryProvider);
  return await customerRepository.getCustomerStatistics();
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
