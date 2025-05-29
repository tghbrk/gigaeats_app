import 'dart:io';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// Network connectivity information service
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Future<NetworkType> get networkType;
  Stream<bool> get onConnectivityChanged;
}

/// Types of network connections
enum NetworkType {
  wifi,
  mobile,
  ethernet,
  none,
  unknown,
}

/// Implementation of NetworkInfo
class NetworkInfoImpl implements NetworkInfo {
  final AppLogger _logger = AppLogger();

  @override
  Future<bool> get isConnected async {
    try {
      if (kIsWeb) {
        // For web, we can't reliably check connectivity
        // We'll assume connected and let network requests fail if not
        return true;
      }

      // Try to lookup a reliable host
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      _logger.debug('Network connectivity check: $isConnected');
      return isConnected;
    } catch (e) {
      _logger.warning('Network connectivity check failed', e);
      return false;
    }
  }

  @override
  Future<NetworkType> get networkType async {
    try {
      if (kIsWeb) {
        // For web, we can't determine the exact network type
        final connected = await isConnected;
        return connected ? NetworkType.unknown : NetworkType.none;
      }

      // For mobile platforms, we would need additional packages like connectivity_plus
      // For now, we'll return unknown if connected, none if not
      final connected = await isConnected;
      return connected ? NetworkType.unknown : NetworkType.none;
    } catch (e) {
      _logger.warning('Network type check failed', e);
      return NetworkType.unknown;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    // For a complete implementation, you would use connectivity_plus package
    // For now, we'll return a simple stream that checks periodically
    return Stream.periodic(
      const Duration(seconds: 5),
      (_) => isConnected,
    ).asyncMap((future) => future);
  }

  /// Checks if the device has a fast internet connection
  Future<bool> get hasFastConnection async {
    try {
      final networkType = await this.networkType;
      
      switch (networkType) {
        case NetworkType.wifi:
        case NetworkType.ethernet:
          return true;
        case NetworkType.mobile:
          // For mobile, we assume it's fast enough
          // In a real implementation, you might check the mobile network type (3G, 4G, 5G)
          return true;
        case NetworkType.none:
          return false;
        case NetworkType.unknown:
          // If we can't determine the type but we're connected, assume it's fast enough
          return await isConnected;
      }
    } catch (e) {
      _logger.warning('Fast connection check failed', e);
      return false;
    }
  }

  /// Measures network latency by pinging a reliable host
  Future<Duration?> measureLatency({String host = 'google.com'}) async {
    try {
      if (kIsWeb) {
        // Can't measure latency reliably on web
        return null;
      }

      final stopwatch = Stopwatch()..start();
      await InternetAddress.lookup(host);
      stopwatch.stop();
      
      final latency = stopwatch.elapsed;
      _logger.debug('Network latency to $host: ${latency.inMilliseconds}ms');
      
      return latency;
    } catch (e) {
      _logger.warning('Latency measurement failed', e);
      return null;
    }
  }

  /// Checks if a specific host is reachable
  Future<bool> isHostReachable(String host, {int port = 80, Duration timeout = const Duration(seconds: 5)}) async {
    try {
      if (kIsWeb) {
        // Can't check specific host reachability on web
        return await isConnected;
      }

      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      
      _logger.debug('Host $host:$port is reachable');
      return true;
    } catch (e) {
      _logger.debug('Host $host:$port is not reachable: $e');
      return false;
    }
  }

  /// Gets network quality description based on latency
  Future<NetworkQuality> getNetworkQuality() async {
    try {
      final connected = await isConnected;
      if (!connected) return NetworkQuality.none;

      final latency = await measureLatency();
      if (latency == null) return NetworkQuality.unknown;

      if (latency.inMilliseconds < 50) {
        return NetworkQuality.excellent;
      } else if (latency.inMilliseconds < 100) {
        return NetworkQuality.good;
      } else if (latency.inMilliseconds < 200) {
        return NetworkQuality.fair;
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      _logger.warning('Network quality check failed', e);
      return NetworkQuality.unknown;
    }
  }
}

/// Network quality levels
enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  none,
  unknown,
}

extension NetworkQualityExtension on NetworkQuality {
  String get description {
    switch (this) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.none:
        return 'No Connection';
      case NetworkQuality.unknown:
        return 'Unknown';
    }
  }

  bool get isGoodEnoughForHeavyOperations {
    switch (this) {
      case NetworkQuality.excellent:
      case NetworkQuality.good:
        return true;
      case NetworkQuality.fair:
      case NetworkQuality.poor:
      case NetworkQuality.none:
      case NetworkQuality.unknown:
        return false;
    }
  }
}
