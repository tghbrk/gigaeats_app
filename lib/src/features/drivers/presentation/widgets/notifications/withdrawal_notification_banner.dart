import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../notifications/data/models/notification.dart';
import '../../providers/driver_wallet_provider.dart';



/// Banner widget for displaying withdrawal-related notifications
class WithdrawalNotificationBanner extends ConsumerStatefulWidget {
  final AppNotification notification;
  final VoidCallback? onDismiss;

  const WithdrawalNotificationBanner({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  @override
  ConsumerState<WithdrawalNotificationBanner> createState() => _WithdrawalNotificationBannerState();
}

class _WithdrawalNotificationBannerState extends ConsumerState<WithdrawalNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationData = widget.notification.data ?? {};
    final withdrawalType = notificationData['type'] as String? ?? 'unknown';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _getNotificationGradient(withdrawalType),
                    border: Border.all(
                      color: _getNotificationColor(withdrawalType).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _handleNotificationTap(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            children: [
                              _buildNotificationIcon(withdrawalType),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.notification.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTimeAgo(widget.notification.createdAt),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.onDismiss != null)
                                IconButton(
                                  onPressed: _handleDismiss,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Message
                          Text(
                            widget.notification.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          
                          // Additional details for specific notification types
                          if (notificationData.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildNotificationDetails(theme, notificationData),
                          ],
                          
                          // Action buttons
                          const SizedBox(height: 16),
                          _buildActionButtons(context, theme, withdrawalType, notificationData),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(String withdrawalType) {
    IconData iconData;
    
    switch (withdrawalType) {
      case 'withdrawal_completed':
        iconData = Icons.check_circle;
        break;
      case 'withdrawal_failed':
        iconData = Icons.error;
        break;
      case 'withdrawal_processing':
        iconData = Icons.sync;
        break;
      case 'withdrawal_pending':
        iconData = Icons.schedule;
        break;
      case 'balance_update':
        iconData = Icons.account_balance_wallet;
        break;
      default:
        iconData = Icons.notifications;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationDetails(ThemeData theme, Map<String, dynamic> data) {
    final details = <Widget>[];
    
    // Amount information
    if (data['amount'] != null) {
      final amount = data['amount'] as double;
      details.add(
        _buildDetailRow(
          theme,
          'Amount',
          'RM ${amount.toStringAsFixed(2)}',
          Icons.attach_money,
        ),
      );
    }
    
    // Net amount (if different from amount)
    if (data['net_amount'] != null && data['amount'] != null) {
      final netAmount = data['net_amount'] as double;
      final amount = data['amount'] as double;
      if ((netAmount - amount).abs() > 0.01) {
        details.add(
          _buildDetailRow(
            theme,
            'Net Amount',
            'RM ${netAmount.toStringAsFixed(2)}',
            Icons.money_off,
          ),
        );
      }
    }
    
    // Withdrawal method
    if (data['withdrawal_method'] != null) {
      details.add(
        _buildDetailRow(
          theme,
          'Method',
          _formatWithdrawalMethod(data['withdrawal_method'] as String),
          Icons.payment,
        ),
      );
    }
    
    // Transaction reference
    if (data['transaction_reference'] != null) {
      details.add(
        _buildDetailRow(
          theme,
          'Reference',
          data['transaction_reference'] as String,
          Icons.receipt,
        ),
      );
    }
    
    if (details.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: details,
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    String withdrawalType,
    Map<String, dynamic> data,
  ) {
    final buttons = <Widget>[];
    
    // View details button
    if (data['withdrawal_id'] != null) {
      buttons.add(
        TextButton.icon(
          onPressed: () => _viewWithdrawalDetails(context, data['withdrawal_id'] as String),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View Details'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      );
    }
    
    // Retry button for failed withdrawals
    if (withdrawalType == 'withdrawal_failed' && data['can_retry'] == true) {
      buttons.add(
        TextButton.icon(
          onPressed: () => _retryWithdrawal(context),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      );
    }
    
    // Contact support button for failures
    if (withdrawalType == 'withdrawal_failed' && data['support_contact'] == true) {
      buttons.add(
        TextButton.icon(
          onPressed: () => _contactSupport(context),
          icon: const Icon(Icons.support_agent, size: 16),
          label: const Text('Support'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      );
    }
    
    if (buttons.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: buttons,
    );
  }

  Color _getNotificationColor(String withdrawalType) {
    switch (withdrawalType) {
      case 'withdrawal_completed':
        return Colors.green;
      case 'withdrawal_failed':
        return Colors.red;
      case 'withdrawal_processing':
        return Colors.blue;
      case 'withdrawal_pending':
        return Colors.orange;
      case 'balance_update':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  LinearGradient _getNotificationGradient(String withdrawalType) {
    final color = _getNotificationColor(withdrawalType);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withValues(alpha: 0.8),
      ],
    );
  }

  String _formatWithdrawalMethod(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'e_wallet':
        return 'E-Wallet';
      case 'cash_pickup':
        return 'Cash Pickup';
      default:
        return method.replaceAll('_', ' ').split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
        ).join(' ');
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleNotificationTap(BuildContext context) {
    final withdrawalId = widget.notification.data?['withdrawal_id'] as String?;
    if (withdrawalId != null) {
      _viewWithdrawalDetails(context, withdrawalId);
    }
  }

  void _handleDismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  void _viewWithdrawalDetails(BuildContext context, String withdrawalId) {
    context.push('/driver/wallet/withdrawal/$withdrawalId');
  }

  void _retryWithdrawal(BuildContext context) {
    // Check wallet verification before allowing retry
    final walletState = ref.read(driverWalletProvider);
    final canWithdraw = walletState.wallet?.isActive == true &&
                       walletState.wallet?.isVerified == true;

    if (canWithdraw) {
      context.push('/driver/wallet/withdraw');
    } else {
      // Show verification required message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet verification required before withdrawals'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _contactSupport(BuildContext context) {
    // TODO: Implement support contact functionality
    debugPrint('📞 [WITHDRAWAL-NOTIFICATION-BANNER] Contact support requested');
  }
}
