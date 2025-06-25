import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/system_setting.dart';

/// System setting card widget
class SystemSettingCard extends StatelessWidget {
  final SystemSetting setting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SystemSettingCard({
    super.key,
    required this.setting,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with key and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        setting.settingKey,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (setting.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          setting.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(setting.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(setting.category).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    setting.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getCategoryColor(setting.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'copy':
                        _copyValue(context);
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Copy Value'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (!setting.isReadOnly)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Value display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Value:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (setting.isPublic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PUBLIC',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (setting.isReadOnly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'READ-ONLY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatValue(setting.settingValue),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Metadata
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(setting.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
                if (setting.updatedBy != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'By: ${setting.updatedBy}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'notification':
        return Colors.orange;
      case 'security':
        return Colors.red;
      case 'delivery':
        return Colors.purple;
      case 'ui':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is List) return value.join(', ');
    if (value is Map) return value.toString();
    return value.toString();
  }

  void _copyValue(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _formatValue(setting.settingValue)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Value copied to clipboard')),
    );
  }
}

/// System setting form dialog
class SystemSettingFormDialog extends StatefulWidget {
  final SystemSetting? setting;
  final Function(String settingKey, dynamic settingValue, String? description, String category, bool isPublic) onSave;

  const SystemSettingFormDialog({
    super.key,
    this.setting,
    required this.onSave,
  });

  @override
  State<SystemSettingFormDialog> createState() => _SystemSettingFormDialogState();
}

class _SystemSettingFormDialogState extends State<SystemSettingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  late TextEditingController _descriptionController;
  String _selectedCategory = SettingCategory.general;
  bool _isPublic = false;
  bool _isLoading = false;

  final List<String> _categories = [
    SettingCategory.general,
    SettingCategory.payment,
    SettingCategory.notification,
    SettingCategory.security,
    SettingCategory.delivery,
    SettingCategory.ui,
  ];

  @override
  void initState() {
    super.initState();
    
    _keyController = TextEditingController(text: widget.setting?.settingKey ?? '');
    _valueController = TextEditingController(text: widget.setting?.settingValue?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.setting?.description ?? '');
    _selectedCategory = widget.setting?.category ?? SettingCategory.general;
    _isPublic = widget.setting?.isPublic ?? false;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.setting != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Setting' : 'Create Setting'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Setting Key
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Setting Key',
                  hintText: 'e.g., app_name',
                  border: OutlineInputBorder(),
                ),
                enabled: !isEditing, // Don't allow editing key for existing settings
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Setting key is required';
                  }
                  if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(value.trim())) {
                    return 'Key must contain only lowercase letters, numbers, and underscores';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Setting Value
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Setting Value',
                  hintText: 'Enter the setting value',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Setting value is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe what this setting does',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.toUpperCase()),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Public setting checkbox
              CheckboxListTile(
                title: const Text('Public Setting'),
                subtitle: const Text('Allow non-admin users to read this setting'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final settingKey = _keyController.text.trim();
      final settingValue = _parseValue(_valueController.text.trim());
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();

      await widget.onSave(
        settingKey,
        settingValue,
        description,
        _selectedCategory,
        _isPublic,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  dynamic _parseValue(String value) {
    // Try to parse as different types
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    if (value.toLowerCase() == 'null') return null;
    
    // Try to parse as number
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;
    
    // Return as string
    return value;
  }
}
