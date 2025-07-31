import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../data/models/user_role.dart';
import '../../../../../shared/widgets/auth_guard.dart';

/// Customer wallet instant verification screen
class CustomerWalletInstantVerificationScreen extends ConsumerStatefulWidget {
  const CustomerWalletInstantVerificationScreen({super.key});

  @override
  ConsumerState<CustomerWalletInstantVerificationScreen> createState() => _CustomerWalletInstantVerificationScreenState();
}

class _CustomerWalletInstantVerificationScreenState extends ConsumerState<CustomerWalletInstantVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _icNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isVerifying = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    debugPrint('⚡ [CUSTOMER-INSTANT-VERIFICATION] Screen initialized');
  }

  @override
  void dispose() {
    _icNumberController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AuthGuard(
      allowedRoles: const [UserRole.customer, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _buildHeaderSection(theme),
                const SizedBox(height: 24),
                
                // Form section
                _buildFormSection(theme),
                const SizedBox(height: 24),
                
                // Terms and conditions
                _buildTermsSection(theme),
                const SizedBox(height: 24),
                
                // Info section
                _buildInfoSection(theme),
                const SizedBox(height: 32),
                
                // Submit button
                _buildSubmitButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      title: const Text(
        'Instant Verification',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      elevation: 0,
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Verification',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verify your identity instantly using your IC number',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verification typically completes within minutes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // IC Number field
            TextFormField(
              controller: _icNumberController,
              decoration: InputDecoration(
                labelText: 'IC Number',
                hintText: 'Enter your 12-digit IC number',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              keyboardType: TextInputType.number,
              maxLength: 12,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your IC number';
                }
                if (value.length != 12) {
                  return 'IC number must be 12 digits';
                }
                if (!RegExp(r'^\d{12}$').hasMatch(value)) {
                  return 'IC number must contain only digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Full Name field
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name as per IC',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Please enter a valid name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() => _agreedToTerms = value ?? false);
              },
              title: Text(
                'I agree to the terms and conditions for identity verification',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                'Your information will be securely processed and stored in compliance with Malaysian data protection laws.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Security & Privacy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(theme, 'Your data is encrypted and securely stored'),
            _buildInfoItem(theme, 'We comply with Malaysian data protection laws'),
            _buildInfoItem(theme, 'Information is only used for verification purposes'),
            _buildInfoItem(theme, 'You can request data deletion at any time'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isVerifying || !_agreedToTerms ? null : _submitVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isVerifying
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Verifying...'),
                ],
              )
            : const Text(
                'Start Instant Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _submitVerification() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      _showErrorSnackBar('Please agree to the terms and conditions');
      return;
    }

    debugPrint('⚡ [INSTANT-VERIFICATION] Starting verification');
    debugPrint('📋 [INSTANT-VERIFICATION] IC: ${_icNumberController.text}');
    debugPrint('👤 [INSTANT-VERIFICATION] Name: ${_fullNameController.text}');

    setState(() => _isVerifying = true);

    // Simulate verification process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isVerifying = false);
        _showVerificationResult();
      }
    });
  }

  void _showVerificationResult() {
    // Simulate random verification result for demo
    final isSuccess = DateTime.now().millisecond % 2 == 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(isSuccess ? 'Verification Successful' : 'Verification Failed'),
          ],
        ),
        content: Text(
          isSuccess
              ? 'Your identity has been verified successfully. Your wallet is now ready for withdrawals.'
              : 'We could not verify your identity with the provided information. Please try again or use document upload verification.',
        ),
        actions: [
          if (!isSuccess)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear form for retry
                _icNumberController.clear();
                _fullNameController.clear();
                setState(() => _agreedToTerms = false);
              },
              child: const Text('Try Again'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isSuccess) {
                context.pop(); // Return to verification screen
              }
            },
            child: Text(isSuccess ? 'OK' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
