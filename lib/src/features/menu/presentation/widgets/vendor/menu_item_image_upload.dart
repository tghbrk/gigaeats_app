import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/services/camera_permission_service.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../../presentation/providers/repository_providers.dart' show fileUploadServiceProvider;

/// Specialized image upload widget for menu items with preview and upload functionality
class MenuItemImageUpload extends ConsumerStatefulWidget {
  final String? currentImageUrl;
  final String vendorId;
  final String menuItemId;
  final ValueChanged<String?> onImageChanged;
  final bool isEnabled;

  const MenuItemImageUpload({
    super.key,
    this.currentImageUrl,
    required this.vendorId,
    required this.menuItemId,
    required this.onImageChanged,
    this.isEnabled = true,
  });

  @override
  ConsumerState<MenuItemImageUpload> createState() => _MenuItemImageUploadState();
}

class _MenuItemImageUploadState extends ConsumerState<MenuItemImageUpload> {
  bool _isUploading = false;
  String? _uploadError;
  XFile? _selectedImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Menu Item Photo',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        
        // Image preview container
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: _uploadError != null 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
          ),
          child: _buildImageContent(theme),
        ),
        
        const SizedBox(height: 12),
        
        // Upload buttons
        if (widget.isEnabled) ...[
          Row(
            children: [
              Expanded(
                child: GEButton.outline(
                  text: 'Gallery',
                  onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                  icon: Icons.photo_library,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GEButton.outline(
                  text: 'Camera',
                  onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                  icon: Icons.camera_alt,
                ),
              ),
            ],
          ),
          
          // Remove button (if image exists)
          if (widget.currentImageUrl != null || _selectedImage != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: GEButton.ghost(
                text: 'Remove Photo',
                onPressed: _isUploading ? null : _removeImage,
                icon: Icons.delete_outline,
                customColor: theme.colorScheme.error,
              ),
            ),
          ],
        ],
        
        // Error message
        if (_uploadError != null) ...[
          const SizedBox(height: 8),
          Container(
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
                const SizedBox(width: 8),
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
          ),
        ],
        
        // Helper text
        if (_uploadError == null) ...[
          const SizedBox(height: 8),
          Text(
            'Add a high-quality photo to showcase your menu item. Recommended size: 1024x1024px',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent(ThemeData theme) {
    // Show loading state
    if (_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Uploading image...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Show current image or selected image
    final imageUrl = widget.currentImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(theme, hasError: true),
        ),
      );
    }

    // Show placeholder
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme, {bool hasError = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError ? Icons.broken_image : Icons.add_photo_alternate,
            size: 48,
            color: hasError 
                ? theme.colorScheme.error 
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasError 
                ? 'Failed to load image' 
                : 'No photo selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasError 
                  ? theme.colorScheme.error 
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!hasError && widget.isEnabled) ...[
            const SizedBox(height: 8),
            Text(
              'Tap buttons below to add photo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!widget.isEnabled) return;

    try {
      debugPrint('🖼️ [MENU-ITEM-IMAGE] Starting image selection from $source');
      
      // Clear previous error
      setState(() {
        _uploadError = null;
      });

      // Check camera permission if using camera
      if (source == ImageSource.camera) {
        final hasPermission = await CameraPermissionService.requestCameraPermission();
        if (!hasPermission) {
          setState(() {
            _uploadError = 'Camera permission is required to take photos';
          });
          return;
        }
      }

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('🖼️ [MENU-ITEM-IMAGE] Image selected: ${image.path}');
        await _uploadImage(image);
      }
    } catch (e) {
      debugPrint('❌ [MENU-ITEM-IMAGE] Error picking image: $e');
      setState(() {
        _uploadError = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _uploadImage(XFile imageFile) async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
      _selectedImage = imageFile;
    });

    try {
      debugPrint('🖼️ [MENU-ITEM-IMAGE] Starting upload for menu item ${widget.menuItemId}');
      
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final imageUrl = await fileUploadService.uploadMenuItemImage(
        widget.vendorId,
        widget.menuItemId,
        imageFile,
      );

      debugPrint('✅ [MENU-ITEM-IMAGE] Upload successful: $imageUrl');
      
      // Notify parent of the new image URL
      widget.onImageChanged(imageUrl);
      
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
    } catch (e) {
      debugPrint('❌ [MENU-ITEM-IMAGE] Upload failed: $e');
      setState(() {
        _isUploading = false;
        _selectedImage = null;
        _uploadError = 'Failed to upload image: $e';
      });
    }
  }

  void _removeImage() {
    if (!widget.isEnabled || _isUploading) return;
    
    debugPrint('🖼️ [MENU-ITEM-IMAGE] Removing image');
    
    // Clear the image
    widget.onImageChanged(null);
    
    setState(() {
      _selectedImage = null;
      _uploadError = null;
    });
  }
}
