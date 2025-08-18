import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/design_system.dart';
import 'feature_flags.dart';

/// Feature Flag Settings Screen
/// 
/// Allows developers and testers to toggle feature flags for testing
/// and gradual feature rollout. Only available in debug mode.
class FeatureFlagSettingsScreen extends ConsumerWidget {
  const FeatureFlagSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureFlagsAsync = ref.watch(featureFlagNotifierProvider);
    
    return GEScreen(
      appBar: GEAppBar(
        title: 'Feature Flags',
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(featureFlagNotifierProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'reset_all':
                  await _showResetConfirmation(context, ref);
                  break;
                case 'enable_all':
                  await _enableAllFlags(ref);
                  break;
                case 'disable_all':
                  await _disableAllFlags(ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'enable_all',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Enable All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'disable_all',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Disable All'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset_all',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: featureFlagsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: GESpacing.md),
              Text(
                'Error loading feature flags',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: GESpacing.sm),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GESpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(featureFlagNotifierProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (flags) => _buildFlagsList(context, ref, flags),
      ),
    );
  }

  Widget _buildFlagsList(BuildContext context, WidgetRef ref, Map<String, bool> flags) {
    return ListView(
      padding: const EdgeInsets.all(GESpacing.md),
      children: [
        // Header Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(GESpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.blue),
                    const SizedBox(width: GESpacing.sm),
                    Text(
                      'Feature Flags',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GESpacing.sm),
                const Text(
                  'Toggle features on/off for testing and gradual rollout. '
                  'Changes take effect immediately.',
                ),
                const SizedBox(height: GESpacing.sm),
                Container(
                  padding: const EdgeInsets.all(GESpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: GESpacing.xs),
                      Expanded(
                        child: Text(
                          'Debug Mode Only - Not available in production',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: GESpacing.lg),
        
        // Feature Flags List
        ...flags.entries.map((entry) => _buildFeatureFlagTile(
          context,
          ref,
          entry.key,
          entry.value,
        )),
      ],
    );
  }

  Widget _buildFeatureFlagTile(
    BuildContext context,
    WidgetRef ref,
    String flag,
    bool isEnabled,
  ) {
    final flagInfo = _getFlagInfo(flag);
    
    return Card(
      margin: const EdgeInsets.only(bottom: GESpacing.sm),
      child: SwitchListTile(
        title: Text(
          flagInfo.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(flagInfo.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isEnabled ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isEnabled ? 'ENABLED' : 'DISABLED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: GESpacing.xs),
                Text(
                  'Default: ${FeatureFlags.getDefaultState(flag) ? 'ON' : 'OFF'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        value: isEnabled,
        onChanged: (value) async {
          await ref.read(featureFlagNotifierProvider.notifier).toggleFlag(flag);
          
          // Show feedback
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${flagInfo.title} ${value ? 'enabled' : 'disabled'}',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: value ? Colors.green : Colors.orange,
              ),
            );
          }
        },
        secondary: Icon(
          flagInfo.icon,
          color: isEnabled ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  _FeatureFlagInfo _getFlagInfo(String flag) {
    switch (flag) {
      case FeatureFlags.enhancedDriverInterface:
        return _FeatureFlagInfo(
          title: 'Enhanced Driver Interface',
          description: 'Improved driver interface with better navigation and order management',
          icon: Icons.local_shipping,
        );
      case FeatureFlags.newPaymentFlow:
        return _FeatureFlagInfo(
          title: 'New Payment Flow',
          description: 'Updated payment processing with improved security and user experience',
          icon: Icons.payment,
        );
      case FeatureFlags.advancedAnalytics:
        return _FeatureFlagInfo(
          title: 'Advanced Analytics',
          description: 'Enhanced analytics and reporting features for better insights',
          icon: Icons.analytics,
        );
      default:
        return _FeatureFlagInfo(
          title: flag.replaceAll('_', ' ').toUpperCase(),
          description: 'Feature flag: $flag',
          icon: Icons.flag,
        );
    }
  }

  Future<void> _showResetConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Feature Flags'),
        content: const Text(
          'This will reset all feature flags to their default states. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(featureFlagNotifierProvider.notifier).resetAllFlags();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All feature flags reset to defaults'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _enableAllFlags(WidgetRef ref) async {
    for (final flag in FeatureFlags.allFlags) {
      await ref.read(featureFlagNotifierProvider.notifier).enableFlag(flag);
    }
  }

  Future<void> _disableAllFlags(WidgetRef ref) async {
    for (final flag in FeatureFlags.allFlags) {
      await ref.read(featureFlagNotifierProvider.notifier).disableFlag(flag);
    }
  }
}

class _FeatureFlagInfo {
  final String title;
  final String description;
  final IconData icon;

  _FeatureFlagInfo({
    required this.title,
    required this.description,
    required this.icon,
  });
}
