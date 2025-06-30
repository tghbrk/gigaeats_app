import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/customer_profile_form_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_error_widget.dart';


/// Customer profile edit screen with comprehensive form validation
class CustomerProfileEditScreen extends ConsumerStatefulWidget {
  const CustomerProfileEditScreen({super.key});

  @override
  ConsumerState<CustomerProfileEditScreen> createState() => _CustomerProfileEditScreenState();
}

class _CustomerProfileEditScreenState extends ConsumerState<CustomerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  


  @override
  void initState() {
    super.initState();
    _initializeControllers();
    
    // Load profile data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  void _loadProfileData() {
    // Initialize the form provider
    ref.read(customerProfileFormProvider.notifier).initialize();

    // Listen to form state changes and update controllers
    ref.listen(customerProfileFormProvider, (previous, next) {
      if (previous?.fullName != next.fullName) {
        _fullNameController.text = next.fullName;
      }
      if (previous?.phoneNumber != next.phoneNumber) {
        _phoneController.text = next.phoneNumber;
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(customerProfileFormProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: formState.isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : formState.error != null
              ? _buildErrorState(formState.error!)
              : _buildForm(),
    );
  }

  Widget _buildErrorState(String error) {
    return CustomErrorWidget(
      message: error,
      onRetry: () {
        ref.read(customerProfileFormProvider.notifier).initialize();
      },
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    final formState = ref.watch(customerProfileFormProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message display
            if (formState.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formState.error!,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Personal Information Section
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                ref.read(customerProfileFormProvider.notifier).updateFullName(value);
              },
              validator: (value) {
                final error = ref.read(customerProfileFormProvider.notifier).getFieldError('fullName');
                return error;
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: '+60123456789',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                ref.read(customerProfileFormProvider.notifier).updatePhoneNumber(value);
              },
              validator: (value) {
                final error = ref.read(customerProfileFormProvider.notifier).getFieldError('phoneNumber');
                return error;
              },
            ),

            const SizedBox(height: 32),
            
            // Account Information Section
            _buildSectionHeader('Account Information'),
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _emailController,
              label: 'Email Address',
              hintText: 'Your email address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              enabled: false, // Email is managed through auth, not editable here
              helperText: 'Email can be changed in account settings',
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: formState.isSaving ? 'Saving...' : 'Save Changes',
                onPressed: formState.isSaving ? null : _saveProfile,
                icon: formState.isSaving ? null : Icons.save,
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: formState.isSaving ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }



  Future<void> _saveProfile() async {
    // Validate using the form provider
    final formNotifier = ref.read(customerProfileFormProvider.notifier);
    if (!formNotifier.validateForm()) {
      return;
    }

    // Save using the form provider
    final success = await formNotifier.saveProfile();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }
}
