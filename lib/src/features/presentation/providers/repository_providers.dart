import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import data models
import '../../user_management/orders/data/models/order.dart';
import '../../customers/data/models/customer.dart';
import '../../vendors/data/models/vendor.dart';
import '../../drivers/data/models/driver_order.dart';

// Import repositories (these will be created in Phase 5)
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/vendor_repository.dart';
import '../../drivers/data/repositories/driver_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/notification_repository.dart';

// Import services
import '../../../core/services/supabase_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';

/// Supabase client provider - Core dependency for all repositories
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Supabase service provider - Wrapper around Supabase client
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Repository Providers

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return UserRepository(client: supabaseClient);
});

/// Order repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

/// Customer repository provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

/// Vendor repository provider
final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository();
});

/// Driver repository provider
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

/// Menu repository provider
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository();
});

/// Payment repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

/// Notification repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// Data Providers - These provide access to data through repositories

/// Current user orders provider
final userOrdersProvider = FutureProvider.family<List<Order>, String>((ref, userId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrdersByUserId(userId);
});

/// Vendor orders provider
final vendorOrdersProvider = FutureProvider.family<List<Order>, String>((ref, vendorId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrdersByVendorId(vendorId);
});

/// Driver orders provider
final driverOrdersProvider = FutureProvider.family<List<DriverOrder>, String>((ref, driverId) async {
  final repository = ref.watch(driverRepositoryProvider);
  return repository.getDriverOrders(driverId);
});

/// Available vendors provider
final availableVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getActiveVendors();
});

/// Customer profile provider
final customerProfileProvider = FutureProvider.family<Customer?, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomerById(customerId);
});

/// Vendor profile provider
final vendorProfileProvider = FutureProvider.family<Vendor?, String>((ref, vendorId) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getVendorById(vendorId);
});

// Stream Providers for real-time data

/// Real-time order updates provider
final orderUpdatesProvider = StreamProvider.family<Order?, String>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.watchOrder(orderId);
});

/// Real-time driver location updates provider
final driverLocationProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, driverId) {
  final repository = ref.watch(driverRepositoryProvider);
  return repository.watchDriverLocation(driverId);
});

/// Real-time vendor status updates provider
final vendorStatusProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, vendorId) {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.watchVendorStatus(vendorId);
});

// Computed Providers - These derive data from other providers

/// User role provider - determines user's role from auth state
final userRoleProvider = Provider<String?>((ref) {
  // This will be implemented when auth provider is available
  return null;
});

/// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  // This will be implemented when auth provider is available
  return null;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  // This will be implemented when auth provider is available
  return false;
});

// Cache Providers - For caching frequently accessed data

/// Cached vendors provider
final cachedVendorsProvider = StateProvider<List<Vendor>>((ref) => []);

/// Cached user orders provider
final cachedUserOrdersProvider = StateProvider<List<Order>>((ref) => []);

/// Cached customer data provider
final cachedCustomerDataProvider = StateProvider<Customer?>((ref) => null);

// Error Handling Providers

/// Repository error provider
final repositoryErrorProvider = StateProvider<String?>((ref) => null);

/// Network status provider
final networkStatusProvider = StateProvider<bool>((ref) => true);

// Utility Providers

/// Loading state provider for global loading indicators
final globalLoadingProvider = StateProvider<bool>((ref) => false);

/// Refresh trigger provider for manual data refresh
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Search query provider for filtering data
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected filters provider for data filtering
final selectedFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Pagination Providers

/// Current page provider for paginated data
final currentPageProvider = StateProvider<int>((ref) => 1);

/// Items per page provider
final itemsPerPageProvider = StateProvider<int>((ref) => 20);

/// Has more data provider for pagination
final hasMoreDataProvider = StateProvider<bool>((ref) => true);

// Feature-specific Providers

/// Cart item count provider
final cartItemCountProvider = StateProvider<int>((ref) => 0);

/// Notification count provider
final notificationCountProvider = StateProvider<int>((ref) => 0);

/// Active delivery count provider (for drivers)
final activeDeliveryCountProvider = StateProvider<int>((ref) => 0);

/// Pending orders count provider (for vendors)
final pendingOrdersCountProvider = StateProvider<int>((ref) => 0);

// Settings Providers

/// App settings provider
final appSettingsProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// User preferences provider
final userPreferencesProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// Theme mode provider
final themeModeProvider = StateProvider<String>((ref) => 'system');

/// Language provider
final languageProvider = StateProvider<String>((ref) => 'en');

// Development/Debug Providers

/// Debug mode provider
final debugModeProvider = StateProvider<bool>((ref) => false);

/// API logging enabled provider
final apiLoggingEnabledProvider = StateProvider<bool>((ref) => false);

/// Performance monitoring provider
final performanceMonitoringProvider = StateProvider<bool>((ref) => false);
