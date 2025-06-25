import 'package:flutter/material.dart';

import '../../data/models/menu_import_data.dart';

/// Widget showing import summary with filter options
class ImportSummaryCard extends StatelessWidget {
  final MenuImportResult importResult;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ImportSummaryCard({
    super.key,
    required this.importResult,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.summarize,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Import Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('${importResult.totalRows} items'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Valid',
                      importResult.validRows,
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Errors',
                      importResult.errorRows,
                      Colors.red,
                      Icons.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Warnings',
                      importResult.warningRows,
                      Colors.orange,
                      Icons.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Success rate indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Success Rate',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: importResult.successRate,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getSuccessRateColor(importResult.successRate),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(importResult.successRate * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getSuccessRateColor(importResult.successRate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Filter chips
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('all', 'All Items', importResult.totalRows, context),
                  _buildFilterChip('valid', 'Valid Only', importResult.validRows, context),
                  if (importResult.errorRows > 0)
                    _buildFilterChip('errors', 'Errors', importResult.errorRows, context),
                  if (importResult.warningRows > 0)
                    _buildFilterChip('warnings', 'Warnings', importResult.warningRows, context),
                ],
              ),
              
              // Categories preview
              if (importResult.categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Categories (${importResult.categories.length})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: importResult.categories.take(5).map((category) =>
                    Chip(
                      label: Text(
                        category,
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ).toList()
                    ..addAll(importResult.categories.length > 5 ? [
                      Chip(
                        label: Text(
                          '+${importResult.categories.length - 5} more',
                          style: const TextStyle(fontSize: 12),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ] : []),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, int count, BuildContext context) {
    final isSelected = selectedFilter == filter;

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(filter),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
