import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/customization_template.dart';

/// Dialog form for creating and editing template options
class TemplateOptionForm extends StatefulWidget {
  final TemplateOption? option;
  final Function(TemplateOption) onSave;

  const TemplateOptionForm({
    super.key,
    this.option,
    required this.onSave,
  });

  @override
  State<TemplateOptionForm> createState() => _TemplateOptionFormState();
}

class _TemplateOptionFormState extends State<TemplateOptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isDefault = false;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    if (widget.option != null) {
      _nameController.text = widget.option!.name;
      _priceController.text = widget.option!.additionalPrice.toString();
      _isDefault = widget.option!.isDefault;
      _isAvailable = widget.option!.isAvailable;
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
            // Option Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Option Name *',
                hintText: 'e.g., Small, Medium, Large',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an option name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Additional Price
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
                  return null; // Optional field
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Default Option Switch
            SwitchListTile(
              title: const Text('Default Option'),
              subtitle: const Text('Pre-selected for customers'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Available Switch
            SwitchListTile(
              title: const Text('Available'),
              subtitle: const Text('Customers can select this option'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
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

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    
    final option = TemplateOption.create(
      templateId: widget.option?.templateId ?? '',
      name: _nameController.text.trim(),
      additionalPrice: price,
      isDefault: _isDefault,
      isAvailable: _isAvailable,
    ).copyWith(
      id: widget.option?.id ?? '',
    );

    widget.onSave(option);
    Navigator.of(context).pop();
  }
}
