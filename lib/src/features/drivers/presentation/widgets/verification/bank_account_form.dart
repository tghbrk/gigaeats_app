import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form widget for collecting bank account details for verification
class BankAccountForm extends StatefulWidget {
  final Function(Map<String, String>) onSubmit;
  final bool isLoading;

  const BankAccountForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _bankCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _icNumberController = TextEditingController();

  String? _selectedBank;
  bool _includeIcNumber = false;

  // Malaysian banks with their codes
  final Map<String, String> _malaysianBanks = {
    'Maybank': 'MBB',
    'CIMB Bank': 'CIMB',
    'Public Bank': 'PBB',
    'RHB Bank': 'RHB',
    'Hong Leong Bank': 'HLB',
    'AmBank': 'AMB',
    'Bank Islam': 'BIMB',
    'BSN': 'BSN',
    'OCBC Bank': 'OCBC',
    'Standard Chartered': 'SCB',
    'HSBC Bank': 'HSBC',
    'UOB Bank': 'UOB',
    'Affin Bank': 'AFFIN',
    'Alliance Bank': 'ABMB',
    'Bank Rakyat': 'BKRM',
  };

  @override
  void dispose() {
    _bankCodeController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _icNumberController.dispose();
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
          // Bank selection
          Text(
            'Select Bank',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBank,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Choose your bank',
              prefixIcon: Icon(Icons.account_balance),
            ),
            items: _malaysianBanks.keys.map((bank) {
              return DropdownMenuItem(
                value: bank,
                child: Text(bank),
              );
            }).toList(),
            onChanged: widget.isLoading ? null : (value) {
              setState(() {
                _selectedBank = value;
                _bankCodeController.text = _malaysianBanks[value] ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your bank';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Account number
          Text(
            'Account Number',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountNumberController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your account number',
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
            enabled: !widget.isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your account number';
              }
              if (value.length < 8) {
                return 'Account number must be at least 8 digits';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Account holder name
          Text(
            'Account Holder Name',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountHolderNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter name as shown on bank account',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
            enabled: !widget.isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the account holder name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // IC number option
          CheckboxListTile(
            title: Text(
              'Include IC Number (Recommended)',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              'Including your IC number may speed up verification',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: _includeIcNumber,
            onChanged: widget.isLoading ? null : (value) {
              setState(() {
                _includeIcNumber = value ?? false;
                if (!_includeIcNumber) {
                  _icNumberController.clear();
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // IC number field (conditional)
          if (_includeIcNumber) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _icNumberController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your IC number (e.g., 123456-78-9012)',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                LengthLimitingTextInputFormatter(14),
                _ICNumberFormatter(),
              ],
              enabled: !widget.isLoading,
              validator: _includeIcNumber ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your IC number';
                }
                if (!_isValidMalaysianIC(value)) {
                  return 'Please enter a valid Malaysian IC number';
                }
                return null;
              } : null,
            ),
          ],

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
                  : const Text('Continue to Verification'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final bankDetails = {
        'bankCode': _bankCodeController.text,
        'accountNumber': _accountNumberController.text,
        'accountHolderName': _accountHolderNameController.text,
        if (_includeIcNumber && _icNumberController.text.isNotEmpty)
          'icNumber': _icNumberController.text,
      };

      widget.onSubmit(bankDetails);
    }
  }

  bool _isValidMalaysianIC(String ic) {
    // Remove any dashes and check format
    final cleanIC = ic.replaceAll('-', '');
    if (cleanIC.length != 12) return false;
    
    // Check if all characters are digits
    if (!RegExp(r'^\d{12}$').hasMatch(cleanIC)) return false;
    
    // Basic format validation (YYMMDD-PB-XXXX)
    final year = int.tryParse(cleanIC.substring(0, 2));
    final month = int.tryParse(cleanIC.substring(2, 4));
    final day = int.tryParse(cleanIC.substring(4, 6));
    
    if (year == null || month == null || day == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    
    return true;
  }
}

/// Custom formatter for Malaysian IC numbers
class _ICNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
    
    if (text.length <= 6) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 8) {
      return newValue.copyWith(
        text: '${text.substring(0, 6)}-${text.substring(6)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else {
      return newValue.copyWith(
        text: '${text.substring(0, 6)}-${text.substring(6, 8)}-${text.substring(8)}',
        selection: TextSelection.collapsed(offset: text.length + 2),
      );
    }
  }
}
