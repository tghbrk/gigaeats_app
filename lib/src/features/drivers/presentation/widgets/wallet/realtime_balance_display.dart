import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../providers/driver_wallet_provider.dart';
import '../../providers/realtime_withdrawal_notification_provider.dart';

/// Widget for displaying real-time wallet balance with live updates
class RealtimeBalanceDisplay extends ConsumerStatefulWidget {
  final bool showChangeIndicator;
  final bool showConnectionStatus;
  final TextStyle? balanceTextStyle;
  final EdgeInsetsGeometry? padding;

  const RealtimeBalanceDisplay({
    super.key,
    this.showChangeIndicator = true,
    this.showConnectionStatus = true,
    this.balanceTextStyle,
    this.padding,
  });

  @override
  ConsumerState<RealtimeBalanceDisplay> createState() => _RealtimeBalanceDisplayState();
}

class _RealtimeBalanceDisplayState extends ConsumerState<RealtimeBalanceDisplay>
    with TickerProviderStateMixin {
  late AnimationController _balanceChangeController;
  late AnimationController _pulseController;
  late Animation<double> _balanceChangeAnimation;
  late Animation<double> _pulseAnimation;
  
  double? _previousBalance;
  bool _showChangeIndicator = false;
  bool _isBalanceIncreasing = false;

  @override
  void initState() {
    super.initState();
    
    _balanceChangeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _balanceChangeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _balanceChangeController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _balanceChangeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showChangeIndicator = false;
        });
        _balanceChangeController.reset();
      }
    });
  }

  @override
  void dispose() {
    _balanceChangeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);
    final notificationState = ref.watch(realtimeWithdrawalNotificationProvider);

    // Check for balance changes
    if (walletState.wallet != null) {
      final currentBalance = walletState.wallet!.availableBalance;
      if (_previousBalance != null && _previousBalance != currentBalance) {
        _handleBalanceChange(_previousBalance!, currentBalance);
      }
      _previousBalance = currentBalance;
    }

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status indicator
          if (widget.showConnectionStatus)
            _buildConnectionStatus(theme, walletState, notificationState),
          
          if (widget.showConnectionStatus)
            const SizedBox(height: 8),
          
          // Balance display
          _buildBalanceDisplay(theme, walletState),
          
          // Balance change indicator
          if (widget.showChangeIndicator && _showChangeIndicator)
            _buildBalanceChangeIndicator(theme),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(
    ThemeData theme,
    DriverWalletState walletState,
    RealtimeWithdrawalNotificationState notificationState,
  ) {
    final isConnected = walletState.hasRealtimeConnection && notificationState.isActive;
    
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'Live Updates Active' : 'Connecting...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isConnected ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isConnected) ...[
          const SizedBox(width: 4),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Icon(
              Icons.wifi,
              size: 12,
              color: Colors.green,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBalanceDisplay(ThemeData theme, DriverWalletState walletState) {
    if (walletState.isLoading && walletState.wallet == null) {
      return _buildLoadingBalance(theme);
    }

    if (walletState.errorMessage != null) {
      return _buildErrorBalance(theme, walletState.errorMessage!);
    }

    if (walletState.wallet == null) {
      return _buildNoWalletBalance(theme);
    }

    final wallet = walletState.wallet!;
    
    return AnimatedBuilder(
      animation: _balanceChangeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_balanceChangeAnimation.value * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main balance
              Text(
                wallet.formattedAvailableBalance,
                style: widget.balanceTextStyle ?? theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              // Last updated time
              if (walletState.lastUpdated != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Updated ${_formatLastUpdated(walletState.lastUpdated!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceChangeIndicator(ThemeData theme) {
    return AnimatedBuilder(
      animation: _balanceChangeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _balanceChangeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -20 * _balanceChangeAnimation.value),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isBalanceIncreasing ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isBalanceIncreasing ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isBalanceIncreasing ? 'Balance Increased' : 'Balance Decreased',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingBalance(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 12,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBalance(ThemeData theme, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Balance Unavailable',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to retry',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildNoWalletBalance(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RM 0.00',
          style: widget.balanceTextStyle ?? theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Wallet not found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _handleBalanceChange(double previousBalance, double currentBalance) {
    if (!widget.showChangeIndicator) return;
    
    setState(() {
      _isBalanceIncreasing = currentBalance > previousBalance;
      _showChangeIndicator = true;
    });
    
    _balanceChangeController.forward();
    
    // Start pulse animation for connection indicator
    _pulseController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inSeconds < 30) {
      return 'just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
