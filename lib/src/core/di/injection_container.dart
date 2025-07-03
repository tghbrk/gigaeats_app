import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/security_service.dart';
import '../network/network_info.dart';
import '../network/api_client.dart';
import '../utils/logger.dart';
import '../../data/services/cache_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/user_management/data/repositories/vendor_repository.dart';
import '../../features/orders/data/repositories/order_repository.dart';
import '../../features/user_management/data/repositories/customer_repository.dart';
import '../../features/menu/data/repositories/menu_item_repository.dart';
import '../services/file_upload_service.dart';

import 'injection_container.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();

/// Manual dependency injection setup
/// This will be replaced by generated code when using injectable
Future<void> setupDependencies() async {
  // Initialize logger first
  final logger = AppLogger();
  logger.init();
  getIt.registerSingleton<AppLogger>(logger);

  // Core services
  getIt.registerLazySingleton<SecurityService>(() => SecurityService());
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  
  // API Client
  final apiClient = ApiClient();
  getIt.registerSingleton<ApiClient>(apiClient);

  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  

  
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Data services
  getIt.registerLazySingleton<CacheService>(
    () => CacheService(),
  );



  getIt.registerLazySingleton<FileUploadService>(
    () => FileUploadService(),
  );

  // Repositories
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(),
  );

  getIt.registerLazySingleton<VendorRepository>(
    () => VendorRepository(),
  );

  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepository(),
  );

  getIt.registerLazySingleton<CustomerRepository>(
    () => CustomerRepository(),
  );

  getIt.registerLazySingleton<MenuItemRepository>(
    () => MenuItemRepository(),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}

/// Register test dependencies
Future<void> setupTestDependencies() async {
  // This would be used for testing with mock implementations
  // Example:
  // getIt.registerSingleton<AuthService>(MockAuthService());
}

/// Extension to make dependency injection easier to use
extension GetItExtension on GetIt {
  /// Get dependency with better error handling
  T getDependency<T extends Object>() {
    try {
      return get<T>();
    } catch (e) {
      throw Exception('Dependency $T not registered. Make sure to call setupDependencies() first.');
    }
  }

  /// Check if dependency is registered
  bool hasDependency<T extends Object>() {
    return isRegistered<T>();
  }

  /// Register singleton with error handling
  void registerSingletonSafe<T extends Object>(T instance) {
    if (!isRegistered<T>()) {
      registerSingleton<T>(instance);
    }
  }

  /// Register lazy singleton with error handling
  void registerLazySingletonSafe<T extends Object>(T Function() factoryFunc) {
    if (!isRegistered<T>()) {
      registerLazySingleton<T>(factoryFunc);
    }
  }
}

/// Service locator for easy access to dependencies
class ServiceLocator {
  static T get<T extends Object>() => getIt.getDependency<T>();
  
  static bool has<T extends Object>() => getIt.hasDependency<T>();
  
  // Commonly used services
  static AppLogger get logger => get<AppLogger>();
  static SecurityService get security => get<SecurityService>();
  static NetworkInfo get networkInfo => get<NetworkInfo>();
  static ApiClient get apiClient => get<ApiClient>();

  static CacheService get cacheService => get<CacheService>();
  
  // Repositories
  static UserRepository get userRepository => get<UserRepository>();
  static VendorRepository get vendorRepository => get<VendorRepository>();
  static OrderRepository get orderRepository => get<OrderRepository>();
  static CustomerRepository get customerRepository => get<CustomerRepository>();
  static MenuItemRepository get menuItemRepository => get<MenuItemRepository>();
}
