import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/customer_account_settings_provider.dart';
import '../../../domain/customer_account_settings.dart';
import '../../../../../shared/widgets/custom_error_widget.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';

/// Customer account settings screen with comprehensive preferences
class CustomerAccountSettingsScreen extends ConsumerStatefulWidget {
  const CustomerAccountSettingsScreen({super.key});

  @override
  ConsumerState<CustomerAccountSettingsScreen> createState() => _CustomerAccountSettingsScreenState();
}

class _CustomerAccountSettingsScreenState extends ConsumerState<CustomerAccountSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load settings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerAccountSettingsProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(customerAccountSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.privacy_tip), text: 'Privacy'),
            Tab(icon: Icon(Icons.settings), text: 'App'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
          ],
        ),
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settingsState.error != null
              ? _buildErrorState(settingsState.error!)
              : _buildSettingsContent(),
    );
  }

  Widget _buildErrorState(String error) {
    return CustomErrorWidget(
      message: error,
      onRetry: () {
        ref.read(customerAccountSettingsProvider.notifier).loadSettings();
      },
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationSettings(),
              _buildPrivacySettings(),
              _buildAppSettings(),
              _buildSecuritySettings(),
            ],
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    final settingsState = ref.watch(customerAccountSettingsProvider);
    final settings = settingsState.settings;
    if (settings == null) return const SizedBox.shrink();

    final notifications = settings.notificationPreferences;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notification Channels'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: notifications.pushNotifications,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(pushNotifications: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: notifications.emailNotifications,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(emailNotifications: value),
            ),
          ),
          _buildSwitchTile(
            title: 'SMS Notifications',
            subtitle: 'Receive notifications via SMS',
            value: notifications.smsNotifications,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(smsNotifications: value),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Notification Categories'),
          _buildSwitchTile(
            title: 'Order Updates',
            subtitle: 'Order status, delivery updates',
            value: notifications.orderNotifications,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(orderNotifications: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Payment Notifications',
            subtitle: 'Payment confirmations, receipts',
            value: notifications.paymentNotifications,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(paymentNotifications: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Promotions & Offers',
            subtitle: 'Special deals and discounts',
            value: notifications.promotionNotifications,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(promotionNotifications: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Account Updates',
            subtitle: 'Profile changes, security alerts',
            value: notifications.accountNotifications,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(accountNotifications: value),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Quiet Hours'),
          _buildSwitchTile(
            title: 'Enable Quiet Hours',
            subtitle: 'Pause non-urgent notifications during specified hours',
            value: notifications.quietHoursEnabled,
            onChanged: (value) => _updateNotificationPreference(
              notifications.copyWith(quietHoursEnabled: value),
            ),
          ),
          
          if (notifications.quietHoursEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerTile(
                    title: 'Start Time',
                    time: notifications.quietHoursStart ?? '22:00',
                    onTimeChanged: (time) => _updateNotificationPreference(
                      notifications.copyWith(quietHoursStart: time),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePickerTile(
                    title: 'End Time',
                    time: notifications.quietHoursEnd ?? '08:00',
                    onTimeChanged: (time) => _updateNotificationPreference(
                      notifications.copyWith(quietHoursEnd: time),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    final settingsState = ref.watch(customerAccountSettingsProvider);
    final settings = settingsState.settings;
    if (settings == null) return const SizedBox.shrink();

    final privacy = settings.privacySettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Data & Analytics'),
          _buildSwitchTile(
            title: 'Analytics',
            subtitle: 'Help improve the app with usage analytics',
            value: privacy.allowAnalytics,
            onChanged: (value) => _updatePrivacySettings(
              privacy.copyWith(allowAnalytics: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Marketing Communications',
            subtitle: 'Receive personalized marketing content',
            value: privacy.allowMarketing,
            onChanged: (value) => _updatePrivacySettings(
              privacy.copyWith(allowMarketing: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Share Data with Partners',
            subtitle: 'Allow sharing anonymized data with trusted partners',
            value: privacy.shareDataWithPartners,
            onChanged: (value) => _updatePrivacySettings(
              privacy.copyWith(shareDataWithPartners: value),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Location & Tracking'),
          _buildSwitchTile(
            title: 'Location Tracking',
            subtitle: 'Enable location services for delivery',
            value: privacy.locationTracking,
            onChanged: (value) => _updatePrivacySettings(
              privacy.copyWith(locationTracking: value),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Profile Visibility'),
          _buildSwitchTile(
            title: 'Order History Visibility',
            subtitle: 'Allow others to see your order history',
            value: privacy.orderHistoryVisibility,
            onChanged: (value) => _updatePrivacySettings(
              privacy.copyWith(orderHistoryVisibility: value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    final settingsState = ref.watch(customerAccountSettingsProvider);
    final settings = settingsState.settings;
    if (settings == null) return const SizedBox.shrink();

    final app = settings.appPreferences;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Appearance'),
          _buildDropdownTile<AppThemeMode>(
            title: 'Theme',
            subtitle: 'Choose your preferred app theme',
            value: app.themeMode,
            items: AppThemeMode.values,
            itemBuilder: (theme) => _getThemeModeDisplayName(theme),
            onChanged: (value) => _updateAppPreferences(
              app.copyWith(themeMode: value),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildDropdownTile<String>(
            title: 'Language',
            subtitle: 'Choose your preferred language',
            value: app.languageCode,
            items: const ['en', 'ms', 'zh'],
            itemBuilder: (lang) => _getLanguageDisplayName(lang),
            onChanged: (value) => _updateAppPreferences(
              app.copyWith(languageCode: value),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Ordering Preferences'),
          _buildSwitchTile(
            title: 'Remember Payment Method',
            subtitle: 'Save your preferred payment method',
            value: app.rememberPaymentMethod,
            onChanged: (value) => _updateAppPreferences(
              app.copyWith(rememberPaymentMethod: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Auto-apply Loyalty Points',
            subtitle: 'Automatically use loyalty points for discounts',
            value: app.autoApplyLoyaltyPoints,
            onChanged: (value) => _updateAppPreferences(
              app.copyWith(autoApplyLoyaltyPoints: value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    final settingsState = ref.watch(customerAccountSettingsProvider);
    final settings = settingsState.settings;
    if (settings == null) return const SizedBox.shrink();

    final security = settings.securitySettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Authentication'),
          _buildSwitchTile(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security to your account',
            value: security.twoFactorEnabled,
            onChanged: (value) => _updateSecuritySettings(
              security.copyWith(twoFactorEnabled: value),
            ),
          ),
          _buildSwitchTile(
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or face recognition to login',
            value: security.biometricLogin,
            onChanged: (value) => _updateSecuritySettings(
              security.copyWith(biometricLogin: value),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Session Management'),
          _buildDropdownTile<int>(
            title: 'Session Timeout',
            subtitle: 'Automatically logout after inactivity',
            value: security.sessionTimeoutMinutes,
            items: const [15, 30, 60, 120, 240],
            itemBuilder: (minutes) => '$minutes minutes',
            onChanged: (value) => _updateSecuritySettings(
              security.copyWith(sessionTimeoutMinutes: value),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Login Notifications',
            subtitle: 'Get notified when someone logs into your account',
            value: security.loginNotifications,
            onChanged: (value) => _updateSecuritySettings(
              security.copyWith(loginNotifications: value),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Account Actions'),
          ListTile(
            leading: const Icon(Icons.key, color: Colors.orange),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to change password screen
              context.push('/customer/profile/change-password');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(itemBuilder(item)),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTimePickerTile({
    required String title,
    required String time,
    required ValueChanged<String> onTimeChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(time),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final timeParts = time.split(':');
        final initialTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );

        final selectedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );

        if (selectedTime != null) {
          final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
          onTimeChanged(formattedTime);
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSaveButton() {
    final settingsState = ref.watch(customerAccountSettingsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: GEButton.primary(
          text: settingsState.isSaving ? 'Saving...' : 'Save Changes',
          onPressed: settingsState.isSaving || !settingsState.hasUnsavedChanges
              ? null
              : _saveSettings,
          icon: settingsState.isSaving ? null : Icons.save,
        ),
      ),
    );
  }

  // Update methods
  void _updateNotificationPreference(CustomerNotificationPreferences preferences) {
    ref.read(customerAccountSettingsProvider.notifier).updateNotificationPreferences(preferences);
  }

  void _updatePrivacySettings(CustomerPrivacySettings privacy) {
    ref.read(customerAccountSettingsProvider.notifier).updatePrivacySettings(privacy);
  }

  void _updateAppPreferences(CustomerAppPreferences app) {
    ref.read(customerAccountSettingsProvider.notifier).updateAppPreferences(app);
  }

  void _updateSecuritySettings(CustomerSecuritySettings security) {
    ref.read(customerAccountSettingsProvider.notifier).updateSecuritySettings(security);
  }

  Future<void> _saveSettings() async {
    final success = await ref.read(customerAccountSettingsProvider.notifier).saveSettings();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Helper methods for display names
  String _getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ms':
        return 'Bahasa Malaysia';
      case 'zh':
        return '中文';
      default:
        return code.toUpperCase();
    }
  }
}
