import 'package:flutter/material.dart';

/// Quick actions grid for wallet operations
class WalletQuickActionsGrid extends StatelessWidget {
  final VoidCallback? onTopUpPressed;
  final VoidCallback? onTransferPressed;
  final VoidCallback? onTransactionsPressed;
  final VoidCallback? onPaymentMethodsPressed;
  final VoidCallback? onLoyaltyPressed;
  final VoidCallback? onSettingsPressed;

  const WalletQuickActionsGrid({
    super.key,
    this.onTopUpPressed,
    this.onTransferPressed,
    this.onTransactionsPressed,
    this.onPaymentMethodsPressed,
    this.onLoyaltyPressed,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                _buildActionItem(
                  theme: theme,
                  icon: Icons.add_circle,
                  label: 'Top Up',
                  color: theme.colorScheme.primary,
                  onPressed: onTopUpPressed,
                ),
                _buildActionItem(
                  theme: theme,
                  icon: Icons.send,
                  label: 'Transfer',
                  color: theme.colorScheme.secondary,
                  onPressed: onTransferPressed,
                ),
                _buildActionItem(
                  theme: theme,
                  icon: Icons.receipt_long,
                  label: 'History',
                  color: theme.colorScheme.tertiary,
                  onPressed: onTransactionsPressed,
                ),
                _buildActionItem(
                  theme: theme,
                  icon: Icons.credit_card,
                  label: 'Cards',
                  color: Colors.purple,
                  onPressed: onPaymentMethodsPressed,
                ),
                _buildActionItem(
                  theme: theme,
                  icon: Icons.stars,
                  label: 'Loyalty',
                  color: Colors.orange,
                  onPressed: onLoyaltyPressed,
                ),
                _buildActionItem(
                  theme: theme,
                  icon: Icons.settings,
                  label: 'Settings',
                  color: Colors.grey,
                  onPressed: onSettingsPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
