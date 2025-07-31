import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_dashboard_providers.dart';

/// Toggle widget for driver online/offline status
class DriverStatusToggle extends ConsumerWidget {
  const DriverStatusToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final driverStatusAsync = ref.watch(currentDriverStatusProvider);
    final statusNotifier = ref.read(driverStatusNotifierProvider.notifier);

    return driverStatusAsync.when(
      data: (status) => _buildToggle(theme, status, statusNotifier),
      loading: () => _buildLoadingToggle(theme),
      error: (error, stack) => _buildErrorToggle(theme, error.toString()),
    );
  }

  Widget _buildToggle(ThemeData theme, String status, DriverStatusNotifier notifier) {
    final isOnline = status == 'online';

    return GestureDetector(
      onTap: () => notifier.toggleStatus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Ultra minimal padding
        decoration: BoxDecoration(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10), // Smaller border radius
          border: Border.all(
            color: isOnline ? Colors.green : Colors.orange,
            width: 1, // Thinner border
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 6, // Even smaller dot
              height: 6,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
                boxShadow: isOnline ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.5),
                    blurRadius: 2, // Smaller shadow
                    spreadRadius: 0.5,
                  ),
                ] : null,
              ),
            ),
            const SizedBox(width: 3), // Even smaller spacing
            Text(
              isOnline ? 'ON' : 'OFF', // Shorter text
              style: theme.textTheme.labelSmall?.copyWith( // Smaller text
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 9, // Even smaller font size
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Ultra minimal padding
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10), // Smaller border radius
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          width: 1, // Thinner border
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 6, // Even smaller loading indicator
            height: 6,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 3), // Even smaller spacing
          Text(
            '...',  // Much shorter text
            style: theme.textTheme.labelSmall?.copyWith( // Smaller text
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 9, // Even smaller font size
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorToggle(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Ultra minimal padding
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10), // Smaller border radius
        border: Border.all(
          color: Colors.red,
          width: 1, // Thinner border
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 6, // Even smaller icon
            color: Colors.red,
          ),
          const SizedBox(width: 3), // Even smaller spacing
          Text(
            'ERR', // Shorter text
            style: theme.textTheme.labelSmall?.copyWith( // Smaller text
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 9, // Even smaller font size
            ),
          ),
        ],
      ),
    );
  }
}
