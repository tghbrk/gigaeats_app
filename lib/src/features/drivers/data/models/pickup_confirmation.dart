import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'pickup_confirmation.g.dart';

/// Data class for pickup confirmation details
@JsonSerializable()
class PickupConfirmation extends Equatable {
  final String orderId;
  final DateTime confirmedAt;
  final Map<String, bool> verificationChecklist;
  final String? notes;
  final String confirmedBy;

  const PickupConfirmation({
    required this.orderId,
    required this.confirmedAt,
    required this.verificationChecklist,
    this.notes,
    required this.confirmedBy,
  });

  factory PickupConfirmation.fromJson(Map<String, dynamic> json) =>
      _$PickupConfirmationFromJson(json);

  Map<String, dynamic> toJson() => _$PickupConfirmationToJson(this);

  @override
  List<Object?> get props => [
        orderId,
        confirmedAt,
        verificationChecklist,
        notes,
        confirmedBy,
      ];

  PickupConfirmation copyWith({
    String? orderId,
    DateTime? confirmedAt,
    Map<String, bool>? verificationChecklist,
    String? notes,
    String? confirmedBy,
  }) {
    return PickupConfirmation(
      orderId: orderId ?? this.orderId,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      verificationChecklist: verificationChecklist ?? this.verificationChecklist,
      notes: notes ?? this.notes,
      confirmedBy: confirmedBy ?? this.confirmedBy,
    );
  }
}

/// Result class for pickup confirmation operations
@JsonSerializable()
class PickupConfirmationResult extends Equatable {
  final bool isSuccess;
  final String? errorMessage;
  final PickupConfirmation? confirmation;

  const PickupConfirmationResult({
    required this.isSuccess,
    this.errorMessage,
    this.confirmation,
  });

  factory PickupConfirmationResult.success(PickupConfirmation confirmation) =>
      PickupConfirmationResult(
        isSuccess: true,
        confirmation: confirmation,
      );

  factory PickupConfirmationResult.failure(String errorMessage) =>
      PickupConfirmationResult(
        isSuccess: false,
        errorMessage: errorMessage,
      );

  factory PickupConfirmationResult.fromJson(Map<String, dynamic> json) =>
      _$PickupConfirmationResultFromJson(json);

  Map<String, dynamic> toJson() => _$PickupConfirmationResultToJson(this);

  @override
  List<Object?> get props => [isSuccess, errorMessage, confirmation];
}
