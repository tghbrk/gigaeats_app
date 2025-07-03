import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user_management/domain/driver.dart';
import '../../data/services/driver_auth_service.dart';
import '../../data/services/driver_profile_service.dart';
// TODO: Restore when driver services are implemented
// import '../../data/services/driver_performance_service.dart';
// import '../../data/services/driver_earnings_service.dart';
// import '../../data/services/driver_comprehensive_performance_service.dart';
// import '../../data/models/driver_performance_stats.dart';

/// Provider for DriverProfileService
final driverProfileServiceProvider = Provider<DriverProfileService>((ref) {
  return DriverProfileService();
});

/// Provider for DriverAuthService
final driverAuthServiceProvider = Provider<DriverAuthService>((ref) {
  return DriverAuthService();
});

// TODO: Restore when DriverPerformanceService is implemented
// /// Provider for DriverPerformanceService
// final driverPerformanceServiceProvider = Provider<DriverPerformanceService>((ref) {
//   return DriverPerformanceService();
// });

// TODO: Restore when DriverEarningsService is implemented
// /// Provider for DriverEarningsService
// final driverEarningsServiceProvider = Provider<DriverEarningsService>((ref) {
//   return DriverEarningsService();
// });

// TODO: Restore when DriverComprehensivePerformanceService is implemented
// /// Provider for DriverComprehensivePerformanceService
// final driverComprehensivePerformanceServiceProvider = Provider<DriverComprehensivePerformanceService>((ref) {
//   return DriverComprehensivePerformanceService();
// });

/// Provider for current driver profile data
final currentDriverProfileProvider = FutureProvider<Driver?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final driverProfileService = ref.read(driverProfileServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return null;
  }

  final userId = authState.user?.id;
  if (userId == null || userId.isEmpty) {
    return null;
  }

  try {
    return await driverProfileService.getDriverProfileByUserId(userId);
  } catch (e) {
    debugPrint('Error getting current driver profile: $e');
    return null;
  }
});

/// Provider for driver profile stream (real-time updates)
final driverProfileStreamProvider = StreamProvider<Driver?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final driverProfileService = ref.read(driverProfileServiceProvider);

  debugPrint('🚗 DriverProfileStreamProvider: Called');
  debugPrint('🚗 Auth Status: ${authState.status}');
  debugPrint('🚗 User Role: ${authState.user?.role}');
  debugPrint('🚗 User ID (public.users): ${authState.user?.id}');

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 DriverProfileStreamProvider: User is not a driver, returning null');
    yield null;
    return;
  }

  final publicUserId = authState.user?.id;
  if (publicUserId == null || publicUserId.isEmpty) {
    debugPrint('🚗 DriverProfileStreamProvider: User ID is null or empty, returning null');
    yield null;
    return;
  }

  try {
    // Use the internal app user ID directly to query the drivers table
    // The drivers table user_id field contains the public.users.id, not the supabase_user_id
    debugPrint('🚗 DriverProfileStreamProvider: Getting profile stream for user: $publicUserId');

    await for (final driver in driverProfileService.getDriverProfileStream(publicUserId)) {
      yield driver;
    }
  } catch (e) {
    debugPrint('🚗 DriverProfileStreamProvider: Error getting driver profile stream: $e');
    yield null;
  }
});

/// Provider for driver profile actions
final driverProfileActionsProvider = Provider<DriverProfileActions>((ref) {
  return DriverProfileActions(ref);
});

/// Class containing driver profile action methods
class DriverProfileActions {
  final Ref _ref;

  DriverProfileActions(this._ref);

  /// Update driver profile information
  Future<bool> updateProfile({
    required String driverId,
    String? name,
    String? phoneNumber,
    VehicleDetails? vehicleDetails,
  }) async {
    try {
      final driverProfileService = _ref.read(driverProfileServiceProvider);

      final success = await driverProfileService.updateDriverProfile(
        driverId: driverId,
        name: name,
        phoneNumber: phoneNumber,
        vehicleDetails: vehicleDetails,
      );

      if (success) {
        // Refresh profile providers
        _ref.invalidate(currentDriverProfileProvider);
      }

      return success;
    } catch (e) {
      debugPrint('Error updating driver profile: $e');
      return false;
    }
  }

  /// Update driver profile photo
  Future<String?> updateProfilePhoto({
    required String driverId,
    required XFile imageFile,
    String? oldPhotoUrl,
  }) async {
    try {
      final driverProfileService = _ref.read(driverProfileServiceProvider);

      // Validate image file
      if (!driverProfileService.isValidImageFile(imageFile)) {
        throw Exception('Please select a valid image file (JPG, PNG, WebP)');
      }

      // Check file size
      final isValidSize = await driverProfileService.isFileSizeValid(imageFile);
      if (!isValidSize) {
        throw Exception('Image size must be less than 5MB');
      }

      final newPhotoUrl = await driverProfileService.updateProfilePhoto(
        driverId: driverId,
        imageFile: imageFile,
        oldPhotoUrl: oldPhotoUrl,
      );

      if (newPhotoUrl != null) {
        // Refresh profile providers
        _ref.invalidate(currentDriverProfileProvider);
      }

      return newPhotoUrl;
    } catch (e) {
      debugPrint('Error updating profile photo: $e');
      rethrow;
    }
  }

  /// Update driver status
  Future<bool> updateStatus({
    required String driverId,
    required String status,
    Map<String, dynamic>? lastLocation,
  }) async {
    try {
      final driverAuthService = _ref.read(driverAuthServiceProvider);

      final success = await driverAuthService.updateDriverStatus(
        driverId: driverId,
        status: status,
        lastLocation: lastLocation,
      );

      if (success) {
        // Refresh profile providers
        _ref.invalidate(currentDriverProfileProvider);
      }

      return success;
    } catch (e) {
      debugPrint('Error updating driver status: $e');
      return false;
    }
  }

  /// Get driver profile by ID
  Future<Driver?> getProfile(String driverId) async {
    try {
      final driverProfileService = _ref.read(driverProfileServiceProvider);
      return await driverProfileService.getDriverProfile(driverId);
    } catch (e) {
      debugPrint('Error getting driver profile: $e');
      return null;
    }
  }

  /// Refresh profile data
  void refreshProfile() {
    _ref.invalidate(currentDriverProfileProvider);
  }
}

/// Provider for driver profile loading state
final driverProfileLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for driver profile error state
final driverProfileErrorProvider = StateProvider<String?>((ref) => null);

/// Provider for profile photo upload state
final profilePhotoUploadProvider = StateProvider<bool>((ref) => false);

/// Provider for profile editing state
final profileEditingProvider = StateProvider<bool>((ref) => false);

/// Provider to test database schema
final databaseSchemaTestProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    return {'error': 'Not a driver'};
  }

  try {
    final userId = authState.user?.id ?? '';
    final supabase = Supabase.instance.client;

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .single();

    final driverId = driverResponse['id'] as String;
    debugPrint('🔍 Testing database schema for driver: $driverId');

    // Test driver_performance table
    try {
      final perfResponse = await supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId)
          .limit(1);

      debugPrint('🔍 driver_performance query successful, found ${perfResponse.length} records');
      if (perfResponse.isNotEmpty) {
        debugPrint('🔍 driver_performance columns: ${perfResponse.first.keys.toList()}');
      }
    } catch (e) {
      debugPrint('🔍 driver_performance query failed: $e');
    }

    // Test driver_earnings_summary table
    try {
      final earningsResponse = await supabase
          .from('driver_earnings_summary')
          .select('*')
          .eq('driver_id', driverId)
          .limit(1);

      debugPrint('🔍 driver_earnings_summary query successful, found ${earningsResponse.length} records');
      if (earningsResponse.isNotEmpty) {
        debugPrint('🔍 driver_earnings_summary columns: ${earningsResponse.first.keys.toList()}');
      }
    } catch (e) {
      debugPrint('🔍 driver_earnings_summary query failed: $e');
    }

    return {'driver_id': driverId, 'test': 'completed'};
  } catch (e) {
    debugPrint('🔍 Database schema test failed: $e');
    return {'error': e.toString()};
  }
});

// TODO: Restore when DriverPerformanceStats is implemented
// /// Provider for comprehensive driver performance stats
// final driverPerformanceStatsProvider = FutureProvider<DriverPerformanceStats>((ref) async {
// TODO: Restore when DriverPerformanceStats and services are implemented
//   final authState = ref.watch(authStateProvider);
//
//   debugPrint('🚗 DriverPerformanceStatsProvider: Starting to fetch performance stats');
//   debugPrint('🚗 Auth Status: ${authState.status}');
//   debugPrint('🚗 User Role: ${authState.user?.role}');
//
//   if (authState.user?.role != UserRole.driver) {
//     debugPrint('🚗 DriverPerformanceStatsProvider: User is not a driver, returning empty stats');
//     return DriverPerformanceStats.empty();
//   }
//
//   try {
//     // First run the database schema test
//     await ref.read(databaseSchemaTestProvider.future);
//
//     // Get driver ID
//     final userId = authState.user?.id ?? '';
//     if (userId.isEmpty) {
//       debugPrint('🚗 DriverPerformanceStatsProvider: User ID is empty');
//       return DriverPerformanceStats.empty();
//     }
//
//     debugPrint('🚗 DriverPerformanceStatsProvider: Getting driver ID for user: $userId');
//
//     final supabase = Supabase.instance.client;
//     final driverResponse = await supabase
//         .from('drivers')
//         .select('id')
//         .eq('user_id', userId)
//         .single();
//
//     final driverId = driverResponse['id'] as String;
//     debugPrint('🚗 DriverPerformanceStatsProvider: Found driver ID: $driverId');
//
//     // Get comprehensive performance data
//     final comprehensiveService = ref.read(driverComprehensivePerformanceServiceProvider);
//
//     debugPrint('🚗 DriverPerformanceStatsProvider: Fetching comprehensive stats...');
//     final stats = await comprehensiveService.getComprehensiveStats(driverId);
//
//     debugPrint('🚗 DriverPerformanceStatsProvider: Successfully fetched stats:');
//     debugPrint('🚗   - Total Deliveries: ${stats.totalDeliveries}');
//     debugPrint('🚗   - Customer Rating: ${stats.customerRating}');
//     debugPrint('🚗   - On-Time Rate: ${stats.onTimeDeliveryRate}%');
//     debugPrint('🚗   - Monthly Earnings: RM ${stats.totalEarningsMonth}');
//     debugPrint('🚗   - Today Earnings: RM ${stats.totalEarningsToday}');
//     debugPrint('🚗   - Weekly Earnings: RM ${stats.totalEarningsWeek}');
//
//     return stats;
//   } catch (e, stackTrace) {
//     debugPrint('🚗 DriverPerformanceStatsProvider: Error getting driver performance stats: $e');
//     debugPrint('🚗 DriverPerformanceStatsProvider: Stack trace: $stackTrace');
//
//     // Return empty stats on error instead of throwing
//     return DriverPerformanceStats.empty();
//   }
// });

// TODO: Restore when DriverPerformanceStats and services are implemented
// /// Provider for real-time driver performance stats with streaming updates
// final driverPerformanceStatsStreamProvider = StreamProvider<DriverPerformanceStats>((ref) async* {
//   final authState = ref.watch(authStateProvider);
//
//   if (authState.user?.role != UserRole.driver) {
//     yield DriverPerformanceStats.empty();
//     return;
//   }
//
//   try {
//     // Get driver ID
//     final userId = authState.user?.id ?? '';
//     if (userId.isEmpty) {
//       yield DriverPerformanceStats.empty();
//       return;
//     }
//
//     final supabase = Supabase.instance.client;
//     final driverResponse = await supabase
//         .from('drivers')
//         .select('id')
//         .eq('user_id', userId)
//         .single();
//
//     final driverId = driverResponse['id'] as String;
//
//     // Stream comprehensive performance data with real-time updates
//     final comprehensiveService = ref.read(driverComprehensivePerformanceServiceProvider);
//     await for (final stats in comprehensiveService.streamComprehensiveStats(driverId)) {
//       yield stats;
//     }
//   } catch (e) {
//     debugPrint('Error streaming driver performance stats: $e');
//     yield DriverPerformanceStats.empty();
//   }
// });

// TODO: Restore when DriverPerformanceStats and services are implemented
// /// Legacy provider for backward compatibility (returns Map format)
// final driverPerformanceStatsLegacyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
//   final stats = await ref.watch(driverPerformanceStatsProvider.future);
//
//   return {
//     'totalDeliveries': stats.totalDeliveries,
//     'rating': stats.customerRating,
//     'onTimeRate': stats.onTimeDeliveryRate.round(),
//     'monthlyEarnings': stats.totalEarningsMonth,
//     'averageDeliveryTime': stats.formattedAverageDeliveryTime,
//     'totalDistance': stats.formattedDistance,
//     'deliveriesToday': stats.deliveriesToday,
//     'deliveriesWeek': stats.deliveriesWeek,
//     'deliveriesMonth': stats.deliveriesMonth,
//     'averageEarningsPerDelivery': stats.averageEarningsPerDelivery,
//     'successRate': stats.successRatePercentage,
//   };
// });

/// Provider for driver status options
final driverStatusOptionsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'value': 'online',
      'label': 'Online',
      'color': '#4CAF50',
      'icon': 'check_circle',
    },
    {
      'value': 'offline',
      'label': 'Offline',
      'color': '#9E9E9E',
      'icon': 'cancel',
    },
    {
      'value': 'on_delivery',
      'label': 'On Delivery',
      'color': '#2196F3',
      'icon': 'local_shipping',
    },
  ];
});

/// Provider for vehicle type options
final vehicleTypeOptionsProvider = Provider<List<String>>((ref) {
  return [
    'Motorcycle',
    'Car',
    'Van',
    'Truck',
    'Bicycle',
    'Scooter',
  ];
});
