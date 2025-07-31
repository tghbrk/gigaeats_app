import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for withdrawal amount input with validation and quick amount buttons
class WithdrawalAmountInput extends StatefulWidget {
  final TextEditingController controller;
  final double maxAmount;
  final Function(String)? onChanged;
  final Function(double)? onQuickAmountSelected;
  final double minAmount;

  const WithdrawalAmountInput({
    super.key,
    required this.controller,
    required this.maxAmount,
    this.onChanged,
    this.onQuickAmountSelected,
    this.minAmount = 10.0,
  });

  @override
  State<WithdrawalAmountInput> createState() => _WithdrawalAmountInputState();
}

class _WithdrawalAmountInputState extends State<WithdrawalAmountInput> {
  final _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateAmount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateAmount);
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAmount() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      setState(() {
        _errorText = null;
      });
      return;
    }

    final amount = double.tryParse(text);
    if (amount == null) {
      setState(() {
        _errorText = 'Please enter a valid amount';
      });
      return;
    }

    if (amount < widget.minAmount) {
      setState(() {
        _errorText = 'Minimum withdrawal amount is RM ${widget.minAmount.toStringAsFixed(2)}';
      });
      return;
    }

    if (amount > widget.maxAmount) {
      setState(() {
        _errorText = 'Amount exceeds available balance (RM ${widget.maxAmount.toStringAsFixed(2)})';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount input field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount (RM)',
            hintText: '0.00',
            prefixText: 'RM ',
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            errorText: _errorText,
          ),
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter withdrawal amount';
            }
            
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid amount';
            }
            
            if (amount < widget.minAmount) {
              return 'Minimum amount is RM ${widget.minAmount.toStringAsFixed(2)}';
            }
            
            if (amount > widget.maxAmount) {
              return 'Amount exceeds available balance';
            }
            
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Quick amount buttons
        _buildQuickAmountButtons(context),
        
        const SizedBox(height: 8),
        
        // Available balance info
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Available: RM ${widget.maxAmount.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButtons(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate quick amount options based on available balance
    final quickAmounts = _getQuickAmounts();
    
    if (quickAmounts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick amounts:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAmounts.map((amount) {
            return _buildQuickAmountChip(context, amount);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(BuildContext context, double amount) {
    final theme = Theme.of(context);
    final isSelected = widget.controller.text == amount.toStringAsFixed(2);
    
    return FilterChip(
      label: Text('RM ${amount.toStringAsFixed(0)}'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          widget.controller.text = amount.toStringAsFixed(2);
          widget.onQuickAmountSelected?.call(amount);
          widget.onChanged?.call(amount.toStringAsFixed(2));
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected 
            ? theme.colorScheme.onPrimaryContainer 
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  List<double> _getQuickAmounts() {
    final maxAmount = widget.maxAmount;
    final quickAmounts = <double>[];
    
    // Standard quick amounts
    final standardAmounts = [50.0, 100.0, 200.0, 500.0, 1000.0];
    
    for (final amount in standardAmounts) {
      if (amount >= widget.minAmount && amount <= maxAmount) {
        quickAmounts.add(amount);
      }
    }
    
    // Add percentage-based amounts
    final percentageAmounts = [
      maxAmount * 0.25, // 25%
      maxAmount * 0.5,  // 50%
      maxAmount * 0.75, // 75%
      maxAmount,        // 100% (All)
    ];
    
    for (final amount in percentageAmounts) {
      if (amount >= widget.minAmount && 
          amount <= maxAmount && 
          !quickAmounts.contains(amount)) {
        quickAmounts.add(amount);
      }
    }
    
    // Sort and limit to 6 options
    quickAmounts.sort();
    return quickAmounts.take(6).toList();
  }
}
