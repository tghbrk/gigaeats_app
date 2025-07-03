import 'package:flutter/material.dart';

/// Quick action widget for analytics
class AnalyticsQuickActionWidget extends StatelessWidget {
  final List<QuickAction> actions;

  const AnalyticsQuickActionWidget({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((action) => _QuickActionButton(action: action)).toList(),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: action.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              color: action.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: action.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action model
class QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

/// Default quick actions for analytics
class DefaultAnalyticsQuickActions {
  static List<QuickAction> get defaultActions => [
    QuickAction(
      label: 'Export Data',
      icon: Icons.download,
      color: Colors.blue,
      onTap: () {
        // TODO: Implement export functionality
      },
    ),
    QuickAction(
      label: 'Set Budget',
      icon: Icons.savings,
      color: Colors.green,
      onTap: () {
        // TODO: Implement budget setting
      },
    ),
    QuickAction(
      label: 'View Reports',
      icon: Icons.analytics,
      color: Colors.orange,
      onTap: () {
        // TODO: Implement reports view
      },
    ),
    QuickAction(
      label: 'Settings',
      icon: Icons.settings,
      color: Colors.grey,
      onTap: () {
        // TODO: Implement settings navigation
      },
    ),
  ];
}
