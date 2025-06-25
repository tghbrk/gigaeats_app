import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_message.freezed.dart';
part 'support_message.g.dart';

/// Support message model
@freezed
class SupportMessage with _$SupportMessage {
  const SupportMessage._();

  const factory SupportMessage({
    required String id,
    required String ticketId,
    required String senderId,
    required SenderType senderType,
    @Default(MessageType.text) MessageType messageType,
    required String content,
    @Default([]) List<String> attachments,
    @Default(false) bool isInternal,
    required DateTime createdAt,
    required DateTime updatedAt,

    // Related data
    UserInfo? sender,
  }) = _SupportMessage;

  factory SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);
}

/// User information for message senders
@freezed
class UserInfo with _$UserInfo {
  const UserInfo._();

  const factory UserInfo({
    required String id,
    required String email,
    Map<String, dynamic>? rawUserMetaData,
  }) = _UserInfo;

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);

  /// Get display name from user metadata
  String get displayName {
    if (rawUserMetaData != null) {
      final name = rawUserMetaData!['full_name'] as String?;
      if (name != null && name.isNotEmpty) return name;

      final firstName = rawUserMetaData!['first_name'] as String?;
      final lastName = rawUserMetaData!['last_name'] as String?;
      if (firstName != null || lastName != null) {
        return '${firstName ?? ''} ${lastName ?? ''}'.trim();
      }
    }

    // Fallback to email username
    return email.split('@').first;
  }

  /// Get avatar URL from user metadata
  String? get avatarUrl {
    return rawUserMetaData?['avatar_url'] as String?;
  }
}

/// Message sender types
enum SenderType {
  @JsonValue('customer')
  customer,
  @JsonValue('admin')
  admin,
  @JsonValue('sales_agent')
  salesAgent,
  @JsonValue('system')
  system,
}

/// Message types
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('file')
  file,
  @JsonValue('system')
  system,
}

/// Extensions for sender type
extension SenderTypeExtension on SenderType {
  String get displayName {
    switch (this) {
      case SenderType.customer:
        return 'Customer';
      case SenderType.admin:
        return 'Admin';
      case SenderType.salesAgent:
        return 'Support Agent';
      case SenderType.system:
        return 'System';
    }
  }

  bool get isStaff {
    return this == SenderType.admin || this == SenderType.salesAgent;
  }
}

/// Extensions for message type
extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.file:
        return 'File';
      case MessageType.system:
        return 'System';
    }
  }

  bool get hasAttachments {
    return this == MessageType.image || this == MessageType.file;
  }
}
