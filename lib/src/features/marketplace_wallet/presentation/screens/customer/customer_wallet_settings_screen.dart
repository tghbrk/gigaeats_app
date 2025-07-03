import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../providers/customer_wallet_settings_provider.dart';
import '../../widgets/customer_wallet_error_widget.dart';
import '../../../../../core/widgets/analytics/analytics_quick_action_widget.dart';
import '../../../data/models/customer_wallet_error.dart';

import '../../widgets/wallet_security_settings_widget.dart';
import '../../widgets/wallet_notification_settings_widget.dart';
import '../../widgets/wallet_auto_reload_settings_widget.dart';
import '../../widgets/wallet_spending_limits_widget.dart';
import '../../widgets/wallet_privacy_settings_widget.dart';

class CustomerWalletSettingsScreen extends ConsumerStatefulWidget {
  const CustomerWalletSettingsScreen({super.key});

  @override
  ConsumerState<CustomerWalletSettingsScreen> createState() => _CustomerWalletSettingsScreenState();
}

class _CustomerWalletSettingsScreenState extends ConsumerState<CustomerWalletSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load wallet settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerWalletSettingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(customerWalletSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsState.isLoading
          ? const LoadingWidget()
          : settingsState.errorMessage != null
              ? CustomerWalletErrorWidget(
                  error: CustomerWalletError.fromMessage(settingsState.errorMessage!),
                  onRetry: () => ref.read(customerWalletSettingsProvider.notifier).loadSettings(),
                )
              : _buildSettingsContent(context, settingsState.settings),
    );
  }

  Widget _buildSettingsContent(BuildContext context, settings) {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Container(
            color: AppTheme.primaryColor,
            child: const TabBar(
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.security), text: 'Security'),
                Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
                Tab(icon: Icon(Icons.autorenew), text: 'Auto-reload'),
                Tab(icon: Icon(Icons.trending_up), text: 'Spending Limits'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                Tab(icon: Icon(Icons.privacy_tip), text: 'Privacy'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Security Settings Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: const WalletSecuritySettingsWidget(),
                ),

                // Notification Preferences Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: const WalletNotificationSettingsWidget(),
                ),

                // Auto-reload Settings Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: const WalletAutoReloadSettingsWidget(),
                ),

                // Spending Limits Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: const WalletSpendingLimitsWidget(),
                ),

                // Analytics Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildAnalyticsTab(context),
                ),

                // Privacy Settings Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: const WalletPrivacySettingsWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildAnalyticsTab(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics & Insights',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your spending analytics and privacy settings.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        // Analytics Quick Access
        const AnalyticsQuickActionWidget(showPreview: false, height: 80),
        const SizedBox(height: 16),

        // Analytics Settings Options
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('View Analytics'),
                subtitle: const Text('Detailed spending insights and trends'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/customer/wallet/analytics'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Analytics Settings'),
                subtitle: const Text('Privacy and data preferences'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/customer/wallet/analytics/settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
