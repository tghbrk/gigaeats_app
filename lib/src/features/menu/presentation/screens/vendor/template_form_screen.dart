import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customization_template_providers.dart';
import '../../../data/models/customization_template.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../widgets/vendor/template_option_form.dart';

/// Screen for creating and editing customization templates
class TemplateFormScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String? templateId;

  const TemplateFormScreen({
    super.key,
    required this.vendorId,
    this.templateId,
  });

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'single';
  bool _isRequired = false;
  bool _isActive = true;
  List<TemplateOption> _options = [];
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.templateId != null;
    if (_isEditing) {
      _loadTemplate();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    if (widget.templateId == null) return;

    setState(() => _isLoading = true);

    try {
      final template = await ref.read(templateByIdProvider(widget.templateId!).future);
      if (template != null) {
        _nameController.text = template.name;
        _descriptionController.text = template.description ?? '';
        _selectedType = template.type;
        _isRequired = template.isRequired;
        _isActive = template.isActive;
        _options = List.from(template.options);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading template: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Template' : 'Create Template'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete Template',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading template...')
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBasicInfoSection(),
                          const SizedBox(height: 24),
                          _buildOptionsSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Template Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name *',
                hintText: 'e.g., Size Options, Spice Level',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a template name';
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
                hintText: 'Brief description of this template',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Template Type
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Selection Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'single',
                  child: Text('Single Selection (Radio buttons)'),
                ),
                DropdownMenuItem(
                  value: 'multiple',
                  child: Text('Multiple Selection (Checkboxes)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Switches
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Required'),
                    subtitle: const Text('Customers must make a selection'),
                    value: _isRequired,
                    onChanged: (value) {
                      setState(() {
                        _isRequired = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Available for use'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Template Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],
            ),
            
            if (_options.isEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No options added yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add options that customers can choose from',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                onReorder: _reorderOptions,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  return _buildOptionTile(option, index);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(TemplateOption option, int index) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey(option.name + index.toString()),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text(option.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (option.hasAdditionalCost)
              Text('Price: ${option.formattedPrice}'),
            Row(
              children: [
                if (option.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Default',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                if (!option.isAvailable) ...[
                  if (option.isDefault) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Unavailable',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editOption(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeOption(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GEButton.secondary(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GEButton.primary(
              text: _isEditing ? 'Update Template' : 'Create Template',
              onPressed: _saveTemplate,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  void _addOption() {
    showDialog(
      context: context,
      builder: (context) => TemplateOptionForm(
        onSave: (option) {
          setState(() {
            _options.add(option);
          });
        },
      ),
    );
  }

  void _editOption(int index) {
    showDialog(
      context: context,
      builder: (context) => TemplateOptionForm(
        option: _options[index],
        onSave: (option) {
          setState(() {
            _options[index] = option;
          });
        },
      ),
    );
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _reorderOptions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final option = _options.removeAt(oldIndex);
      _options.insert(newIndex, option);
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one option')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final template = CustomizationTemplate.create(
        vendorId: widget.vendorId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _selectedType,
        isRequired: _isRequired,
        options: _options,
      ).copyWith(
        id: widget.templateId ?? '',
        isActive: _isActive,
      );

      final notifier = ref.read(templateManagementProvider.notifier);
      final success = _isEditing
          ? await notifier.updateTemplate(template)
          : await notifier.createTemplate(template);

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                  ? 'Failed to update template' 
                  : 'Failed to create template'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTemplate();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate() async {
    if (widget.templateId == null) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(templateManagementProvider.notifier);
      final success = await notifier.deleteTemplate(widget.templateId!);

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete template')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
