import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/enhanced_delivery_method_picker.dart';
import '../providers/enhanced_cart_provider.dart';
import '../../data/models/customer_delivery_method.dart';
import '../../data/services/delivery_method_service.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// Screen for selecting delivery method during checkout
class DeliveryMethodSelectionScreen extends ConsumerStatefulWidget {
  final String? vendorId;
  final double? subtotal;
  final CustomerAddress? deliveryAddress;

  const DeliveryMethodSelectionScreen({
    super.key,
    this.vendorId,
    this.subtotal,
    this.deliveryAddress,
  });

  @override
  ConsumerState<DeliveryMethodSelectionScreen> createState() => _DeliveryMethodSelectionScreenState();
}

class _DeliveryMethodSelectionScreenState extends ConsumerState<DeliveryMethodSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  CustomerDeliveryMethod _selectedMethod = CustomerDeliveryMethod.customerPickup;
  DeliveryMethodRecommendation? _recommendation;
  bool _isLoadingRecommendations = false;
  final AppLogger _logger = AppLogger();

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
    
    _loadRecommendations();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = ref.watch(enhancedCartProvider);

    // Use cart data if parameters not provided
    final vendorId = widget.vendorId ?? cartState.primaryVendorId ?? '';
    final subtotal = widget.subtotal ?? cartState.subtotal;
    final deliveryAddress = widget.deliveryAddress ?? cartState.selectedAddress;

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 24),
                        if (_recommendation != null && _recommendation!.hasRecommendation) ...[
                          _buildRecommendationCard(theme),
                          const SizedBox(height: 24),
                        ],
                        EnhancedDeliveryMethodPicker(
                          selectedMethod: _selectedMethod,
                          onMethodChanged: _onMethodChanged,
                          vendorId: vendorId,
                          subtotal: subtotal,
                          deliveryAddress: deliveryAddress,
                          showEstimatedTime: true,
                          showFeatureComparison: true,
                        ),
                        const SizedBox(height: 24),
                        _buildMethodDetails(theme),
                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom continue button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildContinueButton(theme),
            ),
            
            // Loading overlay
            if (_isLoadingRecommendations)
              const SimpleLoadingOverlay(message: 'Getting recommendations...'),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'Delivery Method',
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
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to receive your order?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the delivery method that works best for you. Fees and delivery times may vary.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(ThemeData theme) {
    final recommendation = _recommendation!;
    
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
                Icons.recommend,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended for You',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.recommended!.displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.reasons.join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (recommendation.recommended != _selectedMethod) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _onMethodChanged(recommendation.recommended!),
              child: Text(
                'Use Recommended',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodDetails(ThemeData theme) {
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
            'About ${_selectedMethod.displayName}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getMethodDetailedDescription(_selectedMethod),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildMethodFeatures(theme),
        ],
      ),
    );
  }

  Widget _buildMethodFeatures(ThemeData theme) {
    final features = _getMethodFeatures(_selectedMethod);
    
    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                feature,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildContinueButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: 'Continue with ${_selectedMethod.displayName}',
          onPressed: () => _continueWithMethod(),
          variant: ButtonVariant.primary,
          icon: Icons.arrow_forward,
        ),
      ),
    );
  }

  String _getMethodDetailedDescription(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.customerPickup:
        return 'You\'ll pick up your order directly from the restaurant. This is the fastest option with no delivery fees. You\'ll receive a notification when your order is ready for pickup.';
      
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'Our sales agent will collect your order from the restaurant and deliver it to you personally. This option includes direct communication and flexible timing arrangements.';
      
      case CustomerDeliveryMethod.ownFleet:
        return 'Your order will be delivered by our professional delivery team. Enjoy real-time tracking, reliable service, and contactless delivery options.';
      
      case CustomerDeliveryMethod.thirdParty:
        return 'Your order will be delivered by our trusted third-party delivery partners. This option provides wide coverage and fast delivery times.';
      
      default:
        return method.description;
    }
  }

  List<String> _getMethodFeatures(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.customerPickup:
        return [
          'No delivery fee',
          'Fastest preparation time',
          'Direct interaction with restaurant',
          'Flexible pickup timing',
        ];
      
      case CustomerDeliveryMethod.salesAgentPickup:
        return [
          'Personal service',
          'Direct communication',
          'Flexible delivery timing',
          'Order verification at pickup',
        ];
      
      case CustomerDeliveryMethod.ownFleet:
        return [
          'Real-time order tracking',
          'Professional delivery team',
          'Contactless delivery option',
          'Reliable delivery times',
          'Customer support available',
        ];
      
      case CustomerDeliveryMethod.thirdParty:
        return [
          'Wide delivery coverage',
          'Fast delivery times',
          'Multiple delivery options',
          'Experienced delivery partners',
        ];
      
      default:
        return [];
    }
  }

  void _onMethodChanged(CustomerDeliveryMethod method) {
    _logger.info('🚚 [DELIVERY-SELECTION] Method changed to: ${method.value}');
    
    setState(() {
      _selectedMethod = method;
    });
  }

  void _continueWithMethod() {
    _logger.info('✅ [DELIVERY-SELECTION] Continuing with method: ${_selectedMethod.value}');
    
    // Update cart with selected delivery method
    ref.read(enhancedCartProvider.notifier).setDeliveryMethod(_selectedMethod);
    
    // Navigate to next step in checkout
    context.push('/customer/checkout/address');
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final cartState = ref.read(enhancedCartProvider);
      final vendorId = widget.vendorId ?? cartState.primaryVendorId;
      final subtotal = widget.subtotal ?? cartState.subtotal;
      final deliveryAddress = widget.deliveryAddress ?? cartState.selectedAddress;

      if (vendorId == null) {
        _logger.warning('No vendor ID available for recommendations');
        return;
      }

      final deliveryMethodService = DeliveryMethodService();
      final recommendation = await deliveryMethodService.getMethodRecommendations(
        vendorId: vendorId,
        orderAmount: subtotal,
        deliveryAddress: deliveryAddress,
      );

      if (mounted) {
        setState(() {
          _recommendation = recommendation;
          if (recommendation.hasRecommendation) {
            _selectedMethod = recommendation.recommended!;
          }
        });
      }

      _logger.info('✅ [DELIVERY-SELECTION] Recommendations loaded');
    } catch (e) {
      _logger.error('❌ [DELIVERY-SELECTION] Failed to load recommendations', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }
}
