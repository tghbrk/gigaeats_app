import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/enhanced_order_tracking_provider.dart';
import '../../data/models/order_tracking_models.dart';
import '../../data/models/order.dart';
import '../../../core/utils/logger.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';

/// Enhanced order tracking screen with real-time updates
class EnhancedOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const EnhancedOrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<EnhancedOrderTrackingScreen> createState() => _EnhancedOrderTrackingScreenState();
}

class _EnhancedOrderTrackingScreenState extends ConsumerState<EnhancedOrderTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start tracking when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enhancedOrderTrackingProvider.notifier).startTracking(widget.orderId);
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    
    // Stop tracking when screen is disposed
    ref.read(enhancedOrderTrackingProvider.notifier).stopTracking(widget.orderId);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingStatus = ref.watch(orderTrackingStatusProvider(widget.orderId));
    final timeline = ref.watch(orderTrackingTimelineProvider(widget.orderId));
    final recentUpdates = ref.watch(orderTrackingUpdatesProvider(widget.orderId));
    final isTracking = ref.watch(isOrderTrackingProvider(widget.orderId));
    final error = ref.watch(orderTrackingErrorProvider);

    return Scaffold(
      appBar: _buildAppBar(theme, trackingStatus),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () => _refreshTracking(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error != null) ...[
                  _buildErrorCard(theme, error),
                  const SizedBox(height: 16),
                ],
                if (trackingStatus != null) ...[
                  _buildOrderHeader(theme, trackingStatus),
                  const SizedBox(height: 24),
                  _buildProgressIndicator(theme, trackingStatus),
                  const SizedBox(height: 24),
                  _buildTimeline(theme, timeline),
                  const SizedBox(height: 24),
                  _buildContactInfo(theme, trackingStatus),
                  if (trackingStatus.deliveryTracking != null) ...[
                    const SizedBox(height: 24),
                    _buildDeliveryTracking(theme, trackingStatus.deliveryTracking!),
                  ],
                  const SizedBox(height: 24),
                  _buildRecentUpdates(theme, recentUpdates),
                ] else if (isTracking) ...[
                  _buildLoadingState(theme),
                ] else ...[
                  _buildNoDataState(theme),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(theme, trackingStatus),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, OrderTrackingStatus? trackingStatus) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track Order',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (trackingStatus != null)
            Text(
              trackingStatus.orderNumber,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.arrow_back,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _refreshTracking,
          icon: Icon(
            Icons.refresh,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(enhancedOrderTrackingProvider.notifier).clearError(),
            child: Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(ThemeData theme, OrderTrackingStatus trackingStatus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trackingStatus.vendorInfo.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order ${trackingStatus.orderNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(theme, trackingStatus.currentStatus),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusDisplayName(trackingStatus.currentStatus),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, OrderTrackingStatus trackingStatus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(trackingStatus.progress * 100).toInt()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: trackingStatus.progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme, List<OrderTrackingTimelineEntry> timeline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...timeline.asMap().entries.map((entry) {
            final index = entry.key;
            final timelineEntry = entry.value;
            final isLast = index == timeline.length - 1;
            
            return _buildTimelineItem(theme, timelineEntry, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ThemeData theme, OrderTrackingTimelineEntry entry, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedBuilder(
              animation: entry.isCurrent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: entry.isCurrent ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: entry.isCompleted || entry.isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: entry.isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: entry.isCompleted
                        ? Icon(
                            Icons.check,
                            size: 12,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                );
              },
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: entry.isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: entry.isCompleted || entry.isCurrent
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry.timestamp != null)
                  Text(
                    _formatTimestamp(entry.timestamp!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontStyle: entry.isEstimated ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(ThemeData theme, OrderTrackingStatus trackingStatus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            theme,
            'Restaurant',
            trackingStatus.vendorInfo.name,
            trackingStatus.vendorInfo.phone,
            Icons.restaurant,
          ),
          if (trackingStatus.driverInfo != null) ...[
            const SizedBox(height: 12),
            _buildContactItem(
              theme,
              'Driver',
              trackingStatus.driverInfo!.name,
              trackingStatus.driverInfo!.phone,
              Icons.delivery_dining,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem(ThemeData theme, String label, String name, String? phone, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (phone != null)
          IconButton(
            onPressed: () => _callContact(phone),
            icon: Icon(
              Icons.phone,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryTracking(ThemeData theme, DeliveryTracking tracking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Tracking',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tracking.address ?? 'Location: ${tracking.latitude.toStringAsFixed(6)}, ${tracking.longitude.toStringAsFixed(6)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${_formatTimestamp(tracking.timestamp)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUpdates(ThemeData theme, List<OrderTrackingUpdate> updates) {
    if (updates.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Updates',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...updates.take(3).map((update) => _buildUpdateItem(theme, update)),
        ],
      ),
    );
  }

  Widget _buildUpdateItem(ThemeData theme, OrderTrackingUpdate update) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTimestamp(update.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading order tracking...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.track_changes,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Tracking Data',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load tracking information for this order.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, OrderTrackingStatus? trackingStatus) {
    return Column(
      children: [
        GEButton.primary(
          text: 'View Order Details',
          onPressed: () => _viewOrderDetails(),
          icon: Icons.receipt_long,
        ),
        const SizedBox(height: 12),
        GEButton.outline(
          text: 'Contact Support',
          onPressed: () => _contactSupport(),
          icon: Icons.support_agent,
        ),
      ],
    );
  }

  Color _getStatusColor(ThemeData theme, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.outForDelivery:
        return Colors.teal;
      case OrderStatus.delivered:
        return theme.colorScheme.tertiary;
      case OrderStatus.cancelled:
        return theme.colorScheme.error;
    }
  }

  String _getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _refreshTracking() async {
    await ref.read(enhancedOrderTrackingProvider.notifier).refreshTrackingStatus(widget.orderId);
  }

  void _callContact(String phone) {
    _logger.info('📞 [ORDER-TRACKING] Calling contact: $phone');
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
  }

  void _viewOrderDetails() {
    _logger.info('📋 [ORDER-TRACKING] Viewing order details');
    context.go('/orders/${widget.orderId}');
  }

  void _contactSupport() {
    _logger.info('🆘 [ORDER-TRACKING] Contacting support');
    // TODO: Implement support contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening support chat...')),
    );
  }
}
