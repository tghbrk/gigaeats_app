import 'package:flutter/material.dart';

/// Widget for downloading import templates
class TemplateDownloadCard extends StatelessWidget {
  final VoidCallback onDownloadCsv;
  final VoidCallback onDownloadExcel;
  final VoidCallback onViewInstructions;

  const TemplateDownloadCard({
    super.key,
    required this.onDownloadCsv,
    required this.onDownloadExcel,
    required this.onViewInstructions,
  });

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
                  Icons.download,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Download Template',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              'Start with our template to ensure your data is formatted correctly. Includes sample menu items and all required columns.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Download buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownloadCsv,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('CSV Template'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownloadExcel,
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Excel Template'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Instructions button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onViewInstructions,
                icon: const Icon(Icons.help_outline),
                label: const Text('View Detailed Instructions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
