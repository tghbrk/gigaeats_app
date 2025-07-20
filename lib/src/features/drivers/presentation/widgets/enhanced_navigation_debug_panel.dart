import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/navigation_models.dart';
import '../providers/enhanced_navigation_provider.dart';

/// Debug panel for testing enhanced navigation service functionality
/// This widget demonstrates the integration of in-app navigation, voice guidance, and traffic-aware routing
class EnhancedNavigationDebugPanel extends ConsumerStatefulWidget {
  final String orderId;
  final String? batchId;

  const EnhancedNavigationDebugPanel({
    super.key,
    required this.orderId,
    this.batchId,
  });

  @override
  ConsumerState<EnhancedNavigationDebugPanel> createState() => _EnhancedNavigationDebugPanelState();
}

class _EnhancedNavigationDebugPanelState extends ConsumerState<EnhancedNavigationDebugPanel> {
  bool _isExpanded = false;
  NavigationPreferences _preferences = NavigationPreferences.defaults();

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(enhancedNavigationProvider);
    final navigationNotifier = ref.read(enhancedNavigationProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: const Text(
          '🧭 Enhanced Navigation Debug Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          navigationState.isNavigating 
            ? '✅ Navigation Active'
            : '❌ Navigation Inactive',
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Section
                _buildStatusSection(navigationState),
                const SizedBox(height: 16),
                
                // Controls Section
                _buildControlsSection(navigationState, navigationNotifier),
                const SizedBox(height: 16),
                
                // Current Instruction Section
                if (navigationState.currentInstruction != null) ...[
                  _buildInstructionSection(navigationState),
                  const SizedBox(height: 16),
                ],
                
                // Route Information Section
                if (navigationState.currentSession != null) ...[
                  _buildRouteSection(navigationState),
                  const SizedBox(height: 16),
                ],
                
                // Preferences Section
                _buildPreferencesSection(navigationNotifier),
                const SizedBox(height: 16),
                
                // Traffic Alerts Section
                if (navigationState.recentTrafficAlerts.isNotEmpty) ...[
                  _buildTrafficAlertsSection(navigationState),
                  const SizedBox(height: 16),
                ],
                
                // Error Section
                if (navigationState.error != null) ...[
                  _buildErrorSection(navigationState),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(EnhancedNavigationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📍 Navigation Status', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoRow('Status', state.isNavigating ? 'Active' : 'Inactive'),
        _buildInfoRow('Voice Enabled', state.isVoiceEnabled ? 'Yes' : 'No'),
        _buildInfoRow('Order ID', widget.orderId),
        if (widget.batchId != null) _buildInfoRow('Batch ID', widget.batchId!),
        if (state.remainingDistance != null)
          _buildInfoRow('Remaining Distance', ref.read(remainingDistanceTextProvider) ?? 'Unknown'),
        if (state.estimatedArrival != null)
          _buildInfoRow('ETA', ref.read(estimatedArrivalTextProvider) ?? 'Unknown'),
        if (state.currentSession != null)
          _buildInfoRow('Progress', '${ref.read(navigationProgressProvider).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildControlsSection(EnhancedNavigationState state, EnhancedNavigationNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎮 Controls', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: state.isNavigating ? null : () => _startNavigation(notifier),
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
            ),
            ElevatedButton.icon(
              onPressed: !state.isNavigating ? null : () => notifier.stopNavigation(),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
            ElevatedButton.icon(
              onPressed: !state.isNavigating || state.currentSession?.status != NavigationSessionStatus.active 
                ? null 
                : () => notifier.pauseNavigation(),
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
            ),
            ElevatedButton.icon(
              onPressed: !state.isNavigating || state.currentSession?.status != NavigationSessionStatus.paused 
                ? null 
                : () => notifier.resumeNavigation(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionSection(EnhancedNavigationState state) {
    final instruction = state.currentInstruction!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🗣️ Current Instruction', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(_getInstructionIcon(instruction.type), size: 20),
                    const SizedBox(width: 8),
                    Text('${instruction.distanceText} • ${instruction.durationText}'),
                  ],
                ),
                if (instruction.streetName != null) ...[
                  const SizedBox(height: 4),
                  Text('Street: ${instruction.streetName}', style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection(EnhancedNavigationState state) {
    final route = state.currentSession!.route;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🗺️ Route Information', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoRow('Total Distance', route.totalDistanceText),
        _buildInfoRow('Total Duration', route.totalDurationText),
        _buildInfoRow('Traffic Delay', route.trafficDelayText),
        _buildInfoRow('Traffic Condition', route.overallTrafficCondition.name),
        _buildInfoRow('Instructions', route.instructions.length.toString()),
        if (route.warnings.isNotEmpty)
          _buildInfoRow('Warnings', route.warnings.length.toString()),
      ],
    );
  }

  Widget _buildPreferencesSection(EnhancedNavigationNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚙️ Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Voice Guidance'),
          value: _preferences.voiceGuidanceEnabled,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences.copyWith(voiceGuidanceEnabled: value);
            });
            notifier.updatePreferences(_preferences);
          },
        ),
        SwitchListTile(
          title: const Text('Traffic Alerts'),
          value: _preferences.trafficAlertsEnabled,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences.copyWith(trafficAlertsEnabled: value);
            });
            notifier.updatePreferences(_preferences);
          },
        ),
        ListTile(
          title: const Text('Language'),
          subtitle: Text(_preferences.language),
          trailing: DropdownButton<String>(
            value: _preferences.language,
            items: const [
              DropdownMenuItem(value: 'en-MY', child: Text('English (MY)')),
              DropdownMenuItem(value: 'ms-MY', child: Text('Bahasa Malaysia')),
              DropdownMenuItem(value: 'zh-CN', child: Text('中文')),
              DropdownMenuItem(value: 'ta-MY', child: Text('தமிழ்')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _preferences = _preferences.copyWith(language: value);
                });
                notifier.updatePreferences(_preferences);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficAlertsSection(EnhancedNavigationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🚦 Recent Traffic Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...state.recentTrafficAlerts.take(3).map((alert) => Card(
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text(alert),
            subtitle: Text('Just now'),
          ),
        )),
      ],
    );
  }

  Widget _buildErrorSection(EnhancedNavigationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('❌ Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            state.error!,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getInstructionIcon(NavigationInstructionType type) {
    switch (type) {
      case NavigationInstructionType.turnLeft:
        return Icons.turn_left;
      case NavigationInstructionType.turnRight:
        return Icons.turn_right;
      case NavigationInstructionType.straight:
        return Icons.straight;
      case NavigationInstructionType.uturnLeft:
      case NavigationInstructionType.uturnRight:
        return Icons.u_turn_left;
      case NavigationInstructionType.destination:
        return Icons.location_on;
      default:
        return Icons.navigation;
    }
  }

  Future<void> _startNavigation(EnhancedNavigationNotifier notifier) async {
    try {
      // Get current location as origin
      final currentPosition = await Geolocator.getCurrentPosition();
      final origin = LatLng(currentPosition.latitude, currentPosition.longitude);
      
      // Use a test destination (1km away)
      final destination = LatLng(
        currentPosition.latitude + 0.009, // ~1km north
        currentPosition.longitude,
      );
      
      await notifier.startNavigation(
        origin: origin,
        destination: destination,
        orderId: widget.orderId,
        batchId: widget.batchId,
        destinationName: 'Test Destination',
        preferences: _preferences,
      );
    } catch (e) {
      debugPrint('Error starting navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting navigation: $e')),
      );
    }
  }
}
