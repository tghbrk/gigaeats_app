import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models/order.dart' hide PaymentMethod, PaymentStatus;
import '../../data/models/payment_method.dart';
import '../../data/services/payment_service.dart';
import '../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';

// Provider for payment service
final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());

// Provider for available payment methods
final availablePaymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final paymentService = ref.read(paymentServiceProvider);
  return await paymentService.getAvailablePaymentMethods();
});

class PaymentScreen extends ConsumerStatefulWidget {
  final Order order;

  const PaymentScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod? _selectedPaymentMethod;
  String? _selectedBankCode;
  stripe.CardFieldInputDetails? _cardDetails;
  bool _isProcessing = false;
  String? _errorMessage;

  // CardField lifecycle management
  bool _cardFieldMounted = false;

  @override
  void initState() {
    super.initState();
    // Initialize CardField after a brief delay to ensure proper platform view setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _cardFieldMounted = true;
        });
        debugPrint('✅ [PAYMENT-SCREEN] CardField initialized and mounted');
      }
    });
  }

  @override
  void dispose() {
    debugPrint('🔧 [PAYMENT-SCREEN] Disposing screen and cleaning up CardField');

    // Mark CardField as unmounted to prevent platform view conflicts
    _cardFieldMounted = false;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(availablePaymentMethodsProvider);

    // Debug: Log when payment screen is built
    debugPrint('PaymentScreen: Building payment screen for order ${widget.order.id}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Return false to indicate payment was not completed
            Navigator.of(context).pop(false);
          },
        ),
      ),
      body: Column(
        children: [
          // Order Summary Card
          _buildOrderSummaryCard(),
          
          // Payment Methods
          Expanded(
            child: paymentMethodsAsync.when(
              data: (paymentMethods) => _buildPaymentMethodsList(paymentMethods),
              loading: () => const LoadingWidget(message: 'Loading payment methods...'),
              error: (error, stack) => CustomErrorWidget(
                message: 'Failed to load payment methods: $error',
                onRetry: () => ref.refresh(availablePaymentMethodsProvider),
              ),
            ),
          ),
          
          // Error Message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          
          // Pay Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: GEButton.primary(
              text: _isProcessing ? 'Processing...' : 'Pay RM ${widget.order.totalAmount.toStringAsFixed(2)}',
              onPressed: _selectedPaymentMethod != null && !_isProcessing
                  ? _processPayment
                  : null,
              isLoading: _isProcessing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.order.orderNumber,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('RM ${widget.order.subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SST (6%)'),
                Text('RM ${widget.order.sstAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee'),
                Text('RM ${widget.order.deliveryFee.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM ${widget.order.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(List<PaymentMethod> paymentMethods) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...paymentMethods.map((method) => _buildPaymentMethodCard(method)),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectPaymentMethod(method),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppConstants.primaryColor, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Payment method icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: method.iconUrl != null
                        ? Image.network(
                            method.iconUrl!,
                            errorBuilder: (context, error, stackTrace) =>
                                _getPaymentMethodIcon(method.type),
                          )
                        : _getPaymentMethodIcon(method.type),
                  ),
                  const SizedBox(width: 16),
                  
                  // Payment method details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (method.description != null)
                          Text(
                            method.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        if (method.processingFee != null)
                          Text(
                            'Processing fee: ${(method.processingFee! * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Selection indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppConstants.primaryColor,
                      size: 24,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                ],
              ),
              
              // Bank selection for FPX
              if (isSelected && method.type == PaymentMethodType.fpx)
                _buildBankSelection(),

              // Card field for credit card payments
              if (isSelected && method.type == PaymentMethodType.creditCard)
                _buildCardField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankSelection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select your bank:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FPXBankCodes.getAllBanks().map((bank) {
            final isSelected = _selectedBankCode == bank.key;
            return FilterChip(
              label: Text(bank.value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedBankCode = selected ? bank.key : null;
                });
              },
              selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppConstants.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCardField() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Enter your card details:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _cardFieldMounted
            ? stripe.CardField(
                onCardChanged: (details) {
                  if (!mounted) return; // Prevent setState after disposal
                  setState(() {
                    _cardDetails = details;
                    // Clear any previous error when user starts typing
                    if (_errorMessage != null) {
                      _errorMessage = null;
                    }
                  });
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Card number',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                enablePostalCode: false, // Disable postal code for Malaysian cards
              )
            : Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Loading payment form...'),
                ),
              ),
        ),
        if (_cardDetails != null && !_cardDetails!.complete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please enter complete card details',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _getPaymentMethodIcon(PaymentMethodType type) {
    IconData iconData;
    Color color;
    
    switch (type) {
      case PaymentMethodType.fpx:
        iconData = Icons.account_balance;
        color = Colors.blue;
        break;
      case PaymentMethodType.creditCard:
        iconData = Icons.credit_card;
        color = Colors.green;
        break;
      case PaymentMethodType.grabPay:
        iconData = Icons.wallet;
        color = Colors.green;
        break;
      case PaymentMethodType.touchNGo:
        iconData = Icons.contactless;
        color = Colors.blue;
        break;
      case PaymentMethodType.boost:
        iconData = Icons.rocket_launch;
        color = Colors.orange;
        break;
      case PaymentMethodType.shopeePay:
        iconData = Icons.shopping_bag;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.payment;
        color = Colors.grey;
    }
    
    return Icon(iconData, color: color, size: 24);
  }

  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
      _selectedBankCode = null; // Reset bank selection
      _cardDetails = null; // Reset card details
      _errorMessage = null;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) return;

    debugPrint('PaymentScreen: Starting payment processing for ${_selectedPaymentMethod!.type}');

    // Validate FPX bank selection
    if (_selectedPaymentMethod!.type == PaymentMethodType.fpx && _selectedBankCode == null) {
      setState(() {
        _errorMessage = 'Please select your bank for FPX payment';
      });
      return;
    }

    // Validate credit card details
    if (_selectedPaymentMethod!.type == PaymentMethodType.creditCard &&
        (_cardDetails == null || !_cardDetails!.complete)) {
      setState(() {
        _errorMessage = 'Please enter complete card details';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    debugPrint('PaymentScreen: Payment validation passed, processing payment...');

    try {
      final paymentService = ref.read(paymentServiceProvider);
      PaymentResult result;

      switch (_selectedPaymentMethod!.type) {
        case PaymentMethodType.fpx:
          result = await paymentService.processFPXPayment(
            order: widget.order,
            bankCode: _selectedBankCode!,
            callbackUrl: 'https://your-app.com/payment/callback',
            redirectUrl: 'https://your-app.com/payment/success',
          );
          break;
          
        case PaymentMethodType.creditCard:
          debugPrint('PaymentScreen: Processing credit card payment');

          // Validate card details
          if (_cardDetails == null || !_cardDetails!.complete) {
            debugPrint('PaymentScreen: Card details incomplete');
            setState(() {
              _errorMessage = 'Please enter complete card details.';
            });
            return;
          }

          debugPrint('PaymentScreen: Card details valid, creating payment intent...');

          // Create Payment Intent
          final paymentIntentData = await paymentService.createPaymentIntent(
            orderId: widget.order.id,
            amount: widget.order.totalAmount,
          );

          debugPrint('PaymentScreen: Payment intent created: ${paymentIntentData.keys}');

          final clientSecret = paymentIntentData['client_secret'];
          if (clientSecret == null) {
            throw Exception('Failed to get payment client secret.');
          }

          debugPrint('PaymentScreen: Confirming payment with Stripe...');
          debugPrint('PaymentScreen: Client secret: ${clientSecret.substring(0, 20)}...');

          // Check if this is a mock payment for testing
          final isMockPayment = paymentIntentData['metadata']?['mock'] == true;

          if (isMockPayment) {
            debugPrint('PaymentScreen: Processing mock payment for testing');
            // Simulate payment processing delay
            await Future.delayed(const Duration(seconds: 2));
            debugPrint('PaymentScreen: Mock payment completed successfully');
          } else {
            // Confirm the payment with Stripe using the actual card details
            debugPrint('PaymentScreen: About to confirm payment with Stripe...');

            try {
              final paymentMethod = stripe.PaymentMethodParams.card(
                paymentMethodData: stripe.PaymentMethodData(
                  billingDetails: stripe.BillingDetails(
                    email: null, // You can add customer email here if available
                  ),
                ),
              );

              debugPrint('PaymentScreen: Calling Stripe.instance.confirmPayment...');
              final result = await stripe.Stripe.instance.confirmPayment(
                paymentIntentClientSecret: clientSecret,
                data: paymentMethod,
              );

              debugPrint('PaymentScreen: Stripe confirmPayment result: $result');
              debugPrint('PaymentScreen: Stripe payment confirmed successfully');
            } catch (stripeError) {
              debugPrint('PaymentScreen: Stripe confirmPayment error: $stripeError');
              debugPrint('PaymentScreen: Stripe error type: ${stripeError.runtimeType}');
              rethrow; // Re-throw to be caught by outer try-catch
            }
          }

          // If we reach here, payment was successful
          result = PaymentResult.success(
            transactionId: paymentIntentData['transaction_id'] ?? 'stripe_success',
            metadata: {
              'payment_method': 'credit_card',
              'client_secret': clientSecret,
            },
          );
          break;
          
        case PaymentMethodType.grabPay:
        case PaymentMethodType.touchNGo:
        case PaymentMethodType.boost:
        case PaymentMethodType.shopeePay:
          result = await paymentService.processEWalletPayment(
            order: widget.order,
            walletType: _selectedPaymentMethod!.type,
            callbackUrl: 'https://your-app.com/payment/callback',
            redirectUrl: 'https://your-app.com/payment/success',
          );
          break;
          
        default:
          throw Exception('Unsupported payment method');
      }

      if (result.success) {
        // Payment successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Return success to the calling screen
          Navigator.of(context).pop(true);
        }
      } else if (result.status == PaymentStatus.pending) {
        // Redirect to payment gateway
        final billUrl = result.metadata?['bill_url'];
        if (billUrl != null && mounted) {
          context.go('/payment/gateway?url=${Uri.encodeComponent(billUrl)}');
        }
      } else {
        // Payment failed
        setState(() {
          _errorMessage = result.errorMessage ?? 'Payment failed. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('PaymentScreen: Payment processing error: $e');
      debugPrint('PaymentScreen: Error type: ${e.runtimeType}');
      debugPrint('PaymentScreen: Error details: ${e.toString()}');

      setState(() {
        _errorMessage = 'Payment error: $e';
      });

      // Show error message and allow user to retry or go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Go Back',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
