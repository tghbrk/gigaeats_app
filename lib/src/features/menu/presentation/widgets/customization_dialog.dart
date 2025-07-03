import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../menu/data/models/product.dart';
import '../../../menu/data/constants/menu_constants.dart';

class CustomizationDialog extends StatefulWidget {
  final MenuItemCustomization? customization;
  final Function(MenuItemCustomization) onSave;

  const CustomizationDialog({
    super.key,
    this.customization,
    required this.onSave,
  });

  @override
  State<CustomizationDialog> createState() => _CustomizationDialogState();
}

class _CustomizationDialogState extends State<CustomizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedType = CustomizationType.single.value;
  bool _isRequired = false;
  List<CustomizationOption> _options = [];

  // Controllers for each option's fields
  final List<TextEditingController> _optionNameControllers = [];
  final List<TextEditingController> _optionPriceControllers = [];

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
    _disposeOptionControllers();
    super.dispose();
  }

  void _disposeOptionControllers() {
    for (final controller in _optionNameControllers) {
      controller.dispose();
    }
    for (final controller in _optionPriceControllers) {
      controller.dispose();
    }
    _optionNameControllers.clear();
    _optionPriceControllers.clear();
  }

  void _populateExistingData() {
    final customization = widget.customization!;
    _nameController.text = customization.name;
    _selectedType = customization.type;
    _isRequired = customization.isRequired;
    _options = List.from(customization.options);
    _initializeControllersForOptions();
  }

  void _addDefaultOption() {
    _options.add(const CustomizationOption(
      id: null, // Let database generate ID
      name: '',
      additionalPrice: 0.0,
      isDefault: false,
    ));
    _initializeControllersForOptions();
  }

  void _initializeControllersForOptions() {
    // Dispose existing controllers first
    _disposeOptionControllers();

    // Create new controllers for each option
    for (final option in _options) {
      _optionNameControllers.add(TextEditingController(text: option.name));
      _optionPriceControllers.add(TextEditingController(text: option.additionalPrice.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customization == null ? 'Add Customization' : 'Edit Customization'),
        actions: [
          TextButton(
            onPressed: _saveCustomization,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customization Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Customization Name *',
                          hintText: 'e.g., Size, Spice Level, Add-ons',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter customization name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Customization Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Selection Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: CustomizationType.values.map((type) {
                          return DropdownMenuItem(
                            value: type.value,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Required Toggle
                      CheckboxListTile(
                        title: const Text('Required'),
                        subtitle: const Text('Customer must select an option'),
                        value: _isRequired,
                        onChanged: (value) {
                          setState(() {
                            _isRequired = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      const SizedBox(height: 24),

                      // Options Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Options',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addOption,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Option'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Options List
                      ..._options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return _buildOptionCard(index, option);
                      }),

                      if (_options.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('No options added yet. Add at least one option.'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOptionCard(int index, CustomizationOption option) {
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
                    controller: _optionNameControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Option Name *',
                      hintText: 'e.g., Large, Extra Spicy',
                      border: OutlineInputBorder(),
                    ),
                    // Remove onChanged to prevent rebuilds during typing
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
                    controller: _optionPriceControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Price (RM)',
                      hintText: '0.00 (free)',
                      helperText: '0.00 = Free add-on',
                      border: OutlineInputBorder(),
                      prefixText: 'RM ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    // Remove onChanged to prevent rebuilds during typing
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Invalid price';
                      }
                      if (price < 0) {
                        return 'Price cannot be negative';
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
                        // Ensure only one default option
                        if (value == true) {
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
                  ),
                ),
                if (index < _optionPriceControllers.length &&
                    (double.tryParse(_optionPriceControllers[index].text) ?? 0.0) == 0.0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'FREE',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
      _options.add(const CustomizationOption(
        id: null, // Let database generate ID
        name: '',
        additionalPrice: 0.0,
        isDefault: false,
      ));

      // Add controllers for the new option
      _optionNameControllers.add(TextEditingController(text: ''));
      _optionPriceControllers.add(TextEditingController(text: '0.0'));
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);

      // Dispose and remove controllers for the removed option
      if (index < _optionNameControllers.length) {
        _optionNameControllers[index].dispose();
        _optionNameControllers.removeAt(index);
      }
      if (index < _optionPriceControllers.length) {
        _optionPriceControllers[index].dispose();
        _optionPriceControllers.removeAt(index);
      }
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

    // Update options with current controller values
    _syncOptionsWithControllers();

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

    final customization = MenuItemCustomization(
      id: widget.customization?.id ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      isRequired: _isRequired,
      options: _options,
    );

    widget.onSave(customization);
  }

  void _syncOptionsWithControllers() {
    for (int i = 0; i < _options.length; i++) {
      if (i < _optionNameControllers.length && i < _optionPriceControllers.length) {
        final name = _optionNameControllers[i].text;
        final price = double.tryParse(_optionPriceControllers[i].text) ?? 0.0;
        _options[i] = _options[i].copyWith(
          name: name,
          additionalPrice: price,
        );
      }
    }
  }
}
