import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/services/camera_permission_service.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../data/models/wallet_verification_models.dart';
import '../../../data/services/customer_document_ai_verification_service.dart';

/// Unified verification form for customers that combines bank account details, 
/// document upload, and instant verification into a single cohesive form
class CustomerUnifiedVerificationForm extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final bool isLoading;

  const CustomerUnifiedVerificationForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  ConsumerState<CustomerUnifiedVerificationForm> createState() => _CustomerUnifiedVerificationFormState();
}

class _CustomerUnifiedVerificationFormState extends ConsumerState<CustomerUnifiedVerificationForm> {
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

  // AI data extraction state
  bool _isProcessingAI = false;
  String? _extractedICNumber;
  String? _extractedFullName;
  double? _extractionConfidence;

  bool _hasExtractedData = false;

  String? _selectedBank;
  bool _agreedToTerms = false;
  final bool _includeInstantVerification = true; // Always enabled but hidden from UI

  @override
  void initState() {
    super.initState();
    _logger.info('🔧 [UNIFIED-VERIFICATION-FORM] Form initialized');
    _logger.debug('🔧 [UNIFIED-VERIFICATION-FORM] Initial state - InstantVerification: $_includeInstantVerification, Terms: $_agreedToTerms');

    // Add listeners to form controllers for debug tracking
    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _logger.debug('🎧 [UNIFIED-VERIFICATION-FORM] Setting up controller listeners');

    _bankCodeController.addListener(() {
      _logger.debug('🏦 [UNIFIED-VERIFICATION-FORM] Bank code changed: ${_bankCodeController.text}');
    });

    _accountNumberController.addListener(() {
      _logger.debug('🏦 [UNIFIED-VERIFICATION-FORM] Account number changed: ${_accountNumberController.text.replaceAll(RegExp(r'\d'), '*')}'); // Mask for security
    });

    _accountHolderNameController.addListener(() {
      _logger.debug('🏦 [UNIFIED-VERIFICATION-FORM] Account holder name changed: ${_accountHolderNameController.text.isNotEmpty ? '[ENTERED]' : '[EMPTY]'}');
    });


  }

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
    _logger.debug('🧹 [UNIFIED-VERIFICATION-FORM] Disposing form controllers and resources');
    _bankCodeController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  /// Process IC images with AI when both front and back are uploaded
  Future<void> _processICImagesWithAI() async {
    if (_icFrontImage == null || _icBackImage == null || !_includeInstantVerification) {
      return;
    }

    if (_isProcessingAI) {
      _logger.debug('🤖 [UNIFIED-VERIFICATION-FORM] AI processing already in progress, skipping');
      return;
    }

    setState(() {
      _isProcessingAI = true;

      _hasExtractedData = false;
    });

    _logger.info('🤖 [UNIFIED-VERIFICATION-FORM] Starting AI data extraction from IC images');

    try {
      // Get current user ID for AI processing
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create AI service instance
      final aiService = CustomerDocumentAIVerificationService();

      // Generate a temporary verification ID for document processing
      final verificationId = 'temp_form_${DateTime.now().millisecondsSinceEpoch}';

      _logger.info('📤 [UNIFIED-VERIFICATION-FORM] Uploading IC front image...');

      // Upload IC front image
      final frontUploadResult = await aiService.uploadVerificationDocument(
        customerId: user.id,
        userId: user.id,
        verificationId: verificationId,
        documentType: DocumentType.icCard,
        documentFile: _icFrontImage!,
        documentSide: 'front',
      );

      if (!frontUploadResult.isSuccess) {
        throw Exception('Failed to upload IC front image: ${frontUploadResult.errorMessage}');
      }

      _logger.info('📤 [UNIFIED-VERIFICATION-FORM] Uploading IC back image...');

      // Upload IC back image
      final backUploadResult = await aiService.uploadVerificationDocument(
        customerId: user.id,
        userId: user.id,
        verificationId: verificationId,
        documentType: DocumentType.icCard,
        documentFile: _icBackImage!,
        documentSide: 'back',
      );

      if (!backUploadResult.isSuccess) {
        throw Exception('Failed to upload IC back image: ${backUploadResult.errorMessage}');
      }

      _logger.info('🤖 [UNIFIED-VERIFICATION-FORM] Extracting IC data with AI...');

      // Extract IC data using AI
      final extractionResult = await aiService.extractICData(
        frontDocumentId: frontUploadResult.documentId!,
        backDocumentId: backUploadResult.documentId!,
        verificationId: verificationId,
      );

      if (!extractionResult.isSuccess) {
        throw Exception('AI extraction failed: ${extractionResult.errorMessage}');
      }

      // Update state with extracted data
      setState(() {
        _extractedICNumber = extractionResult.icNumber;
        _extractedFullName = extractionResult.fullName;
        _extractionConfidence = extractionResult.overallConfidence;
        _hasExtractedData = true;
        _isProcessingAI = false;
      });

      _logger.info('✅ [UNIFIED-VERIFICATION-FORM] AI data extraction completed successfully');
      _logger.debug('🆔 [UNIFIED-VERIFICATION-FORM] Extracted IC: ${_extractedICNumber?.replaceAll(RegExp(r'\d'), '*')}');
      _logger.debug('👤 [UNIFIED-VERIFICATION-FORM] Extracted Name: [EXTRACTED]');
      _logger.debug('📊 [UNIFIED-VERIFICATION-FORM] Confidence: ${(_extractionConfidence! * 100).toInt()}%');

      // Show success message (simplified for user)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ IC documents processed successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e, stackTrace) {
      _logger.error('❌ [UNIFIED-VERIFICATION-FORM] AI data extraction failed', e, stackTrace);

      setState(() {

        _isProcessingAI = false;
        _hasExtractedData = false;
      });

      // Show error message (simplified for user)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to process IC documents. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _logger.debug('🎨 [UNIFIED-VERIFICATION-FORM] Building form UI');
    _logger.debug('🎨 [UNIFIED-VERIFICATION-FORM] Current state - Loading: ${widget.isLoading}, InstantVerification: $_includeInstantVerification');

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
            _logger.info('🏦 [UNIFIED-VERIFICATION-FORM] Bank selected: $value');
            _logger.debug('🏦 [UNIFIED-VERIFICATION-FORM] Bank code: ${_malaysianBanks[value]}');
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
            _logger.info('📋 [UNIFIED-VERIFICATION-FORM] Terms agreement changed: ${value ?? false}');
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: widget.isLoading ? null : () {
              _logger.info('📋 [UNIFIED-VERIFICATION-FORM] Terms text tapped - toggling agreement');
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

    // Debug form validation state
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] Form validation state:');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - Bank selected: ${_selectedBank != null}');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - Account number: ${_accountNumberController.text.isNotEmpty}');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - Account holder name: ${_accountHolderNameController.text.isNotEmpty}');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - IC front image: ${_icFrontImage != null}');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - IC back image: ${_icBackImage != null}');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - Instant verification enabled: $_includeInstantVerification');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - Terms agreed: $_agreedToTerms');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - Can submit: $canSubmit');
    _logger.debug('✅ [UNIFIED-VERIFICATION-FORM] - Is loading: ${widget.isLoading}');

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (canSubmit && !widget.isLoading) ? () {
          _logger.info('🚀 [UNIFIED-VERIFICATION-FORM] Submit button pressed');
          _handleSubmit();
        } : null,
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
      _logger.info('📷 [CUSTOMER-UNIFIED-FORM] Picking document for ${side.name}');

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
        _logger.info('✅ [CUSTOMER-UNIFIED-FORM] Document selected: ${file.name}');

        // Trigger AI processing if both images are now available and instant verification is enabled
        if (_icFrontImage != null && _icBackImage != null && _includeInstantVerification) {
          _logger.info('🤖 [CUSTOMER-UNIFIED-FORM] Both IC images available, triggering AI processing');
          _processICImagesWithAI();
        }
      }
    } catch (e) {
      _logger.error('❌ [CUSTOMER-UNIFIED-FORM] Error picking document', e);
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

      // Clear AI extracted data when any document is removed
      _extractedICNumber = null;
      _extractedFullName = null;
      _extractionConfidence = null;
      _hasExtractedData = false;

      _isProcessingAI = false;
    });

    _logger.info('🗑️ [UNIFIED-VERIFICATION-FORM] Document removed: ${side.name}, AI data cleared');
  }

  void _handleSubmit() {
    _logger.info('📝 [UNIFIED-VERIFICATION-FORM] Starting form submission process');

    final isFormValid = _formKey.currentState?.validate() ?? false;
    _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] Form validation result: $isFormValid');

    if (isFormValid) {
      _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] Form is valid, checking additional requirements');

      if (!_agreedToTerms) {
        _logger.warning('📝 [UNIFIED-VERIFICATION-FORM] Terms not agreed - showing error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_icFrontImage == null || _icBackImage == null) {
        _logger.warning('📝 [UNIFIED-VERIFICATION-FORM] Missing IC images - Front: ${_icFrontImage != null}, Back: ${_icBackImage != null}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload both front and back of your IC'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _logger.info('📝 [UNIFIED-VERIFICATION-FORM] All validations passed, preparing verification data');

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

      _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] Bank details prepared: $_selectedBank (${_bankCodeController.text})');
      _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] Documents prepared: Front and Back IC images');

      // Add instant verification data if enabled and AI has extracted data
      if (_includeInstantVerification) {
        _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] Adding instant verification data');
        verificationData['instantVerification'] = {
          'enabled': true,
          'extractionMethod': 'ai_vision',
          'hasExtractedData': _hasExtractedData,
          'extractedData': _hasExtractedData ? {
            'icNumber': _extractedICNumber,
            'fullName': _extractedFullName,
            'confidence': _extractionConfidence,
            'extractedAt': DateTime.now().toIso8601String(),
          } : null,
        };

        if (_hasExtractedData) {
          _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] Including AI-extracted data - IC: ${_extractedICNumber?.replaceAll(RegExp(r'\d'), '*')}, Name: [EXTRACTED]');
        } else {
          _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] No AI-extracted data available yet');
        }
      } else {
        _logger.debug('📝 [UNIFIED-VERIFICATION-FORM] Instant verification not included - Enabled: $_includeInstantVerification');
      }

      _logger.info('📝 [UNIFIED-VERIFICATION-FORM] Submitting verification data to parent widget');
      widget.onSubmit(verificationData);
    } else {
      _logger.warning('📝 [UNIFIED-VERIFICATION-FORM] Form validation failed - cannot submit');
    }
  }
}

/// Enum for document sides
enum DocumentSide {
  front,
  back,
}
