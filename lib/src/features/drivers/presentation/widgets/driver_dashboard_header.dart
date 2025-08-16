import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/driver_dashboard_providers.dart';
import 'driver_status_toggle.dart';
import '../../../../core/constants/app_routes.dart';

/// Header widget for the driver dashboard with greeting, status, and quick stats
class DriverDashboardHeader extends ConsumerStatefulWidget {
  const DriverDashboardHeader({super.key});

  @override
  ConsumerState<DriverDashboardHeader> createState() => _DriverDashboardHeaderState();
}

class _DriverDashboardHeaderState extends ConsumerState<DriverDashboardHeader> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final driverStatusAsync = ref.watch(currentDriverStatusProvider);
    final todayEarningsAsync = ref.watch(todayEarningsProvider);
    
    final userName = authState.user?.fullName ?? 'Driver';
    final greeting = _getGreeting();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3, // Give more space to the title area
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long names gracefully
                      maxLines: 2, // Allow title to wrap to 2 lines if needed
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12), // Add spacing between title and actions
              // Action Buttons Row - Simple and constrained
              SizedBox(
                width: 90, // Fixed width to prevent overflow
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Multi-Order Dashboard Button - Ultra compact
                    SizedBox(
                      width: 24, // Very small fixed width
                      height: 24, // Very small fixed height
                      child: IconButton(
                        onPressed: () {
                          debugPrint('🚛 [MULTI-ORDER-BUTTON] Multi-Order Dashboard button pressed');
                          context.go(AppRoutes.driverMultiOrderDashboard);
                        },
                        icon: const Icon(Icons.route, size: 14), // Very small icon
                        tooltip: 'Multi-Order',
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.zero, // No padding
                        ),
                      ),
                    ),
                    const SizedBox(width: 2), // Minimal spacing
                    // Driver Status Toggle
                    const DriverStatusToggle(),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats Row
          Row(
            children: [
              // Today's Orders
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: Icons.assignment_turned_in,
                  label: 'Today\'s Orders',
                  value: todayEarningsAsync.when(
                    data: (earnings) => '${earnings['orderCount']}',
                    loading: () => '...',
                    error: (error, stackTrace) => '0',
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Today's Earnings
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: Icons.account_balance_wallet,
                  label: 'Today\'s Earnings',
                  value: todayEarningsAsync.when(
                    data: (earnings) => 'RM${(earnings['totalEarnings'] as double).toStringAsFixed(2)}',
                    loading: () => '...',
                    error: (error, stackTrace) => 'RM0.00',
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Status Indicator
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: Icons.circle,
                  label: 'Status',
                  value: driverStatusAsync.when(
                    data: (status) => status.toUpperCase(),
                    loading: () => '...',
                    error: (error, stackTrace) => 'OFFLINE',
                  ),
                  valueColor: driverStatusAsync.when(
                    data: (status) => status == 'online' 
                        ? Colors.green 
                        : Colors.orange,
                    loading: () => theme.colorScheme.onPrimary,
                    error: (error, stackTrace) => Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onPrimary,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
