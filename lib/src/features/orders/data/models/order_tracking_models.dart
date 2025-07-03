import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'order.dart';

part 'order_tracking_models.g.dart';

/// Order tracking update types
enum OrderTrackingUpdateType {
  initialData,
  statusChange,
  locationUpdate,
  historyUpdate,
  estimatedTimeUpdate,
  driverAssigned,
  deliveryProof,
}

/// Order tracking update
class OrderTrackingUpdate extends Equatable {
  final String orderId;
  final OrderTrackingUpdateType type;
  final OrderStatus? newStatus;
  final OrderStatus? oldStatus;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final DeliveryTracking? deliveryTracking;
  final List<OrderStatusHistoryEntry>? statusHistory;
  final OrderTrackingStatus? trackingStatus;

  const OrderTrackingUpdate({
    required this.orderId,
    required this.type,
    this.newStatus,
    this.oldStatus,
    required this.message,
    required this.timestamp,
    this.data,
    this.deliveryTracking,
    this.statusHistory,
    this.trackingStatus,
  });

  @override
  List<Object?> get props => [
        orderId,
        type,
        newStatus,
        oldStatus,
        message,
        timestamp,
        data,
        deliveryTracking,
        statusHistory,
        trackingStatus,
      ];
}

/// Order tracking status
@JsonSerializable()
class OrderTrackingStatus extends Equatable {
  final String orderId;
  final String orderNumber;
  final OrderStatus currentStatus;
  final double progress;
  final List<OrderStatusHistoryEntry> statusHistory;
  final DeliveryTracking? deliveryTracking;
  final OrderEstimatedTimes estimatedTimes;
  final OrderVendorInfo vendorInfo;
  final OrderCustomerInfo customerInfo;
  final OrderDriverInfo? driverInfo;
  final DateTime lastUpdated;

  const OrderTrackingStatus({
    required this.orderId,
    required this.orderNumber,
    required this.currentStatus,
    required this.progress,
    required this.statusHistory,
    this.deliveryTracking,
    required this.estimatedTimes,
    required this.vendorInfo,
    required this.customerInfo,
    this.driverInfo,
    required this.lastUpdated,
  });

  factory OrderTrackingStatus.fromJson(Map<String, dynamic> json) =>
      _$OrderTrackingStatusFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTrackingStatusToJson(this);

  OrderTrackingStatus copyWith({
    String? orderId,
    String? orderNumber,
    OrderStatus? currentStatus,
    double? progress,
    List<OrderStatusHistoryEntry>? statusHistory,
    DeliveryTracking? deliveryTracking,
    OrderEstimatedTimes? estimatedTimes,
    OrderVendorInfo? vendorInfo,
    OrderCustomerInfo? customerInfo,
    OrderDriverInfo? driverInfo,
    DateTime? lastUpdated,
  }) {
    return OrderTrackingStatus(
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      currentStatus: currentStatus ?? this.currentStatus,
      progress: progress ?? this.progress,
      statusHistory: statusHistory ?? this.statusHistory,
      deliveryTracking: deliveryTracking ?? this.deliveryTracking,
      estimatedTimes: estimatedTimes ?? this.estimatedTimes,
      vendorInfo: vendorInfo ?? this.vendorInfo,
      customerInfo: customerInfo ?? this.customerInfo,
      driverInfo: driverInfo ?? this.driverInfo,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        orderNumber,
        currentStatus,
        progress,
        statusHistory,
        deliveryTracking,
        estimatedTimes,
        vendorInfo,
        customerInfo,
        driverInfo,
        lastUpdated,
      ];
}

/// Order status history entry
@JsonSerializable()
class OrderStatusHistoryEntry extends Equatable {
  final String id;
  final String orderId;
  final OrderStatus status;
  final String? notes;
  final String? updatedBy;
  final DateTime createdAt;

  const OrderStatusHistoryEntry({
    required this.id,
    required this.orderId,
    required this.status,
    this.notes,
    this.updatedBy,
    required this.createdAt,
  });

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusHistoryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusHistoryEntryToJson(this);

  @override
  List<Object?> get props => [id, orderId, status, notes, updatedBy, createdAt];
}

/// Delivery tracking information
@JsonSerializable()
class DeliveryTracking extends Equatable {
  final String id;
  final String orderId;
  final String? driverId;
  final double latitude;
  final double longitude;
  final String? address;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;
  final String? notes;

  const DeliveryTracking({
    required this.id,
    required this.orderId,
    this.driverId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
    this.notes,
  });

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) =>
      _$DeliveryTrackingFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryTrackingToJson(this);

  @override
  List<Object?> get props => [
        id,
        orderId,
        driverId,
        latitude,
        longitude,
        address,
        speed,
        heading,
        accuracy,
        timestamp,
        notes,
      ];
}

/// Order estimated times
@JsonSerializable()
class OrderEstimatedTimes extends Equatable {
  final DateTime? preparation;
  final DateTime? ready;
  final DateTime? delivery;

  const OrderEstimatedTimes({
    this.preparation,
    this.ready,
    this.delivery,
  });

  factory OrderEstimatedTimes.fromJson(Map<String, dynamic> json) =>
      _$OrderEstimatedTimesFromJson(json);

  Map<String, dynamic> toJson() => _$OrderEstimatedTimesToJson(this);

  @override
  List<Object?> get props => [preparation, ready, delivery];
}

/// Order vendor information
@JsonSerializable()
class OrderVendorInfo extends Equatable {
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  const OrderVendorInfo({
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  factory OrderVendorInfo.fromJson(Map<String, dynamic> json) =>
      _$OrderVendorInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderVendorInfoToJson(this);

  @override
  List<Object?> get props => [name, phone, email, address];
}

/// Order customer information
@JsonSerializable()
class OrderCustomerInfo extends Equatable {
  final String name;
  final String? phone;
  final String? email;

  const OrderCustomerInfo({
    required this.name,
    this.phone,
    this.email,
  });

  factory OrderCustomerInfo.fromJson(Map<String, dynamic> json) =>
      _$OrderCustomerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCustomerInfoToJson(this);

  @override
  List<Object?> get props => [name, phone, email];
}

/// Order driver information
@JsonSerializable()
class OrderDriverInfo extends Equatable {
  final String name;
  final String? phone;
  final String? vehicleInfo;
  final String? plateNumber;

  const OrderDriverInfo({
    required this.name,
    this.phone,
    this.vehicleInfo,
    this.plateNumber,
  });

  factory OrderDriverInfo.fromJson(Map<String, dynamic> json) =>
      _$OrderDriverInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDriverInfoToJson(this);

  @override
  List<Object?> get props => [name, phone, vehicleInfo, plateNumber];
}

/// Order tracking timeline entry
class OrderTrackingTimelineEntry extends Equatable {
  final OrderStatus status;
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool isEstimated;

  const OrderTrackingTimelineEntry({
    required this.status,
    required this.title,
    required this.description,
    this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
    required this.isEstimated,
  });

  @override
  List<Object?> get props => [
        status,
        title,
        description,
        timestamp,
        isCompleted,
        isCurrent,
        isEstimated,
      ];
}

/// Order tracking notification
class OrderTrackingNotification extends Equatable {
  final String id;
  final String orderId;
  final String title;
  final String message;
  final OrderTrackingUpdateType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const OrderTrackingNotification({
    required this.id,
    required this.orderId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data,
  });

  @override
  List<Object?> get props => [
        id,
        orderId,
        title,
        message,
        type,
        timestamp,
        isRead,
        data,
      ];
}

/// Order tracking preferences
class OrderTrackingPreferences extends Equatable {
  final bool enablePushNotifications;
  final bool enableSMSNotifications;
  final bool enableEmailNotifications;
  final bool enableLocationTracking;
  final int notificationFrequencyMinutes;

  const OrderTrackingPreferences({
    this.enablePushNotifications = true,
    this.enableSMSNotifications = false,
    this.enableEmailNotifications = false,
    this.enableLocationTracking = true,
    this.notificationFrequencyMinutes = 5,
  });

  @override
  List<Object?> get props => [
        enablePushNotifications,
        enableSMSNotifications,
        enableEmailNotifications,
        enableLocationTracking,
        notificationFrequencyMinutes,
      ];
}
