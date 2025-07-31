import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/driver_dashboard_header.dart';
import '../widgets/available_orders_section.dart';
import '../widgets/current_order_section.dart';
import '../widgets/earnings_summary_card.dart';
import '../widgets/wallet/driver_wallet_compact_card.dart';
import '../providers/driver_dashboard_providers.dart';

/// Comprehensive driver dashboard screen with real-time order management
class DriverOrdersScreen extends ConsumerWidget {
  const DriverOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final driverStatusAsync = ref.watch(currentDriverStatusProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh all driver data
            ref.invalidate(availableOrdersProvider);
            ref.invalidate(currentDriverOrderProvider);
            ref.invalidate(todayEarningsProvider);
            ref.invalidate(currentDriverStatusProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Dashboard Header with status toggle and summary
              const SliverToBoxAdapter(
                child: DriverDashboardHeader(),
              ),

              // Today's Earnings Summary
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: EarningsSummaryCard(),
                ),
              ),

              // Driver Wallet Summary
              const SliverToBoxAdapter(
                child: DriverWalletCompactCard(),
              ),

              // Current Order Section (if driver has an active order)
              const SliverToBoxAdapter(
                child: CurrentOrderSection(),
              ),

              // Available Orders Section
              SliverToBoxAdapter(
                child: driverStatusAsync.when(
                  data: (status) => status == 'online'
                    ? const AvailableOrdersSection()
                    : _buildOfflineMessage(theme),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => _buildErrorMessage(theme, error.toString()),
                ),
              ),

              // Bottom padding for better scrolling experience
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineMessage(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re Currently Offline',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go online to start receiving delivery orders',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme, String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
