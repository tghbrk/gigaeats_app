import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/order_status_history.dart';
import '../models/order_notification.dart';
import '../models/delivery_method.dart';
import '../utils/order_validation_utils.dart';
import '../../../../core/utils/debug_logger.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  OrderRepository();

  /// Get orders for the current user based on their role
  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    debugPrint('🔍 [ANDROID-DEBUG] ===== getOrders method ENTRY POINT =====');
    debugPrint('🔍 [ANDROID-DEBUG] getOrders called with status: $status, limit: $limit, offset: $offset');
    debugPrint('🔍 [ANDROID-DEBUG] About to call executeQuery...');

    try {
      final result = await executeQuery(() async {
      debugPrint('🔍 [ANDROID-DEBUG] Inside executeQuery, getting current user...');
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');
      debugPrint('🔍 [ANDROID-DEBUG] Current user: ${currentUser['role']} (${currentUser['id']})');

      debugPrint('🔍 [ANDROID-DEBUG] Building query with order_items join...');
      // Include order_items to fix "0 item(s)" display issue
      final authenticatedClient = await getAuthenticatedClient();
      var query = authenticatedClient.from('orders').select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(business_name),
            customer:customers!orders_customer_id_fkey(organization_name),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''');

      // Apply role-based filtering
      switch (currentUser['role']) {
        case 'sales_agent':
          query = query.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          // Get vendor ID for this user
          final vendorResponse = await supabase
              .from('vendors')
              .select('id')
              .eq('user_id', currentUserId!)
              .single();
          query = query.eq('vendor_id', vendorResponse['id']);
          break;
        case 'admin':
          // Admins can see all orders
          break;
        default:
          throw Exception('Invalid user role for order access');
      }

      // Apply filters
      if (status != null) {
        query = query.eq('status', status.value);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // Apply ordering and pagination and execute query
      debugPrint('🔍 [ANDROID-DEBUG] About to execute query with ordering and pagination...');
      debugPrint('🔍 [ANDROID-DEBUG] Query limit: $limit, offset: $offset');
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      debugPrint('🔍 [ANDROID-DEBUG] Query executed successfully, got ${response.length} results');

      // Debug: Log the first order's data structure if available
      if (response.isNotEmpty) {
        debugPrint('🔍 [ANDROID-DEBUG] First order raw data: ${response.first}');
        debugPrint('🔍 [ANDROID-DEBUG] delivery_address type in raw data: ${response.first['delivery_address'].runtimeType}');
        debugPrint('🔍 [ANDROID-DEBUG] delivery_address value in raw data: ${response.first['delivery_address']}');
      }

      // Process the response to handle JSON fields and joined data properly
      return response.map((json) {
        try {
          final orderData = Map<String, dynamic>.from(json);

          // ANDROID DEBUG: Log the exact data types we're receiving
          debugPrint('🔍 [ANDROID-DEBUG] Processing order data...');
          debugPrint('🔍 [ANDROID-DEBUG] Order ID: ${orderData['id']}');
          debugPrint('🔍 [ANDROID-DEBUG] delivery_address type: ${orderData['delivery_address'].runtimeType}');
          debugPrint('🔍 [ANDROID-DEBUG] delivery_address value: ${orderData['delivery_address']}');

          // Extract vendor name from joined data
          if (orderData['vendor'] != null && orderData['vendor'] is Map) {
            final vendorData = orderData['vendor'] as Map<String, dynamic>;
            orderData['vendor_name'] = vendorData['business_name']?.toString() ?? 'Unknown Vendor';
          } else {
            orderData['vendor_name'] = 'Unknown Vendor';
          }

          // Extract customer name from joined data
          if (orderData['customer'] != null && orderData['customer'] is Map) {
            final customerData = orderData['customer'] as Map<String, dynamic>;
            orderData['customer_name'] = customerData['organization_name']?.toString() ?? 'Unknown Customer';
          } else {
            orderData['customer_name'] = 'Unknown Customer';
          }

          // Ensure order_items is not null
          if (orderData['order_items'] == null) {
            orderData['order_items'] = [];
          }

          // Remove the nested objects to avoid conflicts
          orderData.remove('vendor');
          orderData.remove('customer');

          if (orderData['metadata'] != null) {
            debugPrint('🔍 [ANDROID-DEBUG] metadata type: ${orderData['metadata'].runtimeType}');
            debugPrint('🔍 [ANDROID-DEBUG] metadata value: ${orderData['metadata']}');
          }

          // Handle delivery_address field - convert from JSON string to Map if needed
          if (orderData['delivery_address'] is String) {
            try {
              debugPrint('🔍 [ANDROID-DEBUG] Converting delivery_address from String to Map');
              orderData['delivery_address'] = jsonDecode(orderData['delivery_address']);
              debugPrint('🔍 [ANDROID-DEBUG] Conversion successful');
            } catch (e) {
              debugPrint('🔍 [ANDROID-DEBUG] Error parsing delivery_address JSON: $e');
              // Provide a default address if parsing fails
              orderData['delivery_address'] = {
                'street': 'Unknown',
                'city': 'Unknown',
                'state': 'Unknown',
                'postal_code': '00000',
                'country': 'Malaysia',
              };
            }
          } else if (orderData['delivery_address'] == null) {
            debugPrint('🔍 [ANDROID-DEBUG] delivery_address is null, providing default');
            orderData['delivery_address'] = {
              'street': 'Unknown',
              'city': 'Unknown',
              'state': 'Unknown',
              'postal_code': '00000',
              'country': 'Malaysia',
            };
          } else {
            debugPrint('🔍 [ANDROID-DEBUG] delivery_address is already a Map: ${orderData['delivery_address'].runtimeType}');
          }

          // Handle address field inconsistencies - normalize postcode/postal_code
          if (orderData['delivery_address'] is Map<String, dynamic>) {
            final addressMap = orderData['delivery_address'] as Map<String, dynamic>;

            // Handle postcode vs postal_code field inconsistency
            if (addressMap.containsKey('postcode') && !addressMap.containsKey('postal_code')) {
              debugPrint('🔍 [ANDROID-DEBUG] Converting postcode to postal_code for address normalization');
              addressMap['postal_code'] = addressMap['postcode'];
              addressMap.remove('postcode');
            }

            // Ensure required address fields are not null (set defaults if needed)
            addressMap['country'] ??= 'Malaysia';
            addressMap['postal_code'] ??= '00000';

            debugPrint('🔍 [ANDROID-DEBUG] Address normalized: ${addressMap.keys.toList()}');
          }

          // Handle metadata field - convert from JSON string to Map if needed
          if (orderData['metadata'] is String) {
            try {
              debugPrint('🔍 [ANDROID-DEBUG] Converting metadata from String to Map');
              orderData['metadata'] = jsonDecode(orderData['metadata']);
            } catch (e) {
              debugPrint('🔍 [ANDROID-DEBUG] Error parsing metadata JSON: $e');
              orderData['metadata'] = null;
            }
          }

          debugPrint('🔍 [ANDROID-DEBUG] ===== PAYMENT FIELDS NOW HANDLED DIRECTLY =====');
          debugPrint('🔍 [ANDROID-DEBUG] Order ID: ${orderData['id']}');
          debugPrint('🔍 [ANDROID-DEBUG] Payment method: ${orderData['payment_method']}');
          debugPrint('🔍 [ANDROID-DEBUG] Payment status: ${orderData['payment_status']}');
          debugPrint('🔍 [ANDROID-DEBUG] Payment reference: ${orderData['payment_reference']}');

          debugPrint('🔍 [ANDROID-DEBUG] About to call Order.fromJson...');
          return Order.fromJson(orderData);
        } catch (e, stackTrace) {
          debugPrint('🔍 [ANDROID-DEBUG] ERROR in order processing: $e');
          debugPrint('🔍 [ANDROID-DEBUG] Stack trace: $stackTrace');
          debugPrint('🔍 [ANDROID-DEBUG] Raw JSON: $json');
          rethrow;
        }
      }).toList();
    });

      debugPrint('🔍 [ANDROID-DEBUG] getOrders completed successfully, returning ${result.length} orders');
      return result;
    } catch (e, stackTrace) {
      debugPrint('🔍 [ANDROID-DEBUG] ERROR in getOrders method: $e');
      debugPrint('🔍 [ANDROID-DEBUG] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get orders stream for real-time updates
  Stream<List<Order>> getOrdersStream({
    OrderStatus? status,
    String? vendorId,
    String? customerId,
  }) {
    debugPrint('🔍 [ANDROID-DEBUG-STREAM-METHOD] ===== getOrdersStream method ENTRY POINT =====');
    debugPrint('🔍 [ANDROID-DEBUG-STREAM-METHOD] getOrdersStream called with status: $status, vendorId: $vendorId, customerId: $customerId');

    return executeStreamQuery(() async* {
      debugPrint('🔍 [ANDROID-DEBUG-STREAM-METHOD] Inside executeStreamQuery, getting current user...');
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');
      debugPrint('🔍 [ANDROID-DEBUG-STREAM-METHOD] Current user: ${currentUser['role']} (${currentUser['id']})');

      dynamic streamBuilder = supabase.from('orders').stream(primaryKey: ['id']);

      // Apply role-based filtering
      switch (currentUser['role']) {
        case 'sales_agent':
          debugPrint('🔍 [ANDROID-DEBUG-STREAM] Applying sales agent filter');
          streamBuilder = streamBuilder.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          debugPrint('🔍 [ANDROID-DEBUG-STREAM] Looking up vendor for user ID: ${currentUser['id']}');
          try {
            final vendorResponse = await supabase
                .from('vendors')
                .select('id')
                .eq('user_id', currentUser['id'])
                .single();
            debugPrint('🔍 [ANDROID-DEBUG-STREAM] Vendor found: ${vendorResponse['id']}');
            streamBuilder = streamBuilder.eq('vendor_id', vendorResponse['id']);
          } catch (e) {
            debugPrint('🔍 [ANDROID-DEBUG-STREAM] ERROR: Vendor lookup failed: $e');
            rethrow;
          }
          break;
        default:
          debugPrint('🔍 [ANDROID-DEBUG-STREAM] No role-based filtering applied for role: ${currentUser['role']}');
      }

      // Apply additional filters
      if (status != null) {
        debugPrint('🔍 [ANDROID-DEBUG-STREAM] Applying status filter: ${status.value}');
        streamBuilder = streamBuilder.eq('status', status.value);
      }

      if (vendorId != null) {
        debugPrint('🔍 [ANDROID-DEBUG-STREAM] Applying vendor ID filter: $vendorId');
        streamBuilder = streamBuilder.eq('vendor_id', vendorId);
      }

      if (customerId != null) {
        debugPrint('🔍 [ANDROID-DEBUG-STREAM] Applying customer ID filter: $customerId');
        streamBuilder = streamBuilder.eq('customer_id', customerId);
      }

      debugPrint('🔍 [ANDROID-DEBUG-STREAM] About to start stream with filters applied...');
      debugPrint('🔍 [ANDROID-DEBUG-STREAM] Stream builder type: ${streamBuilder.runtimeType}');

      // Test: Try a simple stream first to see if it works at all
      debugPrint('🔍 [ANDROID-DEBUG-STREAM] Testing basic stream without filters...');
      try {
        final testStream = supabase.from('orders').stream(primaryKey: ['id']).take(1);
        await for (final testData in testStream) {
          debugPrint('🔍 [ANDROID-DEBUG-STREAM] TEST STREAM SUCCESS! Received ${testData.length} orders');
          break;
        }
      } catch (e) {
        debugPrint('🔍 [ANDROID-DEBUG-STREAM] TEST STREAM FAILED: $e');
      }

      debugPrint('🔍 [ANDROID-DEBUG-STREAM] WORKAROUND: Using basic stream with app-level filtering...');

      // WORKAROUND: Use basic stream and filter in application layer
      // The filtered stream is hanging due to RLS policy issues
      String? vendorIdToFilter;
      String? salesAgentIdToFilter;

      if (currentUser['role'] == 'vendor') {
        try {
          final vendorResponse = await supabase
              .from('vendors')
              .select('id')
              .eq('user_id', currentUser['id'])
              .single();
          vendorIdToFilter = vendorResponse['id'];
          debugPrint('🔍 [ANDROID-DEBUG-STREAM] WORKAROUND: Vendor ID for filtering: $vendorIdToFilter');
        } catch (e) {
          debugPrint('🔍 [ANDROID-DEBUG-STREAM] WORKAROUND: Vendor lookup failed: $e');
        }
      } else if (currentUser['role'] == 'sales_agent') {
        salesAgentIdToFilter = currentUser['id'];
        debugPrint('🔍 [ANDROID-DEBUG-STREAM] WORKAROUND: Sales agent ID for filtering: $salesAgentIdToFilter');
      }

      // Use Supabase real-time subscriptions for efficient updates
      debugPrint('🔍 [ORDER-STREAM] Setting up real-time subscription for orders...');

      // First, get initial data with complete joins
      final authenticatedClient = await getAuthenticatedClient();
      var initialQuery = authenticatedClient
          .from('orders')
          .select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(
              id,
              business_name,
              business_address,
              rating
            ),
            customer:customers!orders_customer_id_fkey(
              id,
              organization_name,
              contact_person_name,
              email,
              phone_number
            ),
            sales_agent:users!orders_sales_agent_id_fkey(
              id,
              full_name,
              email
            ),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''');

      // Apply role-based filtering at query level
      switch (currentUser['role']) {
        case 'sales_agent':
          initialQuery = initialQuery.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          if (vendorIdToFilter != null) {
            initialQuery = initialQuery.eq('vendor_id', vendorIdToFilter);
          }
          break;
      }

      // Apply additional filters
      if (status != null) {
        initialQuery = initialQuery.eq('status', status.value);
      }
      if (vendorId != null) {
        initialQuery = initialQuery.eq('vendor_id', vendorId);
      }
      if (customerId != null) {
        initialQuery = initialQuery.eq('customer_id', customerId);
      }

      // Get initial data
      final initialData = await initialQuery.order('created_at', ascending: false);
      debugPrint('🔍 [ORDER-STREAM] Initial data loaded: ${initialData.length} orders');

      // Create a stream that starts with initial data and then listens for real-time updates
      yield* Stream.fromIterable([initialData]).asyncExpand((data) async* {
        yield data;

        // Set up real-time subscription for updates
        yield* supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .asyncMap((realtimeData) async {
              debugPrint('🔍 [ORDER-STREAM] Real-time update received: ${realtimeData.length} orders');

              // For real-time updates, we need to fetch complete data with joins
              // since real-time subscriptions don't support complex joins
              final List<String> orderIds = realtimeData.map((order) => order['id'].toString()).toList();

              if (orderIds.isEmpty) return <Map<String, dynamic>>[];

              var updateQuery = authenticatedClient
                  .from('orders')
                  .select('''
                    *,
                    vendor:vendors!orders_vendor_id_fkey(
                      id,
                      business_name,
                      business_address,
                      rating
                    ),
                    customer:customers!orders_customer_id_fkey(
                      id,
                      organization_name,
                      contact_person_name,
                      email,
                      phone_number
                    ),
                    sales_agent:users!orders_sales_agent_id_fkey(
                      id,
                      full_name,
                      email
                    ),
                    order_items:order_items(
                      *,
                      menu_item:menu_items!order_items_menu_item_id_fkey(
                        id,
                        name,
                        image_url
                      )
                    )
                  ''')
                  .inFilter('id', orderIds);

              // Apply same filters as initial query
              switch (currentUser['role']) {
                case 'sales_agent':
                  updateQuery = updateQuery.eq('sales_agent_id', currentUser['id']);
                  break;
                case 'vendor':
                  if (vendorIdToFilter != null) {
                    updateQuery = updateQuery.eq('vendor_id', vendorIdToFilter);
                  }
                  break;
              }

              if (status != null) {
                updateQuery = updateQuery.eq('status', status.value);
              }
              if (vendorId != null) {
                updateQuery = updateQuery.eq('vendor_id', vendorId);
              }
              if (customerId != null) {
                updateQuery = updateQuery.eq('customer_id', customerId);
              }

              return await updateQuery.order('created_at', ascending: false);
            });
      })
          .map((data) {
            debugPrint('🔍 [ORDER-STREAM] Processing ${data.length} orders');

            return data.map((json) {
              try {
                final orderData = Map<String, dynamic>.from(json);

                // Handle delivery_address field - convert from JSON string to Map if needed
                if (orderData['delivery_address'] is String) {
                  try {
                    orderData['delivery_address'] = jsonDecode(orderData['delivery_address']);
                  } catch (e) {
                    orderData['delivery_address'] = {
                      'street': 'Unknown',
                      'city': 'Unknown',
                      'state': 'Unknown',
                      'postal_code': '00000',
                      'country': 'Malaysia',
                    };
                  }
                } else if (orderData['delivery_address'] == null) {
                  orderData['delivery_address'] = {
                    'street': 'Unknown',
                    'city': 'Unknown',
                    'state': 'Unknown',
                    'postal_code': '00000',
                    'country': 'Malaysia',
                  };
                }

                // Handle address field inconsistencies - normalize postcode/postal_code
                if (orderData['delivery_address'] is Map<String, dynamic>) {
                  final addressMap = orderData['delivery_address'] as Map<String, dynamic>;

                  // Handle postcode vs postal_code field inconsistency
                  if (addressMap.containsKey('postcode') && !addressMap.containsKey('postal_code')) {
                    addressMap['postal_code'] = addressMap['postcode'];
                    addressMap.remove('postcode');
                  }

                  // Ensure required address fields are not null (set defaults if needed)
                  addressMap['country'] ??= 'Malaysia';
                  addressMap['postal_code'] ??= '00000';
                }

                // Handle metadata field - convert from JSON string to Map if needed
                if (orderData['metadata'] is String) {
                  try {
                    orderData['metadata'] = jsonDecode(orderData['metadata']);
                  } catch (e) {
                    orderData['metadata'] = null;
                  }
                }

                return Order.fromJson(orderData);
              } catch (e) {
                debugPrint('🔍 [ORDER-STREAM] ERROR processing order ${json['id']}: $e');
                rethrow;
              }
            }).toList();
          });
    });
  }

  /// Get single order stream for real-time updates
  Stream<Order?> getOrderStream(String orderId) {
    return executeStreamQuery(() async* {
      yield* supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('id', orderId)
          .map((data) {
            if (data.isEmpty) return null;

            final orderData = Map<String, dynamic>.from(data.first);

            // Handle delivery_address field - convert from JSON string to Map if needed
            if (orderData['delivery_address'] is String) {
              try {
                orderData['delivery_address'] = jsonDecode(orderData['delivery_address']);
              } catch (e) {
                debugPrint('OrderRepository: Error parsing delivery_address JSON in single stream: $e');
                orderData['delivery_address'] = {
                  'street': 'Unknown',
                  'city': 'Unknown',
                  'state': 'Unknown',
                  'postal_code': '00000',
                  'country': 'Malaysia',
                };
              }
            }

            // Handle address field inconsistencies - normalize postcode/postal_code
            if (orderData['delivery_address'] is Map<String, dynamic>) {
              final addressMap = orderData['delivery_address'] as Map<String, dynamic>;

              // Handle postcode vs postal_code field inconsistency
              if (addressMap.containsKey('postcode') && !addressMap.containsKey('postal_code')) {
                addressMap['postal_code'] = addressMap['postcode'];
                addressMap.remove('postcode');
              }

              // Ensure required address fields are not null (set defaults if needed)
              addressMap['country'] ??= 'Malaysia';
              addressMap['postal_code'] ??= '00000';
            }

            // Handle metadata field - convert from JSON string to Map if needed
            if (orderData['metadata'] is String) {
              try {
                orderData['metadata'] = jsonDecode(orderData['metadata']);
              } catch (e) {
                debugPrint('OrderRepository: Error parsing metadata JSON in single stream: $e');
                orderData['metadata'] = null;
              }
            }

            // Payment fields are now handled directly by the Order model

            return Order.fromJson(orderData);
          });
    });
  }

  /// Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    return executeQuery(() async {
      final response = await supabase
          .from('orders')
          .select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(
              id,
              business_name,
              business_address,
              rating
            ),
            customer:customers!orders_customer_id_fkey(
              id,
              organization_name,
              contact_person_name,
              email,
              phone_number
            ),
            sales_agent:users!orders_sales_agent_id_fkey(
              id,
              full_name,
              email
            ),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''')
          .eq('id', orderId)
          .single();

      return Order.fromJson(response);
    });
  }

  /// Create order with retry logic for network resilience
  Future<Map<String, dynamic>> _createOrderWithRetry(
    dynamic client,
    Map<String, dynamic> orderData, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        attempt++;
        DebugLogger.info('Order creation attempt $attempt/$maxRetries', tag: 'OrderRepository-Retry');

        final response = await client
            .from('orders')
            .insert(orderData)
            .select()
            .single();

        DebugLogger.success('Order creation successful on attempt $attempt', tag: 'OrderRepository-Retry');
        return response;

      } catch (e) {
        DebugLogger.error('Order creation attempt $attempt failed: $e', tag: 'OrderRepository-Retry');

        // Check if this is a network-related error that we should retry
        final shouldRetry = _shouldRetryError(e);

        if (!shouldRetry || attempt >= maxRetries) {
          // Don't retry for non-network errors or if we've exhausted retries
          if (attempt >= maxRetries) {
            DebugLogger.error('All $maxRetries retry attempts failed', tag: 'OrderRepository-Retry');
            throw Exception('Failed to create order after $maxRetries attempts. Last error: $e');
          } else {
            DebugLogger.error('Non-retryable error encountered', tag: 'OrderRepository-Retry');
            rethrow;
          }
        }

        // Wait before retrying (exponential backoff)
        if (attempt < maxRetries) {
          DebugLogger.info('Waiting ${delay.inSeconds}s before retry attempt ${attempt + 1}', tag: 'OrderRepository-Retry');
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
        }
      }
    }

    throw Exception('Unexpected error in retry logic');
  }

  /// Determine if an error should trigger a retry
  bool _shouldRetryError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network-related errors that should be retried
    final retryableErrors = [
      'socketexception',
      'connection',
      'timeout',
      'network',
      'error condition has been reset',
      'connection refused',
      'connection timed out',
      'no route to host',
      'network is unreachable',
    ];

    for (final retryableError in retryableErrors) {
      if (errorString.contains(retryableError)) {
        DebugLogger.info('Detected retryable network error: $retryableError', tag: 'OrderRepository-Retry');
        return true;
      }
    }

    // Don't retry authentication, validation, or permission errors
    final nonRetryableErrors = ['401', '403', '422', '400'];
    for (final nonRetryableError in nonRetryableErrors) {
      if (errorString.contains(nonRetryableError)) {
        DebugLogger.info('Detected non-retryable error: $nonRetryableError', tag: 'OrderRepository-Retry');
        return false;
      }
    }

    DebugLogger.info('Unknown error type, will retry: $errorString', tag: 'OrderRepository-Retry');
    return true; // Default to retry for unknown errors
  }

  /// Create new order
  Future<Order> createOrder(Order order) async {
    return executeQuery(() async {
      // Use authenticated client for order creation (critical for RLS policies)
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Creating order with authenticated client');
      debugPrint('OrderRepository: Order data - Customer: ${order.customerName}, Vendor: ${order.vendorName}');
      debugPrint('OrderRepository: Order has ${order.items.length} items');

      // Debug the order items before JSON conversion
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        debugPrint('OrderRepository: Item $i - Type: ${item.runtimeType}, Name: ${item.name}');
      }

      debugPrint('OrderRepository: Converting order to JSON...');
      final orderData = order.toJson();
      debugPrint('OrderRepository: Order JSON conversion successful');

      // Remove nested data that will be handled separately
      orderData.remove('vendor');
      orderData.remove('customer');
      orderData.remove('sales_agent');

      // CRITICAL FIX: Properly handle order items conversion
      final orderItemsRaw = orderData.remove('order_items');
      List<Map<String, dynamic>>? orderItems;

      if (orderItemsRaw != null) {
        if (orderItemsRaw is List<OrderItem>) {
          // Convert OrderItem objects to JSON Maps
          orderItems = orderItemsRaw.map((item) => item.toJson()).toList();
          debugPrint('OrderRepository: Converted ${orderItems.length} OrderItem objects to JSON');
        } else if (orderItemsRaw is List<Map<String, dynamic>>) {
          // Already in correct format
          orderItems = orderItemsRaw;
          debugPrint('OrderRepository: Order items already in JSON format');
        } else {
          debugPrint('OrderRepository: Unexpected order items type: ${orderItemsRaw.runtimeType}');
          throw Exception('Invalid order items format: ${orderItemsRaw.runtimeType}');
        }
      }

      // Remove tracking fields that don't exist in the database schema yet
      // These fields are only used for order updates, not creation
      orderData.remove('actual_delivery_time');
      orderData.remove('preparation_started_at');
      orderData.remove('ready_at');
      orderData.remove('out_for_delivery_at');
      orderData.remove('delivery_zone');
      orderData.remove('special_instructions');
      // Keep contact_phone as it's a valid field for order creation

      // CRITICAL FIX: Remove empty string or temporary UUID fields that should be auto-generated or null
      // The database expects either valid UUIDs or NULL, not empty strings
      if (orderData['id'] == '' || (orderData['id'] is String && orderData['id'].toString().startsWith('temp-'))) {
        orderData.remove('id'); // Let database generate UUID
        debugPrint('OrderRepository: Removed temporary/empty id field - will be auto-generated');
      }
      if (orderData['order_number'] == '' || (orderData['order_number'] is String && orderData['order_number'].toString().startsWith('temp-'))) {
        orderData.remove('order_number'); // Let database generate order number
        debugPrint('OrderRepository: Removed temporary/empty order_number field - will be auto-generated');
      }

      // Validate required UUID fields are not empty strings
      final requiredUuidFields = ['vendor_id', 'customer_id'];
      for (final field in requiredUuidFields) {
        if (orderData[field] == '') {
          debugPrint('OrderRepository: ERROR - Required UUID field $field is empty string');
          throw Exception('Invalid $field: cannot be empty. Please refresh and try again.');
        }
      }

      // Handle optional UUID fields - convert empty strings to null
      final optionalUuidFields = ['sales_agent_id'];
      for (final field in optionalUuidFields) {
        if (orderData[field] == '') {
          orderData[field] = null;
          debugPrint('OrderRepository: Converted empty $field to null');
        }
      }

      // Enhanced UUID debugging
      DebugLogger.info('🔍 Final UUID validation before database insert:', tag: 'OrderRepository');
      DebugLogger.info('  - vendor_id: ${orderData['vendor_id']} (type: ${orderData['vendor_id'].runtimeType})', tag: 'OrderRepository');
      DebugLogger.info('  - customer_id: ${orderData['customer_id']} (type: ${orderData['customer_id'].runtimeType})', tag: 'OrderRepository');
      DebugLogger.info('  - sales_agent_id: ${orderData['sales_agent_id']} (type: ${orderData['sales_agent_id'].runtimeType})', tag: 'OrderRepository');

      DebugLogger.info('📋 Inserting order data with fields: ${orderData.keys.join(', ')}', tag: 'OrderRepository');
      DebugLogger.logObject('Full order data being sent to Supabase', orderData, tag: 'OrderRepository');

      try {
        // Log the exact network request being made
        DebugLogger.networkRequest('POST', '/rest/v1/orders?select=*', data: orderData);

        // Create order with authenticated client and retry logic
        final orderResponse = await _createOrderWithRetry(authenticatedClient, orderData);

        DebugLogger.networkResponse('POST', '/rest/v1/orders', 200, data: orderResponse);
        DebugLogger.success('Order insert successful, response received', tag: 'OrderRepository');

        final orderId = orderResponse['id'];
        debugPrint('OrderRepository: Order created successfully with ID: $orderId');

        // Create order items with authenticated client
        if (orderItems != null && orderItems.isNotEmpty) {
          debugPrint('OrderRepository: ===== STARTING ORDER ITEMS PROCESSING =====');
          debugPrint('OrderRepository: Raw orderItems type: ${orderItems.runtimeType}');
          debugPrint('OrderRepository: Raw orderItems length: ${orderItems.length}');
          debugPrint('OrderRepository: Raw orderItems sample: ${orderItems.isNotEmpty ? orderItems.first : 'none'}');

          // Check each order item for potential issues
          for (int i = 0; i < orderItems.length; i++) {
            final item = orderItems[i];
            debugPrint('OrderRepository: Order item $i raw data: $item');
            debugPrint('OrderRepository: Order item $i type: ${item.runtimeType}');
          }

          final itemsData = orderItems.map((item) {
            // item is already a Map<String, dynamic> from our conversion above
            final itemData = Map<String, dynamic>.from(item);
            itemData['order_id'] = orderId;
            itemData.remove('menu_item'); // Remove nested data

            // CRITICAL FIX: Handle UUID fields in order items
            // Remove empty string or temporary UUID fields that should be auto-generated
            if (itemData['id'] == '' || (itemData['id'] is String && itemData['id'].toString().startsWith('temp-'))) {
              itemData.remove('id'); // Let database generate UUID
              debugPrint('OrderRepository: Removed temporary/empty order item id field');
            }

            // Handle optional UUID fields - convert empty strings to null
            final optionalUuidFields = ['menu_item_id'];
            for (final field in optionalUuidFields) {
              if (itemData[field] == '') {
                itemData[field] = null;
                debugPrint('OrderRepository: Converted empty order item $field to null');
              }
            }

            return itemData;
          }).toList();

          debugPrint('OrderRepository: Creating ${itemsData.length} order items');
          debugPrint('OrderRepository: Order item data sample: ${itemsData.isNotEmpty ? itemsData.first.keys.join(', ') : 'none'}');

          // Debug each order item before insertion
          for (int i = 0; i < itemsData.length; i++) {
            final item = itemsData[i];
            debugPrint('OrderRepository: Order item $i data: $item');

            // Check for empty string UUIDs
            item.forEach((key, value) {
              if (value == '') {
                debugPrint('OrderRepository: WARNING - Order item $i has empty string for field: $key');
              }
            });
          }

          debugPrint('OrderRepository: About to insert order items into database...');
          debugPrint('OrderRepository: Full order items data: $itemsData');

          await authenticatedClient.from('order_items').insert(itemsData);
          debugPrint('OrderRepository: Order items created successfully');
        }

        // Return complete order with relations
        final completeOrder = await getOrderById(orderId);
        if (completeOrder != null) {
          debugPrint('OrderRepository: Order creation completed successfully');
          return completeOrder;
        } else {
          debugPrint('OrderRepository: Warning - Could not fetch complete order, returning basic order');
          return Order.fromJson(orderResponse);
        }
      } catch (e, stackTrace) {
        DebugLogger.error('Error during order insert', tag: 'OrderRepository', error: e, stackTrace: stackTrace);

        // Log detailed error information for debugging
        if (e.toString().contains('400')) {
          DebugLogger.error('400 Bad Request - likely invalid data format or missing required fields', tag: 'OrderRepository-400');
          DebugLogger.networkResponse('POST', '/rest/v1/orders', 400, error: e.toString());
        } else if (e.toString().contains('401')) {
          DebugLogger.error('401 Unauthorized - authentication failed', tag: 'OrderRepository-401');
        } else if (e.toString().contains('403')) {
          DebugLogger.error('403 Forbidden - permission denied by RLS policies', tag: 'OrderRepository-403');
        } else if (e.toString().contains('422')) {
          DebugLogger.error('422 Unprocessable Entity - data validation failed', tag: 'OrderRepository-422');
        }

        rethrow; // Re-throw to be handled by the provider
      }
    });
  }

  /// Update order status with frontend validation
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    return executeQuery(() async {
      debugPrint('OrderRepository: Starting order status update - ID: $orderId, Status: ${status.value}');

      // Get current order to validate transition
      final currentOrder = await getOrderById(orderId);
      if (currentOrder == null) {
        throw Exception('Order not found');
      }

      // Get current user information for permission validation
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('OrderRepository: Current order status: ${currentOrder.status.value}');
      debugPrint('OrderRepository: User role: ${currentUser['role']}');

      // Determine order ownership for validation
      bool isVendorOrder = false;
      bool isSalesAgentOrder = false;

      if (currentUser['role'] == 'vendor') {
        // Check if user is associated with the vendor for this order
        try {
          final vendorResponse = await supabase
              .from('vendors')
              .select('id')
              .eq('user_id', currentUser['id'])
              .single();
          isVendorOrder = currentOrder.vendorId == vendorResponse['id'];
        } catch (e) {
          debugPrint('OrderRepository: Error checking vendor association: $e');
          isVendorOrder = false;
        }
      } else if (currentUser['role'] == 'sales_agent') {
        isSalesAgentOrder = currentOrder.salesAgentId == currentUser['id'];
      }

      // Perform frontend validation
      final validationResult = OrderValidationUtils.validateOrderStatusUpdate(
        currentStatus: currentOrder.status,
        newStatus: status,
        userRole: currentUser['role'],
        isOrderOwner: isVendorOrder || isSalesAgentOrder,
        isVendorOrder: isVendorOrder,
        isSalesAgentOrder: isSalesAgentOrder,
      );

      if (!validationResult.isValid) {
        debugPrint('OrderRepository: Validation failed: ${validationResult.errorMessage}');
        throw Exception(validationResult.errorMessage);
      }

      debugPrint('OrderRepository: Frontend validation passed, proceeding with update');

      final authenticatedClient = await getAuthenticatedClient();

      await authenticatedClient
          .from('orders')
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final updatedOrder = await getOrderById(orderId);
      if (updatedOrder == null) throw Exception('Order not found after update');

      debugPrint('OrderRepository: Order status updated successfully from ${currentOrder.status.value} to ${status.value}');
      return updatedOrder;
    });
  }

  /// Update order payment status
  Future<Order> updatePaymentStatus(
    String orderId,
    PaymentStatus paymentStatus,
    {String? paymentReference}
  ) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Updating payment status - ID: $orderId, Status: ${paymentStatus.value}');

      final updateData = {
        'payment_status': paymentStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paymentReference != null) {
        updateData['payment_reference'] = paymentReference;
      }

      await authenticatedClient
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');

      debugPrint('OrderRepository: Payment status updated successfully');
      return order;
    });
  }

  /// Get order statistics for dashboard
  Future<Map<String, dynamic>> getOrderStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('🔍 [ANDROID-DEBUG-STATS] ===== getOrderStatistics method ENTRY POINT =====');
    debugPrint('🔍 [ANDROID-DEBUG-STATS] getOrderStatistics called with startDate: $startDate, endDate: $endDate');

    return executeQuery(() async {
      debugPrint('🔍 [ANDROID-DEBUG-STATS] Inside executeQuery, getting current user...');
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');
      debugPrint('🔍 [ANDROID-DEBUG-STATS] Current user: ${currentUser['role']} (${currentUser['id']})');

      // Build the RPC call based on user role
      final params = <String, dynamic>{
        'user_role': currentUser['role'],
        'user_id': currentUser['id'],
      };

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }

      final response = await supabase.rpc('get_order_statistics', params: params);
      return response as Map<String, dynamic>;
    });
  }

  /// Cancel order
  Future<Order> cancelOrder(String orderId, String reason) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Cancelling order - ID: $orderId, Reason: $reason');

      await authenticatedClient
          .from('orders')
          .update({
            'status': OrderStatus.cancelled.value,
            'notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');

      debugPrint('OrderRepository: Order cancelled successfully');
      return order;
    });
  }

  /// Get recent orders for dashboard
  Future<List<Order>> getRecentOrders({int limit = 5}) async {
    debugPrint('🔍 [ANDROID-DEBUG-RECENT] ===== getRecentOrders method ENTRY POINT =====');
    debugPrint('🔍 [ANDROID-DEBUG-RECENT] getRecentOrders called with limit: $limit');

    return executeQuery(() async {
      debugPrint('🔍 [ANDROID-DEBUG-RECENT] Inside executeQuery, getting authenticated client...');
      final authenticatedClient = await getAuthenticatedClient();
      debugPrint('🔍 [ANDROID-DEBUG-RECENT] Getting current user...');
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');
      debugPrint('🔍 [ANDROID-DEBUG-RECENT] Current user: ${currentUser['role']} (${currentUser['id']})');

      debugPrint('OrderRepository.getRecentOrders: User role: ${currentUser['role']}, User ID: ${currentUser['id']}');

      var query = authenticatedClient.from('orders').select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(business_name),
            customer:customers!orders_customer_id_fkey(organization_name),
            order_items:order_items(*)
          ''');

      // Apply role-based filtering
      switch (currentUser['role']) {
        case 'sales_agent':
          debugPrint('OrderRepository.getRecentOrders: Filtering by sales_agent_id: ${currentUser['id']}');
          query = query.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          final vendorResponse = await authenticatedClient
              .from('vendors')
              .select('id')
              .eq('user_id', currentUser['id'])
              .single();
          debugPrint('OrderRepository.getRecentOrders: Filtering by vendor_id: ${vendorResponse['id']}');
          query = query.eq('vendor_id', vendorResponse['id']);
          break;
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('OrderRepository.getRecentOrders: Found ${response.length} orders');

      // Handle empty results gracefully
      if (response.isEmpty) {
        debugPrint('OrderRepository: No recent orders found for user role: ${currentUser['role']}');
        return [];
      }

      // Transform the data to match Order model expectations
      final orders = response.map((data) {
        final orderData = Map<String, dynamic>.from(data);

        debugPrint('OrderRepository.getRecentOrders: Processing order ${orderData['order_number']}');
        debugPrint('OrderRepository.getRecentOrders: Raw vendor data: ${orderData['vendor']}');
        debugPrint('OrderRepository.getRecentOrders: Raw customer data: ${orderData['customer']}');

        // Extract vendor name from joined data
        if (orderData['vendor'] != null && orderData['vendor'] is Map) {
          final vendorData = orderData['vendor'] as Map<String, dynamic>;
          orderData['vendor_name'] = vendorData['business_name']?.toString() ?? 'Unknown Vendor';
        } else {
          orderData['vendor_name'] = 'Unknown Vendor';
        }

        // Extract customer name from joined data
        if (orderData['customer'] != null && orderData['customer'] is Map) {
          final customerData = orderData['customer'] as Map<String, dynamic>;
          orderData['customer_name'] = customerData['organization_name']?.toString() ?? 'Unknown Customer';
        } else {
          orderData['customer_name'] = 'Unknown Customer';
        }

        // Ensure all required String fields are not null and properly typed
        orderData['id'] = (orderData['id']?.toString() ?? '').isNotEmpty ? orderData['id'].toString() : '';
        orderData['order_number'] = (orderData['order_number']?.toString() ?? '').isNotEmpty ? orderData['order_number'].toString() : 'N/A';
        orderData['vendor_id'] = (orderData['vendor_id']?.toString() ?? '').isNotEmpty ? orderData['vendor_id'].toString() : '';
        orderData['customer_id'] = (orderData['customer_id']?.toString() ?? '').isNotEmpty ? orderData['customer_id'].toString() : '';

        // Double-check vendor_name and customer_name are never null
        orderData['vendor_name'] = (orderData['vendor_name']?.toString() ?? 'Unknown Vendor').isNotEmpty ? orderData['vendor_name'].toString() : 'Unknown Vendor';
        orderData['customer_name'] = (orderData['customer_name']?.toString() ?? 'Unknown Customer').isNotEmpty ? orderData['customer_name'].toString() : 'Unknown Customer';

        // Ensure order_items is not null
        if (orderData['order_items'] == null) {
          orderData['order_items'] = [];
        }

        // Ensure delivery_address is properly formatted
        if (orderData['delivery_address'] == null || orderData['delivery_address'] is! Map) {
          orderData['delivery_address'] = {
            'street': '',
            'city': '',
            'state': '',
            'postal_code': '',
            'country': 'Malaysia',
          };
        }

        // Remove the nested objects to avoid conflicts
        orderData.remove('vendor');
        orderData.remove('customer');

        debugPrint('OrderRepository.getRecentOrders: Final vendor_name: ${orderData['vendor_name']}');
        debugPrint('OrderRepository.getRecentOrders: Final customer_name: ${orderData['customer_name']}');

        try {
          // Additional validation before parsing
          final requiredStringFields = ['id', 'order_number', 'vendor_id', 'customer_id', 'vendor_name', 'customer_name'];
          for (final field in requiredStringFields) {
            if (orderData[field] == null) {
              debugPrint('OrderRepository.getRecentOrders: WARNING - Required field $field is null, setting default');
              orderData[field] = field.contains('name') ? 'Unknown' : '';
            }
          }

          return Order.fromJson(orderData);
        } catch (e, stackTrace) {
          debugPrint('OrderRepository.getRecentOrders: Error parsing order ${orderData['order_number']}: $e');
          debugPrint('OrderRepository.getRecentOrders: Order data keys: ${orderData.keys.join(', ')}');
          debugPrint('OrderRepository.getRecentOrders: Full order data: $orderData');
          debugPrint('OrderRepository.getRecentOrders: Stack trace: $stackTrace');

          // Return a minimal order object to prevent complete failure
          debugPrint('OrderRepository.getRecentOrders: Attempting to create minimal order object');
          try {
            final minimalOrderData = {
              'id': orderData['id']?.toString() ?? '',
              'order_number': orderData['order_number']?.toString() ?? 'N/A',
              'status': orderData['status']?.toString() ?? 'pending',
              'order_items': [],
              'vendor_id': orderData['vendor_id']?.toString() ?? '',
              'vendor_name': orderData['vendor_name']?.toString() ?? 'Unknown Vendor',
              'customer_id': orderData['customer_id']?.toString() ?? '',
              'customer_name': orderData['customer_name']?.toString() ?? 'Unknown Customer',
              'sales_agent_id': orderData['sales_agent_id']?.toString(),
              'sales_agent_name': orderData['sales_agent_name']?.toString(),
              'delivery_date': orderData['delivery_date']?.toString() ?? DateTime.now().toIso8601String(),
              'delivery_address': {
                'street': '',
                'city': '',
                'state': '',
                'postal_code': '',
                'country': 'Malaysia',
              },
              'subtotal': (orderData['subtotal'] as num?)?.toDouble() ?? 0.0,
              'delivery_fee': (orderData['delivery_fee'] as num?)?.toDouble() ?? 0.0,
              'sst_amount': (orderData['sst_amount'] as num?)?.toDouble() ?? 0.0,
              'total_amount': (orderData['total_amount'] as num?)?.toDouble() ?? 0.0,
              'created_at': orderData['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              'updated_at': orderData['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
            };
            return Order.fromJson(minimalOrderData);
          } catch (fallbackError) {
            debugPrint('OrderRepository.getRecentOrders: Even minimal order creation failed: $fallbackError');
            rethrow;
          }
        }
      }).toList();

      debugPrint('OrderRepository.getRecentOrders: Successfully transformed ${orders.length} orders');
      return orders;
    });
  }

  /// Get order status history
  Future<List<OrderStatusHistory>> getOrderStatusHistory(String orderId) async {
    return executeQuery(() async {
      final response = await supabase
          .from('order_status_history')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return response.map((json) => OrderStatusHistory.fromJson(json)).toList();
    });
  }

  /// Get order notifications for current user
  Future<List<OrderNotification>> getOrderNotifications({
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      var query = supabase
          .from('order_notifications')
          .select('*')
          .eq('recipient_id', currentUserId!);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => OrderNotification.fromJson(json)).toList();
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    return executeQuery(() async {
      await supabase
          .from('order_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_id', currentUserId!);
    });
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    return executeQuery(() async {
      await supabase
          .from('order_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_id', currentUserId!)
          .eq('is_read', false);
    });
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    return executeQuery(() async {
      final response = await supabase
          .from('order_notifications')
          .select('id')
          .eq('recipient_id', currentUserId!)
          .eq('is_read', false);

      return response.length;
    });
  }

  /// Get order notifications stream for real-time updates
  Stream<List<OrderNotification>> getOrderNotificationsStream() {
    return executeStreamQuery(() async* {
      yield* supabase
          .from('order_notifications')
          .stream(primaryKey: ['id'])
          .eq('recipient_id', currentUserId!)
          .order('sent_at', ascending: false)
          .map((data) => data.map((json) => OrderNotification.fromJson(json)).toList());
    });
  }

  /// Update order with enhanced tracking fields
  Future<Order> updateOrderTracking(
    String orderId, {
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    DateTime? preparationStartedAt,
    DateTime? readyAt,
    DateTime? outForDeliveryAt,
    String? deliveryZone,
    String? specialInstructions,
    String? contactPhone,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (estimatedDeliveryTime != null) {
        updateData['estimated_delivery_time'] = estimatedDeliveryTime.toIso8601String();
      }
      if (actualDeliveryTime != null) {
        updateData['actual_delivery_time'] = actualDeliveryTime.toIso8601String();
      }
      if (preparationStartedAt != null) {
        updateData['preparation_started_at'] = preparationStartedAt.toIso8601String();
      }
      if (readyAt != null) {
        updateData['ready_at'] = readyAt.toIso8601String();
      }
      if (outForDeliveryAt != null) {
        updateData['out_for_delivery_at'] = outForDeliveryAt.toIso8601String();
      }
      if (deliveryZone != null) {
        updateData['delivery_zone'] = deliveryZone;
      }
      if (specialInstructions != null) {
        updateData['special_instructions'] = specialInstructions;
      }
      if (contactPhone != null) {
        updateData['contact_phone'] = contactPhone;
      }

      await authenticatedClient
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');

      return order;
    });
  }

  /// Store delivery proof and update order status to delivered
  Future<Order> storeDeliveryProof(String orderId, ProofOfDelivery proofOfDelivery) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Storing delivery proof for order: $orderId');

      // Prepare delivery proof data
      final proofData = {
        'order_id': orderId,
        'photo_url': proofOfDelivery.photoUrl,
        'signature_url': proofOfDelivery.signatureUrl,
        'recipient_name': proofOfDelivery.recipientName,
        'notes': proofOfDelivery.notes,
        'delivered_at': proofOfDelivery.deliveredAt.toIso8601String(),
        'delivered_by': proofOfDelivery.deliveredBy,
        'latitude': proofOfDelivery.latitude,
        'longitude': proofOfDelivery.longitude,
        'location_accuracy': proofOfDelivery.locationAccuracy,
        'delivery_address': proofOfDelivery.deliveryAddress,
      };

      // Remove null values
      proofData.removeWhere((key, value) => value == null);

      debugPrint('OrderRepository: Inserting delivery proof data: $proofData');

      // Insert delivery proof (this will automatically trigger order status update via database trigger)
      final proofResponse = await authenticatedClient
          .from('delivery_proofs')
          .insert(proofData)
          .select()
          .single();

      debugPrint('OrderRepository: Delivery proof stored successfully with ID: ${proofResponse['id']}');

      // Return updated order
      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found after delivery proof creation');

      debugPrint('OrderRepository: Order status updated to delivered successfully');
      return order;
    });
  }

  /// Get delivery proof for an order
  Future<ProofOfDelivery?> getDeliveryProof(String orderId) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Fetching delivery proof for order: $orderId');

      final response = await authenticatedClient
          .from('delivery_proofs')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (response == null) {
        debugPrint('OrderRepository: No delivery proof found for order: $orderId');
        return null;
      }

      debugPrint('OrderRepository: Delivery proof found for order: $orderId');
      return ProofOfDelivery.fromJson(response);
    });
  }

  /// Helper method to get current user with role
  Future<Map<String, dynamic>?> _getCurrentUserWithRole() async {
    if (currentUserId == null) {
      debugPrint('OrderRepository: No current user UID available');
      return null;
    }

    try {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Fetching user role for UID: $currentUserId');

      final response = await authenticatedClient
          .from('users')
          .select('id, role')
          .eq('supabase_user_id', currentUserId!)
          .single();

      debugPrint('OrderRepository: User role fetched - ID: ${response['id']}, Role: ${response['role']}');
      return response;
    } catch (e) {
      debugPrint('OrderRepository: Error fetching user role: $e');
      return null;
    }
  }
}
