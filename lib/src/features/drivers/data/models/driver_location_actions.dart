import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_location_actions.g.dart';

/// Driver location actions for managing driver location operations
@JsonSerializable()
class DriverLocationActions extends Equatable {
  /// Start location tracking
  final bool canStartTracking;
  
  /// Stop location tracking
  final bool canStopTracking;
  
  /// Update current location
  final bool canUpdateLocation;
  
  /// Share location with customer
  final bool canShareLocation;
  
  /// Navigate to destination
  final bool canNavigate;
  
  /// Mark as arrived at pickup location
  final bool canMarkArrivedAtPickup;
  
  /// Mark as arrived at delivery location
  final bool canMarkArrivedAtDelivery;
  
  /// Send location update to server
  final bool canSendLocationUpdate;
  
  /// Request location permissions
  final bool canRequestPermissions;
  
  /// Enable background location
  final bool canEnableBackgroundLocation;
  
  /// Current action state
  final DriverLocationActionState state;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Last action timestamp
  final DateTime? lastActionAt;

  const DriverLocationActions({
    this.canStartTracking = false,
    this.canStopTracking = false,
    this.canUpdateLocation = false,
    this.canShareLocation = false,
    this.canNavigate = false,
    this.canMarkArrivedAtPickup = false,
    this.canMarkArrivedAtDelivery = false,
    this.canSendLocationUpdate = false,
    this.canRequestPermissions = false,
    this.canEnableBackgroundLocation = false,
    this.state = DriverLocationActionState.idle,
    this.errorMessage,
    this.lastActionAt,
  });

  /// Create default actions for idle state
  const DriverLocationActions.idle()
      : canStartTracking = true,
        canStopTracking = false,
        canUpdateLocation = false,
        canShareLocation = false,
        canNavigate = false,
        canMarkArrivedAtPickup = false,
        canMarkArrivedAtDelivery = false,
        canSendLocationUpdate = false,
        canRequestPermissions = true,
        canEnableBackgroundLocation = true,
        state = DriverLocationActionState.idle,
        errorMessage = null,
        lastActionAt = null;

  /// Create actions for tracking state
  const DriverLocationActions.tracking()
      : canStartTracking = false,
        canStopTracking = true,
        canUpdateLocation = true,
        canShareLocation = true,
        canNavigate = true,
        canMarkArrivedAtPickup = true,
        canMarkArrivedAtDelivery = true,
        canSendLocationUpdate = true,
        canRequestPermissions = false,
        canEnableBackgroundLocation = false,
        state = DriverLocationActionState.tracking,
        errorMessage = null,
        lastActionAt = null;

  /// Create actions for error state
  const DriverLocationActions.error(String error)
      : canStartTracking = false,
        canStopTracking = false,
        canUpdateLocation = false,
        canShareLocation = false,
        canNavigate = false,
        canMarkArrivedAtPickup = false,
        canMarkArrivedAtDelivery = false,
        canSendLocationUpdate = false,
        canRequestPermissions = true,
        canEnableBackgroundLocation = false,
        state = DriverLocationActionState.error,
        errorMessage = error,
        lastActionAt = null;

  factory DriverLocationActions.fromJson(Map<String, dynamic> json) =>
      _$DriverLocationActionsFromJson(json);

  Map<String, dynamic> toJson() => _$DriverLocationActionsToJson(this);

  DriverLocationActions copyWith({
    bool? canStartTracking,
    bool? canStopTracking,
    bool? canUpdateLocation,
    bool? canShareLocation,
    bool? canNavigate,
    bool? canMarkArrivedAtPickup,
    bool? canMarkArrivedAtDelivery,
    bool? canSendLocationUpdate,
    bool? canRequestPermissions,
    bool? canEnableBackgroundLocation,
    DriverLocationActionState? state,
    String? errorMessage,
    DateTime? lastActionAt,
  }) {
    return DriverLocationActions(
      canStartTracking: canStartTracking ?? this.canStartTracking,
      canStopTracking: canStopTracking ?? this.canStopTracking,
      canUpdateLocation: canUpdateLocation ?? this.canUpdateLocation,
      canShareLocation: canShareLocation ?? this.canShareLocation,
      canNavigate: canNavigate ?? this.canNavigate,
      canMarkArrivedAtPickup: canMarkArrivedAtPickup ?? this.canMarkArrivedAtPickup,
      canMarkArrivedAtDelivery: canMarkArrivedAtDelivery ?? this.canMarkArrivedAtDelivery,
      canSendLocationUpdate: canSendLocationUpdate ?? this.canSendLocationUpdate,
      canRequestPermissions: canRequestPermissions ?? this.canRequestPermissions,
      canEnableBackgroundLocation: canEnableBackgroundLocation ?? this.canEnableBackgroundLocation,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      lastActionAt: lastActionAt ?? this.lastActionAt,
    );
  }

  /// Check if any action is available
  bool get hasAvailableActions {
    return canStartTracking ||
        canStopTracking ||
        canUpdateLocation ||
        canShareLocation ||
        canNavigate ||
        canMarkArrivedAtPickup ||
        canMarkArrivedAtDelivery ||
        canSendLocationUpdate ||
        canRequestPermissions ||
        canEnableBackgroundLocation;
  }

  /// Check if location tracking is active
  bool get isTrackingActive => state == DriverLocationActionState.tracking;

  /// Check if there's an error
  bool get hasError => state == DriverLocationActionState.error;

  /// Check if actions are in idle state
  bool get isIdle => state == DriverLocationActionState.idle;

  @override
  List<Object?> get props => [
        canStartTracking,
        canStopTracking,
        canUpdateLocation,
        canShareLocation,
        canNavigate,
        canMarkArrivedAtPickup,
        canMarkArrivedAtDelivery,
        canSendLocationUpdate,
        canRequestPermissions,
        canEnableBackgroundLocation,
        state,
        errorMessage,
        lastActionAt,
      ];
}

/// Driver location action state enumeration
enum DriverLocationActionState {
  @JsonValue('idle')
  idle,
  @JsonValue('tracking')
  tracking,
  @JsonValue('updating')
  updating,
  @JsonValue('navigating')
  navigating,
  @JsonValue('error')
  error,
  @JsonValue('permission_required')
  permissionRequired,
}

/// Extension for DriverLocationActionState
extension DriverLocationActionStateExtension on DriverLocationActionState {
  String get value {
    switch (this) {
      case DriverLocationActionState.idle:
        return 'idle';
      case DriverLocationActionState.tracking:
        return 'tracking';
      case DriverLocationActionState.updating:
        return 'updating';
      case DriverLocationActionState.navigating:
        return 'navigating';
      case DriverLocationActionState.error:
        return 'error';
      case DriverLocationActionState.permissionRequired:
        return 'permission_required';
    }
  }

  String get displayName {
    switch (this) {
      case DriverLocationActionState.idle:
        return 'Idle';
      case DriverLocationActionState.tracking:
        return 'Tracking';
      case DriverLocationActionState.updating:
        return 'Updating Location';
      case DriverLocationActionState.navigating:
        return 'Navigating';
      case DriverLocationActionState.error:
        return 'Error';
      case DriverLocationActionState.permissionRequired:
        return 'Permission Required';
    }
  }

  /// Check if state allows location updates
  bool get allowsLocationUpdates {
    switch (this) {
      case DriverLocationActionState.tracking:
      case DriverLocationActionState.updating:
      case DriverLocationActionState.navigating:
        return true;
      case DriverLocationActionState.idle:
      case DriverLocationActionState.error:
      case DriverLocationActionState.permissionRequired:
        return false;
    }
  }

  /// Check if state is active (not idle or error)
  bool get isActive {
    switch (this) {
      case DriverLocationActionState.tracking:
      case DriverLocationActionState.updating:
      case DriverLocationActionState.navigating:
        return true;
      case DriverLocationActionState.idle:
      case DriverLocationActionState.error:
      case DriverLocationActionState.permissionRequired:
        return false;
    }
  }
}
