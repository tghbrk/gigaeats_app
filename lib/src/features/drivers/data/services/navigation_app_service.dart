import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import for device_apps
// import 'package:device_apps/device_apps.dart';

/// Navigation app option
class NavigationApp {
  final String id;
  final String name;
  final String iconAsset;
  final bool isInstalled;
  final bool isDefault;
  final List<String> supportedFeatures;

  const NavigationApp({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.isInstalled,
    this.isDefault = false,
    this.supportedFeatures = const [],
  });

  NavigationApp copyWith({
    String? id,
    String? name,
    String? iconAsset,
    bool? isInstalled,
    bool? isDefault,
    List<String>? supportedFeatures,
  }) {
    return NavigationApp(
      id: id ?? this.id,
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      isInstalled: isInstalled ?? this.isInstalled,
      isDefault: isDefault ?? this.isDefault,
      supportedFeatures: supportedFeatures ?? this.supportedFeatures,
    );
  }
}

/// Route preferences for navigation
class RoutePreferences {
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final String travelMode; // driving, walking, bicycling, transit
  final String units; // metric, imperial

  const RoutePreferences({
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = false,
    this.travelMode = 'driving',
    this.units = 'metric',
  });

  Map<String, dynamic> toMap() {
    return {
      'avoidTolls': avoidTolls,
      'avoidHighways': avoidHighways,
      'avoidFerries': avoidFerries,
      'travelMode': travelMode,
      'units': units,
    };
  }

  factory RoutePreferences.fromMap(Map<String, dynamic> map) {
    return RoutePreferences(
      avoidTolls: map['avoidTolls'] ?? false,
      avoidHighways: map['avoidHighways'] ?? false,
      avoidFerries: map['avoidFerries'] ?? false,
      travelMode: map['travelMode'] ?? 'driving',
      units: map['units'] ?? 'metric',
    );
  }
}

/// Service for managing navigation app selection and deep linking
class NavigationAppService {
  static const String _prefsKey = 'preferred_navigation_app';
  
  /// Get list of available navigation apps
  static Future<List<NavigationApp>> getAvailableNavigationApps() async {
    final apps = [
      NavigationApp(
        id: 'google_maps',
        name: 'Google Maps',
        iconAsset: 'assets/icons/google_maps.png',
        isInstalled: await _isAppInstalled('com.google.android.apps.maps'),
        supportedFeatures: ['traffic', 'avoid_tolls', 'avoid_highways', 'real_time_updates'],
      ),
      NavigationApp(
        id: 'waze',
        name: 'Waze',
        iconAsset: 'assets/icons/waze.png',
        isInstalled: await _isAppInstalled('com.waze'),
        supportedFeatures: ['traffic', 'real_time_updates', 'community_alerts'],
      ),
      NavigationApp(
        id: 'in_app',
        name: 'In-App Navigation',
        iconAsset: 'assets/icons/in_app_nav.png',
        isInstalled: true, // Always available
        isDefault: true,
        supportedFeatures: ['basic_navigation', 'route_preview'],
      ),
    ];

    // Add Malaysian-specific navigation apps
    if (Platform.isAndroid) {
      apps.addAll([
        NavigationApp(
          id: 'here_maps',
          name: 'HERE WeGo',
          iconAsset: 'assets/icons/here_maps.png',
          isInstalled: await _isAppInstalled('com.here.app.maps'),
          supportedFeatures: ['offline_maps', 'public_transport'],
        ),
        NavigationApp(
          id: 'maps_me',
          name: 'MAPS.ME',
          iconAsset: 'assets/icons/maps_me.png',
          isInstalled: await _isAppInstalled('com.mapswithme.maps.pro'),
          supportedFeatures: ['offline_maps', 'hiking_trails'],
        ),
      ]);
    }

    // Sort by installation status and name
    apps.sort((a, b) {
      if (a.isInstalled && !b.isInstalled) return -1;
      if (!a.isInstalled && b.isInstalled) return 1;
      return a.name.compareTo(b.name);
    });

    return apps;
  }

  /// Launch navigation to destination using selected app with enhanced options
  static Future<bool> launchNavigation({
    required String appId,
    required LatLng destination,
    LatLng? origin,
    String? destinationName,
    RoutePreferences? preferences,
    bool enableFallback = true,
  }) async {
    try {
      debugPrint('🧭 NavigationAppService: Launching $appId navigation to ${destination.latitude},${destination.longitude}');

      final prefs = preferences ?? const RoutePreferences();
      bool success = false;

      switch (appId) {
        case 'google_maps':
          success = await _launchGoogleMaps(destination, origin, destinationName, prefs);
          break;
        case 'waze':
          success = await _launchWaze(destination, destinationName, prefs);
          break;
        case 'here_maps':
          success = await _launchHereMaps(destination, destinationName, prefs);
          break;
        case 'maps_me':
          success = await _launchMapsMe(destination, destinationName, prefs);
          break;
        case 'in_app':
          // Return false to indicate in-app navigation should be used
          return false;
        default:
          debugPrint('🧭 NavigationAppService: Unknown app ID: $appId');
          success = false;
      }

      // Fallback handling
      if (!success && enableFallback) {
        debugPrint('🧭 NavigationAppService: Primary app failed, attempting fallback');
        return await _attemptFallbackNavigation(destination, origin, destinationName, prefs, appId);
      }

      return success;
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error launching navigation: $e');

      // Fallback on error
      if (enableFallback) {
        return await _attemptFallbackNavigation(destination, origin, destinationName, preferences, appId);
      }

      return false;
    }
  }

  /// Attempt fallback navigation when primary app fails
  static Future<bool> _attemptFallbackNavigation(
    LatLng destination,
    LatLng? origin,
    String? destinationName,
    RoutePreferences? preferences,
    String failedAppId,
  ) async {
    try {
      final availableApps = await getAvailableNavigationApps();
      final installedApps = availableApps.where((app) => app.isInstalled && app.id != failedAppId).toList();

      // Try Google Maps first as it's most reliable
      if (installedApps.any((app) => app.id == 'google_maps')) {
        debugPrint('🧭 NavigationAppService: Fallback to Google Maps');
        return await _launchGoogleMaps(destination, origin, destinationName, preferences ?? const RoutePreferences());
      }

      // Try other installed apps
      for (final app in installedApps) {
        if (app.id == 'in_app') continue; // Skip in-app for fallback

        debugPrint('🧭 NavigationAppService: Fallback to ${app.name}');
        final success = await launchNavigation(
          appId: app.id,
          destination: destination,
          origin: origin,
          destinationName: destinationName,
          preferences: preferences,
          enableFallback: false, // Prevent infinite recursion
        );

        if (success) return true;
      }

      // Final fallback to web-based Google Maps
      debugPrint('🧭 NavigationAppService: Final fallback to web Google Maps');
      return await _launchWebGoogleMaps(destination, origin, destinationName);

    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error in fallback navigation: $e');
      return false;
    }
  }

  /// Launch Google Maps navigation with route preferences
  static Future<bool> _launchGoogleMaps(
    LatLng destination,
    LatLng? origin,
    String? destinationName,
    RoutePreferences preferences,
  ) async {
    try {
      String url;

      if (origin != null) {
        // Navigation with specific origin
        url = 'https://www.google.com/maps/dir/'
            '${origin.latitude},${origin.longitude}/'
            '${destination.latitude},${destination.longitude}';
      } else {
        // Navigation from current location
        url = 'https://www.google.com/maps/dir/?api=1&'
            'destination=${destination.latitude},${destination.longitude}';

        if (destinationName != null) {
          url += '&destination_place_id=${Uri.encodeComponent(destinationName)}';
        }
      }

      // Add route preferences
      final params = <String>[];
      if (preferences.avoidTolls) params.add('avoid=tolls');
      if (preferences.avoidHighways) params.add('avoid=highways');
      if (preferences.avoidFerries) params.add('avoid=ferries');
      if (preferences.travelMode != 'driving') params.add('travelmode=${preferences.travelMode}');

      if (params.isNotEmpty) {
        url += url.contains('?') ? '&' : '?';
        url += params.join('&');
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error launching Google Maps: $e');
    }
    return false;
  }

  /// Launch Waze navigation with route preferences
  static Future<bool> _launchWaze(LatLng destination, String? destinationName, RoutePreferences preferences) async {
    try {
      String url = 'https://waze.com/ul?'
          'll=${destination.latitude},${destination.longitude}&'
          'navigate=yes';

      // Waze has limited preference support via URL
      if (preferences.avoidTolls) {
        url += '&avoid=tolls';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error launching Waze: $e');
    }
    return false;
  }

  /// Launch HERE Maps navigation with route preferences
  static Future<bool> _launchHereMaps(LatLng destination, String? destinationName, RoutePreferences preferences) async {
    try {
      String url = 'https://share.here.com/r/'
          '${destination.latitude},${destination.longitude}';

      // HERE Maps has limited URL parameter support
      final params = <String>[];
      if (preferences.travelMode == 'walking') params.add('m=w');
      if (preferences.travelMode == 'transit') params.add('m=r');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error launching HERE Maps: $e');
    }
    return false;
  }

  /// Launch MAPS.ME navigation with route preferences
  static Future<bool> _launchMapsMe(LatLng destination, String? destinationName, RoutePreferences preferences) async {
    try {
      String url = 'mapsme://route?'
          'sll=${destination.latitude},${destination.longitude}&'
          'saddr=Current Location&'
          'daddr=${destinationName ?? 'Destination'}';

      // Add travel mode
      switch (preferences.travelMode) {
        case 'walking':
          url += '&type=pedestrian';
          break;
        case 'bicycling':
          url += '&type=bicycle';
          break;
        default:
          url += '&type=vehicle';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error launching MAPS.ME: $e');
    }
    return false;
  }

  /// Launch web-based Google Maps as final fallback
  static Future<bool> _launchWebGoogleMaps(LatLng destination, LatLng? origin, String? destinationName) async {
    try {
      String url;

      if (origin != null) {
        url = 'https://www.google.com/maps/dir/'
            '${origin.latitude},${origin.longitude}/'
            '${destination.latitude},${destination.longitude}';
      } else {
        url = 'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error launching web Google Maps: $e');
    }
    return false;
  }

  /// Check if an app is installed on the device
  static Future<bool> _isAppInstalled(String packageName) async {
    try {
      // Use URL scheme checking for all platforms for simplicity
      return await _checkAppByUrlScheme(packageName);
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error checking app installation: $e');
    }
    return false;
  }

  /// Check app availability by attempting to launch URL scheme
  static Future<bool> _checkAppByUrlScheme(String packageName) async {
    try {
      String urlScheme;

      switch (packageName) {
        case 'com.google.android.apps.maps':
          urlScheme = 'comgooglemaps://';
          break;
        case 'com.waze':
          urlScheme = 'waze://';
          break;
        case 'com.here.app.maps':
          urlScheme = 'here-route://';
          break;
        case 'com.mapswithme.maps.pro':
          urlScheme = 'mapsme://';
          break;
        default:
          return false;
      }

      final uri = Uri.parse(urlScheme);
      return await canLaunchUrl(uri);
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error checking URL scheme: $e');
      return false;
    }
  }

  /// Get user's preferred navigation app
  static Future<String> getPreferredNavigationApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey) ?? 'in_app';
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error getting preferred app: $e');
      return 'in_app'; // Default to in-app navigation
    }
  }

  /// Set user's preferred navigation app
  static Future<void> setPreferredNavigationApp(String appId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, appId);
      debugPrint('🧭 NavigationAppService: Setting preferred app to $appId');
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error setting preferred app: $e');
    }
  }

  /// Get route preferences from storage
  static Future<RoutePreferences> getRoutePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = <String, dynamic>{};

      prefsMap['avoidTolls'] = prefs.getBool('route_avoid_tolls') ?? false;
      prefsMap['avoidHighways'] = prefs.getBool('route_avoid_highways') ?? false;
      prefsMap['avoidFerries'] = prefs.getBool('route_avoid_ferries') ?? false;
      prefsMap['travelMode'] = prefs.getString('route_travel_mode') ?? 'driving';
      prefsMap['units'] = prefs.getString('route_units') ?? 'metric';

      return RoutePreferences.fromMap(prefsMap);
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error getting route preferences: $e');
      return const RoutePreferences();
    }
  }

  /// Save route preferences to storage
  static Future<void> saveRoutePreferences(RoutePreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = preferences.toMap();

      await prefs.setBool('route_avoid_tolls', prefsMap['avoidTolls']);
      await prefs.setBool('route_avoid_highways', prefsMap['avoidHighways']);
      await prefs.setBool('route_avoid_ferries', prefsMap['avoidFerries']);
      await prefs.setString('route_travel_mode', prefsMap['travelMode']);
      await prefs.setString('route_units', prefsMap['units']);

      debugPrint('🧭 NavigationAppService: Route preferences saved');
    } catch (e) {
      debugPrint('🧭 NavigationAppService: Error saving route preferences: $e');
    }
  }

  /// Get deep link URL for navigation app
  static String? getDeepLinkUrl({
    required String appId,
    required LatLng destination,
    LatLng? origin,
    String? destinationName,
  }) {
    switch (appId) {
      case 'google_maps':
        if (origin != null) {
          return 'https://www.google.com/maps/dir/'
              '${origin.latitude},${origin.longitude}/'
              '${destination.latitude},${destination.longitude}';
        } else {
          return 'https://www.google.com/maps/dir/?api=1&'
              'destination=${destination.latitude},${destination.longitude}';
        }
      case 'waze':
        return 'https://waze.com/ul?'
            'll=${destination.latitude},${destination.longitude}&'
            'navigate=yes';
      case 'here_maps':
        return 'https://share.here.com/r/'
            '${destination.latitude},${destination.longitude}';
      case 'maps_me':
        return 'mapsme://route?'
            'sll=${destination.latitude},${destination.longitude}&'
            'saddr=Current Location&'
            'daddr=${destinationName ?? 'Destination'}&'
            'type=vehicle';
      default:
        return null;
    }
  }

  /// Check if navigation app supports traffic information
  static bool supportsTrafficInfo(String appId) {
    switch (appId) {
      case 'google_maps':
      case 'waze':
        return true;
      default:
        return false;
    }
  }

  /// Check if navigation app supports offline maps
  static bool supportsOfflineMaps(String appId) {
    switch (appId) {
      case 'here_maps':
      case 'maps_me':
      case 'in_app':
        return true;
      default:
        return false;
    }
  }
}
