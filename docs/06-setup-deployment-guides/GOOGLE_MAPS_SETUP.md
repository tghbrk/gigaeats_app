# Google Maps Integration Setup Guide

This guide explains how to set up Google Maps integration for the GigaEats driver mobile interface.

## Prerequisites

1. Google Cloud Platform account
2. Google Maps Platform API access
3. Flutter development environment

## Step 1: Create Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API (for route calculation)
   - Places API (optional, for address autocomplete)

4. Create credentials:
   - Go to "Credentials" in the left sidebar
   - Click "Create Credentials" → "API Key"
   - Copy the generated API key

## Step 2: Configure API Key Restrictions

For security, restrict your API key:

1. Click on your API key in the credentials list
2. Under "Application restrictions":
   - For Android: Select "Android apps" and add your package name and SHA-1 fingerprint
   - For iOS: Select "iOS apps" and add your bundle identifier

3. Under "API restrictions":
   - Select "Restrict key"
   - Choose the APIs you enabled above

## Step 3: Configure Flutter App

### Android Configuration

1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

### iOS Configuration

1. Open `ios/Runner/Info.plist`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<key>GMSApiKey</key>
<string>YOUR_ACTUAL_API_KEY_HERE</string>
```

## Step 4: Test the Integration

1. Run the app on a device or emulator
2. Navigate to the driver dashboard
3. Go to the map screen
4. Verify that:
   - The map loads correctly
   - Current location is displayed
   - Markers appear for pickup and delivery locations
   - Route calculation works

## Features Implemented

### Core Map Features
- **Interactive Google Maps**: Pan, zoom, and navigate the map
- **Real-time Location Tracking**: Driver's current location with GPS accuracy
- **Route Visualization**: Polyline showing delivery route
- **Custom Markers**: Different markers for current location, pickup, and delivery points

### Driver-Specific Features
- **Location Tracking Toggle**: Start/stop location tracking
- **Route Information**: Distance and estimated time to destination
- **Navigation Integration**: Quick access to external navigation apps
- **Emergency Features**: Quick access to emergency contacts

### Real-time Updates
- **Live Location Updates**: Driver location updates every 15 seconds
- **Database Synchronization**: Location data stored in Supabase
- **Order Integration**: Map automatically loads active delivery orders

## Technical Implementation

### State Management
- Uses Riverpod for state management
- `DriverMapProvider` handles all map-related state
- Real-time updates through Supabase subscriptions

### Location Services
- `DriverLocationService` handles GPS tracking
- `RouteService` calculates routes and distances
- Proper permission handling for location access

### Database Integration
- Location data stored in `drivers` and `delivery_tracking` tables
- Real-time updates via Supabase real-time subscriptions
- RLS policies ensure data security

## Troubleshooting

### Common Issues

1. **Map not loading**
   - Check API key configuration
   - Verify API restrictions
   - Ensure Maps SDK is enabled

2. **Location not updating**
   - Check location permissions
   - Verify GPS is enabled on device
   - Check network connectivity

3. **Route calculation failing**
   - Verify Directions API is enabled
   - Check API key restrictions
   - Ensure valid coordinates

### Debug Tips

1. Check Flutter logs for error messages
2. Verify API key in Google Cloud Console
3. Test on physical device for GPS functionality
4. Check Supabase logs for database issues

## Security Considerations

1. **API Key Security**
   - Never commit API keys to version control
   - Use environment variables or secure storage
   - Implement proper API key restrictions

2. **Location Privacy**
   - Only track location during active deliveries
   - Implement proper user consent
   - Follow data protection regulations

3. **Database Security**
   - Use RLS policies for data access
   - Encrypt sensitive location data
   - Implement proper authentication

## Performance Optimization

1. **Location Updates**
   - Adjust update frequency based on needs
   - Use distance filters to reduce updates
   - Implement battery optimization

2. **Map Rendering**
   - Limit number of markers on map
   - Use clustering for multiple locations
   - Optimize polyline complexity

3. **Data Usage**
   - Cache map tiles when possible
   - Minimize API calls
   - Use efficient data structures

## Future Enhancements

1. **Advanced Navigation**
   - Turn-by-turn directions
   - Voice navigation
   - Traffic-aware routing

2. **Enhanced Tracking**
   - Geofencing for delivery zones
   - Speed monitoring
   - Route optimization

3. **Analytics**
   - Delivery performance metrics
   - Route efficiency analysis
   - Driver behavior insights

## Support

For issues with Google Maps integration:
1. Check the [Google Maps Platform documentation](https://developers.google.com/maps/documentation)
2. Review Flutter Google Maps plugin documentation
3. Contact the development team for app-specific issues

## Cost Considerations

Google Maps Platform pricing:
- Maps SDK: $7 per 1,000 map loads
- Directions API: $5 per 1,000 requests
- Monitor usage in Google Cloud Console
- Set up billing alerts to avoid unexpected charges

For production deployment, consider:
- Implementing request caching
- Using map tiles efficiently
- Monitoring API usage patterns
