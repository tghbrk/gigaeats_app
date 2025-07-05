import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/vendor_profile_edit_providers.dart';

/// Widget for uploading vendor gallery images
class VendorGalleryUpload extends ConsumerWidget {
  final List<String> currentImages;
  final Function(List<String>) onImagesChanged;
  final int maxImages;

  const VendorGalleryUpload({
    super.key,
    required this.currentImages,
    required this.onImagesChanged,
    this.maxImages = 6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uploadState = ref.watch(imageUploadProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gallery grid
        _buildGalleryGrid(context, theme),
        
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
        
        // Add image buttons
        if (currentImages.length < maxImages) ...[
          _buildAddImageButtons(context, theme, ref, uploadState),
        ],
        
        // Image count info
        _buildImageCountInfo(theme),
      ],
    );
  }

  Widget _buildGalleryGrid(BuildContext context, ThemeData theme) {
    if (currentImages.isEmpty) {
      return _buildEmptyGallery(theme);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: currentImages.length,
      itemBuilder: (context, index) {
        return _buildGalleryItem(context, theme, index);
      },
    );
  }

  Widget _buildEmptyGallery(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No gallery images',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryItem(BuildContext context, ThemeData theme, int index) {
    final imageUrl = currentImages[index];
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Image
            Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
            
            // Remove button overlay
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _removeImage(index),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildAddImageButtons(
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

  Widget _buildImageCountInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${currentImages.length}/$maxImages images',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    try {
      debugPrint('🖼️ [GALLERY-UPLOAD] Picking image from $source');
      
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final imageFile = await fileUploadService.pickImage(source: source);
      
      if (imageFile != null) {
        debugPrint('🖼️ [GALLERY-UPLOAD] Image picked, starting upload');
        
        final imageUrl = await ref.read(imageUploadProvider.notifier).uploadGalleryImage(imageFile);
        
        if (imageUrl != null) {
          debugPrint('🖼️ [GALLERY-UPLOAD] Upload successful: $imageUrl');
          final updatedImages = [...currentImages, imageUrl];
          onImagesChanged(updatedImages);
        }
      }
    } catch (e) {
      debugPrint('❌ [GALLERY-UPLOAD] Error picking image: $e');
    }
  }

  void _removeImage(int index) {
    debugPrint('🗑️ [GALLERY-UPLOAD] Removing image at index $index');
    final updatedImages = [...currentImages];
    updatedImages.removeAt(index);
    onImagesChanged(updatedImages);
  }
}
