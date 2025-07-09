import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/location_service.dart';

part 'delivery_confirmation.g.dart';

/// Data class for delivery confirmation details
@JsonSerializable()
class DeliveryConfirmation extends Equatable {
  final String orderId;
  final DateTime deliveredAt;
  final String photoUrl;
  final LocationData location;
  final String? recipientName;
  final String? notes;
  final String confirmedBy;

  const DeliveryConfirmation({
    required this.orderId,
    required this.deliveredAt,
    required this.photoUrl,
    required this.location,
    this.recipientName,
    this.notes,
    required this.confirmedBy,
  });

  factory DeliveryConfirmation.fromJson(Map<String, dynamic> json) =>
      _$DeliveryConfirmationFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryConfirmationToJson(this);

  @override
  List<Object?> get props => [
        orderId,
        deliveredAt,
        photoUrl,
        location,
        recipientName,
        notes,
        confirmedBy,
      ];

  DeliveryConfirmation copyWith({
    String? orderId,
    DateTime? deliveredAt,
    String? photoUrl,
    LocationData? location,
    String? recipientName,
    String? notes,
    String? confirmedBy,
  }) {
    return DeliveryConfirmation(
      orderId: orderId ?? this.orderId,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      recipientName: recipientName ?? this.recipientName,
      notes: notes ?? this.notes,
      confirmedBy: confirmedBy ?? this.confirmedBy,
    );
  }
}

/// Result class for delivery confirmation operations
@JsonSerializable()
class DeliveryConfirmationResult extends Equatable {
  final bool isSuccess;
  final String? errorMessage;
  final DeliveryConfirmation? confirmation;

  const DeliveryConfirmationResult({
    required this.isSuccess,
    this.errorMessage,
    this.confirmation,
  });

  factory DeliveryConfirmationResult.success(DeliveryConfirmation confirmation) =>
      DeliveryConfirmationResult(
        isSuccess: true,
        confirmation: confirmation,
      );

  factory DeliveryConfirmationResult.failure(String errorMessage) =>
      DeliveryConfirmationResult(
        isSuccess: false,
        errorMessage: errorMessage,
      );

  factory DeliveryConfirmationResult.fromJson(Map<String, dynamic> json) =>
      _$DeliveryConfirmationResultFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryConfirmationResultToJson(this);

  @override
  List<Object?> get props => [isSuccess, errorMessage, confirmation];
}
