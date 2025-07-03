import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_activity_log.dart';
import '../providers/admin_providers_index.dart';
import '../../../../shared/widgets/dashboard_card.dart';

// ============================================================================
// ENHANCED DASHBOARD STATS CARDS
// ============================================================================

/// Enhanced stats cards with real-time data
class EnhancedStatsCards extends ConsumerWidget {
  const EnhancedStatsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStatsAsync = ref.watch(adminDashboardStatsProvider);

    return dashboardStatsAsync.when(
      data: (stats) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Users',
                  value: stats.totalUsers.toString(),
                  subtitle: '+${stats.newUsersToday} today',
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to user management
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Total Revenue',
                  value: 'RM ${stats.totalRevenue.toStringAsFixed(2)}',
                  subtitle: 'RM ${stats.todayRevenue.toStringAsFixed(2)} today',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  onTap: () {
                    // Navigate to revenue analytics
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Orders',
                  value: stats.totalOrders.toString(),
                  subtitle: '${stats.todayOrders} today',
                  icon: Icons.receipt_long,
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to orders
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Active Vendors',
                  value: stats.activeVendors.toString(),
                  subtitle: '${stats.pendingVendors} pending',
                  icon: Icons.store,
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to vendor management
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const _LoadingStatsCards(),
      error: (error, stack) => _ErrorStatsCards(error: error.toString()),
    );
  }
}

/// Loading state for stats cards
class _LoadingStatsCards extends StatelessWidget {
  const _LoadingStatsCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Users',
                value: '---',
                subtitle: 'Loading...',
                icon: Icons.people,
                color: Colors.blue,
                isLoading: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Total Revenue',
                value: '---',
                subtitle: 'Loading...',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
                isLoading: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Orders',
                value: '---',
                subtitle: 'Loading...',
                icon: Icons.receipt_long,
                color: Colors.purple,
                isLoading: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Active Vendors',
                value: '---',
                subtitle: 'Loading...',
                icon: Icons.store,
                color: Colors.orange,
                isLoading: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Error state for stats cards
class _ErrorStatsCards extends StatelessWidget {
  final String error;

  const _ErrorStatsCards({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load dashboard statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REAL-TIME ACTIVITY FEED
// ============================================================================

/// Real-time activity feed widget
class RealTimeActivityFeed extends ConsumerWidget {
  const RealTimeActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentActivity = ref.watch(adminRecentActivityProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full activity log
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentActivity.isEmpty)
          const _EmptyActivityFeed()
        else
          ...recentActivity.take(5).map((activity) => _ActivityItem(activity: activity)),
      ],
    );
  }
}

/// Individual activity item
class _ActivityItem extends StatelessWidget {
  final AdminActivityLog activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(activity.actionType).withValues(alpha: 0.1),
          child: Icon(
            _getActionIcon(activity.actionType),
            color: _getActionColor(activity.actionType),
            size: 20,
          ),
        ),
        title: Text(_getActionDescription(activity)),
        subtitle: Text(_formatTimeAgo(activity.createdAt)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to activity details
        },
      ),
    );
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'user_created':
      case 'user_activated':
        return Colors.green;
      case 'user_deactivated':
      case 'user_deleted':
        return Colors.red;
      case 'vendor_approved':
        return Colors.blue;
      case 'vendor_rejected':
        return Colors.orange;
      case 'order_cancelled':
        return Colors.red;
      case 'system_setting_updated':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'user_created':
        return Icons.person_add;
      case 'user_activated':
        return Icons.check_circle;
      case 'user_deactivated':
        return Icons.block;
      case 'user_deleted':
        return Icons.delete;
      case 'vendor_approved':
        return Icons.store;
      case 'vendor_rejected':
        return Icons.store_mall_directory_outlined;
      case 'order_cancelled':
        return Icons.cancel;
      case 'system_setting_updated':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  String _getActionDescription(AdminActivityLog activity) {
    final actionDesc = AdminActionType.getDescription(activity.actionType);
    final targetDesc = AdminTargetType.getDescription(activity.targetType);
    
    return '$actionDesc - $targetDesc';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

/// Empty activity feed state
class _EmptyActivityFeed extends StatelessWidget {
  const _EmptyActivityFeed();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Admin activities will appear here',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SYSTEM HEALTH INDICATOR
// ============================================================================

/// System health status widget
class SystemHealthIndicator extends ConsumerWidget {
  const SystemHealthIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(adminAnalyticsProvider);
    final connectionStatus = ref.watch(adminConnectionStatusProvider);
    final lastUpdate = ref.watch(adminLastUpdateProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connectionStatus ? Icons.check_circle : Icons.error,
                  color: connectionStatus ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  connectionStatus ? 'System Online' : 'Connection Issues',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lastUpdate != null)
              Text(
                'Last updated: ${_formatTime(lastUpdate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (analyticsState.systemHealth != null) ...[
              const SizedBox(height: 12),
              if (analyticsState.systemHealth!.alerts.isNotEmpty)
                ...analyticsState.systemHealth!.alerts.map((alert) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
