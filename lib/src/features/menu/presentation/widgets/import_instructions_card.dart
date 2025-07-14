import 'package:flutter/material.dart';

/// Widget showing import instructions and tips
class ImportInstructionsCard extends StatelessWidget {
  const ImportInstructionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Tips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTipItem(
              icon: Icons.check_circle_outline,
              title: 'Required Fields',
              description: 'Item Name, Category, and Base Price are mandatory for each item.',
            ),
            const SizedBox(height: 12),

            _buildTipItem(
              icon: Icons.format_list_bulleted,
              title: 'Categories',
              description: 'New categories will be created automatically if they don\'t exist.',
            ),
            const SizedBox(height: 12),

            _buildTipItem(
              icon: Icons.preview,
              title: 'Preview First',
              description: 'Always preview your data before importing to catch errors early.',
            ),
            const SizedBox(height: 12),

            _buildTipItem(
              icon: Icons.backup,
              title: 'Backup Recommended',
              description: 'Export your current menu before importing to have a backup.',
            ),
            const SizedBox(height: 12),
            
            _buildTipItem(
              icon: Icons.attach_money,
              title: 'Pricing',
              description: 'Use numbers only for prices (e.g., 12.50). Currency symbols will be ignored.',
            ),
            const SizedBox(height: 12),
            
            _buildTipItem(
              icon: Icons.code,
              title: 'Customizations',
              description: 'Use JSON format for customization options. Check template for examples.',
            ),
            const SizedBox(height: 12),
            
            _buildTipItem(
              icon: Icons.preview,
              title: 'Preview First',
              description: 'Always review the preview before final import to catch any issues.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
