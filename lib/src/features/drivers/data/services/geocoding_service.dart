import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for geocoding addresses to coordinates with caching
/// Supports multiple geocoding providers with fallback mechanisms
class GeocodingService {
  static const String _cachePrefix = 'geocoding_cache_';
  static const Duration _cacheExpiry = Duration(days: 30);

  // Geocoding providers configuration
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  // Rate limiting
  static DateTime? _lastNominatimRequest;
  static const Duration _nominatimRateLimit = Duration(seconds: 1);
  
  final SharedPreferences _prefs;
  final http.Client _httpClient;
  
  GeocodingService({
    required SharedPreferences prefs,
    http.Client? httpClient,
  }) : _prefs = prefs,
       _httpClient = httpClient ?? http.Client();

  /// Geocode an address to coordinates with caching
  Future<GeocodingResult?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) {
      debugPrint('GeocodingService: Empty address provided');
      return null;
    }
    
    final normalizedAddress = _normalizeAddress(address);
    debugPrint('GeocodingService: Geocoding address: $normalizedAddress');
    
    // Check cache first
    final cachedResult = await _getCachedResult(normalizedAddress);
    if (cachedResult != null) {
      debugPrint('GeocodingService: Using cached result for: $normalizedAddress');
      return cachedResult;
    }
    
    // Try geocoding with fallback providers
    GeocodingResult? result;
    
    // Try Nominatim (OpenStreetMap) first - free but rate limited
    try {
      result = await _geocodeWithNominatim(normalizedAddress);
      if (result != null) {
        await _cacheResult(normalizedAddress, result);
        return result;
      }
    } catch (e) {
      debugPrint('GeocodingService: Nominatim failed: $e');
    }
    
    // Fallback to PositionStack (requires API key)
    try {
      result = await _geocodeWithPositionStack(normalizedAddress);
      if (result != null) {
        await _cacheResult(normalizedAddress, result);
        return result;
      }
    } catch (e) {
      debugPrint('GeocodingService: PositionStack failed: $e');
    }
    
    // If all providers fail, return a default location (Kuala Lumpur city center)
    debugPrint('GeocodingService: All providers failed, using default location');
    final defaultResult = GeocodingResult(
      latitude: 3.1390,
      longitude: 101.6869,
      formattedAddress: 'Kuala Lumpur, Malaysia (Default)',
      accuracy: GeocodingAccuracy.city,
      provider: 'default',
    );
    
    // Cache the default result with shorter expiry
    await _cacheResult(normalizedAddress, defaultResult, Duration(hours: 1));
    return defaultResult;
  }
  
  /// Reverse geocode coordinates to address
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      // Use Nominatim for reverse geocoding
      await _respectRateLimit();
      
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'
      );
      
      final response = await _httpClient.get(
        url,
        headers: {
          'User-Agent': 'GigaEats-Driver-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      debugPrint('GeocodingService: Reverse geocoding failed: $e');
    }
    
    return null;
  }
  
  /// Geocode using Nominatim (OpenStreetMap)
  Future<GeocodingResult?> _geocodeWithNominatim(String address) async {
    await _respectRateLimit();
    
    final url = Uri.parse(
      '$_nominatimBaseUrl/search?format=json&q=${Uri.encodeComponent(address)}&limit=1&addressdetails=1&countrycodes=my'
    );
    
    final response = await _httpClient.get(
      url,
      headers: {
        'User-Agent': 'GigaEats-Driver-App/1.0',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body);
      if (results.isNotEmpty) {
        final result = results.first;
        return GeocodingResult(
          latitude: double.parse(result['lat']),
          longitude: double.parse(result['lon']),
          formattedAddress: result['display_name'],
          accuracy: _parseNominatimAccuracy(result),
          provider: 'nominatim',
        );
      }
    }
    
    return null;
  }
  
  /// Geocode using PositionStack (requires API key)
  Future<GeocodingResult?> _geocodeWithPositionStack(String address) async {
    // This would require an API key from PositionStack
    // For now, return null to skip this provider
    // TODO: Implement PositionStack geocoding with API key
    return null;
  }
  
  /// Respect rate limiting for Nominatim
  Future<void> _respectRateLimit() async {
    if (_lastNominatimRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastNominatimRequest!);
      if (timeSinceLastRequest < _nominatimRateLimit) {
        final waitTime = _nominatimRateLimit - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
    _lastNominatimRequest = DateTime.now();
  }
  
  /// Normalize address for consistent caching
  String _normalizeAddress(String address) {
    return address
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s,.-]'), '');
  }
  
  /// Get cached geocoding result
  Future<GeocodingResult?> _getCachedResult(String address) async {
    try {
      final cacheKey = '$_cachePrefix${address.hashCode}';
      final cachedData = _prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        final cachedAt = DateTime.parse(data['cached_at']);
        
        // Check if cache is still valid
        if (DateTime.now().difference(cachedAt) < _cacheExpiry) {
          return GeocodingResult.fromJson(data['result']);
        } else {
          // Remove expired cache
          await _prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      debugPrint('GeocodingService: Error reading cache: $e');
    }
    
    return null;
  }
  
  /// Cache geocoding result
  Future<void> _cacheResult(String address, GeocodingResult result, [Duration? customExpiry]) async {
    try {
      final cacheKey = '$_cachePrefix${address.hashCode}';
      final cacheData = {
        'result': result.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(customExpiry ?? _cacheExpiry).toIso8601String(),
      };
      
      await _prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      debugPrint('GeocodingService: Error caching result: $e');
    }
  }
  
  /// Parse accuracy from Nominatim result
  GeocodingAccuracy _parseNominatimAccuracy(Map<String, dynamic> result) {
    final type = result['type'] as String?;
    
    if (type == 'house' || type == 'building') {
      return GeocodingAccuracy.building;
    } else if (type == 'road' || type == 'street') {
      return GeocodingAccuracy.street;
    } else if (type == 'suburb' || type == 'neighbourhood') {
      return GeocodingAccuracy.neighborhood;
    } else if (type == 'city' || type == 'town' || type == 'village') {
      return GeocodingAccuracy.city;
    } else {
      return GeocodingAccuracy.approximate;
    }
  }
  
  /// Clear all cached results
  Future<void> clearCache() async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        await _prefs.remove(key);
      }
      debugPrint('GeocodingService: Cache cleared');
    } catch (e) {
      debugPrint('GeocodingService: Error clearing cache: $e');
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      int validEntries = 0;
      int expiredEntries = 0;
      
      for (final key in keys) {
        final cachedData = _prefs.getString(key);
        if (cachedData != null) {
          try {
            final data = json.decode(cachedData);
            final cachedAt = DateTime.parse(data['cached_at']);
            
            if (DateTime.now().difference(cachedAt) < _cacheExpiry) {
              validEntries++;
            } else {
              expiredEntries++;
            }
          } catch (e) {
            expiredEntries++;
          }
        }
      }
      
      return {
        'total_entries': keys.length,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
        'cache_hit_potential': validEntries / (validEntries + expiredEntries),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// Geocoding result model
class GeocodingResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final GeocodingAccuracy accuracy;
  final String provider;
  
  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.accuracy,
    required this.provider,
  });
  
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'formatted_address': formattedAddress,
    'accuracy': accuracy.name,
    'provider': provider,
  };
  
  factory GeocodingResult.fromJson(Map<String, dynamic> json) => GeocodingResult(
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    formattedAddress: json['formatted_address'],
    accuracy: GeocodingAccuracy.values.firstWhere(
      (a) => a.name == json['accuracy'],
      orElse: () => GeocodingAccuracy.approximate,
    ),
    provider: json['provider'],
  );
}

/// Geocoding accuracy levels
enum GeocodingAccuracy {
  building,     // House/building level
  street,       // Street level
  neighborhood, // Neighborhood level
  city,         // City level
  approximate,  // Approximate location
}
