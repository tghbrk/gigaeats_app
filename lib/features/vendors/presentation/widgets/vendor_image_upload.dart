import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/services/camera_permission_service.dart';

class VendorImageUpload extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final ValueChanged<XFile> onImageSelected;
  final bool isLoading;
  final double height;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const VendorImageUpload({
    super.key,
    required this.title,
    this.imageUrl,
    required this.onImageSelected,
    this.isLoading = false,
    this.height = 200,
    this.showRemoveButton = false,
    this.onRemove,
  });

  @override
  State<VendorImageUpload> createState() => _VendorImageUploadState();
}

class _VendorImageUploadState extends State<VendorImageUpload> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.showRemoveButton && widget.imageUrl != null) ...[
              const Spacer(),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Remove image',
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Image display
              if (widget.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    width: double.infinity,
                    height: widget.height,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Placeholder when no image
                Container(
                  width: double.infinity,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Loading overlay
              if (widget.isLoading)
                Container(
                  width: double.infinity,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),

              // Tap overlay
              if (!widget.isLoading)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _showImageSourceDialog,
                      child: Container(),
                    ),
                  ),
                ),

              // Edit button overlay when image exists
              if (widget.imageUrl != null && !widget.isLoading)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Change image',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
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
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Check camera permission if using camera
      if (source == ImageSource.camera) {
        final hasPermission = await CameraPermissionService.requestCameraPermission();
        if (!hasPermission) {
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onImageSelected(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class VendorGalleryUpload extends StatefulWidget {
  final List<String> imageUrls;
  final ValueChanged<XFile> onImageAdded;
  final ValueChanged<String> onImageRemoved;
  final bool isLoading;

  const VendorGalleryUpload({
    super.key,
    required this.imageUrls,
    required this.onImageAdded,
    required this.onImageRemoved,
    this.isLoading = false,
  });

  @override
  State<VendorGalleryUpload> createState() => _VendorGalleryUploadState();
}

class _VendorGalleryUploadState extends State<VendorGalleryUpload> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Gallery Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.imageUrls.length}/5',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.imageUrls.length + (widget.imageUrls.length < 5 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.imageUrls.length) {
                // Add new image button
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: widget.isLoading ? null : _showImageSourceDialog,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add Image',
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Existing image
              final imageUrl = widget.imageUrls[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: const Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Remove button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => widget.onImageRemoved(imageUrl),
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
              );
            },
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
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
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final hasPermission = await CameraPermissionService.requestCameraPermission();
        if (!hasPermission) return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onImageAdded(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
}
