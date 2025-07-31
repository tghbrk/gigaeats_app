import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';

/// Driver wallet document upload screen for verification
class DriverWalletDocumentUploadScreen extends ConsumerStatefulWidget {
  const DriverWalletDocumentUploadScreen({super.key});

  @override
  ConsumerState<DriverWalletDocumentUploadScreen> createState() => _DriverWalletDocumentUploadScreenState();
}

class _DriverWalletDocumentUploadScreenState extends ConsumerState<DriverWalletDocumentUploadScreen> {
  int _currentStep = 0;
  bool _isUploading = false;
  
  final List<DocumentUploadStep> _steps = [
    DocumentUploadStep(
      title: 'Upload IC Front',
      description: 'Take a clear photo of the front of your IC card',
      icon: Icons.credit_card,
      isCompleted: false,
    ),
    DocumentUploadStep(
      title: 'Upload IC Back',
      description: 'Take a clear photo of the back of your IC card',
      icon: Icons.credit_card,
      isCompleted: false,
    ),
    DocumentUploadStep(
      title: 'Upload Driver License',
      description: 'Take a clear photo of your driver license',
      icon: Icons.drive_eta,
      isCompleted: false,
    ),
    DocumentUploadStep(
      title: 'Take Selfie',
      description: 'Take a selfie for identity verification',
      icon: Icons.face,
      isCompleted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('📄 [DRIVER-DOCUMENT-UPLOAD] Screen initialized');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(theme),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current step content
                    _buildCurrentStepContent(theme),
                    const SizedBox(height: 24),
                    
                    // Upload area
                    _buildUploadArea(theme),
                    const SizedBox(height: 24),
                    
                    // Guidelines
                    _buildGuidelines(theme),
                  ],
                ),
              ),
            ),
            
            // Bottom actions
            _buildBottomActions(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      title: const Text(
        'Driver Document Upload',
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

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = _steps[index].isCompleted;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive 
                          ? theme.colorScheme.primary 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _steps.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent(ThemeData theme) {
    final currentStep = _steps[_currentStep];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                currentStep.icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of ${_steps.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStep.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStep.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadArea(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
      ),
      child: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading...'),
                ],
              ),
            )
          : InkWell(
              onTap: _showUploadOptions,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to upload document',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or select from gallery',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGuidelines(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  'Photo Guidelines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuidelineItem(theme, 'Ensure good lighting and clear visibility'),
            _buildGuidelineItem(theme, 'All text should be readable'),
            _buildGuidelineItem(theme, 'No glare or shadows on the document'),
            _buildGuidelineItem(theme, 'Document should fill most of the frame'),
            _buildGuidelineItem(theme, 'File size should be less than 10MB'),
            if (_currentStep == 2) // Driver license specific guidelines
              _buildGuidelineItem(theme, 'License must be valid and not expired'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(ThemeData theme, String text) {
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

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _steps[_currentStep].isCompleted ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_currentStep == _steps.length - 1 ? 'Submit' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload Document',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _selectFromGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _takePhoto() {
    debugPrint('📸 [DRIVER-DOCUMENT-UPLOAD] Taking photo for step $_currentStep');
    // TODO: Implement camera capture
    _simulateUpload();
  }

  void _selectFromGallery() {
    debugPrint('🖼️ [DRIVER-DOCUMENT-UPLOAD] Selecting from gallery for step $_currentStep');
    // TODO: Implement gallery selection
    _simulateUpload();
  }

  void _simulateUpload() {
    setState(() => _isUploading = true);
    
    // Simulate upload delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _steps[_currentStep].isCompleted = true;
        });
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      // Submit verification
      _submitVerification();
    }
  }

  void _submitVerification() {
    debugPrint('✅ [DRIVER-DOCUMENT-UPLOAD] Submitting verification');
    // TODO: Implement verification submission
    
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Documents Uploaded'),
        content: const Text(
          'Your documents have been uploaded successfully. '
          'We will review them and notify you of the verification status within 2-3 business days.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Return to verification screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class DocumentUploadStep {
  final String title;
  final String description;
  final IconData icon;
  bool isCompleted;

  DocumentUploadStep({
    required this.title,
    required this.description,
    required this.icon,
    this.isCompleted = false,
  });
}
