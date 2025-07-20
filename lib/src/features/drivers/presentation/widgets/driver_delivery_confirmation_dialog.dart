import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../drivers/data/models/delivery_confirmation.dart';
import '../../../../core/services/camera_permission_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/widgets/storage_image_widget.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// Mandatory delivery confirmation dialog for drivers with photo capture and GPS verification
/// This dialog enforces delivery proof requirements and cannot be bypassed
class DriverDeliveryConfirmationDialog extends ConsumerStatefulWidget {
  final DriverOrder order;
  final Function(DeliveryConfirmation) onConfirmed;
  final VoidCallback? onCancelled;

  const DriverDeliveryConfirmationDialog({
    super.key,
    required this.order,
    required this.onConfirmed,
    this.onCancelled,
  });

  @override
  ConsumerState<DriverDeliveryConfirmationDialog> createState() => _DriverDeliveryConfirmationDialogState();
}

class _DriverDeliveryConfirmationDialogState extends ConsumerState<DriverDeliveryConfirmationDialog> {
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();
  
  XFile? _capturedPhoto;
  String? _photoUrl;
  LocationData? _currentLocation;
  
  bool _isCapturingPhoto = false;
  bool _isCapturingLocation = false;
  bool _isSubmitting = false;
  // TODO: Implement configurable photo and location requirements

  @override
  void initState() {
    super.initState();
    _captureCurrentLocation();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canConfirmDelivery {
    return _photoUrl != null && 
           _currentLocation != null && 
           !_isCapturingPhoto && 
           !_isCapturingLocation && 
           !_isSubmitting;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false, // Prevent dismissing without confirmation
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.camera_alt,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Delivery Confirmation'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfo(theme),
                const SizedBox(height: 20),
                _buildPhotoSection(theme),
                const SizedBox(height: 16),
                _buildLocationSection(theme),
                const SizedBox(height: 16),
                _buildRecipientSection(theme),
                const SizedBox(height: 16),
                _buildNotesSection(theme),
                const SizedBox(height: 16),
                _buildRequirementsWarning(theme),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () {
              widget.onCancelled?.call();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _canConfirmDelivery ? _confirmDelivery : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Complete Delivery'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.orderNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customer: ${widget.order.customerName}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Address: ${widget.order.deliveryDetails.address}',
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Total: RM${widget.order.orderTotal.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.camera_alt,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Delivery Photo',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'REQUIRED',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_capturedPhoto != null && _photoUrl != null) ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: StorageImageWidget(
              imageUrl: _photoUrl!,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
              placeholder: const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: const Center(
                child: Icon(Icons.error),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isCapturingPhoto ? null : _retakePhoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake Photo'),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Take delivery photo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCapturingPhoto ? null : _capturePhoto,
                  icon: _isCapturingPhoto 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(_isCapturingPhoto ? 'Capturing...' : 'Take Photo'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'GPS Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'REQUIRED',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _currentLocation != null
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _currentLocation != null
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _currentLocation != null ? Icons.check_circle : Icons.location_off,
                color: _currentLocation != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLocation != null
                          ? 'Location captured successfully'
                          : 'Location not available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _currentLocation != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                    if (_currentLocation != null) ...[
                      Text(
                        'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Accuracy: ${_currentLocation!.accuracy.toStringAsFixed(1)}m',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (_isCapturingLocation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_currentLocation == null)
                IconButton(
                  onPressed: _captureCurrentLocation,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Retry location capture',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient Name (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _recipientController,
          decoration: InputDecoration(
            hintText: 'Who received the order?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Notes (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special notes about the delivery...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsWarning(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Photo and GPS location are mandatory for delivery completion. This action cannot be undone.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    debugPrint('📸 [DELIVERY-DIALOG] Starting photo capture process');
    debugPrint('📋 [DELIVERY-DIALOG] Order ID: ${widget.order.id}');

    setState(() {
      _isCapturingPhoto = true;
    });

    try {
      // Check and request camera permissions
      debugPrint('🔒 [DELIVERY-DIALOG] Checking camera permissions');
      final hasPermissions = await CameraPermissionService.handlePhotoPermissionRequest(context);
      if (!hasPermissions) {
        debugPrint('❌ [DELIVERY-DIALOG] Camera permission denied');
        _showError('Camera permission is required to capture delivery photo');
        return;
      }
      debugPrint('✅ [DELIVERY-DIALOG] Camera permissions granted');

      final ImagePicker picker = ImagePicker();
      debugPrint('🔧 [DELIVERY-DIALOG] Opening camera with settings: 1920x1080, quality 85%, rear camera');

      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        debugPrint('✅ [DELIVERY-DIALOG] Photo captured successfully');
        debugPrint('📊 [DELIVERY-DIALOG] Photo path: ${photo.path}');
        debugPrint('📊 [DELIVERY-DIALOG] Photo size: ${await photo.length()} bytes');

        setState(() {
          _capturedPhoto = photo;
        });

        // Upload photo to Supabase storage
        debugPrint('🚀 [DELIVERY-DIALOG] Starting photo upload to Supabase storage');
        await _uploadPhoto(photo);
      } else {
        debugPrint('🚫 [DELIVERY-DIALOG] Photo capture cancelled by user');
      }
    } catch (e) {
      debugPrint('❌ [DELIVERY-DIALOG] Error capturing photo: $e');
      _showError('Failed to capture photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingPhoto = false;
        });
      }
    }
  }

  Future<void> _uploadPhoto(XFile photo) async {
    debugPrint('☁️ [DELIVERY-DIALOG] Starting photo upload to Supabase storage');
    debugPrint('📋 [DELIVERY-DIALOG] Order ID: ${widget.order.id}');

    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);

      // Create unique filename for delivery proof
      final fileName = 'delivery_proof_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('📁 [DELIVERY-DIALOG] Generated filename: $fileName');
      debugPrint('🪣 [DELIVERY-DIALOG] Target bucket: ${SupabaseConfig.deliveryProofsBucket}');

      // Upload to delivery-proofs bucket
      debugPrint('🚀 [DELIVERY-DIALOG] Uploading photo to storage...');
      final photoUrl = await fileUploadService.uploadFile(
        photo,
        bucketName: SupabaseConfig.deliveryProofsBucket,
        fileName: fileName,
      );

      debugPrint('✅ [DELIVERY-DIALOG] Photo uploaded successfully');
      debugPrint('🔗 [DELIVERY-DIALOG] Photo URL: $photoUrl');

      setState(() {
        _photoUrl = photoUrl;
      });

      debugPrint('🔧 [DELIVERY-DIALOG] Photo URL saved to state - delivery confirmation ready');
    } catch (e) {
      debugPrint('❌ [DELIVERY-DIALOG] Photo upload failed: $e');
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
    _capturePhoto();
  }

  Future<void> _captureCurrentLocation() async {
    setState(() {
      _isCapturingLocation = true;
    });

    try {
      final location = await LocationService.getCurrentLocation();

      setState(() {
        _currentLocation = location;
      });
    } catch (e) {
      _showError('Failed to capture location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingLocation = false;
        });
      }
    }
  }

  Future<void> _confirmDelivery() async {
    debugPrint('🎯 [DELIVERY-DIALOG] Starting delivery confirmation process');
    debugPrint('📋 [DELIVERY-DIALOG] Order ID: ${widget.order.id}');
    debugPrint('📸 [DELIVERY-DIALOG] Photo URL: $_photoUrl');
    debugPrint('📍 [DELIVERY-DIALOG] Location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}');
    debugPrint('👤 [DELIVERY-DIALOG] Recipient: ${_recipientController.text.trim()}');
    debugPrint('📝 [DELIVERY-DIALOG] Notes: ${_notesController.text.trim()}');

    if (!_canConfirmDelivery) {
      debugPrint('❌ [DELIVERY-DIALOG] Cannot confirm delivery - missing required fields');
      _showError('Please complete all required fields before confirming delivery');
      return;
    }

    debugPrint('✅ [DELIVERY-DIALOG] All required fields validated successfully');

    // Show final confirmation summary before submitting
    debugPrint('🔍 [DELIVERY-DIALOG] Showing final confirmation summary to user');
    final shouldProceed = await _showFinalDeliveryConfirmationSummary();
    if (!shouldProceed) {
      debugPrint('🚫 [DELIVERY-DIALOG] User cancelled delivery confirmation in summary');
      return;
    }

    debugPrint('✅ [DELIVERY-DIALOG] User confirmed delivery in summary - proceeding');

    setState(() {
      _isSubmitting = true;
    });

    try {
      final confirmation = DeliveryConfirmation(
        orderId: widget.order.id,
        deliveredAt: DateTime.now(),
        photoUrl: _photoUrl!,
        location: _currentLocation!,
        recipientName: _recipientController.text.trim().isNotEmpty
            ? _recipientController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        confirmedBy: 'driver', // TODO: Get actual driver info
      );

      debugPrint('✅ [DELIVERY-DIALOG] Delivery confirmation object created successfully');
      debugPrint('🔧 [DELIVERY-DIALOG] Confirmation details: ${confirmation.toJson()}');

      // Simulate network delay for processing
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        debugPrint('🚀 [DELIVERY-DIALOG] Closing dialog and triggering confirmation callback');
        Navigator.of(context).pop();
        widget.onConfirmed(confirmation);
      }
    } catch (e) {
      debugPrint('❌ [DELIVERY-DIALOG] Error in delivery confirmation: $e');
      _showError('Failed to confirm delivery: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Show final delivery confirmation summary with all captured proof
  Future<bool> _showFinalDeliveryConfirmationSummary() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirm Delivery'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please confirm that you have captured all required delivery proof:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Photo proof verification
            Row(
              children: [
                const Icon(Icons.check, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Text('📸 Delivery photo captured'),
                const Spacer(),
                if (_photoUrl != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green),
                    ),
                    child: StorageImageWidget(
                      imageUrl: _photoUrl!,
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(4),
                      placeholder: const Icon(Icons.image, size: 20),
                      errorWidget: const Icon(Icons.error, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // GPS verification
            Row(
              children: [
                const Icon(Icons.check, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Text('📍 GPS location verified'),
                const Spacer(),
                if (_currentLocation != null)
                  Text(
                    '±${_currentLocation!.accuracy.toStringAsFixed(0)}m',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            if (_recipientController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('👤 Recipient: ${_recipientController.text.trim()}'),
                  ),
                ],
              ),
            ],
            if (_notesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('📝 Notes: ${_notesController.text.trim()}'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action will complete the delivery and cannot be undone.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Review Again'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Delivery'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// DeliveryConfirmation class moved to lib/src/features/drivers/data/models/delivery_confirmation.dart
