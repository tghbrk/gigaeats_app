import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/navigation_location_service.dart';
import '../../../../core/services/location_service.dart';

/// Widget that handles location permission requests with user-friendly UI
class LocationPermissionHandler extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  final bool showPermissionDialog;

  const LocationPermissionHandler({
    super.key,
    required this.child,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.showPermissionDialog = true,
  });

  @override
  ConsumerState<LocationPermissionHandler> createState() => _LocationPermissionHandlerState();
}

class _LocationPermissionHandlerState extends ConsumerState<LocationPermissionHandler> {
  bool _isCheckingPermissions = false;
  bool _hasCheckedPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermissions();
    });
  }

  Future<void> _checkLocationPermissions() async {
    if (_hasCheckedPermissions || _isCheckingPermissions) return;

    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final hasPermission = await LocationService.isLocationPermissionGranted();
      final serviceEnabled = await LocationService.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (widget.showPermissionDialog && mounted) {
          _showLocationServiceDialog();
        }
        widget.onPermissionDenied?.call();
      } else if (!hasPermission) {
        if (widget.showPermissionDialog && mounted) {
          _showLocationPermissionDialog();
        } else {
          final granted = await LocationService.requestLocationPermission();
          if (granted) {
            widget.onPermissionGranted?.call();
          } else {
            widget.onPermissionDenied?.call();
          }
        }
      } else {
        widget.onPermissionGranted?.call();
      }

      _hasCheckedPermissions = true;
    } catch (e) {
      debugPrint('LocationPermissionHandler: Error checking permissions: $e');
      widget.onPermissionDenied?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationServiceDialog(
        onEnablePressed: () async {
          Navigator.of(context).pop();
          final opened = await NavigationLocationService.openLocationSettings();
          if (!opened) {
            _showLocationServiceErrorDialog();
          }
        },
        onCancelPressed: () {
          Navigator.of(context).pop();
          widget.onPermissionDenied?.call();
        },
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        onGrantPressed: () async {
          Navigator.of(context).pop();
          final granted = await LocationService.requestLocationPermission();
          if (granted) {
            widget.onPermissionGranted?.call();
          } else {
            _showLocationPermissionDeniedDialog();
          }
        },
        onCancelPressed: () {
          Navigator.of(context).pop();
          widget.onPermissionDenied?.call();
        },
      ),
    );
  }

  void _showLocationPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => LocationPermissionDeniedDialog(
        onOpenSettingsPressed: () async {
          Navigator.of(context).pop();
          await NavigationLocationService.openAppSettings();
        },
        onCancelPressed: () {
          Navigator.of(context).pop();
          widget.onPermissionDenied?.call();
        },
      ),
    );
  }

  void _showLocationServiceErrorDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services'),
        content: const Text('Unable to open location settings. Please enable location services manually in your device settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPermissionDenied?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Dialog for requesting location service enablement
class LocationServiceDialog extends StatelessWidget {
  final VoidCallback onEnablePressed;
  final VoidCallback onCancelPressed;

  const LocationServiceDialog({
    super.key,
    required this.onEnablePressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.location_off,
        color: theme.colorScheme.error,
        size: 48,
      ),
      title: const Text('Location Services Disabled'),
      content: const Text(
        'Location services are required for navigation. Please enable location services in your device settings to continue.',
      ),
      actions: [
        TextButton(
          onPressed: onCancelPressed,
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: onEnablePressed,
          icon: const Icon(Icons.settings),
          label: const Text('Open Settings'),
        ),
      ],
    );
  }
}

/// Dialog for requesting location permission
class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onGrantPressed;
  final VoidCallback onCancelPressed;

  const LocationPermissionDialog({
    super.key,
    required this.onGrantPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.location_on,
        color: theme.colorScheme.primary,
        size: 48,
      ),
      title: const Text('Location Permission Required'),
      content: const Text(
        'GigaEats needs access to your location to provide accurate navigation and delivery tracking. Your location data is only used for navigation purposes.',
      ),
      actions: [
        TextButton(
          onPressed: onCancelPressed,
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: onGrantPressed,
          icon: const Icon(Icons.check),
          label: const Text('Grant Permission'),
        ),
      ],
    );
  }
}

/// Dialog shown when location permission is permanently denied
class LocationPermissionDeniedDialog extends StatelessWidget {
  final VoidCallback onOpenSettingsPressed;
  final VoidCallback onCancelPressed;

  const LocationPermissionDeniedDialog({
    super.key,
    required this.onOpenSettingsPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.location_disabled,
        color: theme.colorScheme.error,
        size: 48,
      ),
      title: const Text('Location Permission Denied'),
      content: const Text(
        'Location permission is required for navigation. Please grant location permission in app settings to continue.',
      ),
      actions: [
        TextButton(
          onPressed: onCancelPressed,
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: onOpenSettingsPressed,
          icon: const Icon(Icons.settings),
          label: const Text('App Settings'),
        ),
      ],
    );
  }
}

/// Widget that displays current location accuracy status
class LocationAccuracyIndicator extends StatelessWidget {
  final double accuracy;
  final bool showText;

  const LocationAccuracyIndicator({
    super.key,
    required this.accuracy,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracyStatus = NavigationLocationService.getLocationAccuracyStatus(accuracy);
    
    Color color;
    IconData icon;
    String text;
    
    switch (accuracyStatus) {
      case NavigationLocationAccuracy.excellent:
        color = Colors.green;
        icon = Icons.gps_fixed;
        text = 'Excellent (${accuracy.toStringAsFixed(0)}m)';
        break;
      case NavigationLocationAccuracy.good:
        color = Colors.lightGreen;
        icon = Icons.gps_fixed;
        text = 'Good (${accuracy.toStringAsFixed(0)}m)';
        break;
      case NavigationLocationAccuracy.fair:
        color = Colors.orange;
        icon = Icons.gps_not_fixed;
        text = 'Fair (${accuracy.toStringAsFixed(0)}m)';
        break;
      case NavigationLocationAccuracy.poor:
        color = Colors.red;
        icon = Icons.gps_off;
        text = 'Poor (${accuracy.toStringAsFixed(0)}m)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          if (showText) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
