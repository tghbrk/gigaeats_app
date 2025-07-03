import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Restore when admin_notification_preferences model is implemented
// import '../../../data/models/admin_notification_preferences.dart';
// TODO: Restore when admin_notification_settings_provider is implemented
// import '../../../../admin/presentation/providers/admin_notification_settings_provider.dart';
// TODO: Restore when auth provider is implemented
// import '../../../auth/presentation/providers/auth_provider.dart';
// TODO: Restore when loading_widget is used
// import '../../../../shared/widgets/loading_widget.dart';
// TODO: Restore when error_widget is used
// import '../../../../shared/widgets/error_widget.dart';

class AdminNotificationSettingsScreen extends ConsumerWidget {
  const AdminNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Restore when authStateProvider is implemented
    // final authState = ref.watch(authStateProvider);
    // final user = authState.user;
    const user = null; // Placeholder until auth provider is implemented

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        // TODO: Restore when CustomErrorWidget is implemented
        // body: const CustomErrorWidget(
        //   message: 'User not found. Please log in again.',
        // ),
        body: const Center(child: Text('User not found. Please log in again.')),
      );
    }
    
    return _buildNotificationSettings(user.id);
  }

  Widget _buildNotificationSettings(String adminId) {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Restore when adminNotificationSettingsProvider is implemented
        // final settingsState = ref.watch(adminNotificationSettingsProvider(adminId));
        // final categories = ref.watch(adminNotificationCategoriesProvider);
        final settingsState = <String, dynamic>{}; // Placeholder
        // TODO: Restore categories when provider is implemented - commented out for analyzer cleanup
        // final categories = <String, dynamic>{}; // Placeholder

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notification Settings'),
            actions: [
              // TODO: Restore isSaving condition when provider is implemented - commented out for analyzer cleanup
              // if (settingsState.isSaving)
              //   const Padding(
              //     padding: EdgeInsets.all(16.0),
              //     child: SizedBox(
              //       width: 20,
              //       height: 20,
              //       child: CircularProgressIndicator(strokeWidth: 2),
              //     ),
              //   )
              // else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // TODO: Restore adminNotificationSettingsProvider - commented out for analyzer cleanup
                    // ref.read(adminNotificationSettingsProvider(adminId).notifier).refresh();
                  },
                ),
            ],
          ),
          body: (settingsState['isLoading'] ?? false)
              // TODO: Restore when LoadingWidget is implemented
              // ? const LoadingWidget(message: 'Loading notification settings...')
              ? const Center(child: CircularProgressIndicator())
              : settingsState['errorMessage'] != null
                  ? Text('Error: ${settingsState['errorMessage']}') // TODO: Restore CustomErrorWidget - commented out for analyzer cleanup
                      // Container( // CustomErrorWidget(
                      //   child: Text('Error: ${settingsState['errorMessage']}'), // message: settingsState.errorMessage!,
                      //   onRetry: () {
                      //     ref.read(adminNotificationSettingsProvider(adminId).notifier).refresh();
                      //   },
                      // )
                  // TODO: Restore _buildSettingsContent with proper types - commented out for analyzer cleanup
                  // TODO: Restore _buildSettingsContent when provider is implemented - commented out for analyzer cleanup
                  : const Text('Settings content placeholder'), // _buildSettingsContent(adminId, categories, settingsState),
        );
      },
    );
  }

  // TODO: Restore _buildSettingsContent when provider is implemented - commented out for analyzer cleanup
  // TODO: Restore _buildSettingsContent when provider is implemented - commented out for analyzer cleanup
  // TODO: Restore unused element - commented out for analyzer cleanup
  /*
  Widget _buildSettingsContentUnused(
    String adminId,
    // TODO: Restore when AdminNotificationCategory is implemented
    // List<AdminNotificationCategory> categories,
    List<Map<String, dynamic>> categories,
    // TODO: Restore when AdminNotificationSettingsState is implemented
    // AdminNotificationSettingsState settingsState,
    Map<String, dynamic> settingsState,
  ) {
    return Column(
      children: [
        // Success Message
        // TODO: Restore successMessage getter - commented out for analyzer cleanup
        if (settingsState['successMessage'] != null) // settingsState.successMessage != null)
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
                    // TODO: Restore successMessage getter - commented out for analyzer cleanup
                    settingsState['successMessage'] ?? 'Success', // settingsState.successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return IconButton(
                      icon: const Icon(Icons.close, color: Colors.green),
                      onPressed: () {
                        // TODO: Restore adminNotificationSettingsProvider when provider is implemented - commented out for analyzer cleanup
        // ref.read(adminNotificationSettingsProvider(adminId).notifier).clearMessages();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

        // Error Message
        // TODO: Restore errorMessage getter when provider is implemented - commented out for analyzer cleanup
        if ((settingsState['errorMessage'] ?? '') != '') // settingsState.errorMessage != null)
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
                    // TODO: Restore errorMessage getter when provider is implemented - commented out for analyzer cleanup
                    settingsState['errorMessage'] ?? 'Error', // settingsState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // TODO: Restore adminNotificationSettingsProvider when provider is implemented - commented out for analyzer cleanup
                        // ref.read(adminNotificationSettingsProvider(adminId).notifier).clearMessages();
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
              return _buildCategoryCard(adminId, category, settingsState);
            },
          ),
        ),
      ],
    );
  }
  */

  // TODO: Restore unused element - commented out for analyzer cleanup
  /*
  Widget _buildCategoryCard(
    String adminId,
    // TODO: Restore when AdminNotificationCategory is implemented
    // AdminNotificationCategory category,
    Map<String, dynamic> category,
    // TODO: Restore when AdminNotificationSettingsState is implemented
    // AdminNotificationSettingsState settingsState,
    Map<String, dynamic> settingsState,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Header
                Row(
                  children: [
                    Icon(
                      // TODO: Restore category.icon when provider is implemented - commented out for analyzer cleanup
                      category['icon'] ?? Icons.notifications, // category.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // TODO: Restore category.title when provider is implemented - commented out for analyzer cleanup
                            category['title'] ?? 'Category', // category.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            // TODO: Restore category.description when provider is implemented - commented out for analyzer cleanup
                            category['description'] ?? 'Description', // category.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
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
                // TODO: Restore category.settings when provider is implemented - commented out for analyzer cleanup
                ...((category['settings'] ?? []) as List).map<Widget>((setting) {
                  // TODO: Restore setting.getValue when provider is implemented - commented out for analyzer cleanup
                  final isEnabled = false; // setting.getValue(settingsState.preferences);
                  
                  return SwitchListTile(
                    title: Text(setting.title),
                    subtitle: Text(
                      setting.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: isEnabled,
                    // TODO: Restore settingsState.isSaving when provider is implemented - commented out for analyzer cleanup
                    onChanged: (settingsState['isSaving'] ?? false) // settingsState.isSaving
                        ? null
                        : (value) {
                            // TODO: Restore adminNotificationSettingsProvider when provider is implemented - commented out for analyzer cleanup
                            // ref
                            //     .read(adminNotificationSettingsProvider(adminId).notifier)
                            //     .updateSinglePreference(setting.key, value);
                          },
                    contentPadding: EdgeInsets.zero,
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
