import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Navigation method selection dialog that allows drivers to choose
/// between Enhanced In-App Navigation and external navigation apps
class NavigationMethodSelectionDialog extends ConsumerWidget {
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final VoidCallback onInAppNavigationSelected;
  final VoidCallback onExternalNavigationSelected;

  const NavigationMethodSelectionDialog({
    super.key,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    required this.onInAppNavigationSelected,
    required this.onExternalNavigationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.navigation,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose Navigation Method',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Navigate to $destinationName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Enhanced In-App Navigation Option
            _NavigationOptionCard(
              icon: Icons.map,
              title: 'Enhanced In-App Navigation',
              subtitle: '3D maps, voice guidance, traffic alerts',
              features: [
                'Turn-by-turn voice guidance',
                'Real-time traffic updates',
                '3D navigation perspective',
                'Multi-order route optimization',
              ],
              onTap: () {
                Navigator.of(context).pop();
                onInAppNavigationSelected();
              },
              isPrimary: true,
            ),
            
            const SizedBox(height: 16),

            // External Navigation Apps
            _NavigationOptionCard(
              icon: Icons.open_in_new,
              title: 'External Navigation Apps',
              subtitle: 'Google Maps, Waze, Apple Maps',
              features: [
                'Use your preferred navigation app',
                'Offline maps support',
                'Familiar interface',
                'Background navigation',
              ],
              onTap: () {
                Navigator.of(context).pop();
                _showExternalAppSelection(context);
              },
              isPrimary: false,
            ),

            const SizedBox(height: 24),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExternalAppSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ExternalNavigationAppsDialog(
        destinationName: destinationName,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        onAppSelected: onExternalNavigationSelected,
      ),
    );
  }
}

class _NavigationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final VoidCallback onTap;
  final bool isPrimary;

  const _NavigationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isPrimary ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPrimary
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isPrimary
                          ? theme.primaryColor
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPrimary ? theme.primaryColor : null,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'RECOMMENDED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isPrimary
                          ? theme.primaryColor
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExternalNavigationAppsDialog extends StatelessWidget {
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final VoidCallback onAppSelected;

  const _ExternalNavigationAppsDialog({
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    required this.onAppSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Navigation App',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            _ExternalAppOption(
              icon: Icons.map,
              name: 'Google Maps',
              onTap: () => _launchGoogleMaps(context),
            ),
            
            _ExternalAppOption(
              icon: Icons.navigation,
              name: 'Waze',
              onTap: () => _launchWaze(context),
            ),
            
            _ExternalAppOption(
              icon: Icons.location_on,
              name: 'Apple Maps',
              onTap: () => _launchAppleMaps(context),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps(BuildContext context) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      Navigator.of(context).pop();
      onAppSelected();
    }
  }

  Future<void> _launchWaze(BuildContext context) async {
    final url = 'https://waze.com/ul?ll=$destinationLat,$destinationLng&navigate=yes';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      Navigator.of(context).pop();
      onAppSelected();
    }
  }

  Future<void> _launchAppleMaps(BuildContext context) async {
    final url = 'http://maps.apple.com/?daddr=$destinationLat,$destinationLng&dirflg=d';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      Navigator.of(context).pop();
      onAppSelected();
    }
  }
}

class _ExternalAppOption extends StatelessWidget {
  final IconData icon;
  final String name;
  final VoidCallback onTap;

  const _ExternalAppOption({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.primaryColor),
        title: Text(name),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
