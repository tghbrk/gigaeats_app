/// Google services configuration for the GigaEats app
class GoogleConfig {
  // Google Maps API Key (configured in platform-specific files)
  // Android: android/app/src/main/AndroidManifest.xml
  // iOS: ios/Runner/Info.plist
  static const String mapsApiKey = 'AIzaSyByZXMaiBkbvTtWdnZyAJkNQtme7hOoeCE';
  
  // Google Maps configuration
  static const String mapsBaseUrl = 'https://maps.googleapis.com/maps/api';
  static const String directionsApiUrl = '$mapsBaseUrl/directions/json';
  static const String geocodingApiUrl = '$mapsBaseUrl/geocode/json';
  static const String elevationApiUrl = '$mapsBaseUrl/elevation/json';
  static const String placesApiUrl = '$mapsBaseUrl/place';
  
  // API request timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration routeCalculationTimeout = Duration(seconds: 45);
  
  // Rate limiting
  static const int maxRequestsPerSecond = 10;
  static const Duration rateLimitWindow = Duration(seconds: 1);
  
  // Default map settings
  static const double defaultZoom = 15.0;
  static const double routePreviewZoom = 12.0;
  static const double proximityZoom = 18.0;
  
  // Malaysia-specific defaults
  static const double defaultLatitude = 3.1390; // Kuala Lumpur
  static const double defaultLongitude = 101.6869;
  
  // Route calculation preferences
  static const String defaultTravelMode = 'driving';
  static const String defaultUnits = 'metric';
  static const String defaultLanguage = 'en';
  static const String defaultRegion = 'my'; // Malaysia
  
  // Traffic and route options
  static const bool includeTrafficByDefault = true;
  static const bool includeElevationByDefault = true;
  static const bool avoidTollsByDefault = false;
  static const bool avoidHighwaysByDefault = false;
  
  // Geocoding settings
  static const int maxGeocodingResults = 5;
  static const String geocodingComponentCountry = 'MY';
  
  // Places API settings
  static const int maxPlacesResults = 10;
  static const String placesLanguage = 'en';
  static const List<String> placesTypes = [
    'restaurant',
    'food',
    'meal_takeaway',
    'establishment',
  ];
  
  // Error handling
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  /// Check if Google Maps API key is configured
  static bool get isConfigured => mapsApiKey.isNotEmpty && mapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  
  /// Get API key for requests (with validation)
  static String? get apiKeyForRequests => isConfigured ? mapsApiKey : null;
  
  /// Get directions API URL with parameters
  static String getDirectionsUrl({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = defaultTravelMode,
    bool includeTraffic = includeTrafficByDefault,
    bool avoidTolls = avoidTollsByDefault,
    bool avoidHighways = avoidHighwaysByDefault,
  }) {
    final params = <String, String>{
      'origin': '$originLat,$originLng',
      'destination': '$destLat,$destLng',
      'mode': mode,
      'units': defaultUnits,
      'language': defaultLanguage,
      'region': defaultRegion,
      'key': mapsApiKey,
    };
    
    if (includeTraffic) {
      params['departure_time'] = 'now';
    }
    
    if (avoidTolls) {
      params['avoid'] = 'tolls';
    } else if (avoidHighways) {
      params['avoid'] = 'highways';
    }
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$directionsApiUrl?$queryString';
  }
  
  /// Get elevation API URL with parameters
  static String getElevationUrl({
    required List<String> locations,
  }) {
    final params = <String, String>{
      'locations': locations.join('|'),
      'key': mapsApiKey,
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$elevationApiUrl?$queryString';
  }
  
  /// Get geocoding API URL with parameters
  static String getGeocodingUrl({
    required String address,
  }) {
    final params = <String, String>{
      'address': address,
      'components': 'country:$geocodingComponentCountry',
      'language': defaultLanguage,
      'key': mapsApiKey,
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$geocodingApiUrl?$queryString';
  }
}
