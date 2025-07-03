import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:go_router/go_router.dart';

import '../providers/customer_payment_methods_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/card_field_manager.dart';

/// Screen for adding a new payment method
class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends ConsumerState<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final AppLogger _logger = AppLogger();
  final CardFieldManager _cardFieldManager = CardFieldManager();

  bool _isCardComplete = false;
  bool _isLoading = false;
  String? _errorMessage;

  // CardField lifecycle management
  bool _cardFieldMounted = false;
  static const String _screenId = 'add_payment_method_screen';

  @override
  void initState() {
    super.initState();
    // Request CardField permission from global manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCardFieldPermission();
    });
  }

  /// Request permission to use CardField from global manager
  void _requestCardFieldPermission() {
    if (!mounted) return;

    // Use the new cleanup mechanism to handle navigation conflicts
    final hasPermission = _cardFieldManager.requestCardFieldPermissionWithCleanup(_screenId);
    if (hasPermission) {
      // Register cleanup callback
      _cardFieldManager.registerCleanupCallback(_screenId, () {
        if (mounted) {
          setState(() {
            _cardFieldMounted = false;
          });
        }
      });

      // Initialize CardField
      setState(() {
        _cardFieldMounted = true;
      });
      _logger.debug('✅ [ADD-PAYMENT-METHOD] CardField initialized and mounted with cleanup');
    } else {
      _logger.warning('❌ [ADD-PAYMENT-METHOD] CardField permission denied - unexpected error');
      // This should rarely happen with the cleanup mechanism
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to initialize payment form. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _logger.debug('🔧 [ADD-PAYMENT-METHOD] Disposing screen and cleaning up CardField');

    // Release CardField permission from global manager
    _cardFieldManager.releaseCardFieldPermission(_screenId);

    // Mark CardField as unmounted to prevent platform view conflicts
    _cardFieldMounted = false;

    // Dispose controllers
    _nicknameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Method'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Add a New Payment Method',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment information is securely encrypted and stored by Stripe.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Card information section
              _buildCardSection(theme),
              
              const SizedBox(height: 24),
              
              // Nickname section
              _buildNicknameSection(theme),
              
              const SizedBox(height: 32),
              
              // Security info
              _buildSecurityInfo(theme),
              
              const SizedBox(height: 40),
              
              // Add button
              _buildAddButton(theme),
              
              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(theme),
              ],
              
              // Loading indicator
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: _cardFieldMounted
            ? stripe.CardField(
                onCardChanged: (card) {
                  if (!mounted) return; // Prevent setState after disposal
                  setState(() {
                    _isCardComplete = card?.complete ?? false;
                    _errorMessage = null;
                  });
                },
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Container(
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Loading payment form...'),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildNicknameSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nickname (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Give your payment method a memorable name',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: 'e.g., Primary Card, Work Card, Personal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          maxLength: 50,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildSecurityInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & Encrypted',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your card details are encrypted and securely stored by Stripe. We never store your full card number.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || !_isCardComplete ? null : _addPaymentMethod,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Add Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPaymentMethod() async {
    if (!_formKey.currentState!.validate() || !_isCardComplete) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _logger.info('🔍 [ADD-PAYMENT-METHOD] Creating Stripe payment method...');

      // Create payment method with Stripe
      final paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
        params: const stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(),
        ),
      );

      final stripePaymentMethodId = paymentMethod.id;
      final nickname = _nicknameController.text.trim().isEmpty 
          ? null 
          : _nicknameController.text.trim();

      _logger.info('✅ [ADD-PAYMENT-METHOD] Stripe payment method created: $stripePaymentMethodId');

      // Add payment method via provider
      await ref
          .read(customerPaymentMethodsProvider.notifier)
          .addPaymentMethod(
            stripePaymentMethodId: stripePaymentMethodId,
            nickname: nickname,
          );

      _logger.info('✅ [ADD-PAYMENT-METHOD] Payment method added successfully');

      // Navigate back
      if (mounted) {
        context.pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment method added successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.error('❌ [ADD-PAYMENT-METHOD] Failed to add payment method', e, stackTrace);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('card_declined')) {
      return 'Your card was declined. Please try a different card.';
    } else if (errorString.contains('expired_card')) {
      return 'Your card has expired. Please use a different card.';
    } else if (errorString.contains('incorrect_cvc')) {
      return 'The security code is incorrect. Please check and try again.';
    } else if (errorString.contains('processing_error')) {
      return 'There was an error processing your card. Please try again.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else {
      return 'Failed to add payment method. Please try again.';
    }
  }
}
