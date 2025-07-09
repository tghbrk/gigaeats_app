/// Notification templates for the enhanced driver workflow
/// These templates define the structure and content for all workflow notifications
class DriverWorkflowNotificationTemplates {
  
  /// Get all driver workflow notification templates
  static List<Map<String, dynamic>> getAllTemplates() {
    return [
      // Driver notifications
      _driverOrderAssigned(),
      _driverDeliveryCompleted(),
      
      // Customer notifications
      _customerDriverAssigned(),
      _customerDriverEnRoutePickup(),
      _customerDriverAtVendor(),
      _customerOrderPickedUp(),
      _customerDriverEnRouteDelivery(),
      _customerDriverArrived(),
      _customerOrderDelivered(),
      
      // Vendor notifications
      _vendorDriverEnRoute(),
      _vendorDriverArrived(),
      _vendorOrderPickedUp(),
      _vendorOrderDelivered(),
      
      // Sales agent notifications
      _salesAgentOrderPickedUp(),
      _salesAgentOrderDelivered(),
    ];
  }

  // Driver notification templates
  static Map<String, dynamic> _driverOrderAssigned() => {
    'template_key': 'driver_order_assigned',
    'name': 'Driver Order Assigned',
    'description': 'Notification sent to driver when a new order is assigned',
    'title_template': '🚗 New Order Assigned',
    'message_template': 'You have been assigned order {{order_id}} from {{vendor_name}}. Navigate to {{vendor_address}} for pickup.',
    'type': 'order_assigned',
    'priority': 'high',
    'default_channels': ['in_app', 'push'],
    'category': 'driver_workflow',
    'target_roles': ['driver'],
    'required_variables': ['order_id', 'vendor_name', 'vendor_address'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _driverDeliveryCompleted() => {
    'template_key': 'driver_delivery_completed',
    'name': 'Driver Delivery Completed',
    'description': 'Confirmation notification sent to driver after successful delivery',
    'title_template': '✅ Delivery Completed',
    'message_template': 'Great job! You have successfully completed the delivery for order {{order_id}} from {{vendor_name}}.',
    'type': 'delivery_completed',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'driver_workflow',
    'target_roles': ['driver'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  // Customer notification templates
  static Map<String, dynamic> _customerDriverAssigned() => {
    'template_key': 'customer_driver_assigned',
    'name': 'Customer Driver Assigned',
    'description': 'Notification sent to customer when driver is assigned to their order',
    'title_template': '🚗 Driver Assigned',
    'message_template': 'A driver has been assigned to your order from {{vendor_name}}. Your food will be picked up soon!',
    'type': 'driver_assigned',
    'priority': 'normal',
    'default_channels': ['in_app', 'push'],
    'category': 'customer_workflow',
    'target_roles': ['customer'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _customerDriverEnRoutePickup() => {
    'template_key': 'customer_driver_en_route_pickup',
    'name': 'Customer Driver En Route to Pickup',
    'description': 'Notification sent to customer when driver is heading to restaurant',
    'title_template': '🚗 Driver En Route',
    'message_template': 'Your driver is on the way to {{vendor_name}} to pick up your order.',
    'type': 'driver_en_route',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'customer_workflow',
    'target_roles': ['customer'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _customerDriverAtVendor() => {
    'template_key': 'customer_driver_at_vendor',
    'name': 'Customer Driver at Vendor',
    'description': 'Notification sent to customer when driver arrives at restaurant',
    'title_template': '🏪 Driver at Restaurant',
    'message_template': 'Your driver has arrived at {{vendor_name}} and is collecting your order.',
    'type': 'driver_at_vendor',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'customer_workflow',
    'target_roles': ['customer'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _customerOrderPickedUp() => {
    'template_key': 'customer_order_picked_up',
    'name': 'Customer Order Picked Up',
    'description': 'Notification sent to customer when order is picked up from restaurant',
    'title_template': '📦 Order Picked Up',
    'message_template': 'Your order from {{vendor_name}} has been picked up and is on the way to {{delivery_address}}!',
    'type': 'order_picked_up',
    'priority': 'high',
    'default_channels': ['in_app', 'push'],
    'category': 'customer_workflow',
    'target_roles': ['customer'],
    'required_variables': ['order_id', 'vendor_name', 'delivery_address'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _customerDriverEnRouteDelivery() => {
    'template_key': 'customer_driver_en_route_delivery',
    'name': 'Customer Driver En Route to Delivery',
    'description': 'Notification sent to customer when driver is heading to delivery location',
    'title_template': '🚗 Driver Coming to You',
    'message_template': 'Your driver is on the way to {{delivery_address}} with your order from {{vendor_name}}!',
    'type': 'driver_en_route_delivery',
    'priority': 'high',
    'default_channels': ['in_app', 'push'],
    'category': 'customer_workflow',
    'target_roles': ['customer'],
    'required_variables': ['order_id', 'vendor_name', 'delivery_address'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _customerDriverArrived() => {
    'template_key': 'customer_driver_arrived',
    'name': 'Customer Driver Arrived',
    'description': 'Urgent notification sent to customer when driver arrives at delivery location',
    'title_template': '🚪 Driver Arrived!',
    'message_template': 'Your driver has arrived with your order from {{vendor_name}}. Please come to collect your food!',
    'type': 'driver_arrived',
    'priority': 'urgent',
    'default_channels': ['in_app', 'push'],
    'category': 'customer_workflow',
    'target_roles': ['customer'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _customerOrderDelivered() => {
    'template_key': 'customer_order_delivered',
    'name': 'Customer Order Delivered',
    'description': 'Notification sent to customer when order is successfully delivered',
    'title_template': '🎉 Order Delivered!',
    'message_template': 'Your order from {{vendor_name}} has been delivered successfully! Total: RM{{total_amount}}. Thank you for choosing GigaEats!',
    'type': 'order_delivered',
    'priority': 'high',
    'default_channels': ['in_app', 'push'],
    'category': 'customer_workflow',
    'target_roles': ['customer'],
    'required_variables': ['order_id', 'vendor_name', 'total_amount'],
    'optional_variables': [],
    'is_active': true,
  };

  // Vendor notification templates
  static Map<String, dynamic> _vendorDriverEnRoute() => {
    'template_key': 'vendor_driver_en_route',
    'name': 'Vendor Driver En Route',
    'description': 'Notification sent to vendor when driver is heading to restaurant',
    'title_template': '🚗 Driver En Route',
    'message_template': 'A driver is on the way to collect order {{order_id}}. Please prepare the order for pickup.',
    'type': 'driver_en_route',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'vendor_workflow',
    'target_roles': ['vendor'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _vendorDriverArrived() => {
    'template_key': 'vendor_driver_arrived',
    'name': 'Vendor Driver Arrived',
    'description': 'High priority notification sent to vendor when driver arrives for pickup',
    'title_template': '🚪 Driver Arrived for Pickup',
    'message_template': 'The driver has arrived to collect order {{order_id}}. Please hand over the order to the driver.',
    'type': 'driver_arrived',
    'priority': 'high',
    'default_channels': ['in_app', 'push'],
    'category': 'vendor_workflow',
    'target_roles': ['vendor'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _vendorOrderPickedUp() => {
    'template_key': 'vendor_order_picked_up',
    'name': 'Vendor Order Picked Up',
    'description': 'Confirmation notification sent to vendor when order is picked up',
    'title_template': '✅ Order Picked Up',
    'message_template': 'Order {{order_id}} has been picked up by the driver and is now on the way to the customer.',
    'type': 'order_picked_up',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'vendor_workflow',
    'target_roles': ['vendor'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _vendorOrderDelivered() => {
    'template_key': 'vendor_order_delivered',
    'name': 'Vendor Order Delivered',
    'description': 'Notification sent to vendor when order is successfully delivered',
    'title_template': '🎉 Order Delivered Successfully',
    'message_template': 'Order {{order_id}} has been delivered to the customer. Total: RM{{total_amount}}.',
    'type': 'order_delivered',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'vendor_workflow',
    'target_roles': ['vendor'],
    'required_variables': ['order_id', 'vendor_name', 'total_amount'],
    'optional_variables': [],
    'is_active': true,
  };

  // Sales agent notification templates
  static Map<String, dynamic> _salesAgentOrderPickedUp() => {
    'template_key': 'sales_agent_order_picked_up',
    'name': 'Sales Agent Order Picked Up',
    'description': 'Notification sent to sales agent when their order is picked up',
    'title_template': '📦 Order Picked Up',
    'message_template': 'Order {{order_id}} from {{vendor_name}} has been picked up and is on the way to the customer.',
    'type': 'order_picked_up',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'sales_agent_workflow',
    'target_roles': ['sales_agent'],
    'required_variables': ['order_id', 'vendor_name'],
    'optional_variables': [],
    'is_active': true,
  };

  static Map<String, dynamic> _salesAgentOrderDelivered() => {
    'template_key': 'sales_agent_order_delivered',
    'name': 'Sales Agent Order Delivered',
    'description': 'Notification sent to sales agent when their order is delivered',
    'title_template': '✅ Order Delivered',
    'message_template': 'Order {{order_id}} from {{vendor_name}} has been delivered successfully. Total: RM{{total_amount}}.',
    'type': 'order_delivered',
    'priority': 'normal',
    'default_channels': ['in_app'],
    'category': 'sales_agent_workflow',
    'target_roles': ['sales_agent'],
    'required_variables': ['order_id', 'vendor_name', 'total_amount'],
    'optional_variables': [],
    'is_active': true,
  };
}
