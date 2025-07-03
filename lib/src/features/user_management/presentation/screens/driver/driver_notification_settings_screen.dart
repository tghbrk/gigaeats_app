import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Restore when driver notification models and providers are implemented
// import '../../data/models/driver_notification_preferences.dart';
// import '../providers/driver_notification_settings_provider.dart';
// TODO: Restore when auth provider is implemented
// import '../../../auth/presentation/providers/auth_provider.dart';
// TODO: Restore when loading_widget is used
// import '../../../../shared/widgets/loading_widget.dart';
// TODO: Restore when custom error widget is implemented
// import '../../../../shared/widgets/custom_error_widget.dart';

class DriverNotificationSettingsScreen extends ConsumerWidget {
  const DriverNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Restore when authStateProvider is implemented
    // final authState = ref.watch(authStateProvider);
    const authState = null; // Placeholder until auth provider is implemented
    final user = authState.user;



    if (user == null) {

      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        // TODO: Restore when CustomErrorWidget is implemented
        // body: const CustomErrorWidget(
        //   message: 'User not found. Please log in again.',
        // ),
        body: const Center(
          child: Text('User not found. Please log in again.'),
        ),
      );
    }

    return _buildNotificationSettings(user.id);
  }

  Widget _buildNotificationSettings(String driverId) {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore when driverNotificationSettingsProvider is implemented
        // final settingsState = ref.watch(driverNotificationSettingsProvider(driverId));
        // TODO: Restore when driverNotificationCategoriesProvider is implemented
        // final categories = ref.watch(driverNotificationCategoriesProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notification Settings'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            actions: [
              // TODO: Restore when settingsState is implemented
              // TODO: Restore dead code - commented out for analyzer cleanup
              // TODO: Restore dead code - commented out for analyzer cleanup
              // if (false) // settingsState.isSaving
              //   const Padding(
              //     padding: EdgeInsets.all(16.0),
              //     child: SizedBox(
              //       width: 20,
              //       height: 20,
              //       child: CircularProgressIndicator(
              //         strokeWidth: 2,
              //         color: Colors.white,
              //       ),
              //     ),
              //   )
              // else
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // TODO: Restore when driverNotificationSettingsProvider is implemented
                    // ref.read(driverNotificationSettingsProvider(driverId).notifier).refresh();
                  },
                  tooltip: 'Refresh settings',
                ),
            ],
          ),
          // TODO: Restore when settingsState is implemented
          body: const Center(child: Text('Driver notification settings not available')),
        );
      },
    );
  }

  // TODO: Restore when DriverNotificationCategory and DriverNotificationSettingsState are implemented
  /*Widget _buildSettingsContent(
    String driverId,
    List<DriverNotificationCategory> categories,
    DriverNotificationSettingsState settingsState,
  ) {
    return Column(
      children: [
        // Success Message
        if (settingsState.successMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settingsState.successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return IconButton(
                      icon: const Icon(Icons.close, color: Colors.green),
                      onPressed: () {
                        // TODO: Restore when driverNotificationSettingsProvider is implemented
                        // ref.read(driverNotificationSettingsProvider(driverId).notifier).clearMessages();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

        // Error Message
        if (settingsState.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settingsState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // TODO: Restore when driverNotificationSettingsProvider is implemented
                        // ref.read(driverNotificationSettingsProvider(driverId).notifier).clearMessages();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

        // Settings Content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(driverId, category, settingsState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String driverId,
    DriverNotificationCategory category,
    DriverNotificationSettingsState settingsState,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Header
                Row(
                  children: [
                    Icon(
                      category.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                
                // Category Settings
                ...category.settings.map<Widget>((setting) {
                  final isEnabled = setting.getValue(settingsState.preferences);
                  
                  return SwitchListTile(
                    title: Text(
                      setting.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      setting.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    value: isEnabled,
                    onChanged: settingsState.isSaving
                        ? null
                        : (value) {
                            debugPrint('🔔 Driver notification setting changed: ${setting.key} = $value');
                            // TODO: Restore when driverNotificationSettingsProvider is implemented
                            // ref
                            //     .read(driverNotificationSettingsProvider(driverId).notifier)
                            //     .updateSinglePreference(setting.key, value);
                          },
                    contentPadding: EdgeInsets.zero,
                    activeColor: Theme.of(context).colorScheme.primary,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
  */
}
