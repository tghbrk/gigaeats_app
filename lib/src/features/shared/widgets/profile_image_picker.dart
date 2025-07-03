import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Profile image picker widget
class ProfileImagePicker extends StatefulWidget {
  final String? imageUrl;
  final Function(String?) onImageSelected;
  final double size;
  
  const ProfileImagePicker({
    super.key,
    this.imageUrl,
    required this.onImageSelected,
    this.size = 100,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        // In a real app, you would upload the image to storage
        // and get back a URL. For now, we'll use the local path.
        widget.onImageSelected(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: widget.imageUrl != null
            ? ClipOval(
                child: Image.network(
                  widget.imageUrl!,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
                ),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Icon(
      Icons.add_a_photo,
      size: widget.size * 0.4,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
