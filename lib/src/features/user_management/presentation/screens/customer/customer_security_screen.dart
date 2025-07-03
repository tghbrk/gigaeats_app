import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore unused import if navigation functionality is added
// import 'package:go_router/go_router.dart';

// TODO: Restore missing URI imports when security components are implemented
// import '../../../../core/theme/app_theme.dart';
// TODO: Restore when loading_widget is used
// import '../../../../shared/widgets/loading_widget.dart';
// import '../providers/customer_security_provider.dart';
// import '../widgets/security_widgets.dart';
// import '../widgets/customer_wallet_error_widget.dart';
// import '../../data/models/customer_wallet_error.dart';

class CustomerSecurityScreen extends ConsumerStatefulWidget {
  const CustomerSecurityScreen({super.key});

  @override
  ConsumerState<CustomerSecurityScreen> createState() => _CustomerSecurityScreenState();
}

class _CustomerSecurityScreenState extends ConsumerState<CustomerSecurityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial security data
    // TODO: Restore when customerSecurityProvider is implemented
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(customerSecurityProvider.notifier).refreshAll();
    // });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Restore when customerSecurityProvider is implemented
    // final securityState = ref.watch(customerSecurityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        // TODO: Restore when AppTheme is implemented
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // TODO: Restore when context.pop() is implemented
          // onPressed: () => context.pop(),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // TODO: Restore when customerSecurityProvider is implemented
            onPressed: () {}, // => ref.read(customerSecurityProvider.notifier).refreshAll(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            // TODO: Restore undefined identifier - commented out for analyzer cleanup
            // onSelected: _handleMenuAction,
            onSelected: (action) => debugPrint('Menu action not implemented: $action'),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'audit_logs',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Security Audit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'devices',
                child: Row(
                  children: [
                    Icon(Icons.devices),
                    SizedBox(width: 8),
                    Text('Manage Devices'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Authentication', icon: Icon(Icons.security, size: 20)),
            Tab(text: 'Privacy', icon: Icon(Icons.privacy_tip, size: 20)),
            Tab(text: 'Activity', icon: Icon(Icons.timeline, size: 20)),
          ],
        ),
      ),
      // TODO: Restore when securityState is implemented
      body: const Center(child: Text('Security settings not available')),
      /*body: securityState.isLoading
          ? const LoadingWidget()
          : securityState.errorMessage != null
              // TODO: Restore when CustomerWalletErrorWidget is implemented
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Security Error: ${securityState.errorMessage}'),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Restore when customerSecurityProvider is implemented
                          // ref.read(customerSecurityProvider.notifier).refreshAll();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAuthenticationTab(),
                    _buildPrivacyTab(),
                    _buildActivityTab(),
                  ],
                ),*/
    );
  }

  // TODO: Use _buildAuthenticationTab when authentication tab is restored
  /*
  Widget _buildAuthenticationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Score Card
          // TODO: Restore when SecurityScoreCard is implemented
          // const SecurityScoreCard(),
          const Placeholder(child: Text('Security Score Card')),
          const SizedBox(height: 24),

          // TODO: Restore when security card widgets are implemented
          // Biometric Authentication
          // const BiometricAuthenticationCard(),
          const Placeholder(child: Text('Biometric Authentication Card')),
          const SizedBox(height: 16),

          // PIN Authentication
          // const PINAuthenticationCard(),
          const Placeholder(child: Text('PIN Authentication Card')),
          const SizedBox(height: 16),

          // Transaction Security
          // const TransactionSecurityCard(),
          const Placeholder(child: Text('Transaction Security Card')),
          const SizedBox(height: 16),

          // Auto-lock Settings
          // const AutoLockSettingsCard(),
          const Placeholder(child: Text('Auto-lock Settings Card')),
          const SizedBox(height: 16),

          // Multi-factor Authentication
          // const MFASettingsCard(),
          const Placeholder(child: Text('MFA Settings Card')),
        ],
      ),
    );
  }
  */

  // TODO: Use _buildPrivacyTab when privacy tab is restored
  /*
  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: Restore when privacy card widgets are implemented
          // Privacy Overview
          // const PrivacyOverviewCard(),
          const Placeholder(child: Text('Privacy Overview Card')),
          const SizedBox(height: 24),

          // Data Protection
          // const DataProtectionCard(),
          const Placeholder(child: Text('Data Protection Card')),
          const SizedBox(height: 16),

          // Device Management
          // const DeviceManagementCard(),
          const Placeholder(child: Text('Device Management Card')),
          const SizedBox(height: 16),

          // Location Privacy
          // const LocationPrivacyCard(),
          const Placeholder(child: Text('Location Privacy Card')),
          const SizedBox(height: 16),

          // Communication Preferences
          // const CommunicationPreferencesCard(),
          const Placeholder(child: Text('Communication Preferences Card')),
        ],
      ),
    );
  }
  */

  // TODO: Use _buildActivityTab when activity tab is restored
  /*
  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: Restore when security activity widgets are implemented
          // Security Activity Overview
          // const SecurityActivityOverview(),
          const Placeholder(child: Text('Security Activity Overview')),
          const SizedBox(height: 24),

          // Recent Security Events
          // const RecentSecurityEvents(),
          const Placeholder(child: Text('Recent Security Events')),
          const SizedBox(height: 16),

          // Suspicious Activity Alerts
          // const SuspiciousActivityAlerts(),
          const Placeholder(child: Text('Suspicious Activity Alerts')),
          const SizedBox(height: 16),

          // Security Recommendations
          // const SecurityRecommendations(),
          const Placeholder(child: Text('Security Recommendations')),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'audit_logs':
        _navigateToAuditLogs();
        break;
      case 'devices':
        _navigateToDeviceManagement();
        break;
    }
  }

  void _navigateToAuditLogs() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SecurityAuditLogsScreen(),
      ),
    );
  }

  void _navigateToDeviceManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeviceManagementScreen(),
      ),
    );
  }
}

/// Security audit logs screen
class SecurityAuditLogsScreen extends ConsumerStatefulWidget {
  const SecurityAuditLogsScreen({super.key});

  @override
  ConsumerState<SecurityAuditLogsScreen> createState() => _SecurityAuditLogsScreenState();
}

class _SecurityAuditLogsScreenState extends ConsumerState<SecurityAuditLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Restore when customerSecurityProvider is implemented
      // ref.read(customerSecurityProvider.notifier).loadAuditLogs(limit: 50);
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Restore when customerSecurityProvider is implemented
    // final securityState = ref.watch(customerSecurityProvider);
    // final auditLogs = securityState.auditLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Audit Logs'),
        // TODO: Restore when AppTheme is implemented
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // TODO: Restore when auditLogs is implemented
      body: const Center(child: Text('Security audit logs not available')),
      /*body: auditLogs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No security events found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: auditLogs.length,
              itemBuilder: (context, index) {
                final log = auditLogs[index];
                // TODO: Restore when SecurityAuditLogCard is implemented
                // return SecurityAuditLogCard(log: log);
                return ListTile(
                  title: Text(log.action ?? 'Security Action'),
                  subtitle: Text(log.timestamp?.toString() ?? 'Unknown time'),
                  trailing: Icon(
                    log.isSuccessful == true ? Icons.check_circle : Icons.error,
                    color: log.isSuccessful == true ? Colors.green : Colors.red,
                  ),
                );
              },
            ),*/
    );
  }
}

/// Device management screen
class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends ConsumerState<DeviceManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Restore when customerSecurityProvider is implemented
      // ref.read(customerSecurityProvider.notifier).loadUserDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Restore when customerSecurityProvider is implemented
    // final securityState = ref.watch(customerSecurityProvider);
    // final devices = securityState.devices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        // TODO: Restore when AppTheme is implemented
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // TODO: Restore when devices is implemented
      body: const Center(child: Text('Device management not available')),
      /*body: devices.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No devices found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                // TODO: Restore when DeviceInfoCard is implemented
                // return DeviceInfoCard(device: device);
                return ListTile(
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Text(device.platform ?? 'Unknown Platform'),
                  trailing: Text(device.lastActive?.toString() ?? 'Never'),
                );
              },
            ),*/
    );
  }
  */
}


