enum UserRole {
  salesAgent('sales_agent', 'Sales Agent'),
  vendor('vendor', 'Vendor'),
  admin('admin', 'Admin'),
  customer('customer', 'Customer'),
  driver('driver', 'Driver');

  const UserRole(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.customer,
    );
  }

  bool get isSalesAgent => this == UserRole.salesAgent;
  bool get isVendor => this == UserRole.vendor;
  bool get isAdmin => this == UserRole.admin;
  bool get isCustomer => this == UserRole.customer;
  bool get isDriver => this == UserRole.driver;
}
