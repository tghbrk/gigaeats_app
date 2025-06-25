import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vendor_details_provider.dart';
import '../widgets/vendor_gallery_widget.dart';
import '../widgets/vendor_reviews_widget.dart';
import '../widgets/vendor_business_hours_widget.dart';
import '../widgets/vendor_promotions_widget.dart';
import '../../utils/vendor_utils.dart';
import '../../../vendors/data/models/vendor.dart';
import '../../../vendors/presentation/providers/vendor_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';

class VendorDetailsTestScreen extends ConsumerStatefulWidget {
  const VendorDetailsTestScreen({super.key});

  @override
  ConsumerState<VendorDetailsTestScreen> createState() => _VendorDetailsTestScreenState();
}

class _VendorDetailsTestScreenState extends ConsumerState<VendorDetailsTestScreen> {
  String? selectedVendorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorsProvider.notifier).loadVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Details Test'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: vendorsState.isLoading
          ? const Center(child: LoadingWidget(message: 'Loading vendors...'))
          : vendorsState.vendors.isEmpty
              ? const Center(child: Text('No vendors available'))
              : Column(
                  children: [
                    // Vendor selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a vendor to test:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedVendorId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: 'Choose a vendor...',
                            ),
                            items: vendorsState.vendors.map((vendor) {
                              return DropdownMenuItem(
                                value: vendor.id,
                                child: Text(vendor.businessName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedVendorId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Test content
                    if (selectedVendorId != null)
                      Expanded(
                        child: _buildTestContent(selectedVendorId!),
                      ),
                  ],
                ),
    );
  }

  Widget _buildTestContent(String vendorId) {
    final vendor = ref.watch(vendorsProvider).vendors
        .where((v) => v.id == vendorId)
        .firstOrNull;

    if (vendor == null) {
      return const Center(child: Text('Vendor not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor basic info
          _buildVendorBasicInfo(vendor),
          const SizedBox(height: 24),
          
          // Gallery test
          _buildTestSection(
            'Gallery Widget',
            VendorGalleryWidget(
              coverImageUrl: vendor.coverImageUrl,
              galleryImages: vendor.galleryImages,
              vendorName: vendor.businessName,
            ),
          ),
          
          // Business hours test
          _buildTestSection(
            'Business Hours Widget',
            VendorBusinessHoursWidget(vendor: vendor),
          ),
          
          // Promotions test
          _buildTestSection(
            'Promotions Widget',
            VendorPromotionsWidget(vendorId: vendorId),
          ),
          
          // Reviews test
          _buildTestSection(
            'Reviews Widget',
            VendorReviewsWidget(vendorId: vendorId),
          ),
          
          // Favorites test
          _buildTestSection(
            'Favorites Test',
            _buildFavoritesTest(vendorId),
          ),
          
          // Vendor utilities test
          _buildTestSection(
            'Vendor Utils Test',
            _buildVendorUtilsTest(vendor),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorBasicInfo(Vendor vendor) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendor.businessName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rating: ${vendor.rating.toStringAsFixed(1)} (${vendor.totalReviews} reviews)',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Status: ${vendor.isActive ? 'Active' : 'Inactive'}',
              style: theme.textTheme.bodyMedium,
            ),
            if (vendor.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                vendor.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(String title, Widget content) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFavoritesTest(String vendorId) {
    return Consumer(
      builder: (context, ref, child) {
        final favoriteAsync = ref.watch(vendorFavoriteNotifierProvider(vendorId));
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorite Status Test',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                favoriteAsync.when(
                  data: (isFavorited) => Row(
                    children: [
                      Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFavorited ? 'Favorited' : 'Not favorited',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      CustomButton(
                        text: isFavorited ? 'Remove' : 'Add to Favorites',
                        onPressed: () {
                          ref.read(vendorFavoriteNotifierProvider(vendorId).notifier)
                              .toggleFavorite();
                        },
                        type: ButtonType.primary,
                        isExpanded: false,
                      ),
                    ],
                  ),
                  loading: () => const Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 8),
                      Text('Loading favorite status...'),
                    ],
                  ),
                  error: (error, stack) => Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVendorUtilsTest(Vendor vendor) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendor Utils Test',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildUtilRow('Is Open:', VendorUtils.isVendorOpen(vendor).toString()),
            _buildUtilRow('Status Text:', VendorUtils.getVendorStatusText(vendor)),
            _buildUtilRow('Today Hours:', VendorUtils.getTodayHours(vendor)),
            _buildUtilRow('Estimated Delivery:', VendorUtils.getEstimatedDeliveryTime(vendor)),
            _buildUtilRow('Delivery Fee:', VendorUtils.formatDeliveryFee(
              vendor.deliveryFee, 
              vendor.freeDeliveryThreshold, 
              50.0
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
