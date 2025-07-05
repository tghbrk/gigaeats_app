import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/vendor_profile_edit_providers.dart';

/// Widget for uploading vendor cover photo
class VendorCoverPhotoUpload extends ConsumerWidget {
  final String? currentImageUrl;
  final Function(String?) onImageChanged;

  const VendorCoverPhotoUpload({
    super.key,
    this.currentImageUrl,
    required this.onImageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uploadState = ref.watch(imageUploadProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover photo preview
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1,
            ),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: _buildImagePreview(context, theme),
        ),
        
        const SizedBox(height: 12),
        
        // Upload progress indicator
        if (uploadState.isUploading) ...[
          _buildProgressIndicator(theme, uploadState),
          const SizedBox(height: 12),
        ],
        
        // Error message
        if (uploadState.error != null) ...[
          _buildErrorMessage(theme, uploadState.error!),
          const SizedBox(height: 12),
        ],
        
        // Upload buttons
        _buildUploadButtons(context, theme, ref, uploadState),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context, ThemeData theme) {
    if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image
            Image.network(
              currentImageUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(theme);
              },
            ),
            
            // Remove button overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _removeImage(),
                  tooltip: 'Remove cover photo',
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Cover Photo',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommended: 1200x400px',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, ImageUploadState uploadState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: uploadState.progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(uploadState.progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (uploadState.status != null) ...[
          const SizedBox(height: 4),
          Text(
            uploadState.status!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme, String error) {
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
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    ImageUploadState uploadState,
  ) {
    final isUploading = uploadState.isUploading;
    
    return Row(
      children: [
        // Camera button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isUploading ? null : () => _pickImage(ref, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
        ),
        const SizedBox(width: 12),
        
        // Gallery button
        Expanded(
          child: FilledButton.icon(
            onPressed: isUploading ? null : () => _pickImage(ref, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    try {
      debugPrint('📸 [COVER-UPLOAD] Picking image from $source');
      
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final imageFile = await fileUploadService.pickImage(source: source);
      
      if (imageFile != null) {
        debugPrint('📸 [COVER-UPLOAD] Image picked, starting upload');
        
        final imageUrl = await ref.read(imageUploadProvider.notifier).uploadCoverImage(imageFile);
        
        if (imageUrl != null) {
          debugPrint('📸 [COVER-UPLOAD] Upload successful: $imageUrl');
          onImageChanged(imageUrl);
        }
      }
    } catch (e) {
      debugPrint('❌ [COVER-UPLOAD] Error picking image: $e');
    }
  }

  void _removeImage() {
    debugPrint('🗑️ [COVER-UPLOAD] Removing cover image');
    onImageChanged(null);
  }
}
