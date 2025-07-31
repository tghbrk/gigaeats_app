import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/services/camera_permission_service.dart';
import '../../../../../core/utils/logger.dart';

/// Unified verification form that combines bank account details with IC document upload
class UnifiedVerificationForm extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final bool isLoading;

  const UnifiedVerificationForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  ConsumerState<UnifiedVerificationForm> createState() => _UnifiedVerificationFormState();
}

class _UnifiedVerificationFormState extends ConsumerState<UnifiedVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _logger = AppLogger();
  
  // Bank account form controllers
  final _bankCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  
  // Document upload state
  XFile? _icFrontImage;
  XFile? _icBackImage;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  String? _frontUploadError;
  String? _backUploadError;
  
  String? _selectedBank;
  bool _agreedToTerms = false;

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
          // Section 1: Bank Account Details
          _buildSectionHeader(theme, 'Bank Account Details', Icons.account_balance),
          const SizedBox(height: 16),
          _buildBankAccountSection(theme),
          
          const SizedBox(height: 32),
          
          // Section 2: Identity Verification
          _buildSectionHeader(theme, 'Identity Verification', Icons.credit_card),
          const SizedBox(height: 16),
          _buildDocumentUploadSection(theme),
          
          const SizedBox(height: 32),
          
          // Terms and conditions
          _buildTermsSection(theme),
          
          const SizedBox(height: 24),
          
          // Submit button
          _buildSubmitButton(theme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccountSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank selection
        Text(
          'Bank Name',
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
      ],
    );
  }

  Widget _buildDocumentUploadSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload your Malaysian IC (front and back)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        
        // IC Front upload
        _buildDocumentUploadCard(
          theme,
          'IC Front',
          'Upload the front side of your Malaysian IC',
          _icFrontImage,
          _isUploadingFront,
          _frontUploadError,
          () => _pickDocument(DocumentSide.front),
          () => _removeDocument(DocumentSide.front),
        ),
        
        const SizedBox(height: 16),
        
        // IC Back upload
        _buildDocumentUploadCard(
          theme,
          'IC Back',
          'Upload the back side of your Malaysian IC',
          _icBackImage,
          _isUploadingBack,
          _backUploadError,
          () => _pickDocument(DocumentSide.back),
          () => _removeDocument(DocumentSide.back),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadCard(
    ThemeData theme,
    String title,
    String description,
    XFile? selectedFile,
    bool isUploading,
    String? error,
    VoidCallback onPick,
    VoidCallback onRemove,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selectedFile != null ? Icons.check_circle : Icons.credit_card,
                  color: selectedFile != null ? Colors.green : theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            if (selectedFile == null) ...[
              // Upload button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isUploading || widget.isLoading ? null : onPick,
                  icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                  label: Text(isUploading ? 'Uploading...' : 'Take Photo'),
                ),
              ),
            ] else ...[
              // File selected
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Photo captured successfully',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.isLoading ? null : onRemove,
                      icon: const Icon(Icons.close, size: 18),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],

            if (error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: widget.isLoading ? null : (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: widget.isLoading ? null : () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' for wallet verification.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    final bool canSubmit = _selectedBank != null &&
        _accountNumberController.text.isNotEmpty &&
        _accountHolderNameController.text.isNotEmpty &&
        _icFrontImage != null &&
        _icBackImage != null &&
        _agreedToTerms;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (canSubmit && !widget.isLoading) ? _handleSubmit : null,
        child: widget.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Complete Verification'),
      ),
    );
  }

  Future<void> _pickDocument(DocumentSide side) async {
    try {
      _logger.info('📷 Picking document for ${side.name}');

      // Check camera permission
      final hasPermission = await CameraPermissionService.requestCameraPermission();
      if (!hasPermission) {
        _logger.warning('Camera permission denied');
        return;
      }

      setState(() {
        if (side == DocumentSide.front) {
          _isUploadingFront = true;
          _frontUploadError = null;
        } else {
          _isUploadingBack = true;
          _backUploadError = null;
        }
      });

      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90, // High quality for OCR
      );

      if (file != null) {
        setState(() {
          if (side == DocumentSide.front) {
            _icFrontImage = file;
          } else {
            _icBackImage = file;
          }
        });
        _logger.info('✅ Document selected: ${file.name}');
      }
    } catch (e) {
      _logger.error('❌ Error picking document', e);
      setState(() {
        if (side == DocumentSide.front) {
          _frontUploadError = 'Failed to capture photo: $e';
        } else {
          _backUploadError = 'Failed to capture photo: $e';
        }
      });
    } finally {
      setState(() {
        if (side == DocumentSide.front) {
          _isUploadingFront = false;
        } else {
          _isUploadingBack = false;
        }
      });
    }
  }

  void _removeDocument(DocumentSide side) {
    setState(() {
      if (side == DocumentSide.front) {
        _icFrontImage = null;
        _frontUploadError = null;
      } else {
        _icBackImage = null;
        _backUploadError = null;
      }
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_icFrontImage == null || _icBackImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload both front and back of your IC'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final verificationData = {
        'bankDetails': {
          'bankCode': _bankCodeController.text,
          'bankName': _selectedBank!,
          'accountNumber': _accountNumberController.text,
          'accountHolderName': _accountHolderNameController.text,
        },
        'documents': {
          'icFrontImage': _icFrontImage!,
          'icBackImage': _icBackImage!,
        },
        'verificationMethod': 'unified_verification',
      };

      widget.onSubmit(verificationData);
    }
  }
}

/// Enum for document sides
enum DocumentSide {
  front,
  back,
}
