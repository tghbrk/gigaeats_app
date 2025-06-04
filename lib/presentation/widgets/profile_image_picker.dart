import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/services/camera_permission_service.dart';
import '../providers/repository_providers.dart';

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
  String? _uploadedImageUrl;

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
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
      });

      // Check and request permissions before picking image
      final hasPermissions = await CameraPermissionService.handlePhotoPermissionRequest(context);
      if (!hasPermissions) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final fileUploadService = ref.read(fileUploadServiceProvider);
      final imageFile = await fileUploadService.pickImage(source: source);

      if (imageFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Validate file
      if (!fileUploadService.isValidImageFile(imageFile)) {
        _showError('Please select a valid image file (JPG, PNG, GIF, WebP)');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Check file size
      final bytes = await imageFile.readAsBytes();
      if (!fileUploadService.isFileSizeValid(bytes.length, maxSizeMB: 5.0)) {
        _showError('Image size must be less than 5MB');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload image
      final imageUrl = await fileUploadService.uploadProfileImage(
        widget.userId,
        imageFile,
      );

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploading = false;
      });

      // Notify parent
      widget.onImageUploaded?.call(imageUrl);

      _showSuccess('Profile image updated successfully');
    } catch (e) {
      setState(() {
        _isUploading = false;
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
