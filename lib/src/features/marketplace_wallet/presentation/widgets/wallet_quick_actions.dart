import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/wallet_state_provider.dart';

class WalletQuickActions extends ConsumerWidget {
  final String userRole;

  const WalletQuickActions({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(currentUserWalletProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionGrid(context, ref, walletState.wallet?.id),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, WidgetRef ref, String? walletId) {
    final actions = _getActionsForRole(context, userRole, walletId);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          context,
          ref,
          action.icon,
          action.title,
          action.subtitle,
          action.color,
          action.onTap,
          action.isEnabled,
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback? onTap,
    bool isEnabled,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isEnabled ? null : theme.colorScheme.surface.withValues(alpha: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isEnabled ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isEnabled ? color : color.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  if (!isEnabled)
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled 
                      ? theme.colorScheme.onSurface 
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isEnabled 
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<QuickActionData> _getActionsForRole(BuildContext context, String role, String? walletId) {
    final baseActions = [
      QuickActionData(
        icon: Icons.receipt_long,
        title: 'Transaction History',
        subtitle: 'View all transactions',
        color: AppTheme.primaryColor,
        onTap: () => GoRouter.of(context).push('/wallet/transactions'),
        isEnabled: true,
      ),
      QuickActionData(
        icon: Icons.analytics,
        title: 'Analytics',
        subtitle: 'View earnings analytics',
        color: AppTheme.infoColor,
        onTap: () => GoRouter.of(context).push('/wallet/analytics'),
        isEnabled: true,
      ),
    ];

    switch (role) {
      case 'vendor':
        return [
          ...baseActions,
          QuickActionData(
            icon: Icons.account_balance,
            title: 'Request Payout',
            subtitle: 'Withdraw earnings',
            color: AppTheme.successColor,
            onTap: () => GoRouter.of(context).push('/wallet/payout/create'),
            isEnabled: walletId != null,
          ),
          QuickActionData(
            icon: Icons.monetization_on,
            title: 'Commission Tracking',
            subtitle: 'Track order commissions',
            color: AppTheme.warningColor,
            onTap: () => GoRouter.of(context).push('/wallet/commissions'),
            isEnabled: true,
          ),
        ];

      case 'sales_agent':
        return [
          ...baseActions,
          QuickActionData(
            icon: Icons.account_balance,
            title: 'Request Payout',
            subtitle: 'Withdraw commissions',
            color: AppTheme.successColor,
            onTap: () => GoRouter.of(context).push('/wallet/payout/create'),
            isEnabled: walletId != null,
          ),
          QuickActionData(
            icon: Icons.trending_up,
            title: 'Sales Performance',
            subtitle: 'View sales metrics',
            color: AppTheme.warningColor,
            onTap: () => GoRouter.of(context).push('/wallet/performance'),
            isEnabled: true,
          ),
        ];

      case 'driver':
        return [
          ...baseActions,
          QuickActionData(
            icon: Icons.account_balance,
            title: 'Request Payout',
            subtitle: 'Withdraw earnings',
            color: AppTheme.successColor,
            onTap: () => GoRouter.of(context).push('/wallet/payout/create'),
            isEnabled: walletId != null,
          ),
          QuickActionData(
            icon: Icons.local_shipping,
            title: 'Delivery Earnings',
            subtitle: 'Track delivery income',
            color: AppTheme.warningColor,
            onTap: () => GoRouter.of(context).push('/wallet/delivery-earnings'),
            isEnabled: true,
          ),
        ];

      case 'customer':
        return [
          ...baseActions,
          QuickActionData(
            icon: Icons.add_card,
            title: 'Add Funds',
            subtitle: 'Top up wallet balance',
            color: AppTheme.successColor,
            onTap: () => GoRouter.of(context).push('/customer/wallet/top-up'),
            isEnabled: walletId != null,
          ),
          QuickActionData(
            icon: Icons.card_giftcard,
            title: 'Rewards',
            subtitle: 'View loyalty rewards',
            color: AppTheme.warningColor,
            onTap: () => GoRouter.of(context).push('/wallet/rewards'),
            isEnabled: true,
          ),
        ];

      case 'admin':
        return [
          QuickActionData(
            icon: Icons.dashboard,
            title: 'Platform Overview',
            subtitle: 'System-wide metrics',
            color: AppTheme.primaryColor,
            onTap: () => GoRouter.of(context).push('/admin/wallet-overview'),
            isEnabled: true,
          ),
          QuickActionData(
            icon: Icons.account_balance,
            title: 'Payout Management',
            subtitle: 'Manage all payouts',
            color: AppTheme.infoColor,
            onTap: () => GoRouter.of(context).push('/admin/payouts'),
            isEnabled: true,
          ),
          QuickActionData(
            icon: Icons.security,
            title: 'Audit Logs',
            subtitle: 'Financial audit trail',
            color: AppTheme.warningColor,
            onTap: () => GoRouter.of(context).push('/admin/audit-logs'),
            isEnabled: true,
          ),
          QuickActionData(
            icon: Icons.settings,
            title: 'Commission Settings',
            subtitle: 'Manage commission rates',
            color: AppTheme.successColor,
            onTap: () => GoRouter.of(context).push('/admin/commission-settings'),
            isEnabled: true,
          ),
        ];

      default:
        return baseActions;
    }
  }
}

class QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });
}

/// Role-specific quick action widgets
class VendorQuickActions extends ConsumerWidget {
  const VendorQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletQuickActions(userRole: 'vendor');
  }
}

class SalesAgentQuickActions extends ConsumerWidget {
  const SalesAgentQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletQuickActions(userRole: 'sales_agent');
  }
}

class DriverQuickActions extends ConsumerWidget {
  const DriverQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletQuickActions(userRole: 'driver');
  }
}

class CustomerQuickActions extends ConsumerWidget {
  const CustomerQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletQuickActions(userRole: 'customer');
  }
}

class AdminQuickActions extends ConsumerWidget {
  const AdminQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletQuickActions(userRole: 'admin');
  }
}
