import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'navigation_models.g.dart';

/// LatLng JSON converter
class LatLngConverter implements JsonConverter<LatLng, Map<String, dynamic>> {
  const LatLngConverter();

  @override
  LatLng fromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(LatLng latLng) {
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    };
  }
}

/// List of LatLng JSON converter
class LatLngListConverter implements JsonConverter<List<LatLng>, List<dynamic>> {
  const LatLngListConverter();

  @override
  List<LatLng> fromJson(List<dynamic> json) {
    return json.map((item) => const LatLngConverter().fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  List<dynamic> toJson(List<LatLng> latLngList) {
    return latLngList.map((latLng) => const LatLngConverter().toJson(latLng)).toList();
  }
}

/// Navigation instruction types
enum NavigationInstructionType {
  @JsonValue('turn_left')
  turnLeft,
  @JsonValue('turn_right')
  turnRight,
  @JsonValue('turn_slight_left')
  turnSlightLeft,
  @JsonValue('turn_slight_right')
  turnSlightRight,
  @JsonValue('turn_sharp_left')
  turnSharpLeft,
  @JsonValue('turn_sharp_right')
  turnSharpRight,
  @JsonValue('uturn_left')
  uturnLeft,
  @JsonValue('uturn_right')
  uturnRight,
  @JsonValue('straight')
  straight,
  @JsonValue('ramp_left')
  rampLeft,
  @JsonValue('ramp_right')
  rampRight,
  @JsonValue('merge')
  merge,
  @JsonValue('fork_left')
  forkLeft,
  @JsonValue('fork_right')
  forkRight,
  @JsonValue('ferry')
  ferry,
  @JsonValue('roundabout_left')
  roundaboutLeft,
  @JsonValue('roundabout_right')
  roundaboutRight,
  @JsonValue('destination')
  destination,
}

/// Traffic condition levels
enum TrafficCondition {
  @JsonValue('unknown')
  unknown,
  @JsonValue('clear')
  clear,
  @JsonValue('light')
  light,
  @JsonValue('moderate')
  moderate,
  @JsonValue('heavy')
  heavy,
  @JsonValue('severe')
  severe,
}

/// Navigation session status
enum NavigationSessionStatus {
  @JsonValue('initializing')
  initializing,
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('error')
  error,
}

/// Navigation preferences
@JsonSerializable()
class NavigationPreferences extends Equatable {
  final String language;
  final bool voiceGuidanceEnabled;
  final double voiceVolume;
  final bool trafficAlertsEnabled;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final String units; // 'metric' or 'imperial'
  final int instructionDistance; // meters before turn to announce
  final bool nightMode;

  const NavigationPreferences({
    this.language = 'en-MY',
    this.voiceGuidanceEnabled = true,
    this.voiceVolume = 0.8,
    this.trafficAlertsEnabled = true,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = false,
    this.units = 'metric',
    this.instructionDistance = 100,
    this.nightMode = false,
  });

  factory NavigationPreferences.fromJson(Map<String, dynamic> json) => _$NavigationPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NavigationPreferencesToJson(this);

  factory NavigationPreferences.defaults() => const NavigationPreferences();

  NavigationPreferences copyWith({
    String? language,
    bool? voiceGuidanceEnabled,
    double? voiceVolume,
    bool? trafficAlertsEnabled,
    bool? avoidTolls,
    bool? avoidHighways,
    bool? avoidFerries,
    String? units,
    int? instructionDistance,
    bool? nightMode,
  }) {
    return NavigationPreferences(
      language: language ?? this.language,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      voiceVolume: voiceVolume ?? this.voiceVolume,
      trafficAlertsEnabled: trafficAlertsEnabled ?? this.trafficAlertsEnabled,
      avoidTolls: avoidTolls ?? this.avoidTolls,
      avoidHighways: avoidHighways ?? this.avoidHighways,
      avoidFerries: avoidFerries ?? this.avoidFerries,
      units: units ?? this.units,
      instructionDistance: instructionDistance ?? this.instructionDistance,
      nightMode: nightMode ?? this.nightMode,
    );
  }

  @override
  List<Object?> get props => [
        language,
        voiceGuidanceEnabled,
        voiceVolume,
        trafficAlertsEnabled,
        avoidTolls,
        avoidHighways,
        avoidFerries,
        units,
        instructionDistance,
        nightMode,
      ];
}

/// Navigation instruction
@JsonSerializable()
class NavigationInstruction extends Equatable {
  final String id;
  final NavigationInstructionType type;
  final String text;
  final String htmlText;
  final double distanceMeters;
  final int durationSeconds;
  @LatLngConverter()
  final LatLng location;
  final String? streetName;
  final String? maneuver;
  final TrafficCondition trafficCondition;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const NavigationInstruction({
    required this.id,
    required this.type,
    required this.text,
    required this.htmlText,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
    this.streetName,
    this.maneuver,
    this.trafficCondition = TrafficCondition.unknown,
    required this.timestamp,
    this.metadata,
  });

  factory NavigationInstruction.fromJson(Map<String, dynamic> json) => _$NavigationInstructionFromJson(json);
  Map<String, dynamic> toJson() => _$NavigationInstructionToJson(this);

  /// Get voice announcement text
  String get voiceText {
    switch (type) {
      case NavigationInstructionType.turnLeft:
        return 'Turn left${streetName != null ? ' onto $streetName' : ''}';
      case NavigationInstructionType.turnRight:
        return 'Turn right${streetName != null ? ' onto $streetName' : ''}';
      case NavigationInstructionType.straight:
        return 'Continue straight${streetName != null ? ' on $streetName' : ''}';
      case NavigationInstructionType.destination:
        return 'You have arrived at your destination';
      default:
        return text;
    }
  }

  /// Get distance text for display
  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get duration text for display
  String get durationText {
    if (durationSeconds < 60) {
      return '${durationSeconds}s';
    } else if (durationSeconds < 3600) {
      return '${(durationSeconds / 60).round()}min';
    } else {
      final hours = (durationSeconds / 3600).floor();
      final minutes = ((durationSeconds % 3600) / 60).round();
      return '${hours}h ${minutes}min';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        text,
        htmlText,
        distanceMeters,
        durationSeconds,
        location,
        streetName,
        maneuver,
        trafficCondition,
        timestamp,
        metadata,
      ];
}

/// Route information with traffic data
@JsonSerializable()
class NavigationRoute extends Equatable {
  final String id;
  @LatLngListConverter()
  final List<LatLng> polylinePoints;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final int durationInTrafficSeconds;
  final List<NavigationInstruction> instructions;
  final TrafficCondition overallTrafficCondition;
  final String summary;
  final List<String> warnings;
  final DateTime calculatedAt;
  final Map<String, dynamic>? metadata;

  const NavigationRoute({
    required this.id,
    required this.polylinePoints,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.durationInTrafficSeconds,
    required this.instructions,
    this.overallTrafficCondition = TrafficCondition.unknown,
    required this.summary,
    this.warnings = const [],
    required this.calculatedAt,
    this.metadata,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) => _$NavigationRouteFromJson(json);
  Map<String, dynamic> toJson() => _$NavigationRouteToJson(this);

  /// Get total distance text
  String get totalDistanceText {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.round()}m';
    } else {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get total duration text
  String get totalDurationText {
    if (totalDurationSeconds < 60) {
      return '${totalDurationSeconds}s';
    } else if (totalDurationSeconds < 3600) {
      return '${(totalDurationSeconds / 60).round()}min';
    } else {
      final hours = (totalDurationSeconds / 3600).floor();
      final minutes = ((totalDurationSeconds % 3600) / 60).round();
      return '${hours}h ${minutes}min';
    }
  }

  /// Get traffic delay text
  String get trafficDelayText {
    final delay = durationInTrafficSeconds - totalDurationSeconds;
    if (delay <= 0) return 'No delay';
    
    if (delay < 60) {
      return '${delay}s delay';
    } else {
      return '${(delay / 60).round()}min delay';
    }
  }

  @override
  List<Object?> get props => [
        id,
        polylinePoints,
        totalDistanceMeters,
        totalDurationSeconds,
        durationInTrafficSeconds,
        instructions,
        overallTrafficCondition,
        summary,
        warnings,
        calculatedAt,
        metadata,
      ];
}

/// Navigation session
@JsonSerializable()
class NavigationSession extends Equatable {
  final String id;
  final String orderId;
  final String? batchId;
  final NavigationRoute route;
  final NavigationPreferences preferences;
  final NavigationSessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  @LatLngConverter()
  final LatLng origin;
  @LatLngConverter()
  final LatLng destination;
  final String? destinationName;
  final int currentInstructionIndex;
  final double progressPercentage;
  final Map<String, dynamic>? metadata;

  const NavigationSession({
    required this.id,
    required this.orderId,
    this.batchId,
    required this.route,
    required this.preferences,
    this.status = NavigationSessionStatus.initializing,
    required this.startTime,
    this.endTime,
    required this.origin,
    required this.destination,
    this.destinationName,
    this.currentInstructionIndex = 0,
    this.progressPercentage = 0.0,
    this.metadata,
  });

  factory NavigationSession.fromJson(Map<String, dynamic> json) => _$NavigationSessionFromJson(json);
  Map<String, dynamic> toJson() => _$NavigationSessionToJson(this);

  /// Get current instruction
  NavigationInstruction? get currentInstruction {
    if (currentInstructionIndex < route.instructions.length) {
      return route.instructions[currentInstructionIndex];
    }
    return null;
  }

  /// Get next instruction
  NavigationInstruction? get nextInstruction {
    if (currentInstructionIndex + 1 < route.instructions.length) {
      return route.instructions[currentInstructionIndex + 1];
    }
    return null;
  }

  /// Check if navigation is active
  bool get isActive => status == NavigationSessionStatus.active;

  /// Check if navigation is completed
  bool get isCompleted => status == NavigationSessionStatus.completed;

  /// Get session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  NavigationSession copyWith({
    String? id,
    String? orderId,
    String? batchId,
    NavigationRoute? route,
    NavigationPreferences? preferences,
    NavigationSessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    LatLng? origin,
    LatLng? destination,
    String? destinationName,
    int? currentInstructionIndex,
    double? progressPercentage,
    Map<String, dynamic>? metadata,
  }) {
    return NavigationSession(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      batchId: batchId ?? this.batchId,
      route: route ?? this.route,
      preferences: preferences ?? this.preferences,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      destinationName: destinationName ?? this.destinationName,
      currentInstructionIndex: currentInstructionIndex ?? this.currentInstructionIndex,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        batchId,
        route,
        preferences,
        status,
        startTime,
        endTime,
        origin,
        destination,
        destinationName,
        currentInstructionIndex,
        progressPercentage,
        metadata,
      ];
}
