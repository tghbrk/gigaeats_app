import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../core/services/camera_permission_service.dart';
import '../../core/utils/image_compression_utils.dart';
import '../../presentation/providers/repository_providers.dart';

class ProfileImagePicker extends ConsumerStatefulWidget {
  final String? currentImageUrl;
  final String userId;
  final double size;
  final Function(String imageUrl)? onImageUploaded;
  final bool isEditable;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    required this.userId,
    this.size = 120,
    this.onImageUploaded,
    this.isEditable = true,
  });

  @override
  ConsumerState<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends ConsumerState<ProfileImagePicker> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedImageUrl;
  String? _compressionStatus;

  String? get _displayImageUrl => _uploadedImageUrl ?? widget.currentImageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Profile Image
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: _displayImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _displayImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person,
                        size: widget.size * 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      size: widget.size * 0.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),

        // Upload Button
        if (widget.isEditable)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _showImagePickerOptions,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
            ),
          ),

        // Upload Progress Overlay
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    if (_uploadProgress > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (_compressionStatus != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _compressionStatus!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_displayImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _compressionStatus = null;
      });

      // Check and request permissions before picking image
      final hasPermissions = await CameraPermissionService.handlePhotoPermissionRequest(context);
      if (!hasPermissions) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _uploadProgress = 0.1;
        _compressionStatus = 'Selecting image...';
      });

      final fileUploadService = ref.read(fileUploadServiceProvider);
      final imageFile = await fileUploadService.pickImage(source: source);

      if (imageFile == null) {
        setState(() {
          _isUploading = false;
          _compressionStatus = null;
        });
        return;
      }

      setState(() {
        _uploadProgress = 0.2;
        _compressionStatus = 'Validating image...';
      });

      // Validate image format
      if (!ImageCompressionUtils.isValidImageFormat(imageFile.name)) {
        _showError('Please select a valid image file (JPG, PNG, WebP)');
        setState(() {
          _isUploading = false;
          _compressionStatus = null;
        });
        return;
      }

      // Check if image is valid
      if (!await ImageCompressionUtils.isValidImage(imageFile)) {
        _showError('Selected file is not a valid image');
        setState(() {
          _isUploading = false;
          _compressionStatus = null;
        });
        return;
      }

      setState(() {
        _uploadProgress = 0.3;
        _compressionStatus = 'Checking file size...';
      });

      // Get original file size
      final originalSize = await ImageCompressionUtils.getFileSize(imageFile);
      final originalSizeFormatted = ImageCompressionUtils.formatFileSize(originalSize);

      // Check if compression is needed
      final needsCompression = await ImageCompressionUtils.needsCompression(
        imageFile,
        maxSizeKB: 300,
        maxWidth: 512,
        maxHeight: 512,
      );

      Uint8List finalImageBytes;

      if (needsCompression) {
        setState(() {
          _uploadProgress = 0.4;
          _compressionStatus = 'Compressing image ($originalSizeFormatted)...';
        });

        // Compress image for profile picture
        finalImageBytes = await ImageCompressionUtils.optimizeForProfile(imageFile);

        final compressedSize = ImageCompressionUtils.formatFileSize(finalImageBytes.length);
        setState(() {
          _uploadProgress = 0.6;
          _compressionStatus = 'Compressed to $compressedSize';
        });
      } else {
        setState(() {
          _uploadProgress = 0.6;
          _compressionStatus = 'Image size optimal ($originalSizeFormatted)';
        });

        if (kIsWeb) {
          finalImageBytes = await imageFile.readAsBytes();
        } else {
          finalImageBytes = await File(imageFile.path).readAsBytes();
        }
      }

      setState(() {
        _uploadProgress = 0.7;
        _compressionStatus = 'Uploading to server...';
      });

      // Upload compressed image
      final fileName = 'profile_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageUrl = await fileUploadService.uploadFile(
        imageFile,
        bucketName: 'user-uploads',
        fileName: 'profiles/$fileName',
      );

      setState(() {
        _uploadProgress = 1.0;
        _compressionStatus = 'Upload complete!';
      });

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploading = false;
        _compressionStatus = null;
      });

      // Notify parent
      widget.onImageUploaded?.call(imageUrl);

      _showSuccess('Profile image updated successfully');
    } catch (e) {
      setState(() {
        _isUploading = false;
        _compressionStatus = null;
      });
      _showError('Failed to upload image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _uploadedImageUrl = null;
    });
    widget.onImageUploaded?.call('');
    _showSuccess('Profile image removed');
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
