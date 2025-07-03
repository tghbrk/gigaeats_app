import 'package:flutter/material.dart';

import '../../data/models/menu_import_data.dart';

/// Widget for displaying individual import item in preview
class ImportPreviewItemCard extends StatelessWidget {
  final MenuImportRow importRow;
  final VoidCallback? onTap;

  const ImportPreviewItemCard({
    super.key,
    required this.importRow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Row number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Row ${importRow.rowNumber}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Spacer(),
                  
                  // Status badges
                  if (importRow.hasErrors)
                    _buildStatusBadge('Error', Colors.red),
                  if (importRow.hasWarnings && !importRow.hasErrors)
                    _buildStatusBadge('Warning', Colors.orange),
                  if (importRow.isValid && !importRow.hasWarnings)
                    _buildStatusBadge('Valid', Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              
              // Item details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name
                        Text(
                          importRow.name.isNotEmpty ? importRow.name : 'Unnamed Item',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: importRow.name.isEmpty ? Colors.red : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Category and price
                        Row(
                          children: [
                            if (importRow.category.isNotEmpty) ...[
                              Icon(
                                Icons.category,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                importRow.category,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'RM ${importRow.basePrice.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: importRow.basePrice <= 0 ? Colors.red : null,
                              ),
                            ),
                          ],
                        ),
                        
                        // Description (if available)
                        if (importRow.description != null && importRow.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            importRow.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Additional info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Dietary indicators
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (importRow.isHalal == true)
                            _buildDietaryIcon(Icons.verified, Colors.green, 'Halal'),
                          if (importRow.isVegetarian == true)
                            _buildDietaryIcon(Icons.eco, Colors.green, 'Vegetarian'),
                          if (importRow.isSpicy == true)
                            _buildDietaryIcon(Icons.local_fire_department, Colors.red, 'Spicy'),
                        ],
                      ),
                      
                      // Unit and quantities
                      if (importRow.unit != null || importRow.minOrderQuantity != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _buildQuantityText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              // Error and warning messages
              if (importRow.hasErrors || importRow.hasWarnings) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (importRow.hasErrors ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (importRow.hasErrors ? Colors.red : Colors.orange).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (importRow.hasErrors) ...[
                        ...importRow.errors.take(2).map((error) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (importRow.errors.length > 2)
                          Text(
                            '... and ${importRow.errors.length - 2} more errors',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                      if (importRow.hasWarnings && !importRow.hasErrors) ...[
                        ...importRow.warnings.take(2).map((warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (importRow.warnings.length > 2)
                          Text(
                            '... and ${importRow.warnings.length - 2} more warnings',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (importRow.hasErrors) return Colors.red;
    if (importRow.hasWarnings) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDietaryIcon(IconData icon, Color color, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  String _buildQuantityText() {
    final parts = <String>[];
    
    if (importRow.unit != null) {
      parts.add(importRow.unit!);
    }
    
    if (importRow.minOrderQuantity != null) {
      if (importRow.maxOrderQuantity != null) {
        parts.add('${importRow.minOrderQuantity}-${importRow.maxOrderQuantity}');
      } else {
        parts.add('min ${importRow.minOrderQuantity}');
      }
    }
    
    return parts.join(' • ');
  }
}
