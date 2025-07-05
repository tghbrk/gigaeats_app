import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/advanced_pricing.dart';

/// Enhanced bulk pricing tier dialog with advanced features
class EnhancedBulkPricingTierDialog extends StatefulWidget {
  final EnhancedBulkPricingTier? tier;
  final double basePrice;
  final Function(EnhancedBulkPricingTier) onSave;

  const EnhancedBulkPricingTierDialog({
    super.key,
    this.tier,
    required this.basePrice,
    required this.onSave,
  });

  @override
  State<EnhancedBulkPricingTierDialog> createState() => _EnhancedBulkPricingTierDialogState();
}

class _EnhancedBulkPricingTierDialogState extends State<EnhancedBulkPricingTierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _minQuantityController = TextEditingController();
  final _maxQuantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validUntil;
  double? _calculatedDiscount;

  @override
  void initState() {
    super.initState();
    if (widget.tier != null) {
      _populateExistingData();
    }
    _priceController.addListener(_calculateDiscount);
  }

  @override
  void dispose() {
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _populateExistingData() {
    final tier = widget.tier!;
    _minQuantityController.text = tier.minimumQuantity.toString();
    if (tier.maximumQuantity != null) {
      _maxQuantityController.text = tier.maximumQuantity.toString();
    }
    _priceController.text = tier.pricePerUnit.toString();
    if (tier.description != null) {
      _descriptionController.text = tier.description!;
    }
    _isActive = tier.isActive;
    _validFrom = tier.validFrom;
    _validUntil = tier.validUntil;
    _calculatedDiscount = tier.discountPercentage;
  }

  void _calculateDiscount() {
    final price = double.tryParse(_priceController.text);
    if (price != null && widget.basePrice > 0) {
      final discount = ((widget.basePrice - price) / widget.basePrice) * 100;
      setState(() {
        _calculatedDiscount = discount > 0 ? discount : null;
      });
    } else {
      setState(() {
        _calculatedDiscount = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tier != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                    Icons.layers,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Bulk Pricing Tier' : 'Add Bulk Pricing Tier',
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
                      // Quantity Range
                      Text(
                        'Quantity Range',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Minimum Quantity *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.arrow_upward),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final qty = int.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Invalid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Maximum Quantity',
                                hintText: 'Optional',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.arrow_downward),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final maxQty = int.tryParse(value);
                                  final minQty = int.tryParse(_minQuantityController.text);
                                  if (maxQty == null || maxQty <= 0) {
                                    return 'Invalid quantity';
                                  }
                                  if (minQty != null && maxQty <= minQty) {
                                    return 'Must be > min quantity';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Pricing
                      Text(
                        'Pricing',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price per Unit (RM) *',
                                border: OutlineInputBorder(),
                                prefixText: 'RM ',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _calculatedDiscount != null && _calculatedDiscount! > 0
                                    ? Colors.green[50]
                                    : Colors.grey[50],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discount',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _calculatedDiscount != null && _calculatedDiscount! > 0
                                        ? '${_calculatedDiscount!.toStringAsFixed(1)}%'
                                        : 'No discount',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _calculatedDiscount != null && _calculatedDiscount! > 0
                                          ? Colors.green[600]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Optional description for this tier',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 20),

                      // Active Status
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Enable this pricing tier'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 20),

                      // Validity Period
                      Text(
                        'Validity Period (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectValidFrom,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Valid From',
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _validFrom != null
                                          ? _formatDate(_validFrom!)
                                          : 'Select date',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectValidUntil,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Valid Until',
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _validUntil != null
                                          ? _formatDate(_validUntil!)
                                          : 'Select date',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      onPressed: _saveTier,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectValidFrom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _validFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _validFrom = date;
      });
    }
  }

  Future<void> _selectValidUntil() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _validFrom ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _validUntil = date;
      });
    }
  }

  void _saveTier() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tier = EnhancedBulkPricingTier(
      id: widget.tier?.id,
      minimumQuantity: int.parse(_minQuantityController.text),
      maximumQuantity: _maxQuantityController.text.trim().isNotEmpty
          ? int.parse(_maxQuantityController.text)
          : null,
      pricePerUnit: double.parse(_priceController.text),
      discountPercentage: _calculatedDiscount,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      isActive: _isActive,
      validFrom: _validFrom,
      validUntil: _validUntil,
    );

    widget.onSave(tier);
    Navigator.of(context).pop();
  }
}