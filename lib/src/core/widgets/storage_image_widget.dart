import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../presentation/providers/repository_providers.dart';

/// Widget for displaying images from Supabase storage buckets
/// Automatically handles signed URLs for private buckets
class StorageImageWidget extends ConsumerStatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const StorageImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  ConsumerState<StorageImageWidget> createState() => _StorageImageWidgetState();
}

class _StorageImageWidgetState extends ConsumerState<StorageImageWidget> {
  String? _signedUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(StorageImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      
      // Check if this is a Supabase storage URL that needs conversion to signed URL
      if (widget.imageUrl.contains('supabase.co/storage/v1/object/public/')) {
        // Convert public URL to signed URL for private buckets
        final signedUrl = await fileUploadService.convertToSignedUrl(widget.imageUrl);
        
        if (mounted) {
          setState(() {
            _signedUrl = signedUrl;
            _isLoading = false;
          });
        }
      } else {
        // Use original URL (already signed or external URL)
        if (mounted) {
          setState(() {
            _signedUrl = widget.imageUrl;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [STORAGE-IMAGE] Failed to load image: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child;

    if (_isLoading) {
      child = widget.placeholder ?? 
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    } else if (_error != null) {
      child = widget.errorWidget ?? 
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
    } else if (_signedUrl != null) {
      child = CachedNetworkImage(
        imageUrl: _signedUrl!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        placeholder: (context, url) => widget.placeholder ?? 
            Container(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        errorWidget: (context, url, error) => widget.errorWidget ?? 
            Container(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: const Center(
                child: Icon(Icons.error, color: Colors.red),
              ),
            ),
      );
    } else {
      child = widget.errorWidget ?? 
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }
}


