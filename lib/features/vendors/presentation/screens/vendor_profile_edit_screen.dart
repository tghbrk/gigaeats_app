import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/vendor_profile_provider.dart';
import 'vendor_profile_form_screen.dart';

class VendorProfileEditScreen extends ConsumerStatefulWidget {
  const VendorProfileEditScreen({super.key});

  @override
  ConsumerState<VendorProfileEditScreen> createState() => _VendorProfileEditScreenState();
}

class _VendorProfileEditScreenState extends ConsumerState<VendorProfileEditScreen> {
  @override
  void initState() {
    super.initState();
    // Load current vendor profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProfileFormProvider.notifier).loadCurrentVendorProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentVendorAsync = ref.watch(currentVendorProfileProvider);

    return currentVendorAsync.when(
      data: (vendor) {
        if (vendor == null) {
          // No vendor profile exists, redirect to create
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Profile'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Vendor Profile Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to create a vendor profile first.',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/vendor/profile/create');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Profile'),
                  ),
                ],
              ),
            ),
          );
        }

        // Vendor profile exists, show edit form
        return const VendorProfileFormScreen(isEditing: true);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 64,
                color: Colors.red.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(currentVendorProfileProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
