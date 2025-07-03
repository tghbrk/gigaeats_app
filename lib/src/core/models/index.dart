// Core models export file for GigaEats
// This file provides a centralized export for all core models and types

// Order-related models
export '../../features/orders/data/models/order.dart';
export '../../features/orders/data/models/order_status_history.dart';
export '../../features/orders/data/models/cart_item.dart';
export '../../features/orders/data/models/delivery_method.dart';
export '../../features/orders/data/models/customer_delivery_method.dart';

// Menu-related models
export '../../features/menu/data/models/menu_item.dart';
export '../../features/menu/data/models/vendor_filters.dart';
export '../../features/menu/data/models/order_info.dart';

// User management models
export '../../features/user_management/data/models/customer.dart';
export '../../features/user_management/data/models/vendor.dart';
export '../../features/user_management/data/models/sales_agent_profile.dart';

// Driver-related models
export '../../features/drivers/data/models/driver_location_actions.dart';

// Authentication models
export '../../features/auth/presentation/providers/auth_provider.dart' show AuthState, AuthStatus;

// Common types and enums
export '../../features/orders/data/models/order.dart' show Address;

// Re-export commonly used types for convenience
export '../../features/orders/data/models/order.dart' show Order, OrderStatus, OrderItem;
export '../../features/menu/data/models/menu_item.dart' show MenuItem, MenuItemStatus;
export '../../features/orders/data/models/delivery_method.dart' show DeliveryMethod;
export '../../features/orders/data/models/customer_delivery_method.dart' show CustomerDeliveryMethod;
export '../../features/menu/data/models/vendor_filters.dart' show VendorFilters, VendorSortOption;
export '../../features/menu/data/models/order_info.dart' show OrderInfo, OrderInfoStatus;
export '../../features/drivers/data/models/driver_location_actions.dart' show DriverLocationActions, DriverLocationActionState;
