import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form widget for verifying micro deposit amounts
class MicroDepositVerificationForm extends StatefulWidget {
  final String accountId;
  final Function(List<double>) onSubmit;
  final bool isLoading;

  const MicroDepositVerificationForm({
    super.key,
    required this.accountId,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<MicroDepositVerificationForm> createState() => _MicroDepositVerificationFormState();
}

class _MicroDepositVerificationFormState extends State<MicroDepositVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount1Controller = TextEditingController();
  final _amount2Controller = TextEditingController();
  final _amount1FocusNode = FocusNode();
  final _amount2FocusNode = FocusNode();

  @override
  void dispose() {
    _amount1Controller.dispose();
    _amount2Controller.dispose();
    _amount1FocusNode.dispose();
    _amount2FocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How to Find Micro Deposits',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Check your bank statement or mobile banking app\n'
                  '2. Look for two small deposits from "GigaEats Verification"\n'
                  '3. Deposits are typically between RM 0.01 and RM 0.99\n'
                  '4. Enter the amounts in cents (e.g., RM 0.23 = 23)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Amount input fields
          Text(
            'Enter Deposit Amounts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // First amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First Deposit (cents)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amount1Controller,
                      focusNode: _amount1FocusNode,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., 23',
                        prefixText: 'RM 0.',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _amount1Controller.clear(),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      enabled: !widget.isLoading,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _amount2FocusNode.requestFocus();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final amount = int.tryParse(value);
                        if (amount == null || amount < 1 || amount > 99) {
                          return 'Enter 1-99';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Second amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Second Deposit (cents)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amount2Controller,
                      focusNode: _amount2FocusNode,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., 67',
                        prefixText: 'RM 0.',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _amount2Controller.clear(),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      enabled: !widget.isLoading,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSubmit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final amount = int.tryParse(value);
                        if (amount == null || amount < 1 || amount > 99) {
                          return 'Enter 1-99';
                        }
                        // Check if amounts are different
                        final amount1 = int.tryParse(_amount1Controller.text);
                        if (amount1 != null && amount == amount1) {
                          return 'Must be different';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Example section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Example',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'If you see deposits of RM 0.23 and RM 0.67 in your bank statement, '
                  'enter "23" in the first field and "67" in the second field.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify Deposits'),
            ),
          ),

          const SizedBox(height: 16),

          // Help text
          Center(
            child: TextButton.icon(
              onPressed: () => _showHelpDialog(),
              icon: const Icon(Icons.help_outline),
              label: const Text('Don\'t see the deposits?'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount1 = int.parse(_amount1Controller.text) / 100.0;
      final amount2 = int.parse(_amount2Controller.text) / 100.0;
      
      widget.onSubmit([amount1, amount2]);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Need Help?'),
        content: const Text(
          'Micro deposits can take 1-2 business days to appear in your account. '
          'If you still don\'t see them after 2 business days, please contact our support team.\n\n'
          'Make sure to check:\n'
          '• Your bank statement\n'
          '• Mobile banking app\n'
          '• Online banking portal\n\n'
          'Look for deposits from "GigaEats Verification" or similar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Add contact support functionality
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}
