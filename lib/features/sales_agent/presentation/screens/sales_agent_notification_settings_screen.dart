import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sales_agent_notification_preferences.dart';
import '../providers/sales_agent_notification_settings_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';

class SalesAgentNotificationSettingsScreen extends ConsumerWidget {
  const SalesAgentNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the current user notification settings provider
    final settingsState = ref.watch(currentSalesAgentNotificationSettingsProvider);
    final categories = ref.watch(salesAgentNotificationCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (settingsState.isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(currentSalesAgentNotificationSettingsProvider.notifier).refresh();
              },
            ),
        ],
      ),
      body: settingsState.isLoading
          ? const LoadingWidget(message: 'Loading notification settings...')
          : settingsState.errorMessage != null
              ? CustomErrorWidget(
                  message: settingsState.errorMessage!,
                  onRetry: () {
                    ref.read(currentSalesAgentNotificationSettingsProvider.notifier).refresh();
                  },
                )
              : _buildSettingsContent(categories, settingsState, ref),
    );
  }

  Widget _buildSettingsContent(
    List<SalesAgentNotificationCategory> categories,
    SalesAgentNotificationSettingsState settingsState,
    WidgetRef ref,
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
              color: Theme.of(ref.context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border.all(color: Theme.of(ref.context).colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(ref.context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    settingsState.successMessage!,
                    style: TextStyle(
                      color: Theme.of(ref.context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(ref.context).colorScheme.primary,
                  ),
                  onPressed: () {
                    ref.read(currentSalesAgentNotificationSettingsProvider.notifier).clearMessages();
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
              color: Theme.of(ref.context).colorScheme.errorContainer.withValues(alpha: 0.3),
              border: Border.all(color: Theme.of(ref.context).colorScheme.error),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Theme.of(ref.context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    settingsState.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(ref.context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(ref.context).colorScheme.error,
                  ),
                  onPressed: () {
                    ref.read(currentSalesAgentNotificationSettingsProvider.notifier).clearMessages();
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
              return _buildCategoryCard(category, settingsState, ref);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    SalesAgentNotificationCategory category,
    SalesAgentNotificationSettingsState settingsState,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ref.context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category.icon,
                    color: Theme.of(ref.context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: Theme.of(ref.context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(ref.context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: Theme.of(ref.context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ref.context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Category Settings
            ...category.settings.map<Widget>((setting) {
              final isEnabled = setting.getValue(settingsState.preferences);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SwitchListTile.adaptive(
                  title: Text(
                    setting.title,
                    style: Theme.of(ref.context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    setting.description,
                    style: Theme.of(ref.context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ref.context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: isEnabled,
                  onChanged: settingsState.isSaving
                      ? null
                      : (value) {
                          ref
                              .read(currentSalesAgentNotificationSettingsProvider.notifier)
                              .updateSinglePreference(setting.key, value);
                        },
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(ref.context).colorScheme.primary,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
