// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorNotificationPreferences _$VendorNotificationPreferencesFromJson(
  Map<String, dynamic> json,
) => VendorNotificationPreferences(
  newOrders: json['newOrders'] as bool? ?? true,
  orderStatusChanges: json['orderStatusChanges'] as bool? ?? true,
  orderCancellations: json['orderCancellations'] as bool? ?? true,
  orderPayments: json['orderPayments'] as bool? ?? true,
  profileUpdates: json['profileUpdates'] as bool? ?? true,
  menuApprovals: json['menuApprovals'] as bool? ?? true,
  systemAnnouncements: json['systemAnnouncements'] as bool? ?? true,
  accountUpdates: json['accountUpdates'] as bool? ?? true,
  promotions: json['promotions'] as bool? ?? false,
  featureUpdates: json['featureUpdates'] as bool? ?? true,
  businessTips: json['businessTips'] as bool? ?? false,
  marketingCampaigns: json['marketingCampaigns'] as bool? ?? false,
  earnings: json['earnings'] as bool? ?? true,
  payouts: json['payouts'] as bool? ?? true,
  transactionAlerts: json['transactionAlerts'] as bool? ?? true,
  paymentFailures: json['paymentFailures'] as bool? ?? true,
  emailNotifications: json['emailNotifications'] as bool? ?? true,
  pushNotifications: json['pushNotifications'] as bool? ?? true,
  smsNotifications: json['smsNotifications'] as bool? ?? false,
);

Map<String, dynamic> _$VendorNotificationPreferencesToJson(
  VendorNotificationPreferences instance,
) => <String, dynamic>{
  'newOrders': instance.newOrders,
  'orderStatusChanges': instance.orderStatusChanges,
  'orderCancellations': instance.orderCancellations,
  'orderPayments': instance.orderPayments,
  'profileUpdates': instance.profileUpdates,
  'menuApprovals': instance.menuApprovals,
  'systemAnnouncements': instance.systemAnnouncements,
  'accountUpdates': instance.accountUpdates,
  'promotions': instance.promotions,
  'featureUpdates': instance.featureUpdates,
  'businessTips': instance.businessTips,
  'marketingCampaigns': instance.marketingCampaigns,
  'earnings': instance.earnings,
  'payouts': instance.payouts,
  'transactionAlerts': instance.transactionAlerts,
  'paymentFailures': instance.paymentFailures,
  'emailNotifications': instance.emailNotifications,
  'pushNotifications': instance.pushNotifications,
  'smsNotifications': instance.smsNotifications,
};
