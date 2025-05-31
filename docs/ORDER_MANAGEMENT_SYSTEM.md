# GigaEats Order Management System

## 🎯 Overview

The GigaEats Order Management System provides comprehensive backend functionality for handling orders, tracking, notifications, and inventory management with Malaysian market-specific features.

## 🏗️ Architecture

### **Database Schema**

#### **Enhanced Orders Table**
```sql
-- Core order fields (existing)
id, order_number, status, vendor_id, customer_id, sales_agent_id
delivery_date, delivery_address, subtotal, delivery_fee, sst_amount, total_amount
payment_status, payment_method, payment_reference, notes, metadata
created_at, updated_at

-- New tracking fields
estimated_delivery_time, actual_delivery_time, preparation_started_at
ready_at, out_for_delivery_at

-- Malaysian specific fields  
delivery_zone, special_instructions, contact_phone
```

#### **Order Status History Table**
```sql
CREATE TABLE order_status_history (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  old_status order_status_enum,
  new_status order_status_enum,
  changed_by UUID REFERENCES users(id),
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE
);
```

#### **Order Notifications Table**
```sql
CREATE TABLE order_notifications (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  recipient_id UUID REFERENCES users(id),
  notification_type TEXT, -- 'status_change', 'payment_update', 'delivery_update'
  title TEXT,
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB
);
```

### **Database Functions & Triggers**

#### **1. Order Number Generation**
```sql
CREATE FUNCTION generate_order_number() RETURNS TEXT
-- Format: GE-YYYYMMDD-XXXX (e.g., GE-20241201-0001)
```

#### **2. Order Validation**
```sql
CREATE FUNCTION validate_order_creation() RETURNS TRIGGER
-- Validates vendor exists, generates order number, sets estimated delivery time
```

#### **3. Inventory Management**
```sql
CREATE FUNCTION check_inventory_on_order_item() RETURNS TRIGGER
-- Checks stock availability and updates inventory when items are ordered
```

#### **4. Status Change Handling**
```sql
CREATE FUNCTION handle_order_status_change() RETURNS TRIGGER
-- Updates timestamps, creates status history, sends notifications
```

#### **5. Inventory Restoration**
```sql
CREATE FUNCTION restore_inventory_on_cancel() RETURNS TRIGGER
-- Restores inventory when orders are cancelled
```

#### **6. Customer Statistics Update**
```sql
CREATE FUNCTION update_customer_stats_on_delivery() RETURNS TRIGGER
-- Updates customer spending and order statistics when orders are delivered
```

## 🔧 Backend Features

### **1. Order Creation**
- ✅ Automatic order number generation (GE-YYYYMMDD-XXXX format)
- ✅ Order validation (vendor exists, items available)
- ✅ Inventory checking and stock updates
- ✅ Pricing calculation with Malaysian SST
- ✅ Delivery fee calculation based on zones
- ✅ RLS policies for secure access

### **2. Order Tracking**
- ✅ Real-time status updates via Supabase subscriptions
- ✅ Automatic timestamp tracking for each status
- ✅ Status history audit trail
- ✅ Estimated vs actual delivery time tracking
- ✅ Preparation and ready time tracking

### **3. Notification System**
- ✅ Automatic notifications for status changes
- ✅ Real-time notification streams
- ✅ Read/unread status management
- ✅ Notification metadata for rich content
- ✅ Multi-recipient support (vendor, sales agent, customer)

### **4. Inventory Management**
- ✅ Stock quantity tracking per menu item
- ✅ Low stock threshold alerts
- ✅ Automatic stock deduction on order
- ✅ Stock restoration on cancellation
- ✅ Optional inventory tracking per item

### **5. Malaysian Market Features**
- ✅ MYR currency support
- ✅ Malaysian payment methods (FPX, GrabPay, Touch 'n Go)
- ✅ SST (Sales and Service Tax) calculation
- ✅ Delivery zones for Malaysian cities
- ✅ Malaysian phone number format (+60)
- ✅ Local address format support

## 📱 Flutter Integration

### **Models**

#### **Enhanced Order Model**
```dart
class Order {
  // Core fields
  final String id, orderNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  
  // Enhanced tracking
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DateTime? preparationStartedAt;
  final DateTime? readyAt;
  final DateTime? outForDeliveryAt;
  
  // Malaysian specific
  final String? deliveryZone;
  final String? specialInstructions;
  final String? contactPhone;
}
```

#### **Order Status History Model**
```dart
class OrderStatusHistory {
  final String id, orderId;
  final OrderStatus? oldStatus;
  final OrderStatus newStatus;
  final String? changedBy;
  final String? reason;
  final DateTime createdAt;
}
```

#### **Order Notification Model**
```dart
class OrderNotification {
  final String id, orderId, recipientId;
  final NotificationType notificationType;
  final String title, message;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;
  
  // Helper methods
  bool get isUnread => !isRead;
  int get ageInMinutes;
  bool get isRecent;
  OrderNotification markAsRead();
}
```

### **Repository Methods**

#### **Order Repository**
```dart
class OrderRepository {
  // Core CRUD
  Future<List<Order>> getOrders({filters});
  Future<Order?> getOrderById(String id);
  Future<Order> createOrder(Order order);
  Future<Order> updateOrderStatus(String id, OrderStatus status);
  
  // Enhanced tracking
  Future<Order> updateOrderTracking(String id, {tracking_fields});
  Future<List<OrderStatusHistory>> getOrderStatusHistory(String id);
  
  // Notifications
  Future<List<OrderNotification>> getOrderNotifications({filters});
  Future<void> markNotificationAsRead(String id);
  Future<int> getUnreadNotificationCount();
  Stream<List<OrderNotification>> getOrderNotificationsStream();
  
  // Real-time streams
  Stream<List<Order>> getOrdersStream({filters});
  Stream<Order?> getOrderStream(String id);
}
```

### **Providers (Riverpod)**

#### **Order Management Providers**
```dart
// Core providers
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>;
final orderProvider = FutureProvider.family<Order?, String>;

// Enhanced tracking
final orderTrackingProvider = StateNotifierProvider.family<OrderTrackingNotifier, AsyncValue<Order?>, String>;
final orderStatusHistoryProvider = FutureProvider.family<List<OrderStatusHistory>, String>;

// Notifications
final orderNotificationsProvider = FutureProvider<List<OrderNotification>>;
final unreadNotificationCountProvider = FutureProvider<int>;
final orderNotificationsStreamProvider = StreamProvider<List<OrderNotification>>;
final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<OrderNotification>>>;
```

## 🔒 Security & RLS Policies

### **Order Access Control**
```sql
-- Vendors can view/update own orders
CREATE POLICY "Vendors can manage own orders" ON orders
  FOR ALL USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

-- Sales agents can manage assigned orders  
CREATE POLICY "Sales agents can manage own orders" ON orders
  FOR ALL USING (sales_agent_id = auth.uid());

-- Admins can manage all orders
CREATE POLICY "Admins can manage all orders" ON orders
  FOR ALL USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));
```

### **Notification Access Control**
```sql
-- Users can only view their own notifications
CREATE POLICY "Users can view own notifications" ON order_notifications
  FOR SELECT USING (recipient_id = auth.uid());
```

## 🧪 Testing

### **Test Coverage**
- ✅ Order creation with validation
- ✅ Status transition logic
- ✅ Notification generation
- ✅ Inventory management
- ✅ Malaysian market features
- ✅ Real-time updates
- ✅ Error handling

### **Test Files**
- `test/order_management_test.dart` - Comprehensive unit tests
- Integration tests for real-time features
- End-to-end tests for order lifecycle

## 🚀 Deployment

### **Database Migration**
```bash
# Apply the enhanced order management migration
supabase db reset
# or
supabase migration up
```

### **Flutter Code Generation**
```bash
# Generate JSON serialization code
flutter packages pub run build_runner build
```

## 📊 Performance Optimizations

### **Database Indexes**
```sql
-- Order performance indexes
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_delivery_date ON orders(delivery_date);
CREATE INDEX idx_order_notifications_recipient_id ON order_notifications(recipient_id);
CREATE INDEX idx_order_notifications_is_read ON order_notifications(is_read);
```

### **Real-time Optimization**
- Efficient Supabase subscription filters
- Pagination for large order lists
- Lazy loading for order details
- Optimized notification streams

## 🔄 Future Enhancements

### **Planned Features**
- [ ] Multi-vendor order splitting
- [ ] Advanced delivery routing
- [ ] Integration with Malaysian payment gateways
- [ ] Push notifications via FCM
- [ ] Order analytics dashboard
- [ ] Automated inventory reordering
- [ ] Customer loyalty program integration

### **Scalability Considerations**
- Database partitioning for large order volumes
- Caching strategies for frequently accessed data
- Background job processing for heavy operations
- API rate limiting and throttling
