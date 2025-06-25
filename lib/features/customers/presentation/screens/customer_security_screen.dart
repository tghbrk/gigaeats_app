import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/customer_security_provider.dart';
import '../widgets/security_widgets.dart';
import '../widgets/customer_wallet_error_widget.dart';
import '../../data/models/customer_wallet_error.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerSecurityProvider.notifier).refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(customerSecurityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customerSecurityProvider.notifier).refreshAll(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
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
      body: securityState.isLoading
          ? const LoadingWidget()
          : securityState.errorMessage != null
              ? CustomerWalletErrorWidget(
                  error: CustomerWalletError.fromMessage(securityState.errorMessage!),
                  onRetry: () => ref.read(customerSecurityProvider.notifier).refreshAll(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAuthenticationTab(),
                    _buildPrivacyTab(),
                    _buildActivityTab(),
                  ],
                ),
    );
  }

  Widget _buildAuthenticationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Score Card
          const SecurityScoreCard(),
          const SizedBox(height: 24),

          // Biometric Authentication
          const BiometricAuthenticationCard(),
          const SizedBox(height: 16),

          // PIN Authentication
          const PINAuthenticationCard(),
          const SizedBox(height: 16),

          // Transaction Security
          const TransactionSecurityCard(),
          const SizedBox(height: 16),

          // Auto-lock Settings
          const AutoLockSettingsCard(),
          const SizedBox(height: 16),

          // Multi-factor Authentication
          const MFASettingsCard(),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy Overview
          const PrivacyOverviewCard(),
          const SizedBox(height: 24),

          // Data Protection
          const DataProtectionCard(),
          const SizedBox(height: 16),

          // Device Management
          const DeviceManagementCard(),
          const SizedBox(height: 16),

          // Location Privacy
          const LocationPrivacyCard(),
          const SizedBox(height: 16),

          // Communication Preferences
          const CommunicationPreferencesCard(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Activity Overview
          const SecurityActivityOverview(),
          const SizedBox(height: 24),

          // Recent Security Events
          const RecentSecurityEvents(),
          const SizedBox(height: 16),

          // Suspicious Activity Alerts
          const SuspiciousActivityAlerts(),
          const SizedBox(height: 16),

          // Security Recommendations
          const SecurityRecommendations(),
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
      ref.read(customerSecurityProvider.notifier).loadAuditLogs(limit: 50);
    });
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(customerSecurityProvider);
    final auditLogs = securityState.auditLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Audit Logs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: auditLogs.isEmpty
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
                return SecurityAuditLogCard(log: log);
              },
            ),
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
      ref.read(customerSecurityProvider.notifier).loadUserDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(customerSecurityProvider);
    final devices = securityState.devices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: devices.isEmpty
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
                return DeviceInfoCard(device: device);
              },
            ),
    );
  }
}


