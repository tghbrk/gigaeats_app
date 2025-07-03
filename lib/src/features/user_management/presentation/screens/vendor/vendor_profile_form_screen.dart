import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore when go_router is used
// import 'package:go_router/go_router.dart';

// TODO: Restore when vendor_profile_provider is implemented
// import '../providers/vendor_profile_provider.dart';
// TODO: Restore when vendor_profile_form widget is implemented
// import '../widgets/vendor_profile_form.dart';
// TODO: Restore when business_hours_editor widget is implemented
// import '../widgets/business_hours_editor.dart';
// TODO: Restore when vendor_image_upload widget is implemented
// import '../widgets/vendor_image_upload.dart';

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
    // TODO: Restore when vendorProfileFormProvider is implemented
    // final state = ref.watch(vendorProfileFormProvider);
    // final notifier = ref.read(vendorProfileFormProvider.notifier);
    final state = <String, dynamic>{}; // Placeholder
    final notifier = null; // Placeholder

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Profile' : 'Create Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
                    // TODO: Restore when VendorProfileForm widget is implemented
                    // VendorProfileForm(
                    //   isEditing: widget.isEditing,
                    // ),
                    const Text('Vendor profile form not available'),

                    const SizedBox(height: 24),

                    // Business Hours Section
                    _buildSectionHeader('Business Hours'),
                    const SizedBox(height: 16),

                    // TODO: Restore when BusinessHoursEditor widget is implemented
                    // BusinessHoursEditor(
                    //   initialHours: state.businessHours,
                    //   onChanged: notifier.updateBusinessHours,
                    // ),
                    const Text('Business hours editor not available'),

                    const SizedBox(height: 24),

                    // Gallery Images Section
                    _buildSectionHeader('Gallery Images'),
                    const SizedBox(height: 16),

                    // TODO: Restore when VendorGalleryUpload widget is implemented
                    // VendorGalleryUpload(
                    //   imageUrls: state.galleryImages,
                    //   onImageAdded: notifier.addGalleryImage,
                    //   onImageRemoved: notifier.removeGalleryImage,
                    //   isLoading: state.isSaving,
                    // ),
                    const Text('Gallery upload not available'),

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
                      onPressed: () => Navigator.of(context).pop(), // state.isSaving ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      // TODO: Restore when state.isSaving is implemented
                      // onPressed: state.isSaving ? null : _saveProfile,
                      onPressed: null, // Placeholder
                      // TODO: Restore dead code - commented out for analyzer cleanup
                      // child: false // state.isSaving placeholder
                      //     ? const SizedBox(
                      //         height: 20,
                      //         width: 20,
                      //         child: CircularProgressIndicator(strokeWidth: 2),
                      //       )
                      //     : Text(widget.isEditing ? 'Update' : 'Create'),
                      child: Text(widget.isEditing ? 'Update' : 'Create'),
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

  // TODO: Restore undefined classes - commented out for analyzer cleanup
  // Widget _buildDeliverySettings(VendorProfileFormState state, VendorProfileFormNotifier notifier) {
  Widget _buildDeliverySettings(Map<String, dynamic> state, Map<String, dynamic> notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimum Order Amount
            TextFormField(
              // TODO: Restore state.minimumOrderAmount when provider is implemented - commented out for analyzer cleanup
              initialValue: (state['minimumOrderAmount']?.toString() ?? ''), // state.minimumOrderAmount?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Minimum Order Amount (RM)',
                hintText: 'Enter minimum order amount',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // TODO: Restore amount usage when provider is implemented - commented out for analyzer cleanup
                // final amount = double.tryParse(value);
                // TODO: Restore notifier.updateMinimumOrderAmount when provider is implemented - commented out for analyzer cleanup
                // notifier.updateMinimumOrderAmount(amount);
              },
            ),

            const SizedBox(height: 16),

            // Delivery Fee
            TextFormField(
              // TODO: Restore state.deliveryFee when provider is implemented - commented out for analyzer cleanup
              initialValue: (state['deliveryFee']?.toString() ?? ''), // state.deliveryFee?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Delivery Fee (RM)',
                hintText: 'Enter delivery fee',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // TODO: Restore fee usage when provider is implemented - commented out for analyzer cleanup
                // final fee = double.tryParse(value);
                // TODO: Restore notifier.updateDeliveryFee when provider is implemented - commented out for analyzer cleanup
                // notifier.updateDeliveryFee(fee);
              },
            ),

            const SizedBox(height: 16),

            // Free Delivery Threshold
            TextFormField(
              // TODO: Restore state.freeDeliveryThreshold when provider is implemented - commented out for analyzer cleanup
              initialValue: (state['freeDeliveryThreshold']?.toString() ?? ''), // state.freeDeliveryThreshold?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Free Delivery Threshold (RM)',
                hintText: 'Enter amount for free delivery',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
                helperText: 'Orders above this amount get free delivery',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // TODO: Restore threshold usage when provider is implemented - commented out for analyzer cleanup
                // final threshold = double.tryParse(value);
                // TODO: Restore notifier.updateFreeDeliveryThreshold when provider is implemented - commented out for analyzer cleanup
                // notifier.updateFreeDeliveryThreshold(threshold);
              },
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Restore unused element - commented out for analyzer cleanup
  /*
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // TODO: Restore when vendorProfileFormProvider is implemented
    // final success = await ref.read(vendorProfileFormProvider.notifier).saveProfile();
    final success = false; // Placeholder
    
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
      Navigator.of(context).pop(); // context.go('/vendor');
    }
  }
  */

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
              // TODO: Restore unused variable - commented out for analyzer cleanup
              // final messenger = ScaffoldMessenger.of(context);
              // TODO: Restore when GoRouter is available
              // final router = GoRouter.of(context);

              navigator.pop();

              // TODO: Restore when vendorProfileFormProvider is implemented
              // final success = await ref.read(vendorProfileFormProvider.notifier).deleteProfile();
              // TODO: Restore unused variable - commented out for analyzer cleanup
              // final success = false; // Placeholder

              // TODO: Restore dead code - commented out for analyzer cleanup
              // if (success && mounted) {
              //   messenger.showSnackBar(
              //     const SnackBar(
              //       content: Text('Profile deleted successfully'),
              //       backgroundColor: Colors.green,
              //     ),
              //   );

              //   // Navigate back to dashboard
              //   // TODO: Restore when router is available
              //   // router.go('/vendor');
              //   navigator.pop(); // Fallback navigation
              // }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
