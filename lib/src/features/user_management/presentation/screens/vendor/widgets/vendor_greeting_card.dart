import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../design_system/design_system.dart';
import '../../../../../../presentation/providers/repository_providers.dart';

/// Vendor Greeting Card Component
/// 
/// A rich greeting section that displays vendor information,
/// personalized greeting, current date, and quick action buttons.
class VendorGreetingCard extends ConsumerWidget {
  final Function(int)? onNavigateToTab;
  final VoidCallback? onViewOrders;
  final VoidCallback? onAddProduct;
  final VoidCallback? onContactSupport;

  const VendorGreetingCard({
    super.key,
    this.onNavigateToTab,
    this.onViewOrders,
    this.onAddProduct,
    this.onContactSupport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('👋 [GREETING-CARD] Building vendor greeting card');

    final theme = Theme.of(context);
    final vendorAsync = ref.watch(currentVendorProvider);

    debugPrint('👋 [GREETING-CARD] Vendor async state: ${vendorAsync.runtimeType}');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GESpacing.screenPadding,
        vertical: GESpacing.md,
      ),
      child: GECard.elevated(
        padding: const EdgeInsets.all(GESpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and greeting
            _buildGreetingHeader(context, theme, vendorAsync),
            
            const SizedBox(height: GESpacing.sm),
            
            // Date information
            _buildDateInfo(theme),
            
            const SizedBox(height: GESpacing.sm),
            
            // Quick action buttons
            _buildQuickActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, ThemeData theme, AsyncValue vendorAsync) {
    return Row(
      children: [
        // Avatar with gradient background
        _buildAvatar(vendorAsync),
        
        const SizedBox(width: GESpacing.sm),
        
        // Greeting text
        Expanded(
          child: _buildGreetingText(theme, vendorAsync),
        ),
      ],
    );
  }

  Widget _buildAvatar(AsyncValue vendorAsync) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        gradient: GEGradients.avatarGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: vendorAsync.when(
          data: (vendor) {
            if (vendor?.businessName != null) {
              // Get initials from business name
              final words = vendor!.businessName.split(' ');
              final initials = words.length >= 2
                  ? '${words[0][0]}${words[1][0]}'
                  : words[0].length >= 2
                      ? '${words[0][0]}${words[0][1]}'
                      : words[0][0];
              
              return Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return const Icon(
              Icons.store,
              color: Colors.white,
              size: 24,
            );
          },
          loading: () => const Icon(
            Icons.store,
            color: Colors.white,
            size: 24,
          ),
          error: (_, __) => const Icon(
            Icons.store,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingText(ThemeData theme, AsyncValue vendorAsync) {
    final greeting = _getTimeBasedGreeting();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: GEVendorColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        vendorAsync.when(
          data: (vendor) => Text(
            'Welcome back to ${vendor?.businessName ?? 'your restaurant'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GEVendorColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => Text(
            'Loading...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GEVendorColors.textSecondary,
            ),
          ),
          error: (_, __) => Text(
            'Welcome back',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GEVendorColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(ThemeData theme) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    
    return Text(
      dateFormat.format(now),
      style: theme.textTheme.bodySmall?.copyWith(
        color: GEVendorColors.textLight,
        fontSize: 14,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // View Orders button
        Expanded(
          child: _buildQuickActionButton(
            context: context,
            label: 'View Orders',
            icon: Icons.receipt_long,
            color: GEVendorColors.quickActionPrimary,
            onTap: onViewOrders ?? () => onNavigateToTab?.call(1),
          ),
        ),
        
        const SizedBox(width: GESpacing.xs),
        
        // Add Product button
        Expanded(
          child: _buildQuickActionButton(
            context: context,
            label: 'Add Product',
            icon: Icons.add,
            color: GEVendorColors.quickActionSecondary,
            onTap: onAddProduct ?? () => onNavigateToTab?.call(2),
          ),
        ),
        
        const SizedBox(width: GESpacing.xs),
        
        // Support button
        Expanded(
          child: _buildQuickActionButton(
            context: context,
            label: 'Support',
            icon: Icons.headset_mic,
            color: GEVendorColors.quickActionTertiary,
            onTap: onContactSupport ?? () => _showSupportDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GESpacing.xs),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: GESpacing.sm,
            horizontal: GESpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(GESpacing.xs),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Need help? Our support team is here to assist you with any questions or issues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement support contact functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support contact feature coming soon!'),
                ),
              );
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}
