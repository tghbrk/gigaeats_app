import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Simple test screen to validate Google Maps API key and basic functionality
class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key});

  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  GoogleMapController? _controller;
  bool _mapCreated = false;
  String _status = 'Initializing...';

  // Test location: Mountain View, CA (Google HQ)
  static const LatLng _testLocation = LatLng(37.4219983, -122.084);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Test'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Status card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _mapCreated ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _mapCreated ? Colors.green : Colors.orange,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Status: $_status'),
                Text('Map Created: $_mapCreated'),
                Text('Controller: ${_controller != null ? 'Available' : 'Null'}'),
              ],
            ),
          ),
          
          // Map container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    debugPrint('🗺️ TEST: Map created successfully');
                    setState(() {
                      _controller = controller;
                      _mapCreated = true;
                      _status = 'Map created successfully';
                    });
                  },
                  initialCameraPosition: const CameraPosition(
                    target: _testLocation,
                    zoom: 15.0,
                  ),
                  markers: {
                    const Marker(
                      markerId: MarkerId('test_marker'),
                      position: _testLocation,
                      infoWindow: InfoWindow(
                        title: 'Test Location',
                        snippet: 'Google HQ - Mountain View, CA',
                      ),
                    ),
                  },
                  onTap: (LatLng position) {
                    debugPrint('🗺️ TEST: Map tapped at $position');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onCameraMove: (CameraPosition position) {
                    debugPrint('🗺️ TEST: Camera moved to ${position.target}');
                  },
                  onCameraIdle: () {
                    debugPrint('🗺️ TEST: Camera movement finished');
                    setState(() {
                      _status = 'Map is interactive and working';
                    });
                  },
                  // Minimal configuration for testing
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  compassEnabled: true,
                  trafficEnabled: false,
                  buildingsEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),
          
          // Test buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testMapFunctionality,
                    child: const Text('Test Map'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showApiKeyInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('API Key Info'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _testMapFunctionality() async {
    if (_controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map controller not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Test camera movement
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_testLocation, 18.0),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map functionality test passed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('🗺️ TEST ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Map test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApiKeyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Maps API Key Checklist'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Required APIs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('✓ Maps SDK for Android'),
              Text('✓ Maps SDK for iOS'),
              Text('✓ Directions API (optional)'),
              SizedBox(height: 16),
              Text(
                'Common Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• API key restrictions too strict'),
              Text('• Billing not enabled'),
              Text('• Wrong package name in restrictions'),
              Text('• API quotas exceeded'),
              SizedBox(height: 16),
              Text(
                'If map shows gray tiles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Check Google Cloud Console'),
              Text('• Verify API key in AndroidManifest.xml'),
              Text('• Enable billing for the project'),
              Text('• Check API usage quotas'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
