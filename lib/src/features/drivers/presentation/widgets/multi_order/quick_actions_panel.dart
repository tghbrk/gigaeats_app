import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick actions panel for common multi-order operations
/// Provides easy access to frequently used batch management functions
class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildActionCard(
                theme,
                icon: Icons.navigation,
                label: 'Navigate',
                color: Colors.blue,
                onTap: () => _handleAction(context, 'navigate'),
              ),
              _buildActionCard(
                theme,
                icon: Icons.phone,
                label: 'Call Customer',
                color: Colors.green,
                onTap: () => _handleAction(context, 'call_customer'),
              ),
              _buildActionCard(
                theme,
                icon: Icons.message,
                label: 'Send Message',
                color: Colors.orange,
                onTap: () => _handleAction(context, 'send_message'),
              ),
              _buildActionCard(
                theme,
                icon: Icons.camera_alt,
                label: 'Take Photo',
                color: Colors.purple,
                onTap: () => _handleAction(context, 'take_photo'),
              ),
              _buildActionCard(
                theme,
                icon: Icons.report_problem,
                label: 'Report Issue',
                color: Colors.red,
                onTap: () => _handleAction(context, 'report_issue'),
              ),
              _buildActionCard(
                theme,
                icon: Icons.help_outline,
                label: 'Help',
                color: Colors.grey,
                onTap: () => _handleAction(context, 'help'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Batch actions
          Text(
            'Batch Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildBatchActionButton(
                  theme,
                  icon: Icons.pause,
                  label: 'Pause Batch',
                  color: Colors.orange,
                  onTap: () => _handleAction(context, 'pause_batch'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBatchActionButton(
                  theme,
                  icon: Icons.refresh,
                  label: 'Reoptimize',
                  color: Colors.blue,
                  onTap: () => _handleAction(context, 'reoptimize'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: _buildBatchActionButton(
              theme,
              icon: Icons.emergency,
              label: 'Emergency Stop',
              color: Colors.red,
              onTap: () => _handleAction(context, 'emergency_stop'),
            ),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    Navigator.of(context).pop();
    
    switch (action) {
      case 'navigate':
        _showSnackBar(context, 'Opening navigation...');
        // TODO: Implement navigation
        break;
      case 'call_customer':
        _showSnackBar(context, 'Calling customer...');
        // TODO: Implement phone call
        break;
      case 'send_message':
        _showSnackBar(context, 'Opening message composer...');
        // TODO: Implement messaging
        break;
      case 'take_photo':
        _showSnackBar(context, 'Opening camera...');
        // TODO: Implement photo capture
        break;
      case 'report_issue':
        _showSnackBar(context, 'Opening issue reporter...');
        // TODO: Implement issue reporting
        break;
      case 'help':
        _showSnackBar(context, 'Opening help...');
        // TODO: Implement help system
        break;
      case 'pause_batch':
        _showConfirmationDialog(
          context,
          title: 'Pause Batch',
          message: 'Are you sure you want to pause the current batch?',
          onConfirm: () => _showSnackBar(context, 'Batch paused'),
        );
        break;
      case 'reoptimize':
        _showSnackBar(context, 'Reoptimizing route...');
        // TODO: Implement reoptimization
        break;
      case 'emergency_stop':
        _showConfirmationDialog(
          context,
          title: 'Emergency Stop',
          message: 'This will immediately stop the current batch and require manual intervention. Continue?',
          onConfirm: () => _showSnackBar(context, 'Emergency stop activated'),
          isDestructive: true,
        );
        break;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
