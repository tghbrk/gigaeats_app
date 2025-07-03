import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_result.g.dart';

@JsonSerializable()
class PaymentResult extends Equatable {
  final bool success;
  final String? transactionId;
  final String? paymentUrl;
  final String? clientSecret;
  final PaymentResultStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime? processedAt;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.paymentUrl,
    this.clientSecret,
    required this.status,
    this.errorMessage,
    this.metadata,
    this.processedAt,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] as bool,
      transactionId: json['transaction_id'] as String?,
      paymentUrl: json['payment_url'] as String?,
      clientSecret: json['client_secret'] as String?,
      status: PaymentResultStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => PaymentResultStatus.pending,
      ),
      errorMessage: json['error_message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transaction_id': transactionId,
      'payment_url': paymentUrl,
      'client_secret': clientSecret,
      'status': status.value,
      'error_message': errorMessage,
      'metadata': metadata,
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  factory PaymentResult.success({
    required String transactionId,
    String? paymentUrl,
    String? clientSecret,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      paymentUrl: paymentUrl,
      clientSecret: clientSecret,
      status: PaymentResultStatus.completed,
      metadata: metadata,
      processedAt: DateTime.now(),
    );
  }

  factory PaymentResult.failure({
    required String errorMessage,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: false,
      transactionId: transactionId,
      status: PaymentResultStatus.failed,
      errorMessage: errorMessage,
      metadata: metadata,
      processedAt: DateTime.now(),
    );
  }

  factory PaymentResult.pending({
    required String transactionId,
    String? paymentUrl,
    String? clientSecret,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: false,
      transactionId: transactionId,
      paymentUrl: paymentUrl,
      clientSecret: clientSecret,
      status: PaymentResultStatus.pending,
      metadata: metadata,
      processedAt: DateTime.now(),
    );
  }

  PaymentResult copyWith({
    bool? success,
    String? transactionId,
    String? paymentUrl,
    String? clientSecret,
    PaymentResultStatus? status,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? processedAt,
  }) {
    return PaymentResult(
      success: success ?? this.success,
      transactionId: transactionId ?? this.transactionId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      clientSecret: clientSecret ?? this.clientSecret,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  List<Object?> get props => [
        success,
        transactionId,
        paymentUrl,
        clientSecret,
        status,
        errorMessage,
        metadata,
        processedAt,
      ];

  /// Check if payment is completed successfully
  bool get isCompleted => success && status == PaymentResultStatus.completed;

  /// Check if payment is pending
  bool get isPending => status == PaymentResultStatus.pending;

  /// Check if payment failed
  bool get isFailed => !success || status == PaymentResultStatus.failed;

  /// Get display status
  String get displayStatus => status.displayName;
}

enum PaymentResultStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded;

  static PaymentResultStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentResultStatus.pending;
      case 'completed':
        return PaymentResultStatus.completed;
      case 'failed':
        return PaymentResultStatus.failed;
      case 'cancelled':
        return PaymentResultStatus.cancelled;
      case 'refunded':
        return PaymentResultStatus.refunded;
      case 'escrowed': // Add support for marketplace-specific status
        return PaymentResultStatus.pending;
      default:
        throw ArgumentError('Invalid payment result status: $value');
    }
  }
}

extension PaymentResultStatusExtension on PaymentResultStatus {
  String get displayName {
    switch (this) {
      case PaymentResultStatus.pending:
        return 'Pending';
      case PaymentResultStatus.completed:
        return 'Completed';
      case PaymentResultStatus.failed:
        return 'Failed';
      case PaymentResultStatus.cancelled:
        return 'Cancelled';
      case PaymentResultStatus.refunded:
        return 'Refunded';
    }
  }

  String get value {
    switch (this) {
      case PaymentResultStatus.pending:
        return 'pending';
      case PaymentResultStatus.completed:
        return 'completed';
      case PaymentResultStatus.failed:
        return 'failed';
      case PaymentResultStatus.cancelled:
        return 'cancelled';
      case PaymentResultStatus.refunded:
        return 'refunded';
    }
  }


}
