import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/route_cache_service.dart';

/// Widget for managing route cache and offline routes
class RouteCacheManager extends ConsumerStatefulWidget {
  final bool showOfflineRoutes;
  final bool showCacheStatistics;
  final VoidCallback? onSettingsChanged;

  const RouteCacheManager({
    super.key,
    this.showOfflineRoutes = true,
    this.showCacheStatistics = true,
    this.onSettingsChanged,
  });

  @override
  ConsumerState<RouteCacheManager> createState() => _RouteCacheManagerState();
}

class _RouteCacheManagerState extends ConsumerState<RouteCacheManager> {
  NavigationPreferences? _preferences;
  CacheStatistics? _statistics;
  List<OfflineRoute> _offlineRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final preferences = await RouteCacheService.getNavigationPreferences();
      final statistics = await RouteCacheService.getCacheStatistics();
      final offlineRoutes = await RouteCacheService.listOfflineRoutes();

      setState(() {
        _preferences = preferences;
        _statistics = statistics;
        _offlineRoutes = offlineRoutes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('RouteCacheManager: Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences(NavigationPreferences newPreferences) async {
    await RouteCacheService.saveNavigationPreferences(newPreferences);
    setState(() {
      _preferences = newPreferences;
    });
    widget.onSettingsChanged?.call();
  }

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmationDialog(
      'Clear Cache',
      'This will remove all cached route information. Are you sure?',
    );

    if (confirmed) {
      await RouteCacheService.clearCache();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  Future<void> _deleteOfflineRoute(OfflineRoute route) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Offline Route',
      'Delete "${route.name}"? This action cannot be undone.',
    );

    if (confirmed) {
      await RouteCacheService.deleteOfflineRoute(route.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${route.name}"')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          if (widget.showCacheStatistics) ...[
            _buildCacheStatistics(theme),
            const SizedBox(height: 16),
          ],
          _buildCacheSettings(theme),
          if (widget.showOfflineRoutes) ...[
            const SizedBox(height: 16),
            _buildOfflineRoutes(theme),
          ],
        ],
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
            Icons.storage,
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
                'Route Cache Manager',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Manage cached routes and offline navigation',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildCacheStatistics(ThemeData theme) {
    if (_statistics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cache Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearCache,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Cache'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.route,
                    'Cached Routes',
                    '${_statistics!.cachedRoutesCount}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.offline_pin,
                    'Offline Routes',
                    '${_statistics!.offlineRoutesCount}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.storage,
                    'Cache Size',
                    _statistics!.formattedCacheSize,
                  ),
                ),
              ],
            ),
            if (_statistics!.expiredRoutesCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_statistics!.expiredRoutesCount} expired routes will be cleaned up',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCacheSettings(ThemeData theme) {
    if (_preferences == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cache Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Cache Routes'),
              subtitle: const Text('Automatically cache route calculations for faster access'),
              value: _preferences!.cacheRoutes,
              onChanged: (value) {
                _updatePreferences(_preferences!.copyWith(cacheRoutes: value));
              },
            ),
            SwitchListTile(
              title: const Text('Use Offline Routes'),
              subtitle: const Text('Use saved offline routes when available'),
              value: _preferences!.useOfflineRoutes,
              onChanged: (value) {
                _updatePreferences(_preferences!.copyWith(useOfflineRoutes: value));
              },
            ),
            SwitchListTile(
              title: const Text('Show Traffic Alerts'),
              subtitle: const Text('Display traffic conditions and warnings'),
              value: _preferences!.showTrafficAlerts,
              onChanged: (value) {
                _updatePreferences(_preferences!.copyWith(showTrafficAlerts: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineRoutes(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.offline_pin,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Offline Routes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_offlineRoutes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No offline routes saved. Save routes for offline access when you have poor connectivity.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_offlineRoutes.map((route) => _buildOfflineRouteItem(theme, route))),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineRouteItem(ThemeData theme, OfflineRoute route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.offline_pin,
            color: theme.colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(route.name),
        subtitle: Text(
          'Saved ${_formatDate(route.savedAt)} • ${route.routeInfo.distanceText}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          onPressed: () => _deleteOfflineRoute(route),
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete offline route',
        ),
        onTap: () {
          // TODO: Implement route preview or navigation
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
