import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/enhanced_error_handling_provider.dart';
import '../providers/enhanced_cart_provider.dart';
import '../providers/enhanced_checkout_flow_provider.dart';
import '../providers/enhanced_payment_provider.dart';
import '../widgets/enhanced_validation_widgets.dart';
import '../../data/services/comprehensive_validation_service.dart';

import '../../data/models/customer_delivery_method.dart';
import '../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';

/// Enhanced validation demonstration screen
class EnhancedValidationDemoScreen extends ConsumerStatefulWidget {
  const EnhancedValidationDemoScreen({super.key});

  @override
  ConsumerState<EnhancedValidationDemoScreen> createState() => _EnhancedValidationDemoScreenState();
}

class _EnhancedValidationDemoScreenState extends ConsumerState<EnhancedValidationDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _promoCodeController = TextEditingController();
  
  final AppLogger _logger = AppLogger();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFormValid = ref.watch(isFormValidProvider);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: EnhancedFormValidation(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 24),
                  _buildValidationDemoSection(theme),
                  const SizedBox(height: 24),
                  _buildFormFields(theme),
                  const SizedBox(height: 24),
                  _buildValidationActions(theme, isFormValid),
                  const SizedBox(height: 24),
                  _buildValidationResults(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'Validation Demo',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.arrow_back,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _clearAllValidation,
          icon: Icon(
            Icons.clear_all,
            color: theme.colorScheme.onSurface,
          ),
          tooltip: 'Clear All',
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comprehensive Validation System',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This screen demonstrates the enhanced validation and error handling system with real-time feedback.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildValidationDemoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Validation Features',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(theme, 'Real-time field validation'),
          _buildFeatureItem(theme, 'Global error and warning display'),
          _buildFeatureItem(theme, 'Form validation status'),
          _buildFeatureItem(theme, 'Cart and checkout workflow validation'),
          _buildFeatureItem(theme, 'Payment method validation'),
          _buildFeatureItem(theme, 'Business rules validation'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Form Validation Demo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        EnhancedValidatedTextField(
          fieldName: 'email',
          controller: _emailController,
          label: 'Email Address',
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!Validators.isValidEmail(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        EnhancedValidatedTextField(
          fieldName: 'phone',
          controller: _phoneController,
          label: 'Phone Number',
          hintText: 'Enter your phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            if (!Validators.isValidPhoneNumber(value)) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        EnhancedValidatedTextField(
          fieldName: 'address',
          controller: _addressController,
          label: 'Delivery Address',
          hintText: 'Enter your delivery address',
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Delivery address is required';
            }
            if (value.length < 10) {
              return 'Please enter a complete address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        EnhancedValidatedTextField(
          fieldName: 'instructions',
          controller: _instructionsController,
          label: 'Special Instructions (Optional)',
          hintText: 'Any special delivery instructions',
          prefixIcon: Icons.note_outlined,
          maxLines: 3,
          maxLength: 500,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return Validators.validateAndSanitizeText(
                value,
                maxLength: 500,
                allowEmpty: true,
              );
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        EnhancedValidatedTextField(
          fieldName: 'promo_code',
          controller: _promoCodeController,
          label: 'Promo Code (Optional)',
          hintText: 'Enter promo code',
          prefixIcon: Icons.local_offer_outlined,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length < 3 || value.length > 20) {
                return 'Promo code must be between 3 and 20 characters';
              }
              if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.toUpperCase())) {
                return 'Promo code can only contain letters and numbers';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildValidationActions(ThemeData theme, bool isFormValid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validation Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Add Test Errors',
                onPressed: _addTestErrors,
                variant: ButtonVariant.outlined,
                icon: Icons.error_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Add Test Warnings',
                onPressed: _addTestWarnings,
                variant: ButtonVariant.outlined,
                icon: Icons.warning_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Validate Workflow',
                onPressed: _isValidating ? null : _validateWorkflow,
                variant: ButtonVariant.primary,
                icon: Icons.check_circle_outline,
                isLoading: _isValidating,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Clear All',
                onPressed: _clearAllValidation,
                variant: ButtonVariant.outlined,
                icon: Icons.clear_all,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValidationResults(ThemeData theme) {
    final errorSummary = ref.watch(errorSummaryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validation Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(theme, 'Total Errors', errorSummary.totalErrors.toString(), 
                           errorSummary.totalErrors > 0 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
          _buildSummaryItem(theme, 'Total Warnings', errorSummary.totalWarnings.toString(),
                           errorSummary.totalWarnings > 0 ? Colors.orange : theme.colorScheme.onSurfaceVariant),
          _buildSummaryItem(theme, 'Has Field Errors', errorSummary.hasFieldErrors ? 'Yes' : 'No',
                           errorSummary.hasFieldErrors ? theme.colorScheme.error : theme.colorScheme.tertiary),
          _buildSummaryItem(theme, 'Has Global Errors', errorSummary.hasGlobalErrors ? 'Yes' : 'No',
                           errorSummary.hasGlobalErrors ? theme.colorScheme.error : theme.colorScheme.tertiary),
          _buildSummaryItem(theme, 'Form Valid', ref.watch(isFormValidProvider) ? 'Yes' : 'No',
                           ref.watch(isFormValidProvider) ? theme.colorScheme.tertiary : theme.colorScheme.error),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(ThemeData theme, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _addTestErrors() {
    _logger.info('🧪 [VALIDATION-DEMO] Adding test errors');

    final errorHandler = ref.read(enhancedErrorHandlingProvider.notifier);
    
    errorHandler.addGlobalError('This is a test global error');
    errorHandler.addGlobalError('Another test error for demonstration');
    errorHandler.addFieldError('test_field', 'This is a test field error');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test errors added')),
    );
  }

  void _addTestWarnings() {
    _logger.info('🧪 [VALIDATION-DEMO] Adding test warnings');

    final errorHandler = ref.read(enhancedErrorHandlingProvider.notifier);
    
    errorHandler.addWarning('This is a test warning');
    errorHandler.addWarning('Another test warning for demonstration');
    errorHandler.setRecommendations([
      'Consider reviewing your input',
      'Check for any missing information',
    ]);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test warnings added')),
    );
  }

  Future<void> _validateWorkflow() async {
    setState(() {
      _isValidating = true;
    });

    try {
      _logger.info('🔍 [VALIDATION-DEMO] Starting workflow validation');

      final cartState = ref.read(enhancedCartProvider);
      final checkoutState = ref.read(enhancedCheckoutFlowProvider);

      final validationService = ComprehensiveValidationService();

      final result = await validationService.validateCompleteWorkflow(
        cartState: cartState,
        deliveryMethod: checkoutState.selectedDeliveryMethod ?? CustomerDeliveryMethod.customerPickup,
        deliveryAddress: checkoutState.selectedAddress,
        scheduledDeliveryTime: checkoutState.scheduledDeliveryTime,
        paymentMethod: PaymentMethodType.card,
        specialInstructions: _instructionsController.text,
        promoCode: _promoCodeController.text,
      );

      ref.read(enhancedErrorHandlingProvider.notifier).handleValidationResult(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isValid ? 'Workflow validation passed!' : 'Workflow validation failed'),
          backgroundColor: result.isValid ? Colors.green : Colors.red,
        ),
      );

    } catch (e) {
      _logger.error('❌ [VALIDATION-DEMO] Workflow validation failed', e);
      
      ref.read(enhancedErrorHandlingProvider.notifier).handleException(e);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validation failed with error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _clearAllValidation() {
    _logger.info('🧹 [VALIDATION-DEMO] Clearing all validation');

    ref.read(enhancedErrorHandlingProvider.notifier).clearAll();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All validation cleared')),
    );
  }
}
