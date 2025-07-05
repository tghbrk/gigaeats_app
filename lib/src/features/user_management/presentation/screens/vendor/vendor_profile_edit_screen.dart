import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/vendor_profile_edit_providers.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../core/utils/profile_validators.dart';
import '../../../../../core/utils/debug_logger.dart';
import '../../widgets/enhanced_business_hours_editor.dart';
import '../../widgets/cuisine_types_selector.dart';
import '../../widgets/vendor_cover_photo_upload.dart';
import '../../widgets/vendor_gallery_upload.dart';
import '../../widgets/pricing_settings_section.dart';

class VendorProfileEditScreen extends ConsumerStatefulWidget {
  const VendorProfileEditScreen({super.key});

  @override
  ConsumerState<VendorProfileEditScreen> createState() => _VendorProfileEditScreenState();
}

class _VendorProfileEditScreenState extends ConsumerState<VendorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessRegistrationController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _businessNameFocus = FocusNode();
  final _businessRegistrationFocus = FocusNode();
  final _businessAddressFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  // Keyboard shortcuts
  final _saveShortcut = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS);
  final _resetShortcut = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR);

  @override
  void initState() {
    super.initState();

    DebugLogger.info('🚀 [VENDOR-EDIT-SCREEN] Screen initialized', tag: 'VendorProfileEditScreen');

    // Load current vendor profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLogger.info('📋 [VENDOR-EDIT-SCREEN] Post-frame callback triggered, loading vendor profile', tag: 'VendorProfileEditScreen');
      ref.read(vendorProfileEditProvider.notifier).loadVendorProfile();
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessRegistrationController.dispose();
    _businessAddressController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();

    // Dispose focus nodes
    _businessNameFocus.dispose();
    _businessRegistrationFocus.dispose();
    _businessAddressFocus.dispose();
    _descriptionFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(vendorProfileEditProvider);
    final theme = Theme.of(context);
    final isDirty = ref.watch(formIsDirtyProvider);

    // Update controllers when state changes
    _updateControllersFromState(editState);

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isDirty) {
          _handleBackPress(context, isDirty);
        }
      },
      child: Shortcuts(
        shortcuts: {
          _saveShortcut: const SaveIntent(),
          _resetShortcut: const ResetIntent(),
        },
        child: Actions(
          actions: {
            SaveIntent: CallbackAction<SaveIntent>(
              onInvoke: (intent) {
                if (ref.read(canSaveFormProvider)) {
                  _handleSave();
                }
                return null;
              },
            ),
            ResetIntent: CallbackAction<ResetIntent>(
              onInvoke: (intent) {
                if (ref.read(formIsDirtyProvider)) {
                  _handleReset();
                }
                return null;
              },
            ),
          },
          child: Scaffold(
            appBar: _buildAppBar(context, theme, editState),
            body: _buildBody(context, theme, editState),
          ),
        ),
      ),
    );
  }

  /// Update form controllers from state
  void _updateControllersFromState(VendorProfileEditState state) {
    if (_businessNameController.text != state.businessName) {
      _businessNameController.text = state.businessName;
    }
    if (_businessRegistrationController.text != state.businessRegistrationNumber) {
      _businessRegistrationController.text = state.businessRegistrationNumber;
    }
    if (_businessAddressController.text != state.businessAddress) {
      _businessAddressController.text = state.businessAddress;
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.text = state.description;
    }
  }

  /// Build app bar with save/cancel actions
  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme, VendorProfileEditState state) {
    final canSave = ref.watch(canSaveFormProvider);
    final isDirty = ref.watch(formIsDirtyProvider);
    final changedFieldsCount = ref.watch(changedFieldsCountProvider);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Profile'),
          if (isDirty)
            Text(
              '$changedFieldsCount field${changedFieldsCount > 1 ? 's' : ''} modified',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 11,
              ),
            ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBackPress(context, isDirty),
      ),
      actions: [
        if (isDirty) ...[
          IconButton(
            onPressed: state.isSaving ? null : () => _showChangesDialog(),
            icon: const Icon(Icons.info_outline),
            tooltip: 'View Changes',
          ),
          TextButton.icon(
            onPressed: state.isSaving ? null : () => _handleReset(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: canSave && !state.isSaving ? () => _handleSave() : null,
          icon: state.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: const Text('Save'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  /// Build main body content
  Widget _buildBody(BuildContext context, ThemeData theme, VendorProfileEditState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.globalError != null) {
      return _buildErrorState(context, theme, state);
    }

    return Stack(
      children: [
        Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSuccessMessage(theme, state),
                _buildErrorSummary(theme, state),
                _buildBasicInfoSection(theme, state),
                const SizedBox(height: 24),
                _buildCuisineTypesSection(theme, state),
                const SizedBox(height: 24),
                _buildImageUploadSection(theme, state),
                const SizedBox(height: 24),
                _buildContactInfoSection(theme, state),
              const SizedBox(height: 24),
              _buildBusinessHoursSection(theme, state),
                const SizedBox(height: 24),
                _buildPricingSettingsSection(theme, state),
                const SizedBox(height: 24),
                _buildBusinessDetailsSection(theme, state),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        if (state.isSaving)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, ThemeData theme, VendorProfileEditState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Profile',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.globalError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(vendorProfileEditProvider.notifier).loadVendorProfile();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build success message
  Widget _buildSuccessMessage(ThemeData theme, VendorProfileEditState state) {
    if (state.successMessage == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.successMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(vendorProfileEditProvider.notifier).clearSuccessMessage();
            },
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error summary
  Widget _buildErrorSummary(ThemeData theme, VendorProfileEditState state) {
    final errorCount = ref.watch(errorCountProvider);
    final globalError = ref.watch(globalErrorProvider);

    if (errorCount == 0 && globalError == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  globalError ?? 'Please fix the following errors:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(vendorProfileEditProvider.notifier).clearErrors();
                },
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
          if (errorCount > 0 && globalError == null) ...[
            const SizedBox(height: 8),
            Text(
              '$errorCount validation error${errorCount > 1 ? 's' : ''} found',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build basic information section
  Widget _buildBasicInfoSection(ThemeData theme, VendorProfileEditState state) {
    return _buildFormSection(
      theme: theme,
      title: 'Basic Information',
      icon: Icons.business,
      children: [
        CustomTextField(
          controller: _businessNameController,
          focusNode: _businessNameFocus,
          label: 'Business Name *',
          hintText: 'Enter your business name',
          prefixIcon: Icons.store,
          textInputAction: TextInputAction.next,
          errorText: ref.watch(fieldErrorProvider('businessName')),
          onChanged: (value) {
            ref.read(vendorProfileEditProvider.notifier).updateBusinessName(value);
            // Real-time validation
            ref.read(vendorProfileEditProvider.notifier).validateField('businessName', value);
          },
          onSubmitted: (_) => _businessRegistrationFocus.requestFocus(),
          validator: (value) => ProfileValidators.validateFullName(value),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _businessRegistrationController,
          focusNode: _businessRegistrationFocus,
          label: 'Business Registration Number *',
          hintText: 'Enter your business registration number',
          prefixIcon: Icons.assignment,
          textInputAction: TextInputAction.next,
          errorText: ref.watch(fieldErrorProvider('businessRegistrationNumber')),
          onChanged: (value) {
            ref.read(vendorProfileEditProvider.notifier).updateBusinessRegistrationNumber(value);
            // Real-time validation
            ref.read(vendorProfileEditProvider.notifier).validateField('businessRegistrationNumber', value);
          },
          onSubmitted: (_) => _businessAddressFocus.requestFocus(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Business registration number is required';
            }
            if (value.length < 5) {
              return 'Registration number must be at least 5 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildBusinessTypeDropdown(theme, state),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _descriptionController,
          label: 'Business Description',
          hintText: 'Describe your business (optional)',
          prefixIcon: Icons.description,
          maxLines: 3,
          maxLength: 1000,
          errorText: ref.watch(fieldErrorProvider('description')),
          onChanged: (value) {
            ref.read(vendorProfileEditProvider.notifier).updateDescription(value);
            // Real-time validation
            ref.read(vendorProfileEditProvider.notifier).validateField('description', value);
          },
        ),
      ],
    );
  }

  /// Build cuisine types section
  Widget _buildCuisineTypesSection(ThemeData theme, VendorProfileEditState state) {
    return _buildFormSection(
      theme: theme,
      title: 'Cuisine Types',
      icon: Icons.restaurant_menu,
      children: [
        const CuisineTypesSelector(),
      ],
    );
  }

  /// Build image upload section
  Widget _buildImageUploadSection(ThemeData theme, VendorProfileEditState state) {
    debugPrint('📸 [VENDOR-EDIT-SCREEN] Building image upload section');
    debugPrint('📸 [VENDOR-EDIT-SCREEN] Current cover image: ${state.coverImageUrl}');
    debugPrint('📸 [VENDOR-EDIT-SCREEN] Current gallery images: ${state.galleryImages.length} images');

    return _buildFormSection(
      theme: theme,
      title: 'Images',
      icon: Icons.photo_library,
      children: [
        // Cover photo upload
        Text(
          'Cover Photo',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        VendorCoverPhotoUpload(
          currentImageUrl: state.coverImageUrl,
          onImageChanged: (imageUrl) {
            ref.read(vendorProfileEditProvider.notifier).updateCoverImageUrl(imageUrl);
          },
        ),

        const SizedBox(height: 24),

        // Gallery images upload
        Text(
          'Gallery Images',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photos of your restaurant, food, and ambiance',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        VendorGalleryUpload(
          currentImages: state.galleryImages,
          onImagesChanged: (images) {
            ref.read(vendorProfileEditProvider.notifier).updateGalleryImages(images);
          },
        ),
      ],
    );
  }

  /// Build contact information section
  Widget _buildContactInfoSection(ThemeData theme, VendorProfileEditState state) {
    return _buildFormSection(
      theme: theme,
      title: 'Contact Information',
      icon: Icons.contact_phone,
      children: [
        CustomTextField(
          controller: _businessAddressController,
          label: 'Business Address *',
          hintText: 'Enter your complete business address',
          prefixIcon: Icons.location_on,
          maxLines: 2,
          errorText: ref.watch(fieldErrorProvider('businessAddress')),
          onChanged: (value) {
            ref.read(vendorProfileEditProvider.notifier).updateBusinessAddress(value);
            // Real-time validation
            ref.read(vendorProfileEditProvider.notifier).validateField('businessAddress', value);
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Business address is required';
            }
            if (value.length < 10) {
              return 'Address must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Build business hours section
  Widget _buildBusinessHoursSection(ThemeData theme, VendorProfileEditState state) {
    return EnhancedBusinessHoursEditor(
      initialHours: state.businessHours,
      onChanged: (hours) {
        ref.read(vendorProfileEditProvider.notifier).updateBusinessHours(hours);
      },
      showQuickActions: true,
      showValidationErrors: true,
    );
  }

  /// Build pricing settings section
  Widget _buildPricingSettingsSection(ThemeData theme, VendorProfileEditState state) {
    debugPrint('💰 [VENDOR-EDIT-SCREEN] Building pricing settings section');
    debugPrint('💰 [VENDOR-EDIT-SCREEN] Min order: RM ${state.minimumOrderAmount}');
    debugPrint('💰 [VENDOR-EDIT-SCREEN] Delivery fee: RM ${state.deliveryFee}');
    debugPrint('💰 [VENDOR-EDIT-SCREEN] Free delivery: RM ${state.freeDeliveryThreshold}');

    return _buildFormSection(
      theme: theme,
      title: 'Pricing Settings',
      icon: Icons.attach_money,
      children: [
        const PricingSettingsSection(),
      ],
    );
  }

  /// Build business details section
  Widget _buildBusinessDetailsSection(ThemeData theme, VendorProfileEditState state) {
    return _buildFormSection(
      theme: theme,
      title: 'Business Details',
      icon: Icons.settings,
      children: [
        _buildHalalCertificationToggle(theme, state),
        if (state.isHalalCertified) ...[
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Halal Certification Number',
            hintText: 'Enter your halal certification number',
            prefixIcon: Icons.verified,
            onChanged: (value) {
              ref.read(vendorProfileEditProvider.notifier).updateHalalCertification(
                state.isHalalCertified,
                value,
              );
            },
          ),
        ],
      ],
    );
  }

  /// Build form section wrapper
  Widget _buildFormSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Build business type dropdown
  Widget _buildBusinessTypeDropdown(ThemeData theme, VendorProfileEditState state) {
    const businessTypes = [
      {'value': 'restaurant', 'label': 'Restaurant'},
      {'value': 'cafe', 'label': 'Cafe'},
      {'value': 'food_truck', 'label': 'Food Truck'},
      {'value': 'catering', 'label': 'Catering'},
      {'value': 'bakery', 'label': 'Bakery'},
      {'value': 'grocery', 'label': 'Grocery'},
      {'value': 'other', 'label': 'Other'},
    ];

    return DropdownButtonFormField<String>(
      value: state.businessType.isEmpty ? null : state.businessType,
      decoration: InputDecoration(
        labelText: 'Business Type *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        errorText: ref.watch(fieldErrorProvider('businessType')),
      ),
      hint: const Text('Select your business type'),
      items: businessTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type['value'],
          child: Text(type['label']!),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(vendorProfileEditProvider.notifier).updateBusinessType(value);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Business type is required';
        }
        return null;
      },
    );
  }

  /// Build halal certification toggle
  Widget _buildHalalCertificationToggle(ThemeData theme, VendorProfileEditState state) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: const Text('Halal Certified'),
        subtitle: const Text('Is your business halal certified?'),
        secondary: const Icon(Icons.verified),
        value: state.isHalalCertified,
        onChanged: (value) {
          ref.read(vendorProfileEditProvider.notifier).updateHalalCertification(
            value,
            value ? state.halalCertificationNumber : null,
          );
        },
      ),
    );
  }

  /// Handle back press with unsaved changes check
  void _handleBackPress(BuildContext context, bool isDirty) {
    DebugLogger.info('🔙 [VENDOR-EDIT-SCREEN] Back press detected', tag: 'VendorProfileEditScreen');
    DebugLogger.logObject('Back Press Context', {
      'isDirty': isDirty,
      'hasUnsavedChanges': ref.read(formIsDirtyProvider),
      'canSave': ref.read(canSaveFormProvider),
    });

    if (!isDirty) {
      DebugLogger.info('✅ [VENDOR-EDIT-SCREEN] No unsaved changes, navigating back', tag: 'VendorProfileEditScreen');
      context.pop();
      return;
    }

    final changedFieldsCount = ref.read(changedFieldsCountProvider);
    DebugLogger.info('⚠️ [VENDOR-EDIT-SCREEN] Unsaved changes detected, showing confirmation dialog', tag: 'VendorProfileEditScreen');
    DebugLogger.logObject('Unsaved Changes', {
      'changedFieldsCount': changedFieldsCount,
      'changesSummary': ref.read(changesSummaryProvider).keys.toList(),
    });

    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Unsaved Changes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have $changedFieldsCount unsaved change${changedFieldsCount > 1 ? 's' : ''}. What would you like to do?',
            ),
            const SizedBox(height: 16),
            Text(
              'Your changes will be lost if you leave without saving.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: Text(
              'Discard Changes',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save & Leave'),
          ),
        ],
      ),
    ).then((action) {
      switch (action) {
        case 'discard':
          ref.read(vendorProfileEditProvider.notifier).discardChanges();
          context.pop();
          break;
        case 'save':
          _handleSaveAndLeave();
          break;
        case 'cancel':
        default:
          // Do nothing, stay on the screen
          break;
      }
    });
  }

  /// Handle form reset
  void _handleReset() {
    final changedFieldsCount = ref.read(changedFieldsCountProvider);

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Reset Form'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reset all $changedFieldsCount change${changedFieldsCount > 1 ? 's' : ''}?',
            ),
            const SizedBox(height: 8),
            Text(
              'This will restore all fields to their original values. This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    ).then((shouldReset) {
      if (shouldReset == true) {
        ref.read(vendorProfileEditProvider.notifier).discardChanges();

        // Show confirmation snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.refresh, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Form reset to original values')),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  /// Show changes dialog
  void _showChangesDialog() {
    final changes = ref.read(changesSummaryProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note),
            SizedBox(width: 8),
            Text('Unsaved Changes'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The following fields have been modified:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: changes.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = changes.entries.elementAt(index);
                    final fieldName = _getFieldDisplayName(entry.key);
                    final change = entry.value as Map<String, dynamic>;

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.edit,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        fieldName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From: ${_formatValue(change['original'])}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            'To: ${_formatValue(change['current'])}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSave();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  /// Save and leave
  Future<void> _handleSaveAndLeave() async {
    final success = await _handleSaveInternal();
    if (success && mounted) {
      context.pop();
    }
  }

  /// Internal save method that returns success status
  Future<bool> _handleSaveInternal() async {
    // Clear any previous messages
    ref.read(vendorProfileEditProvider.notifier).clearErrors();

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Show validation error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Please fix validation errors before saving')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    // Check for validation errors from providers
    final hasErrors = ref.read(hasValidationErrorsProvider);
    if (hasErrors) {
      // Scroll to top to show error summary
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false;
    }

    return await ref.read(vendorProfileEditProvider.notifier).saveProfile();
  }

  /// Get display name for field
  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'businessName':
        return 'Business Name';
      case 'businessRegistrationNumber':
        return 'Registration Number';
      case 'businessAddress':
        return 'Business Address';
      case 'businessType':
        return 'Business Type';
      case 'cuisineTypes':
        return 'Cuisine Types';
      case 'description':
        return 'Description';
      case 'minimumOrderAmount':
        return 'Minimum Order Amount';
      case 'deliveryFee':
        return 'Delivery Fee';
      case 'freeDeliveryThreshold':
        return 'Free Delivery Threshold';
      default:
        return fieldName;
    }
  }

  /// Format value for display
  String _formatValue(dynamic value) {
    if (value == null) return 'Not set';
    if (value is String && value.isEmpty) return 'Empty';
    if (value is List) return value.join(', ');
    if (value is double) return 'RM ${value.toStringAsFixed(2)}';
    return value.toString();
  }

  /// Handle form save
  Future<void> _handleSave() async {
    DebugLogger.info('💾 [VENDOR-EDIT-SCREEN] Save button pressed', tag: 'VendorProfileEditScreen');
    DebugLogger.logObject('Save Context', {
      'canSave': ref.read(canSaveFormProvider),
      'isDirty': ref.read(formIsDirtyProvider),
      'errorCount': ref.read(errorCountProvider),
      'changedFieldsCount': ref.read(changedFieldsCountProvider),
    });

    final success = await _handleSaveInternal();

    DebugLogger.info('📊 [VENDOR-EDIT-SCREEN] Save operation completed', tag: 'VendorProfileEditScreen');
    DebugLogger.logObject('Save Result', {
      'success': success,
      'mounted': mounted,
    });

    if (mounted && success) {
      DebugLogger.info('✅ [VENDOR-EDIT-SCREEN] Save successful, showing success feedback', tag: 'VendorProfileEditScreen');

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Profile updated successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Auto-clear success message after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          DebugLogger.info('🧹 [VENDOR-EDIT-SCREEN] Auto-clearing success message', tag: 'VendorProfileEditScreen');
          ref.read(vendorProfileEditProvider.notifier).clearSuccessMessage();
        }
      });
    } else if (mounted && !success) {
      DebugLogger.warning('❌ [VENDOR-EDIT-SCREEN] Save failed, scrolling to show errors', tag: 'VendorProfileEditScreen');

      // Error handling is now done in the provider with better error messages
      // Scroll to top to show error summary
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

/// Intent classes for keyboard shortcuts
class SaveIntent extends Intent {
  const SaveIntent();
}

class ResetIntent extends Intent {
  const ResetIntent();
}
