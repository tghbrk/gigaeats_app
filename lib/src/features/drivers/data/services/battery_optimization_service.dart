import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Battery optimization service for adaptive location tracking
/// Adjusts GPS settings based on battery level, device capabilities, and usage patterns
class BatteryOptimizationService {
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Battery monitoring
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  final StreamController<int> _batteryLevelController = StreamController<int>.broadcast();
  
  // Current state
  int _currentBatteryLevel = 100;
  BatteryState _currentBatteryState = BatteryState.unknown;
  bool _isLowPowerMode = false;
  bool _isCharging = false;
  
  // Device capabilities
  bool _isHighEndDevice = true;
  String _deviceModel = 'Unknown';
  
  // Optimization settings
  static const int _lowBatteryThreshold = 20;
  static const int _criticalBatteryThreshold = 10;
  static const Duration _batteryCheckInterval = Duration(minutes: 1);
  
  // Adaptive settings
  Timer? _batteryMonitorTimer;
  bool _isInitialized = false;

  /// Stream of battery level changes
  Stream<int> get batteryLevelStream => _batteryLevelController.stream;

  /// Initialize battery optimization service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🔋 [BATTERY-OPT] Initializing battery optimization service');
    
    try {
      // Get initial battery state
      _currentBatteryLevel = await _battery.batteryLevel;
      _currentBatteryState = await _battery.batteryState;
      _isCharging = _currentBatteryState == BatteryState.charging;
      
      // Detect device capabilities
      await _detectDeviceCapabilities();
      
      // Start battery monitoring
      await _startBatteryMonitoring();
      
      _isInitialized = true;
      debugPrint('🔋 [BATTERY-OPT] Battery optimization initialized - Level: $_currentBatteryLevel%, Device: $_deviceModel');
    } catch (e) {
      debugPrint('❌ [BATTERY-OPT] Error initializing battery optimization: $e');
    }
  }

  /// Get current battery level
  Future<int> getBatteryLevel() async {
    try {
      _currentBatteryLevel = await _battery.batteryLevel;
      return _currentBatteryLevel;
    } catch (e) {
      debugPrint('❌ [BATTERY-OPT] Error getting battery level: $e');
      return _currentBatteryLevel;
    }
  }

  /// Get current battery state
  Future<BatteryState> getBatteryState() async {
    try {
      _currentBatteryState = await _battery.batteryState;
      _isCharging = _currentBatteryState == BatteryState.charging;
      return _currentBatteryState;
    } catch (e) {
      debugPrint('❌ [BATTERY-OPT] Error getting battery state: $e');
      return _currentBatteryState;
    }
  }

  /// Check if device is in low power mode
  bool get isLowPowerMode => _isLowPowerMode;

  /// Check if device is charging
  bool get isCharging => _isCharging;

  /// Check if battery is low
  bool get isLowBattery => _currentBatteryLevel <= _lowBatteryThreshold;

  /// Check if battery is critical
  bool get isCriticalBattery => _currentBatteryLevel <= _criticalBatteryThreshold;

  /// Get optimized location settings based on battery state
  LocationSettings getOptimizedLocationSettings({
    LocationAccuracy defaultAccuracy = LocationAccuracy.high,
    int defaultDistanceFilter = 10,
    Duration? defaultTimeLimit,
  }) {
    LocationAccuracy accuracy;
    int distanceFilter;
    Duration? timeLimit;
    
    if (isCriticalBattery && !_isCharging) {
      // Critical battery - maximum power saving
      accuracy = LocationAccuracy.low;
      distanceFilter = 50;
      timeLimit = const Duration(seconds: 10);
      debugPrint('🔋 [BATTERY-OPT] Critical battery mode - using power-saving settings');
    } else if (isLowBattery && !_isCharging) {
      // Low battery - moderate power saving
      accuracy = LocationAccuracy.medium;
      distanceFilter = 25;
      timeLimit = const Duration(seconds: 20);
      debugPrint('🔋 [BATTERY-OPT] Low battery mode - using balanced settings');
    } else if (_isCharging) {
      // Charging - can use high accuracy
      accuracy = LocationAccuracy.high;
      distanceFilter = 5;
      timeLimit = defaultTimeLimit;
      debugPrint('🔋 [BATTERY-OPT] Charging mode - using high accuracy settings');
    } else if (!_isHighEndDevice) {
      // Low-end device - conservative settings
      accuracy = LocationAccuracy.medium;
      distanceFilter = 15;
      timeLimit = const Duration(seconds: 30);
      debugPrint('🔋 [BATTERY-OPT] Low-end device - using conservative settings');
    } else {
      // Normal operation
      accuracy = defaultAccuracy;
      distanceFilter = defaultDistanceFilter;
      timeLimit = defaultTimeLimit;
    }
    
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

  /// Get optimized update interval based on battery state
  Duration getOptimizedUpdateInterval({
    Duration defaultInterval = const Duration(seconds: 15),
  }) {
    if (isCriticalBattery && !_isCharging) {
      return Duration(seconds: defaultInterval.inSeconds * 4); // 4x longer
    } else if (isLowBattery && !_isCharging) {
      return Duration(seconds: defaultInterval.inSeconds * 2); // 2x longer
    } else if (_isCharging) {
      return Duration(seconds: (defaultInterval.inSeconds * 0.75).round()); // 25% faster
    } else {
      return defaultInterval;
    }
  }

  /// Get battery optimization recommendations
  Map<String, dynamic> getBatteryOptimizationRecommendations() {
    final recommendations = <String, dynamic>{
      'battery_level': _currentBatteryLevel,
      'is_charging': _isCharging,
      'is_low_battery': isLowBattery,
      'is_critical_battery': isCriticalBattery,
      'device_tier': _isHighEndDevice ? 'high_end' : 'low_end',
      'recommended_accuracy': 'medium',
      'recommended_interval_seconds': 15,
      'power_saving_active': false,
    };
    
    if (isCriticalBattery && !_isCharging) {
      recommendations.addAll({
        'recommended_accuracy': 'low',
        'recommended_interval_seconds': 60,
        'power_saving_active': true,
        'message': 'Critical battery - using maximum power saving mode',
      });
    } else if (isLowBattery && !_isCharging) {
      recommendations.addAll({
        'recommended_accuracy': 'medium',
        'recommended_interval_seconds': 30,
        'power_saving_active': true,
        'message': 'Low battery - using power saving mode',
      });
    } else if (_isCharging) {
      recommendations.addAll({
        'recommended_accuracy': 'high',
        'recommended_interval_seconds': 10,
        'power_saving_active': false,
        'message': 'Device charging - using high accuracy mode',
      });
    }
    
    return recommendations;
  }

  /// Detect device capabilities
  Future<void> _detectDeviceCapabilities() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        
        // Simple heuristic for device tier based on Android version and RAM
        final sdkInt = androidInfo.version.sdkInt;
        _isHighEndDevice = sdkInt >= 28; // Android 9+ generally indicates newer device
        
        debugPrint('🔋 [BATTERY-OPT] Android device: $_deviceModel (SDK: $sdkInt, High-end: $_isHighEndDevice)');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceModel = '${iosInfo.name} ${iosInfo.model}';
        
        // iOS devices generally have good battery optimization
        _isHighEndDevice = true;
        
        debugPrint('🔋 [BATTERY-OPT] iOS device: $_deviceModel');
      }
    } catch (e) {
      debugPrint('❌ [BATTERY-OPT] Error detecting device capabilities: $e');
      _deviceModel = 'Unknown';
      _isHighEndDevice = true; // Default to high-end to avoid over-optimization
    }
  }

  /// Start battery monitoring
  Future<void> _startBatteryMonitoring() async {
    // Monitor battery state changes
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      final wasCharging = _isCharging;
      _currentBatteryState = state;
      _isCharging = state == BatteryState.charging;
      
      if (wasCharging != _isCharging) {
        debugPrint('🔋 [BATTERY-OPT] Charging state changed: ${_isCharging ? "Charging" : "Not charging"}');
      }
    });
    
    // Periodic battery level checks
    _batteryMonitorTimer = Timer.periodic(_batteryCheckInterval, (timer) async {
      final previousLevel = _currentBatteryLevel;
      await getBatteryLevel();
      
      if (_currentBatteryLevel != previousLevel) {
        _batteryLevelController.add(_currentBatteryLevel);
        
        // Log significant battery level changes
        if ((_currentBatteryLevel <= _lowBatteryThreshold && previousLevel > _lowBatteryThreshold) ||
            (_currentBatteryLevel <= _criticalBatteryThreshold && previousLevel > _criticalBatteryThreshold) ||
            (_currentBatteryLevel > _lowBatteryThreshold && previousLevel <= _lowBatteryThreshold)) {
          debugPrint('🔋 [BATTERY-OPT] Battery level changed: $previousLevel% → $_currentBatteryLevel%');
        }
      }
    });
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🔋 [BATTERY-OPT] Disposing battery optimization service');
    
    await _batteryStateSubscription?.cancel();
    _batteryMonitorTimer?.cancel();
    await _batteryLevelController.close();
    
    _isInitialized = false;
  }
}
