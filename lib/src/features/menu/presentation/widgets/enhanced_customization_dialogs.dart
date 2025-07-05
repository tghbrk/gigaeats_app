import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/product.dart' as product_model;

/// Enhanced customization group dialog with improved UX
class EnhancedCustomizationGroupDialog extends StatefulWidget {
  final product_model.MenuItemCustomization? customization;
  final Function(product_model.MenuItemCustomization) onSave;

  const EnhancedCustomizationGroupDialog({
    super.key,
    this.customization,
    required this.onSave,
  });

  @override
  State<EnhancedCustomizationGroupDialog> createState() => _EnhancedCustomizationGroupDialogState();
}

class _EnhancedCustomizationGroupDialogState extends State<EnhancedCustomizationGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'single';
  bool _isRequired = false;
  List<product_model.CustomizationOption> _options = [];

  @override
  void initState() {
    super.initState();
    if (widget.customization != null) {
      _populateExistingData();
    } else {
      _addDefaultOption();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _populateExistingData() {
    final customization = widget.customization!;
    _nameController.text = customization.name;
    _selectedType = customization.type;
    _isRequired = customization.isRequired;
    _options = List.from(customization.options);
  }

  void _addDefaultOption() {
    _options.add(const product_model.CustomizationOption(
      name: '',
      additionalPrice: 0.0,
      isDefault: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customization != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Customization Group' : 'Add Customization Group',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Group Name *',
                          hintText: 'e.g., Size Options, Spice Level',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter group name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Selection Type
                      Text(
                        'Selection Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Single Choice'),
                              subtitle: const Text('Radio buttons'),
                              value: 'single',
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Multiple Choice'),
                              subtitle: const Text('Checkboxes'),
                              value: 'multiple',
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Required Toggle
                      SwitchListTile(
                        title: const Text('Required Selection'),
                        subtitle: const Text('Customers must make a choice'),
                        value: _isRequired,
                        onChanged: (value) {
                          setState(() {
                            _isRequired = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 20),

                      // Options Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Options',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addOption,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Option'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Options List
                      if (_options.isEmpty)
                        _buildEmptyOptionsState()
                      else
                        ..._options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          return _buildOptionCard(index, option);
                        }),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveCustomization,
                      child: Text(isEditing ? 'Update' : 'Add'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOptionsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'No options added yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Add at least one option for customers to choose from',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(int index, product_model.CustomizationOption option) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: option.name,
                    decoration: const InputDecoration(
                      labelText: 'Option Name *',
                      hintText: 'e.g., Large, Extra Spicy',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _options[index] = option.copyWith(name: value);
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: option.additionalPrice.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Price (RM)',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixText: 'RM ',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      _options[index] = option.copyWith(additionalPrice: price);
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _removeOption(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove option',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Default Option'),
                    value: option.isDefault,
                    onChanged: (value) {
                      setState(() {
                        _options[index] = option.copyWith(isDefault: value ?? false);
                        // Ensure only one default option for single choice
                        if (value == true && _selectedType == 'single') {
                          for (int i = 0; i < _options.length; i++) {
                            if (i != index) {
                              _options[i] = _options[i].copyWith(isDefault: false);
                            }
                          }
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addOption() {
    setState(() {
      _options.add(const product_model.CustomizationOption(
        name: '',
        additionalPrice: 0.0,
        isDefault: false,
      ));
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _saveCustomization() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one option'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that all options have names
    final hasEmptyOptions = _options.any((option) => option.name.trim().isEmpty);
    if (hasEmptyOptions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all option names'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final customization = product_model.MenuItemCustomization(
      id: widget.customization?.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      isRequired: _isRequired,
      options: _options,
    );

    widget.onSave(customization);
    Navigator.of(context).pop();
  }
}

/// Enhanced customization option dialog
class EnhancedCustomizationOptionDialog extends StatefulWidget {
  final product_model.CustomizationOption? option;
  final Function(product_model.CustomizationOption) onSave;

  const EnhancedCustomizationOptionDialog({
    super.key,
    this.option,
    required this.onSave,
  });

  @override
  State<EnhancedCustomizationOptionDialog> createState() => _EnhancedCustomizationOptionDialogState();
}

class _EnhancedCustomizationOptionDialogState extends State<EnhancedCustomizationOptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.option != null) {
      _nameController.text = widget.option!.name;
      _priceController.text = widget.option!.additionalPrice.toString();
      _isDefault = widget.option!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.option != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Option' : 'Add Option'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Option Name *',
                hintText: 'e.g., Large, Extra Spicy',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter option name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Additional Price (RM)',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price (use 0 for no additional cost)';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Invalid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Default Selection'),
              subtitle: const Text('Pre-select this option'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveOption,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveOption() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final option = product_model.CustomizationOption(
      id: widget.option?.id,
      name: _nameController.text.trim(),
      additionalPrice: double.parse(_priceController.text),
      isDefault: _isDefault,
    );

    widget.onSave(option);
    Navigator.of(context).pop();
  }
}
