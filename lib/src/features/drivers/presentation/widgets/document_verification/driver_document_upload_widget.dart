import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/services/camera_permission_service.dart';
import '../../../../../core/utils/logger.dart';
import '../../../domain/models/driver_document_verification.dart';


/// Material Design 3 document upload widget for driver verification
class DriverDocumentUploadWidget extends ConsumerStatefulWidget {
  final DocumentType documentType;
  final String? documentSide; // 'front', 'back' for cards
  final String verificationId;
  final String driverId;
  final String userId;
  final VoidCallback? onUploadComplete;
  final VoidCallback? onUploadError;

  const DriverDocumentUploadWidget({
    super.key,
    required this.documentType,
    this.documentSide,
    required this.verificationId,
    required this.driverId,
    required this.userId,
    this.onUploadComplete,
    this.onUploadError,
  });

  @override
  ConsumerState<DriverDocumentUploadWidget> createState() =>
      _DriverDocumentUploadWidgetState();
}

class _DriverDocumentUploadWidgetState
    extends ConsumerState<DriverDocumentUploadWidget>
    with SingleTickerProviderStateMixin {
  final AppLogger _logger = AppLogger();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  XFile? _selectedFile;
  bool _isUploading = false;
  String? _uploadError;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildUploadArea(theme),
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              _buildPreviewSection(theme),
            ],
            if (_uploadError != null) ...[
              const SizedBox(height: 12),
              _buildErrorSection(theme),
            ],
            if (_isUploading) ...[
              const SizedBox(height: 16),
              _buildProgressSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final documentName = _getDocumentDisplayName();
    final sideText = widget.documentSide != null 
        ? ' (${widget.documentSide!.toUpperCase()})'
        : '';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getDocumentIcon(),
            color: theme.colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$documentName$sideText',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getDocumentDescription(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea(ThemeData theme) {
    if (_selectedFile != null && !_isUploading) {
      return _buildActionButtons(theme);
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Upload ${_getDocumentDisplayName()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo or select from gallery',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildUploadButtons(theme),
                const SizedBox(height: 12),
                _buildUploadRequirements(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadButtons(ThemeData theme) {
    return Row(
      children: [
        // Camera button
        Expanded(
          child: FilledButton.icon(
            onPressed: _isUploading ? null : () => _pickDocument(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Gallery button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : () => _pickDocument(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadRequirements(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Requirements',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._getDocumentRequirements().map((requirement) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requirement,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
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
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Document Selected',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentIcon(),
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: _selectedFile!.length(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final sizeKB = (snapshot.data! / 1024).round();
                          return Text(
                            '${sizeKB}KB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        // Replace button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : () => _showReplaceOptions(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Replace'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              side: BorderSide(color: theme.colorScheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Upload button
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isUploading ? null : _uploadDocument,
            icon: _isUploading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.upload),
            label: Text(_isUploading ? 'Uploading...' : 'Upload Document'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _uploadError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.cloud_upload,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Uploading document...',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ],
    );
  }

  // Document interaction methods
  Future<void> _pickDocument(ImageSource source) async {
    try {
      _logger.info('📷 Picking document from ${source.name}');

      // Check camera permission if using camera
      if (source == ImageSource.camera) {
        final hasPermission = await CameraPermissionService.requestCameraPermission();
        if (!hasPermission) {
          _logger.warning('Camera permission denied');
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90, // High quality for OCR
      );

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _uploadError = null;
        });
        _logger.info('✅ Document selected: ${file.name}');
      }
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to pick document', e, stackTrace);
      setState(() {
        _uploadError = 'Failed to select document: $e';
      });
    }
  }

  void _showReplaceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Replace Document',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) return;

    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
        _uploadProgress = 0.0;
      });

      _animationController.forward();

      _logger.info('📤 Starting document upload');

      // Simulate progress updates
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100;
          });
        }
      }

      // Simulate upload for now (will be replaced with actual service)
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful result
      final result = DriverDocumentUploadResult.success(
        documentId: 'mock-doc-id',
        filePath: 'mock/path',
        fileUrl: 'mock-url',
        fileSize: await _selectedFile!.length(),
        mimeType: 'image/jpeg',
        fileHash: 'mock-hash',
      );

      if (result.success) {
        _logger.info('✅ Document uploaded successfully: ${result.documentId}');
        setState(() {
          _isUploading = false;
          _uploadProgress = 1.0;
        });

        widget.onUploadComplete?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Document uploaded successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(result.errorMessage ?? 'Upload failed');
      }
    } catch (e, stackTrace) {
      _logger.error('❌ Document upload failed', e, stackTrace);
      setState(() {
        _isUploading = false;
        _uploadError = e.toString();
        _uploadProgress = 0.0;
      });

      widget.onUploadError?.call();
    } finally {
      _animationController.reverse();
    }
  }

  // Helper methods for document information
  String _getDocumentDisplayName() {
    switch (widget.documentType) {
      case DocumentType.icCard:
        return 'Malaysian IC';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.driverLicense:
        return 'Driver\'s License';
      case DocumentType.utilityBill:
        return 'Utility Bill';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.selfie:
        return 'Selfie Photo';
    }
  }

  String _getDocumentDescription() {
    switch (widget.documentType) {
      case DocumentType.icCard:
        return 'Clear photo of your Malaysian Identity Card';
      case DocumentType.passport:
        return 'Clear photo of your passport information page';
      case DocumentType.driverLicense:
        return 'Clear photo of your driver\'s license';
      case DocumentType.utilityBill:
        return 'Recent utility bill for address verification';
      case DocumentType.bankStatement:
        return 'Recent bank statement for verification';
      case DocumentType.selfie:
        return 'Clear selfie photo for identity verification';
    }
  }

  IconData _getDocumentIcon() {
    switch (widget.documentType) {
      case DocumentType.icCard:
        return Icons.credit_card;
      case DocumentType.passport:
        return Icons.book;
      case DocumentType.driverLicense:
        return Icons.drive_eta;
      case DocumentType.utilityBill:
        return Icons.receipt_long;
      case DocumentType.bankStatement:
        return Icons.account_balance;
      case DocumentType.selfie:
        return Icons.face;
    }
  }

  List<String> _getDocumentRequirements() {
    switch (widget.documentType) {
      case DocumentType.icCard:
        return [
          'All text must be clearly visible',
          'No glare or shadows on the document',
          'Document must be valid and not expired',
          'Photo must show the entire document',
        ];
      case DocumentType.passport:
        return [
          'Information page must be fully visible',
          'All text must be clearly readable',
          'No glare or shadows on the page',
          'Passport must be valid and not expired',
        ];
      case DocumentType.driverLicense:
        return [
          'License must be valid and not expired',
          'All information must be clearly visible',
          'No glare or shadows on the document',
          'Photo must show the entire license',
        ];
      case DocumentType.utilityBill:
        return [
          'Bill must be dated within last 3 months',
          'Your name and address must be visible',
          'All text must be clearly readable',
          'Document must be complete and unedited',
        ];
      case DocumentType.bankStatement:
        return [
          'Statement must be dated within last 3 months',
          'Your name and account details must be visible',
          'All text must be clearly readable',
          'Document must be complete and unedited',
        ];
      case DocumentType.selfie:
        return [
          'Face must be clearly visible',
          'Good lighting with no shadows',
          'Look directly at the camera',
          'Remove sunglasses or face coverings',
        ];
    }
  }
}
