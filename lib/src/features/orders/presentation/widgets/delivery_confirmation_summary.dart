import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/order.dart';

import '../../../../core/services/location_service.dart';

/// Widget that displays a comprehensive summary of delivery confirmation
/// including photo preview, location display, and order details
class DeliveryConfirmationSummary extends StatelessWidget {
  final Order order;
  final String? photoUrl;
  final LocationData? locationData;
  final String? recipientName;
  final String? notes;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onEditLocation;
  final VoidCallback? onConfirmDelivery;
  final bool isSubmitting;

  const DeliveryConfirmationSummary({
    super.key,
    required this.order,
    this.photoUrl,
    this.locationData,
    this.recipientName,
    this.notes,
    this.onEditPhoto,
    this.onEditLocation,
    this.onConfirmDelivery,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canConfirm = photoUrl != null && locationData != null;

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
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
                  Icons.assignment_turned_in,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delivery Confirmation Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Information
                _buildOrderSummary(theme),
                const SizedBox(height: 20),

                // Photo Preview
                _buildPhotoPreview(theme),
                const SizedBox(height: 20),

                // Location Preview
                _buildLocationPreview(theme),
                const SizedBox(height: 20),

                // Additional Details
                if (recipientName?.isNotEmpty == true || notes?.isNotEmpty == true)
                  _buildAdditionalDetails(theme),

                const SizedBox(height: 24),

                // Confirmation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canConfirm && !isSubmitting ? onConfirmDelivery : null,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(isSubmitting ? 'Confirming Delivery...' : 'Confirm Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                if (!canConfirm) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Please capture both photo and location to confirm delivery',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            'Order #${order.orderNumber}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customer: ${order.customerName}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Total: RM ${order.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              photoUrl != null ? Icons.check_circle : Icons.camera_alt,
              color: photoUrl != null ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Delivery Photo',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (photoUrl != null && onEditPhoto != null)
              TextButton.icon(
                onPressed: onEditPhoto,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (photoUrl != null) ...[
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
        ] else ...[
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photo not captured',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              locationData != null ? Icons.check_circle : Icons.location_on,
              color: locationData != null ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Delivery Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (locationData != null && onEditLocation != null)
              TextButton.icon(
                onPressed: onEditLocation,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (locationData != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS: ${locationData!.latitude.toStringAsFixed(6)}, ${locationData!.longitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Accuracy: ±${locationData!.accuracy.toStringAsFixed(1)}m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: locationData!.accuracy <= 50 ? Colors.green : Colors.orange,
                  ),
                ),
                if (locationData!.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    locationData!.address!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location not captured',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (recipientName?.isNotEmpty == true) ...[
          Text(
            'Recipient: $recipientName',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
        if (notes?.isNotEmpty == true) ...[
          Text(
            'Notes: $notes',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
