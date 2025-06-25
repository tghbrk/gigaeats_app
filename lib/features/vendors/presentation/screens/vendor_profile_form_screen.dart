import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/vendor_profile_provider.dart';
import '../widgets/vendor_profile_form.dart';
import '../widgets/business_hours_editor.dart';
import '../widgets/vendor_image_upload.dart';

class VendorProfileFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const VendorProfileFormScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  ConsumerState<VendorProfileFormScreen> createState() => _VendorProfileFormScreenState();
}

class _VendorProfileFormScreenState extends ConsumerState<VendorProfileFormScreen> {
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorProfileFormProvider);
    final notifier = ref.read(vendorProfileFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Profile' : 'Create Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.isEditing)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Profile', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Form
                    VendorProfileForm(
                      isEditing: widget.isEditing,
                    ),

                    const SizedBox(height: 24),

                    // Business Hours Section
                    _buildSectionHeader('Business Hours'),
                    const SizedBox(height: 16),

                    BusinessHoursEditor(
                      initialHours: state.businessHours,
                      onChanged: notifier.updateBusinessHours,
                    ),

                    const SizedBox(height: 24),

                    // Gallery Images Section
                    _buildSectionHeader('Gallery Images'),
                    const SizedBox(height: 16),

                    VendorGalleryUpload(
                      imageUrls: state.galleryImages,
                      onImageAdded: notifier.addGalleryImage,
                      onImageRemoved: notifier.removeGalleryImage,
                      isLoading: state.isSaving,
                    ),

                    const SizedBox(height: 24),

                    // Delivery Settings Section
                    _buildSectionHeader('Delivery Settings'),
                    const SizedBox(height: 16),

                    _buildDeliverySettings(state, notifier),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isSaving ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.isSaving ? null : _saveProfile,
                      child: state.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isEditing ? 'Update' : 'Create'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDeliverySettings(VendorProfileFormState state, VendorProfileFormNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimum Order Amount
            TextFormField(
              initialValue: state.minimumOrderAmount?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Minimum Order Amount (RM)',
                hintText: 'Enter minimum order amount',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                notifier.updateMinimumOrderAmount(amount);
              },
            ),

            const SizedBox(height: 16),

            // Delivery Fee
            TextFormField(
              initialValue: state.deliveryFee?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Delivery Fee (RM)',
                hintText: 'Enter delivery fee',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final fee = double.tryParse(value);
                notifier.updateDeliveryFee(fee);
              },
            ),

            const SizedBox(height: 16),

            // Free Delivery Threshold
            TextFormField(
              initialValue: state.freeDeliveryThreshold?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Free Delivery Threshold (RM)',
                hintText: 'Enter amount for free delivery',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
                helperText: 'Orders above this amount get free delivery',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final threshold = double.tryParse(value);
                notifier.updateFreeDeliveryThreshold(threshold);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(vendorProfileFormProvider.notifier).saveProfile();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing 
              ? 'Profile updated successfully!' 
              : 'Profile created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to vendor dashboard
      context.go('/vendor');
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text(
          'Are you sure you want to delete your vendor profile? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);

              navigator.pop();

              final success = await ref.read(vendorProfileFormProvider.notifier).deleteProfile();

              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Profile deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Navigate back to dashboard
                router.go('/vendor');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
