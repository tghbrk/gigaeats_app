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
2. Navigate to the driver workflow screens
3. Test navigation features during order delivery
4. Verify that:
   - In-app navigation loads correctly during delivery
   - Turn-by-turn directions work properly
   - Route preview shows before navigation starts
   - External navigation app integration functions

## Features Implemented

### Navigation Features
- **In-App Navigation**: Full-screen turn-by-turn navigation during delivery
- **Route Preview**: Pre-navigation overview with distance and ETA
- **External Navigation**: Integration with Google Maps, Waze, and other navigation apps
- **Multi-Waypoint Navigation**: Support for batch delivery routes

### Driver Workflow Integration
- **Order-Based Navigation**: Navigation triggered during driver workflow steps
- **Real-time Location Tracking**: Driver's current location with GPS accuracy
- **Route Optimization**: Efficient routing for multiple deliveries
- **Voice Guidance**: Turn-by-turn voice instructions

### Real-time Updates
- **Live Location Updates**: Driver location updates during active deliveries
- **Database Synchronization**: Location data stored in Supabase
- **Order Integration**: Navigation integrated with order status transitions

> **Note**: The dashboard map feature has been removed as it didn't serve a functional purpose. Maps are now used specifically for navigation during the driver workflow. A future implementation may add a map feature for visualizing nearby orders.

## Technical Implementation

### State Management
- Uses Riverpod for state management
- `EnhancedNavigationProvider` handles navigation state
- `MultiOrderBatchProvider` manages batch delivery navigation
- Real-time updates through Supabase subscriptions

### Navigation Services
- `EnhancedNavigationService` handles in-app navigation
- `NavigationAppService` manages external navigation integration
- `RouteOptimizationService` calculates optimal routes for batch deliveries
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
