import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/services/navigation_location_service.dart';
import '../../../../core/services/location_service.dart';

/// Provider for current navigation location
final navigationLocationProvider = StateNotifierProvider<NavigationLocationNotifier, NavigationLocationState>((ref) {
  return NavigationLocationNotifier();
});

/// Provider for location permission status
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  return await LocationService.isLocationPermissionGranted();
});

/// Provider for location service status
final locationServiceProvider = FutureProvider<bool>((ref) async {
  return await LocationService.isLocationServiceEnabled();
});

/// Provider for combined location availability
final locationAvailabilityProvider = FutureProvider<LocationAvailability>((ref) async {
  final hasPermission = await ref.watch(locationPermissionProvider.future);
  final serviceEnabled = await ref.watch(locationServiceProvider.future);
  
  return LocationAvailability(
    hasPermission: hasPermission,
    serviceEnabled: serviceEnabled,
    isAvailable: hasPermission && serviceEnabled,
  );
});

/// State notifier for navigation location management
class NavigationLocationNotifier extends StateNotifier<NavigationLocationState> {
  NavigationLocationNotifier() : super(const NavigationLocationState.initial());

  /// Get current location for navigation
  Future<void> getCurrentLocation({
    bool requireHighAccuracy = true,
    int maxRetries = 3,
  }) async {
    if (state.isLoading) return;

    state = const NavigationLocationState.loading();

    try {
      final result = await NavigationLocationService.getCurrentLocationForNavigation(
        requireHighAccuracy: requireHighAccuracy,
        maxRetries: maxRetries,
      );

      if (result.isSuccess && result.location != null) {
        state = NavigationLocationState.success(result.location!);
      } else {
        state = NavigationLocationState.error(
          result.errorMessage ?? 'Unknown location error',
          result.errorType,
        );
      }
    } catch (e) {
      debugPrint('NavigationLocationNotifier: Error getting location: $e');
      state = NavigationLocationState.error(
        'Failed to get location: ${e.toString()}',
        NavigationLocationErrorType.unknown,
      );
    }
  }

  /// Validate current location for navigation to destination
  Future<void> validateLocationForNavigation(LatLng destination) async {
    if (state.location == null) {
      await getCurrentLocation();
    }

    if (state.location != null) {
      try {
        final validation = await NavigationLocationService.validateLocationForNavigation(
          state.location!.toLatLng(),
          destination,
        );

        state = state.copyWith(validation: validation);
      } catch (e) {
        debugPrint('NavigationLocationNotifier: Error validating location: $e');
      }
    }
  }

  /// Refresh location permissions
  Future<void> refreshPermissions() async {
    try {
      final hasPermission = await LocationService.isLocationPermissionGranted();
      final serviceEnabled = await LocationService.isLocationServiceEnabled();

      if (hasPermission && serviceEnabled) {
        // Permissions are now available, try to get location
        await getCurrentLocation();
      } else {
        state = NavigationLocationState.error(
          hasPermission 
              ? 'Location services are disabled'
              : 'Location permission is required',
          hasPermission 
              ? NavigationLocationErrorType.serviceDisabled
              : NavigationLocationErrorType.permissionDenied,
        );
      }
    } catch (e) {
      debugPrint('NavigationLocationNotifier: Error refreshing permissions: $e');
    }
  }

  /// Clear current state
  void clear() {
    state = const NavigationLocationState.initial();
  }

  /// Update location manually (for testing or manual refresh)
  void updateLocation(NavigationLocation location) {
    state = NavigationLocationState.success(location);
  }
}

/// State class for navigation location
class NavigationLocationState {
  final NavigationLocation? location;
  final bool isLoading;
  final String? errorMessage;
  final NavigationLocationErrorType? errorType;
  final NavigationLocationValidation? validation;

  const NavigationLocationState._({
    this.location,
    this.isLoading = false,
    this.errorMessage,
    this.errorType,
    this.validation,
  });

  const NavigationLocationState.initial() : this._();

  const NavigationLocationState.loading() : this._(isLoading: true);

  const NavigationLocationState.success(NavigationLocation location) 
      : this._(location: location);

  const NavigationLocationState.error(
    String message,
    NavigationLocationErrorType? type,
  ) : this._(errorMessage: message, errorType: type);

  bool get hasLocation => location != null;
  bool get hasError => errorMessage != null;
  bool get isSuccess => hasLocation && !hasError && !isLoading;

  NavigationLocationState copyWith({
    NavigationLocation? location,
    bool? isLoading,
    String? errorMessage,
    NavigationLocationErrorType? errorType,
    NavigationLocationValidation? validation,
  }) {
    return NavigationLocationState._(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      validation: validation ?? this.validation,
    );
  }

  @override
  String toString() {
    return 'NavigationLocationState(location: $location, isLoading: $isLoading, errorMessage: $errorMessage, errorType: $errorType, validation: $validation)';
  }
}

/// Location availability information
class LocationAvailability {
  final bool hasPermission;
  final bool serviceEnabled;
  final bool isAvailable;

  const LocationAvailability({
    required this.hasPermission,
    required this.serviceEnabled,
    required this.isAvailable,
  });

  String get statusMessage {
    if (isAvailable) {
      return 'Location services are available';
    } else if (!serviceEnabled) {
      return 'Location services are disabled';
    } else if (!hasPermission) {
      return 'Location permission is required';
    } else {
      return 'Location services are not available';
    }
  }

  @override
  String toString() {
    return 'LocationAvailability(hasPermission: $hasPermission, serviceEnabled: $serviceEnabled, isAvailable: $isAvailable)';
  }
}

/// Provider for location accuracy monitoring
final locationAccuracyProvider = Provider.family<NavigationLocationAccuracy?, double?>((ref, accuracy) {
  if (accuracy == null) return null;
  return NavigationLocationService.getLocationAccuracyStatus(accuracy);
});

/// Provider for distance calculation between two points
final distanceCalculationProvider = Provider.family<double?, DistanceCalculationParams?>((ref, params) {
  if (params == null) return null;
  return NavigationLocationService.calculateDistance(params.from, params.to);
});

/// Parameters for distance calculation
class DistanceCalculationParams {
  final LatLng from;
  final LatLng to;

  const DistanceCalculationParams({
    required this.from,
    required this.to,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DistanceCalculationParams &&
        other.from == from &&
        other.to == to;
  }

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}
