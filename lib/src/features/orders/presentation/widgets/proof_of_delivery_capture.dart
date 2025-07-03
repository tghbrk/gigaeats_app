import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/order.dart';
import '../../data/models/delivery_method.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../presentation/providers/repository_providers.dart';
import 'delivery_confirmation_summary.dart';

class ProofOfDeliveryCapture extends ConsumerStatefulWidget {
  final Order order;
  final Function(ProofOfDelivery) onProofCaptured;

  const ProofOfDeliveryCapture({
    super.key,
    required this.order,
    required this.onProofCaptured,
  });

  @override
  ConsumerState<ProofOfDeliveryCapture> createState() => _ProofOfDeliveryCaptureState();
}

class _ProofOfDeliveryCaptureState extends ConsumerState<ProofOfDeliveryCapture> {
  final _recipientNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  XFile? _capturedPhoto;
  String? _photoUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  LocationData? _capturedLocation;
  bool _isCapturingLocation = false;
  int _currentStep = 0; // 0: Capture, 1: Preview/Confirm

  @override
  void dispose() {
    _recipientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Proof of Delivery',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0 ? _buildCaptureStep() : _buildConfirmationStep(),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: _currentStep == 0 ? _buildCaptureActions() : _buildConfirmationActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Info
        _buildOrderInfo(),
        const SizedBox(height: 24),

        // Photo Capture Section
        _buildPhotoCaptureSection(),
        const SizedBox(height: 20),

        // Location Capture Section
        _buildLocationCaptureSection(),
        const SizedBox(height: 20),

        // Recipient Information
        _buildRecipientSection(),
        const SizedBox(height: 20),

        // Delivery Notes
        _buildNotesSection(),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return DeliveryConfirmationSummary(
      order: widget.order,
      photoUrl: _photoUrl,
      locationData: _capturedLocation,
      recipientName: _recipientNameController.text.trim().isNotEmpty
          ? _recipientNameController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      onEditPhoto: () {
        setState(() {
          _currentStep = 0;
        });
      },
      onEditLocation: () {
        setState(() {
          _currentStep = 0;
        });
      },
      onConfirmDelivery: _submitProofOfDelivery,
      isSubmitting: _isSubmitting,
    );
  }

  Widget _buildCaptureActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _canSubmit() && !_isSubmitting ? _proceedToConfirmation : null,
          child: const Text('Review & Confirm'),
        ),
      ],
    );
  }

  Widget _buildConfirmationActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _isSubmitting ? null : () {
            setState(() {
              _currentStep = 0;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Edit'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildOrderInfo() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.orderNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer: ${widget.order.customerName}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Total: RM ${widget.order.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Delivery Address: ${widget.order.deliveryAddress.street}, ${widget.order.deliveryAddress.city}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCaptureSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Photo *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_capturedPhoto != null || _photoUrl != null) ...[
          // Show captured photo
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error),
                      ),
                    )
                  : Image.network(
                      _capturedPhoto!.path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _retakePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _removePhoto,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Photo capture buttons
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Capture delivery photo',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : () => _capturePhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : () => _capturePhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        
        if (_isUploading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Uploading photo...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationCaptureSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Location *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (_capturedLocation != null) ...[
          // Show captured location
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location Captured',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Coordinates: ${_capturedLocation!.latitude.toStringAsFixed(6)}, ${_capturedLocation!.longitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Accuracy: ±${_capturedLocation!.accuracy.toStringAsFixed(1)}m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _capturedLocation!.accuracy <= 50 ? Colors.green : Colors.orange,
                  ),
                ),
                if (_capturedLocation!.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Address: ${_capturedLocation!.address}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isCapturingLocation ? null : _captureLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Update Location'),
                ),
              ],
            ),
          ),
        ] else ...[
          // Location capture button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  size: 32,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture delivery location',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isCapturingLocation ? null : _captureLocation,
                  icon: _isCapturingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isCapturingLocation ? 'Getting Location...' : 'Get Current Location'),
                ),
              ],
            ),
          ),
        ],

        if (_isCapturingLocation) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Capturing GPS location...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecipientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _recipientNameController,
          decoration: const InputDecoration(
            labelText: 'Recipient Name',
            hintText: 'Who received the order?',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes',
            hintText: 'Any additional delivery notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Check and request permissions before capturing photo
      final hasPermissions = await CameraPermissionService.handlePhotoPermissionRequest(context);
      if (!hasPermissions) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = photo;
        });

        // Upload to Supabase storage
        await _uploadPhoto(photo);
      }
    } catch (e) {
      _showError('Failed to capture photo: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadPhoto(XFile photo) async {
    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      
      // Create a unique filename for the proof of delivery photo
      final fileName = 'proof_delivery_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to delivery-proofs bucket
      final photoUrl = await fileUploadService.uploadFile(
        photo,
        bucketName: SupabaseConfig.deliveryProofsBucket,
        fileName: fileName,
      );

      setState(() {
        _photoUrl = photoUrl;
      });
    } catch (e) {
      _showError('Failed to upload photo: $e');
      setState(() {
        _capturedPhoto = null;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
      _photoUrl = null;
    });
    _capturePhoto(ImageSource.camera);
  }

  void _removePhoto() {
    setState(() {
      _capturedPhoto = null;
      _photoUrl = null;
    });
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturingLocation = true;
    });

    try {
      // Check and request location permissions
      final hasPermissions = await LocationService.handleLocationPermissionRequest(context);
      if (!hasPermissions) {
        setState(() {
          _isCapturingLocation = false;
        });
        return;
      }

      // Get accurate location
      final location = await LocationService.getAccurateLocation(
        maxRetries: 3,
        includeAddress: true,
      );

      if (location != null) {
        setState(() {
          _capturedLocation = location;
        });

        // Show success message with accuracy info
        if (mounted) {
          final accuracyText = location.accuracy <= 50
              ? 'High accuracy (±${location.accuracy.toStringAsFixed(1)}m)'
              : 'Moderate accuracy (±${location.accuracy.toStringAsFixed(1)}m)';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location captured with $accuracyText'),
              backgroundColor: location.accuracy <= 50 ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        _showError('Failed to capture location. Please try again.');
      }
    } catch (e) {
      _showError('Failed to capture location: $e');
    } finally {
      setState(() {
        _isCapturingLocation = false;
      });
    }
  }

  void _proceedToConfirmation() {
    setState(() {
      _currentStep = 1;
    });
  }

  bool _canSubmit() {
    return _photoUrl != null &&
           _capturedLocation != null &&
           !_isUploading &&
           !_isCapturingLocation;
  }

  Future<void> _submitProofOfDelivery() async {
    if (!_canSubmit()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final proofOfDelivery = ProofOfDelivery(
        photoUrl: _photoUrl!,
        recipientName: _recipientNameController.text.trim().isNotEmpty
            ? _recipientNameController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        deliveredAt: DateTime.now(),
        deliveredBy: 'Vendor', // TODO: Get actual delivery person name
        latitude: _capturedLocation?.latitude,
        longitude: _capturedLocation?.longitude,
        locationAccuracy: _capturedLocation?.accuracy,
        deliveryAddress: _capturedLocation?.address,
      );

      Navigator.of(context).pop();
      widget.onProofCaptured(proofOfDelivery);
    } catch (e) {
      _showError('Failed to submit proof of delivery: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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
}
