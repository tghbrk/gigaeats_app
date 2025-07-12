import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/navigation_app_service.dart';

/// Material Design 3 widget for selecting navigation apps with preference persistence
class NavigationAppSelector extends ConsumerStatefulWidget {
  final List<NavigationApp> availableApps;
  final String? selectedAppId;
  final ValueChanged<String> onAppSelected;
  final bool showInstallPrompt;
  final bool showDescription;

  const NavigationAppSelector({
    super.key,
    required this.availableApps,
    this.selectedAppId,
    required this.onAppSelected,
    this.showInstallPrompt = true,
    this.showDescription = true,
  });

  @override
  ConsumerState<NavigationAppSelector> createState() => _NavigationAppSelectorState();
}

class _NavigationAppSelectorState extends ConsumerState<NavigationAppSelector> {
  String? _selectedAppId;

  @override
  void initState() {
    super.initState();
    _selectedAppId = widget.selectedAppId;
    _loadSavedPreference();
  }

  Future<void> _loadSavedPreference() async {
    if (_selectedAppId != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAppId = prefs.getString('preferred_navigation_app');
      
      if (savedAppId != null && 
          widget.availableApps.any((app) => app.id == savedAppId && app.isInstalled)) {
        setState(() {
          _selectedAppId = savedAppId;
        });
        widget.onAppSelected(savedAppId);
      } else {
        // Default to first installed app or in-app navigation
        final defaultApp = widget.availableApps.firstWhere(
          (app) => app.isInstalled,
          orElse: () => widget.availableApps.first,
        );
        setState(() {
          _selectedAppId = defaultApp.id;
        });
        widget.onAppSelected(defaultApp.id);
      }
    } catch (e) {
      debugPrint('🧭 NavigationAppSelector: Error loading preference: $e');
    }
  }

  Future<void> _savePreference(String appId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_navigation_app', appId);
    } catch (e) {
      debugPrint('🧭 NavigationAppSelector: Error saving preference: $e');
    }
  }

  void _selectApp(String appId) {
    setState(() {
      _selectedAppId = appId;
    });
    widget.onAppSelected(appId);
    _savePreference(appId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            if (widget.showDescription) ...[
              _buildDescription(theme),
              const SizedBox(height: 16),
            ],
            _buildAppGrid(theme),
            if (widget.showInstallPrompt) ...[
              const SizedBox(height: 12),
              _buildInstallPrompt(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.navigation,
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Navigation App',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Choose your preferred navigation app',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your selection will be saved for future deliveries. You can change it anytime.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppGrid(ThemeData theme) {
    return Column(
      children: widget.availableApps.map((app) => _buildAppTile(theme, app)).toList(),
    );
  }

  Widget _buildAppTile(ThemeData theme, NavigationApp app) {
    final isSelected = _selectedAppId == app.id;
    final isInstalled = app.isInstalled;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInstalled ? () => _selectApp(app.id) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected 
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : null,
            ),
            child: Row(
              children: [
                _buildAppIcon(theme, app),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAppInfo(theme, app),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 24,
                  )
                else if (!isInstalled)
                  Icon(
                    Icons.download,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(ThemeData theme, NavigationApp app) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: app.isInstalled 
            ? null 
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _getAppIcon(app),
      ),
    );
  }

  Widget _getAppIcon(NavigationApp app) {
    // Use built-in icons for now, can be replaced with actual app icons
    IconData iconData;
    Color? iconColor;
    
    switch (app.id) {
      case 'google_maps':
        iconData = Icons.map;
        iconColor = Colors.green;
        break;
      case 'waze':
        iconData = Icons.traffic;
        iconColor = Colors.blue;
        break;
      case 'here_maps':
        iconData = Icons.location_on;
        iconColor = Colors.orange;
        break;
      case 'maps_me':
        iconData = Icons.explore;
        iconColor = Colors.purple;
        break;
      case 'in_app':
        iconData = Icons.navigation;
        iconColor = Colors.indigo;
        break;
      default:
        iconData = Icons.navigation;
        iconColor = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildAppInfo(ThemeData theme, NavigationApp app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: app.isInstalled 
                ? null 
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          app.isInstalled ? 'Installed' : 'Not installed',
          style: theme.textTheme.bodySmall?.copyWith(
            color: app.isInstalled 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInstallPrompt(ThemeData theme) {
    final notInstalledApps = widget.availableApps.where((app) => !app.isInstalled).toList();
    
    if (notInstalledApps.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.download,
            color: theme.colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Install additional navigation apps for more options',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
