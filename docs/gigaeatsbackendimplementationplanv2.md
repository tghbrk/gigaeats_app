# GigaEats Backend Implementation Plan - Refined with Flutter & Supabase Best Practices

## Overview

This refined implementation plan incorporates current Flutter and Supabase best practices for 2024/2025, including modern state management patterns, security considerations, and efficient development workflows.

## 🚀 IMPLEMENTATION STATUS

### ✅ Completed Features
- Basic Database Schema (Migration 001-006)
- Supabase Authentication System
- Enhanced Order Management Database Schema
- Basic Payment Integration
- Commission Tracking Service Layer
- Vendor Management Repository
- Riverpod State Management Foundation
- Row Level Security Policies

### 🔄 In Progress - High Priority Features
1. **Enhanced Order Management System** - Riverpod + Real-time + Edge Functions
2. **Secure Payment Integration** - Enhanced audit trail + Edge Functions
3. **Advanced Commission Tracking** - Database enhancements + automation
4. **Enhanced Vendor Menu Management** - Versioning + bulk operations

## Architecture & Technology Stack

### Backend Architecture
- **Database**: PostgreSQL with Supabase
- **Authentication**: Supabase Auth with Row Level Security (RLS)
- **Real-time**: Supabase Realtime subscriptions
- **Storage**: Supabase Storage for file uploads
- **Edge Functions**: Supabase Edge Functions for complex business logic

### Frontend Architecture
- **State Management**: Riverpod (recommended for 2024+)
- **HTTP Client**: Supabase Flutter SDK with built-in caching
- **Local Storage**: Hive/SharedPreferences for offline capabilities
- **Navigation**: GoRouter for declarative routing
- **UI Framework**: Flutter with Material 3 design system

## Development Environment Setup

### Project Structure Best Practices
```
gigaeats/
├── supabase/                 # Supabase backend
│   ├── migrations/
│   ├── functions/
│   └── config.toml
├── lib/                      # Flutter app
│   ├── core/                 # Core utilities, constants
│   ├── features/             # Feature-based architecture
│   │   ├── auth/
│   │   ├── orders/
│   │   ├── vendors/
│   │   └── ...
│   ├── shared/               # Shared widgets, models
│   └── main.dart
└── test/                     # Tests
```

### Dependency Management
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.3.4
  flutter_riverpod: ^2.4.9
  go_router: ^12.1.3
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  hive_flutter: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
  flutter_lints: ^3.0.1
```

## High Priority Features (4-6 weeks)

### 1. Enhanced Order Management System (1-2 weeks)

**Key Improvements:**
- Use Supabase Edge Functions for complex order validation
- Implement optimistic updates with Riverpod
- Add comprehensive error handling and retry logic
- Use Supabase real-time for instant order updates

**Database Schema Refinements:**
```sql
-- Enhanced order management with better indexing and constraints
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number TEXT NOT NULL UNIQUE,
  customer_id UUID REFERENCES customers(id) ON DELETE RESTRICT,
  vendor_id UUID REFERENCES vendors(id) ON DELETE RESTRICT,
  sales_agent_id UUID REFERENCES users(id) ON DELETE SET NULL,
  status order_status_enum NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  delivery_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
  total_amount DECIMAL(12,2) GENERATED ALWAYS AS (subtotal + tax_amount + delivery_fee) STORED,
  commission_amount DECIMAL(10,2),
  payment_status payment_status_enum DEFAULT 'pending',
  payment_method payment_method_enum,
  payment_reference TEXT,
  delivery_address TEXT NOT NULL,
  delivery_latitude DECIMAL(10,8),
  delivery_longitude DECIMAL(11,8),
  expected_delivery_time TIMESTAMP WITH TIME ZONE,
  special_instructions TEXT,
  -- Tracking timestamps
  preparation_started_at TIMESTAMP WITH TIME ZONE,
  ready_at TIMESTAMP WITH TIME ZONE,
  out_for_delivery_at TIMESTAMP WITH TIME ZONE,
  actual_delivery_time TIMESTAMP WITH TIME ZONE,
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Indexes for common queries
  CONSTRAINT valid_amounts CHECK (subtotal >= 0 AND tax_amount >= 0 AND delivery_fee >= 0)
);

-- Indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_orders_customer_created_at ON orders(customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_status ON orders(vendor_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_sales_agent_created_at ON orders(sales_agent_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at ON orders(status, created_at DESC);

-- Enhanced RLS policies with better performance
CREATE POLICY "Users can view their own orders" ON orders
  FOR SELECT TO authenticated
  USING (
    auth.uid() IN (
      SELECT user_id FROM user_profiles WHERE user_id = customer_id::uuid
      UNION
      SELECT sales_agent_id WHERE sales_agent_id IS NOT NULL
      UNION 
      SELECT user_id FROM vendor_users WHERE vendor_id = orders.vendor_id
    )
  );
```

**Flutter Implementation with Riverpod:**
```dart
// Order state management with Riverpod
@riverpod
class OrderNotifier extends _$OrderNotifier {
  @override
  FutureOr<List<Order>> build() async {
    // Listen to real-time updates
    _setupRealtimeSubscription();
    return _fetchOrders();
  }

  void _setupRealtimeSubscription() {
    ref.read(supabaseProvider).channel('orders')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          // Update state optimistically
          _handleRealtimeUpdate(payload);
        },
      ).subscribe();
  }

  Future<Order> createOrder(CreateOrderRequest request) async {
    // Optimistic update
    final tempOrder = _createTempOrder(request);
    state = AsyncValue.data([tempOrder, ...state.value ?? []]);

    try {
      final order = await ref.read(orderRepositoryProvider)
        .createOrder(request);
      
      // Replace temp order with real order
      _replaceTempOrder(tempOrder.id, order);
      return order;
    } catch (error) {
      // Revert optimistic update
      _removeTempOrder(tempOrder.id);
      rethrow;
    }
  }
}
```

**Edge Function for Order Validation:**
```typescript
// supabase/functions/validate-order/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { orderData } = await req.json()
    
    // Complex validation logic
    const validationResult = await validateOrderData(orderData)
    
    if (!validationResult.isValid) {
      return new Response(
        JSON.stringify({ error: validationResult.errors }),
        { status: 400 }
      )
    }

    // If valid, create order in database
    const order = await createOrderInDatabase(orderData)
    
    return new Response(JSON.stringify(order), {
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
```

### 2. Secure Payment Integration (1-2 weeks)

**Security Enhancements:**
- Use Supabase Edge Functions for payment processing
- Implement webhook signature verification
- Add comprehensive payment audit logging
- Use encrypted storage for sensitive data

**Enhanced Payment Schema:**
```sql
-- Enhanced payment transactions with audit trail
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'MYR',
  payment_method payment_method_enum NOT NULL,
  payment_gateway TEXT NOT NULL,
  gateway_transaction_id TEXT,
  gateway_reference TEXT,
  status payment_transaction_status NOT NULL DEFAULT 'pending',
  failure_reason TEXT,
  webhook_data JSONB,
  metadata JSONB DEFAULT '{}',
  -- Audit fields
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Constraints
  CONSTRAINT unique_gateway_transaction UNIQUE (payment_gateway, gateway_transaction_id)
);

-- Payment audit log
CREATE TABLE IF NOT EXISTS payment_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_transaction_id UUID REFERENCES payment_transactions(id),
  action TEXT NOT NULL,
  old_status TEXT,
  new_status TEXT,
  user_id UUID REFERENCES users(id),
  ip_address INET,
  user_agent TEXT,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Flutter Payment Integration:**
```dart
@riverpod
class PaymentNotifier extends _$PaymentNotifier {
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    try {
      // Use Edge Function for secure payment processing
      final response = await ref.read(supabaseProvider)
        .functions
        .invoke('process-payment', body: request.toJson());

      if (response.error != null) {
        throw PaymentException(response.error!.message);
      }

      return PaymentResult.fromJson(response.data);
    } catch (error) {
      // Log error securely (without sensitive data)
      ref.read(analyticsProvider).logError('payment_failed', {
        'order_id': request.orderId,
        'payment_method': request.paymentMethod,
      });
      rethrow;
    }
  }
}
```

### 3. Advanced Commission Tracking (1 week)

**Key Improvements:**
- Real-time commission calculations
- Automated payout scheduling
- Commission dispute handling
- Performance-based commission tiers

**Enhanced Commission Schema:**
```sql
-- Advanced commission tracking with tiers and automation
CREATE TABLE IF NOT EXISTS commission_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sales_agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  tier_name TEXT NOT NULL,
  min_orders INTEGER NOT NULL,
  max_orders INTEGER,
  commission_rate DECIMAL(5,4) NOT NULL CHECK (commission_rate >= 0 AND commission_rate <= 1),
  valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  valid_until TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS commission_payouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sales_agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
  period_start TIMESTAMP WITH TIME ZONE NOT NULL,
  period_end TIMESTAMP WITH TIME ZONE NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
  transaction_count INTEGER NOT NULL DEFAULT 0,
  status commission_payout_status DEFAULT 'pending',
  payout_reference TEXT,
  payout_date TIMESTAMP WITH TIME ZONE,
  bank_details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4. Enhanced Vendor Menu Management (1 week)

**Key Improvements:**
- Image optimization with Supabase Storage
- Bulk menu operations
- Menu versioning and rollback
- A/B testing for menu items

**Enhanced Menu Schema:**
```sql
-- Advanced menu management with versioning
CREATE TABLE IF NOT EXISTS menu_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT false,
  published_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vendor_id, version_number)
);

CREATE TABLE IF NOT EXISTS menu_items_versioned (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  menu_version_id UUID REFERENCES menu_versions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  category_id UUID REFERENCES menu_categories(id),
  image_url TEXT,
  image_alt_text TEXT,
  is_available BOOLEAN DEFAULT true,
  preparation_time INTEGER DEFAULT 30,
  nutritional_info JSONB,
  allergen_info TEXT[],
  tags TEXT[],
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Medium Priority Features (3-5 weeks)

### 5. Smart Customer Management (CRM) (1 week)

**AI-Enhanced Features:**
- Customer behavior prediction
- Automated segmentation
- Personalized recommendations
- Churn prediction

**Flutter Implementation:**
```dart
@riverpod
class CustomerInsightsNotifier extends _$CustomerInsightsNotifier {
  Future<CustomerInsights> getCustomerInsights(String customerId) async {
    // Use Edge Function for AI-powered insights
    final response = await ref.read(supabaseProvider)
      .functions
      .invoke('customer-insights', body: {'customer_id': customerId});
    
    return CustomerInsights.fromJson(response.data);
  }
}
```

### 6. Advanced Push Notifications (1 week)

**Modern Implementation:**
- FCM with topic-based messaging
- Rich notifications with actions
- Notification scheduling
- A/B testing for notification content

**Flutter Notification Service:**
```dart
@riverpod
class NotificationService extends _$NotificationService {
  @override
  FutureOr<void> build() async {
    await _initializeNotifications();
    await _setupMessageHandlers();
  }

  Future<void> _initializeNotifications() async {
    final messaging = FirebaseMessaging.instance;
    
    // Request permissions
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get token and save to Supabase
    final token = await messaging.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }
}
```

### 7. Real-time Order Tracking with WebSockets (1-2 weeks)

**Enhanced Real-time Features:**
- Live order status updates
- Delivery tracking with GPS
- Kitchen display integration
- Customer notifications

**Supabase Real-time Implementation:**
```dart
@riverpod
class RealtimeOrderTracking extends _$RealtimeOrderTracking {
  late final RealtimeChannel _channel;

  @override
  FutureOr<OrderTrackingState> build(String orderId) async {
    await _setupRealtimeSubscription(orderId);
    return _fetchInitialOrderState(orderId);
  }

  Future<void> _setupRealtimeSubscription(String orderId) async {
    _channel = ref.read(supabaseProvider)
      .channel('order_tracking_$orderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: orderId,
        ),
        callback: (payload) {
          final updatedOrder = Order.fromJson(payload.newRecord);
          state = AsyncValue.data(
            state.value!.copyWith(order: updatedOrder)
          );
        },
      )
      .subscribe();
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    super.dispose();
  }
}
```

### 8. Advanced Search with Elasticsearch-like Features (1 week)

**Enhanced Search Capabilities:**
- Full-text search with ranking
- Faceted search and filters
- Auto-complete and suggestions
- Search analytics

**PostgreSQL Full-Text Search Enhancement:**
```sql
-- Advanced search with custom ranking
CREATE OR REPLACE FUNCTION advanced_search(
  search_query TEXT,
  filters JSONB DEFAULT '{}'::jsonb,
  sort_by TEXT DEFAULT 'relevance',
  limit_count INTEGER DEFAULT 20,
  offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
  type TEXT,
  id UUID,
  name TEXT,
  description TEXT,
  image_url TEXT,
  price DECIMAL(10,2),
  vendor_name TEXT,
  rank REAL,
  highlights TEXT[]
) AS $$
DECLARE
  ts_query tsquery;
BEGIN
  -- Create the tsquery from search terms
  ts_query := websearch_to_tsquery('english', search_query);
  
  RETURN QUERY
  WITH search_results AS (
    -- Search menu items
    SELECT 
      'menu_item' AS type,
      mi.id,
      mi.name,
      mi.description,
      mi.image_url,
      mi.price,
      v.name AS vendor_name,
      ts_rank_cd(
        mi.search_vector, 
        ts_query,
        32 /* rank with proximity */
      ) AS rank,
      ts_headline('english', mi.name || ' ' || mi.description, ts_query) AS highlight
    FROM menu_items mi
    JOIN vendors v ON mi.vendor_id = v.id
    WHERE mi.search_vector @@ ts_query
      AND mi.is_available = true
      AND v.is_active = true
    
    UNION ALL
    
    -- Search vendors
    SELECT 
      'vendor' AS type,
      v.id,
      v.name,
      v.description,
      v.logo_url AS image_url,
      NULL::DECIMAL(10,2) AS price,
      v.name AS vendor_name,
      ts_rank_cd(v.search_vector, ts_query, 32) AS rank,
      ts_headline('english', v.name || ' ' || v.description, ts_query) AS highlight
    FROM vendors v
    WHERE v.search_vector @@ ts_query
      AND v.is_active = true
  )
  SELECT 
    sr.type,
    sr.id,
    sr.name,
    sr.description,
    sr.image_url,
    sr.price,
    sr.vendor_name,
    sr.rank,
    string_to_array(sr.highlight, ' ') AS highlights
  FROM search_results sr
  ORDER BY 
    CASE 
      WHEN sort_by = 'relevance' THEN sr.rank
      WHEN sort_by = 'price_asc' THEN sr.price
      WHEN sort_by = 'price_desc' THEN -sr.price
      ELSE sr.rank
    END DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$ LANGUAGE plpgsql STABLE;
```

## Low Priority Features (3-4 weeks)

### 9. Advanced Analytics Dashboard (1-2 weeks)

**Real-time Analytics:**
- Live sales metrics
- Performance KPIs
- Predictive analytics
- Custom reporting

**Implementation with Materialized Views:**
```sql
-- Materialized views for fast analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_sales_summary AS
SELECT 
  DATE_TRUNC('day', o.created_at) AS date,
  COUNT(*) AS total_orders,
  SUM(o.total_amount) AS total_revenue,
  SUM(o.commission_amount) AS total_commission,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  COUNT(DISTINCT o.vendor_id) AS active_vendors,
  AVG(o.total_amount) AS avg_order_value
FROM orders o
WHERE o.status = 'delivered'
GROUP BY DATE_TRUNC('day', o.created_at);

-- Refresh materialized views automatically
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY daily_sales_summary;
  REFRESH MATERIALIZED VIEW CONCURRENTLY vendor_performance_summary;
  REFRESH MATERIALIZED VIEW CONCURRENTLY sales_agent_performance_summary;
END;
$$ LANGUAGE plpgsql;

-- Schedule automatic refresh
SELECT cron.schedule('refresh-analytics', '0 */6 * * *', 'SELECT refresh_analytics_views();');
```

### 10. Smart Inventory Management (1 week)

**AI-Powered Features:**
- Demand forecasting
- Automated reorder points
- Waste reduction suggestions
- Seasonal adjustments

### 11. Advanced Bulk Order Management (1 week)

**Enhanced Features:**
- Multi-vendor coordination
- Delivery slot optimization
- Cost optimization algorithms
- Automated vendor selection

## Security Best Practices

### 1. Row Level Security (RLS) Policies
```sql
-- Comprehensive RLS policies
CREATE POLICY "Users can only access their own data" ON user_profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Sales agents can view assigned customers" ON customers
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid()
      AND up.role = 'sales_agent'
      AND (
        customers.assigned_sales_agent_id = auth.uid()
        OR customers.created_by = auth.uid()
      )
    )
  );
```

### 2. API Security
```dart
// Secure API client with retry and error handling
@riverpod
class SecureApiClient extends _$SecureApiClient {
  @override
  SupabaseClient build() {
    return SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
      ),
    );
  }

  Future<T> secureRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (error) {
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(delay * (attempt + 1));
      }
    }
    throw Exception('Max retries exceeded');
  }
}
```

## Performance Optimization

### 1. Database Indexing Strategy
```sql
-- Strategic indexes for common query patterns
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_status_date 
  ON orders(customer_id, status, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_menu_items_vendor_available 
  ON menu_items(vendor_id, is_available) WHERE is_available = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_transactions_order_status 
  ON payment_transactions(order_id, status);
```

### 2. Flutter Performance Optimizations
```dart
// Efficient list rendering with proper pagination
@riverpod
class PaginatedOrderList extends _$PaginatedOrderList {
  @override
  FutureOr<PaginatedResult<Order>> build({
    int page = 1,
    int limit = 20,
  }) async {
    return _fetchOrders(page: page, limit: limit);
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    final nextPage = await _fetchOrders(
      page: currentState.currentPage + 1,
      limit: 20,
    );

    state = AsyncValue.data(
      currentState.copyWith(
        items: [...currentState.items, ...nextPage.items],
        currentPage: nextPage.currentPage,
        hasMore: nextPage.hasMore,
      ),
    );
  }
}
```

## Testing Strategy

### 1. Unit Testing
```dart
// Comprehensive unit tests for business logic
void main() {
  group('OrderNotifier', () {
    late ProviderContainer container;
    late MockOrderRepository mockRepository;

    setUp(() {
      mockRepository = MockOrderRepository();
      container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    test('should create order successfully', () async {
      // Arrange
      final request = CreateOrderRequest(/* ... */);
      final expectedOrder = Order(/* ... */);
      when(() => mockRepository.createOrder(request))
          .thenAnswer((_) async => expectedOrder);

      // Act
      final notifier = container.read(orderNotifierProvider.notifier);
      final result = await notifier.createOrder(request);

      // Assert
      expect(result, equals(expectedOrder));
      verify(() => mockRepository.createOrder(request)).called(1);
    });
  });
}
```

### 2. Integration Testing
```dart
// Integration tests with Supabase
void main() {
  group('Supabase Integration', () {
    late SupabaseClient supabase;

    setUpAll(() async {
      supabase = SupabaseClient(testUrl, testAnonKey);
      await supabase.auth.signInWithPassword(
        email: testEmail,
        password: testPassword,
      );
    });

    test('should create and retrieve order', () async {
      // Test full order creation flow
      final orderData = {
        'customer_id': testCustomerId,
        'vendor_id': testVendorId,
        'total_amount': 25.50,
        // ...
      };

      final response = await supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      expect(response['total_amount'], equals(25.50));
    });
  });
}
```

## Deployment Strategy

### 1. Environment Management
```yaml
# .env.example
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Development
ENVIRONMENT=development
DEBUG=true

# Production
ENVIRONMENT=production
DEBUG=false
```

### 2. CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter analyze

  deploy-backend:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase db push --linked
      - run: supabase functions deploy

  deploy-frontend:
    needs: [test, deploy-backend]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build web --release
```

## Monitoring and Observability

### 1. Error Tracking
```dart
// Comprehensive error tracking
@riverpod
class ErrorTracker extends _$ErrorTracker {
  void logError(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  }) {
    // Log to multiple services
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      context: context,
    );

    // Log to Supabase for backend errors
    if (error is SupabaseException) {
      ref.read(supabaseProvider)
          .from('error_logs')
          .insert({
            'error_message': error.message,
            'error_code': error.statusCode,
            'context': context,
            'user_id': ref.read(authProvider).currentUser?.id,
            'timestamp': DateTime.now().toIso8601String(),
          });
    }
  }
}
```

### 2. Performance Monitoring
```dart
// Performance monitoring with custom metrics
@riverpod
class PerformanceMonitor extends _$PerformanceMonitor {
  void trackApiCall(String endpoint, Duration duration) {
    FirebasePerformance.instance
        .newHttpMetric(endpoint, HttpMethod.Post)
        .setResponsePayloadSize(1024)
        .setRequestPayloadSize(512)
        .setHttpResponseCode(200)
        .setResponseContentType('application/json')
        .stop();
  }

  void trackUserAction(String action, Map<String, dynamic> properties) {
    FirebaseAnalytics.instance.logEvent(
      name: action,
      parameters: properties,
    );
  }
}
```

## Conclusion

This refined implementation plan incorporates modern Flutter and Supabase best practices, ensuring:

1. **Scalable Architecture**: Feature-based structure with proper separation of concerns
2. **Modern State Management**: Riverpod for predictable state management
3. **Security First**: Comprehensive RLS policies and secure API practices
4. **Performance Optimized**: Strategic indexing and efficient Flutter patterns
5. **Real-time Capabilities**: Full utilization of Supabase real-time features
6. **Comprehensive Testing**: Unit, integration, and end-to-end testing strategies
7. **Production Ready**: Proper CI/CD, monitoring, and deployment practices

The plan maintains the original timeline while significantly improving code quality, security, and maintainability through the adoption of current best practices in the Flutter and Supabase ecosystem.