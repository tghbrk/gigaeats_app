import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_profile_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/customer_profile.dart';
import '../../../../core/utils/auth_utils.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends ConsumerState<CustomerSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load customer profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProfileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(customerProfileProvider);
    final preferences = ref.watch(customerPreferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationSettings(preferences),
                  const SizedBox(height: 24),
                  _buildFoodPreferences(preferences),
                  const SizedBox(height: 24),
                  _buildAccountSettings(),
                  const SizedBox(height: 24),
                  _buildAppSettings(),
                  const SizedBox(height: 32),
                  _buildSignOutSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationSettings(CustomerPreferences? preferences) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Order Updates'),
                subtitle: const Text('Get notified about order status changes'),
                value: preferences?.notificationPreferences.orderUpdates ?? true,
                onChanged: (value) => _updateNotificationPreference('orderUpdates', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Delivery Updates'),
                subtitle: const Text('Get notified when your order is on the way'),
                value: preferences?.notificationPreferences.deliveryUpdates ?? true,
                onChanged: (value) => _updateNotificationPreference('deliveryUpdates', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Promotional Offers'),
                subtitle: const Text('Receive special offers and discounts'),
                value: preferences?.notificationPreferences.promotionalOffers ?? false,
                onChanged: (value) => _updateNotificationPreference('promotionalOffers', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('New Restaurants'),
                subtitle: const Text('Get notified about new restaurants'),
                value: preferences?.notificationPreferences.newRestaurants ?? false,
                onChanged: (value) => _updateNotificationPreference('newRestaurants', value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodPreferences(CustomerPreferences? preferences) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Preferences',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Halal Only'),
                subtitle: const Text('Show only halal-certified restaurants'),
                value: preferences?.halalOnly ?? false,
                onChanged: (value) => _updateFoodPreference('halalOnly', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Vegetarian Options'),
                subtitle: const Text('Prefer restaurants with vegetarian options'),
                value: preferences?.vegetarianOptions ?? false,
                onChanged: (value) => _updateFoodPreference('vegetarianOptions', value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Vegan Options'),
                subtitle: const Text('Prefer restaurants with vegan options'),
                value: preferences?.veganOptions ?? false,
                onChanged: (value) => _updateFoodPreference('veganOptions', value),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Spice Tolerance'),
                subtitle: Text('Level ${preferences?.spiceToleranceLevel ?? 2} of 5'),
                trailing: DropdownButton<int>(
                  value: preferences?.spiceToleranceLevel ?? 2,
                  items: List.generate(5, (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('Level ${index + 1}'),
                  )),
                  onChanged: (value) => _updateSpiceTolerance(value ?? 2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                subtitle: const Text('Update your personal information'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/customer/profile/edit'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Manage Addresses'),
                subtitle: const Text('Add or edit delivery addresses'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/customer/addresses'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Payment Methods'),
                subtitle: const Text('Manage your payment options'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog('Payment Methods'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog('Language Settings'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help or contact support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showComingSoonDialog('Help & Support'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                subtitle: const Text('App version and information'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomButton(
          text: 'Sign Out',
          onPressed: _showSignOutDialog,
          type: ButtonType.secondary,
          icon: Icons.logout,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'GigaEats v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _updateNotificationPreference(String key, bool value) async {
    final preferences = ref.read(customerPreferencesProvider);
    if (preferences == null) return;

    NotificationPreferences updatedNotifications;
    switch (key) {
      case 'orderUpdates':
        updatedNotifications = preferences.notificationPreferences.copyWith(orderUpdates: value);
        break;
      case 'deliveryUpdates':
        updatedNotifications = preferences.notificationPreferences.copyWith(deliveryUpdates: value);
        break;
      case 'promotionalOffers':
        updatedNotifications = preferences.notificationPreferences.copyWith(promotionalOffers: value);
        break;
      case 'newRestaurants':
        updatedNotifications = preferences.notificationPreferences.copyWith(newRestaurants: value);
        break;
      default:
        return;
    }

    final updatedPreferences = preferences.copyWith(notificationPreferences: updatedNotifications);
    await ref.read(customerProfileProvider.notifier).updatePreferences(updatedPreferences);
  }

  void _updateFoodPreference(String key, bool value) async {
    final preferences = ref.read(customerPreferencesProvider);
    if (preferences == null) return;

    CustomerPreferences updatedPreferences;
    switch (key) {
      case 'halalOnly':
        updatedPreferences = preferences.copyWith(halalOnly: value);
        break;
      case 'vegetarianOptions':
        updatedPreferences = preferences.copyWith(vegetarianOptions: value);
        break;
      case 'veganOptions':
        updatedPreferences = preferences.copyWith(veganOptions: value);
        break;
      default:
        return;
    }

    await ref.read(customerProfileProvider.notifier).updatePreferences(updatedPreferences);
  }

  void _updateSpiceTolerance(int level) async {
    final preferences = ref.read(customerPreferencesProvider);
    if (preferences == null) return;

    final updatedPreferences = preferences.copyWith(spiceToleranceLevel: level);
    await ref.read(customerProfileProvider.notifier).updatePreferences(updatedPreferences);
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthUtils.logout(context, ref);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature functionality will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About GigaEats'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GigaEats Customer App'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Your favorite food delivery platform in Malaysia.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
