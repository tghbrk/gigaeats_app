import 'package:equatable/equatable.dart';

/// Model representing a payment group for collaborative spending
class PaymentGroup extends Equatable {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final List<GroupMember> members;
  final GroupType type;
  final GroupSettings settings;
  final double totalSpent;
  final int transactionCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? imageUrl;

  const PaymentGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.members,
    required this.type,
    required this.settings,
    this.totalSpent = 0.0,
    this.transactionCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.imageUrl,
  });

  factory PaymentGroup.fromJson(Map<String, dynamic> json) {
    return PaymentGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      createdBy: json['created_by'] as String,
      memberIds: List<String>.from(json['member_ids'] ?? []),
      members: (json['members'] as List<dynamic>?)
              ?.map((item) => GroupMember.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      type: GroupType.fromString(json['type'] as String),
      settings: GroupSettings.fromJson(json['settings'] as Map<String, dynamic>),
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'member_ids': memberIds,
      'members': members.map((member) => member.toJson()).toList(),
      'type': type.value,
      'settings': settings.toJson(),
      'total_spent': totalSpent,
      'transaction_count': transactionCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'image_url': imageUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdBy,
        memberIds,
        members,
        type,
        settings,
        totalSpent,
        transactionCount,
        createdAt,
        updatedAt,
        isActive,
        imageUrl,
      ];

  /// Get formatted total spent amount
  String get formattedTotalSpent => 'RM ${totalSpent.toStringAsFixed(2)}';

  /// Get average spending per member
  double get averageSpendingPerMember {
    if (members.isEmpty) return 0.0;
    return totalSpent / members.length;
  }

  /// Get formatted average spending per member
  String get formattedAverageSpending => 'RM ${averageSpendingPerMember.toStringAsFixed(2)}';

  /// Check if user is group admin
  bool isAdmin(String userId) {
    return createdBy == userId || 
           members.any((member) => member.userId == userId && member.role == GroupRole.admin);
  }

  /// Check if user is group member
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  /// Get member by user ID
  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }
}

/// Group member information
class GroupMember extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final GroupRole role;
  final double totalContributed;
  final double totalOwed;
  final DateTime joinedAt;
  final bool isActive;

  const GroupMember({
    required this.userId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    this.totalContributed = 0.0,
    this.totalOwed = 0.0,
    required this.joinedAt,
    this.isActive = true,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      role: GroupRole.fromString(json['role'] as String),
      totalContributed: (json['total_contributed'] as num?)?.toDouble() ?? 0.0,
      totalOwed: (json['total_owed'] as num?)?.toDouble() ?? 0.0,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'role': role.value,
      'total_contributed': totalContributed,
      'total_owed': totalOwed,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        email,
        phoneNumber,
        profileImageUrl,
        role,
        totalContributed,
        totalOwed,
        joinedAt,
        isActive,
      ];

  /// Get formatted total contributed amount
  String get formattedTotalContributed => 'RM ${totalContributed.toStringAsFixed(2)}';

  /// Get formatted total owed amount
  String get formattedTotalOwed => 'RM ${totalOwed.toStringAsFixed(2)}';

  /// Get net balance (positive means owed money, negative means owes money)
  double get netBalance => totalContributed - totalOwed;

  /// Get formatted net balance
  String get formattedNetBalance {
    final balance = netBalance.abs();
    final prefix = netBalance >= 0 ? '+' : '-';
    return '$prefix RM ${balance.toStringAsFixed(2)}';
  }

  /// Check if member owes money
  bool get owesMoneyToGroup => netBalance < 0;

  /// Check if member is owed money
  bool get isOwedMoneyByGroup => netBalance > 0;
}

/// Group settings and preferences
class GroupSettings extends Equatable {
  final bool allowMemberInvites;
  final bool requireApprovalForExpenses;
  final double expenseApprovalThreshold;
  final SplitMethod defaultSplitMethod;
  final bool enableNotifications;
  final bool enableReminders;
  final int reminderFrequencyDays;
  final bool isPrivate;
  final List<String> allowedCategories;

  const GroupSettings({
    this.allowMemberInvites = true,
    this.requireApprovalForExpenses = false,
    this.expenseApprovalThreshold = 100.0,
    this.defaultSplitMethod = SplitMethod.equal,
    this.enableNotifications = true,
    this.enableReminders = true,
    this.reminderFrequencyDays = 7,
    this.isPrivate = false,
    this.allowedCategories = const [],
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      allowMemberInvites: json['allow_member_invites'] as bool? ?? true,
      requireApprovalForExpenses: json['require_approval_for_expenses'] as bool? ?? false,
      expenseApprovalThreshold: (json['expense_approval_threshold'] as num?)?.toDouble() ?? 100.0,
      defaultSplitMethod: SplitMethod.fromString(json['default_split_method'] as String? ?? 'equal'),
      enableNotifications: json['enable_notifications'] as bool? ?? true,
      enableReminders: json['enable_reminders'] as bool? ?? true,
      reminderFrequencyDays: json['reminder_frequency_days'] as int? ?? 7,
      isPrivate: json['is_private'] as bool? ?? false,
      allowedCategories: List<String>.from(json['allowed_categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_member_invites': allowMemberInvites,
      'require_approval_for_expenses': requireApprovalForExpenses,
      'expense_approval_threshold': expenseApprovalThreshold,
      'default_split_method': defaultSplitMethod.value,
      'enable_notifications': enableNotifications,
      'enable_reminders': enableReminders,
      'reminder_frequency_days': reminderFrequencyDays,
      'is_private': isPrivate,
      'allowed_categories': allowedCategories,
    };
  }

  @override
  List<Object?> get props => [
        allowMemberInvites,
        requireApprovalForExpenses,
        expenseApprovalThreshold,
        defaultSplitMethod,
        enableNotifications,
        enableReminders,
        reminderFrequencyDays,
        isPrivate,
        allowedCategories,
      ];
}

/// Enumeration for group types
enum GroupType {
  family('family'),
  friends('friends'),
  roommates('roommates'),
  travel('travel'),
  project('project'),
  other('other');

  const GroupType(this.value);
  final String value;

  static GroupType fromString(String value) {
    return GroupType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => GroupType.other,
    );
  }

  String get displayName {
    switch (this) {
      case GroupType.family:
        return 'Family';
      case GroupType.friends:
        return 'Friends';
      case GroupType.roommates:
        return 'Roommates';
      case GroupType.travel:
        return 'Travel';
      case GroupType.project:
        return 'Project';
      case GroupType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case GroupType.family:
        return 'Share expenses with family members';
      case GroupType.friends:
        return 'Split bills and expenses with friends';
      case GroupType.roommates:
        return 'Manage shared household expenses';
      case GroupType.travel:
        return 'Track travel expenses and split costs';
      case GroupType.project:
        return 'Manage project-related expenses';
      case GroupType.other:
        return 'Custom group for any purpose';
    }
  }
}

/// Enumeration for group member roles
enum GroupRole {
  admin('admin'),
  member('member'),
  viewer('viewer');

  const GroupRole(this.value);
  final String value;

  static GroupRole fromString(String value) {
    return GroupRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => GroupRole.member,
    );
  }

  String get displayName {
    switch (this) {
      case GroupRole.admin:
        return 'Admin';
      case GroupRole.member:
        return 'Member';
      case GroupRole.viewer:
        return 'Viewer';
    }
  }
}

/// Enumeration for expense split methods
enum SplitMethod {
  equal('equal'),
  percentage('percentage'),
  amount('amount'),
  shares('shares');

  const SplitMethod(this.value);
  final String value;

  static SplitMethod fromString(String value) {
    return SplitMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => SplitMethod.equal,
    );
  }

  String get displayName {
    switch (this) {
      case SplitMethod.equal:
        return 'Split Equally';
      case SplitMethod.percentage:
        return 'Split by Percentage';
      case SplitMethod.amount:
        return 'Split by Amount';
      case SplitMethod.shares:
        return 'Split by Shares';
    }
  }

  String get description {
    switch (this) {
      case SplitMethod.equal:
        return 'Divide the total amount equally among all members';
      case SplitMethod.percentage:
        return 'Each member pays a specific percentage of the total';
      case SplitMethod.amount:
        return 'Each member pays a specific amount';
      case SplitMethod.shares:
        return 'Divide based on the number of shares each member has';
    }
  }
}

/// Model representing a bill splitting transaction
class BillSplit extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final double totalAmount;
  final String paidBy;
  final SplitMethod splitMethod;
  final List<BillSplitParticipant> participants;
  final String? receiptImageUrl;
  final String? category;
  final DateTime transactionDate;
  final DateTime createdAt;
  final BillSplitStatus status;
  final Map<String, dynamic>? metadata;

  const BillSplit({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.paidBy,
    required this.splitMethod,
    required this.participants,
    this.receiptImageUrl,
    this.category,
    required this.transactionDate,
    required this.createdAt,
    required this.status,
    this.metadata,
  });

  factory BillSplit.fromJson(Map<String, dynamic> json) {
    return BillSplit(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidBy: json['paid_by'] as String,
      splitMethod: SplitMethod.fromString(json['split_method'] as String),
      participants: (json['participants'] as List<dynamic>)
          .map((item) => BillSplitParticipant.fromJson(item as Map<String, dynamic>))
          .toList(),
      receiptImageUrl: json['receipt_image_url'] as String?,
      category: json['category'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: BillSplitStatus.fromString(json['status'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'description': description,
      'total_amount': totalAmount,
      'paid_by': paidBy,
      'split_method': splitMethod.value,
      'participants': participants.map((p) => p.toJson()).toList(),
      'receipt_image_url': receiptImageUrl,
      'category': category,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.value,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        description,
        totalAmount,
        paidBy,
        splitMethod,
        participants,
        receiptImageUrl,
        category,
        transactionDate,
        createdAt,
        status,
        metadata,
      ];

  /// Get formatted total amount
  String get formattedTotalAmount => 'RM ${totalAmount.toStringAsFixed(2)}';

  /// Get number of participants
  int get participantCount => participants.length;

  /// Get amount owed by a specific user
  double getAmountOwedBy(String userId) {
    final participant = participants.where((p) => p.userId == userId).firstOrNull;
    return participant?.amountOwed ?? 0.0;
  }

  /// Get formatted amount owed by a specific user
  String getFormattedAmountOwedBy(String userId) {
    final amount = getAmountOwedBy(userId);
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  /// Check if bill is fully settled
  bool get isFullySettled {
    return participants.every((p) => p.isPaid);
  }

  /// Get total amount settled
  double get totalSettled {
    return participants.where((p) => p.isPaid).fold(0.0, (sum, p) => sum + p.amountOwed);
  }

  /// Get total amount pending
  double get totalPending {
    return participants.where((p) => !p.isPaid).fold(0.0, (sum, p) => sum + p.amountOwed);
  }

  /// Get settlement percentage
  double get settlementPercentage {
    if (totalAmount == 0) return 0.0;
    return (totalSettled / totalAmount) * 100;
  }
}

/// Bill split participant information
class BillSplitParticipant extends Equatable {
  final String userId;
  final String name;
  final double amountOwed;
  final double? percentage;
  final int? shares;
  final bool isPaid;
  final DateTime? paidAt;
  final String? paymentTransactionId;

  const BillSplitParticipant({
    required this.userId,
    required this.name,
    required this.amountOwed,
    this.percentage,
    this.shares,
    this.isPaid = false,
    this.paidAt,
    this.paymentTransactionId,
  });

  factory BillSplitParticipant.fromJson(Map<String, dynamic> json) {
    return BillSplitParticipant(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      amountOwed: (json['amount_owed'] as num).toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      shares: json['shares'] as int?,
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      paymentTransactionId: json['payment_transaction_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'amount_owed': amountOwed,
      'percentage': percentage,
      'shares': shares,
      'is_paid': isPaid,
      'paid_at': paidAt?.toIso8601String(),
      'payment_transaction_id': paymentTransactionId,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        amountOwed,
        percentage,
        shares,
        isPaid,
        paidAt,
        paymentTransactionId,
      ];

  /// Get formatted amount owed
  String get formattedAmountOwed => 'RM ${amountOwed.toStringAsFixed(2)}';

  /// Get payment status display
  String get paymentStatusDisplay {
    if (isPaid) {
      return 'Paid';
    } else {
      return 'Pending';
    }
  }
}

/// Bill split status enumeration
enum BillSplitStatus {
  pending('pending'),
  partiallyPaid('partially_paid'),
  fullyPaid('fully_paid'),
  cancelled('cancelled');

  const BillSplitStatus(this.value);
  final String value;

  static BillSplitStatus fromString(String value) {
    return BillSplitStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BillSplitStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case BillSplitStatus.pending:
        return 'Pending';
      case BillSplitStatus.partiallyPaid:
        return 'Partially Paid';
      case BillSplitStatus.fullyPaid:
        return 'Fully Paid';
      case BillSplitStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Model representing a payment request
class PaymentRequest extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String toUserName;
  final double amount;
  final String title;
  final String? description;
  final String? groupId;
  final String? billSplitId;
  final DateTime dueDate;
  final DateTime createdAt;
  final PaymentRequestStatus status;
  final DateTime? respondedAt;
  final String? responseMessage;
  final List<PaymentReminder> reminders;

  const PaymentRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.toUserName,
    required this.amount,
    required this.title,
    this.description,
    this.groupId,
    this.billSplitId,
    required this.dueDate,
    required this.createdAt,
    required this.status,
    this.respondedAt,
    this.responseMessage,
    this.reminders = const [],
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      fromUserName: json['from_user_name'] as String,
      toUserName: json['to_user_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      title: json['title'] as String,
      description: json['description'] as String?,
      groupId: json['group_id'] as String?,
      billSplitId: json['bill_split_id'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: PaymentRequestStatus.fromString(json['status'] as String),
      respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at'] as String) : null,
      responseMessage: json['response_message'] as String?,
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((item) => PaymentReminder.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'from_user_name': fromUserName,
      'to_user_name': toUserName,
      'amount': amount,
      'title': title,
      'description': description,
      'group_id': groupId,
      'bill_split_id': billSplitId,
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.value,
      'responded_at': respondedAt?.toIso8601String(),
      'response_message': responseMessage,
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        fromUserName,
        toUserName,
        amount,
        title,
        description,
        groupId,
        billSplitId,
        dueDate,
        createdAt,
        status,
        respondedAt,
        responseMessage,
        reminders,
      ];

  /// Get formatted amount
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';

  /// Check if request is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status == PaymentRequestStatus.pending;
  }

  /// Get days until due
  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  /// Get days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  /// Check if request is related to a group
  bool get isGroupRequest => groupId != null;

  /// Check if request is related to a bill split
  bool get isBillSplitRequest => billSplitId != null;
}

/// Payment reminder information
class PaymentReminder extends Equatable {
  final String id;
  final String paymentRequestId;
  final DateTime sentAt;
  final String message;
  final bool isRead;

  const PaymentReminder({
    required this.id,
    required this.paymentRequestId,
    required this.sentAt,
    required this.message,
    this.isRead = false,
  });

  factory PaymentReminder.fromJson(Map<String, dynamic> json) {
    return PaymentReminder(
      id: json['id'] as String,
      paymentRequestId: json['payment_request_id'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_request_id': paymentRequestId,
      'sent_at': sentAt.toIso8601String(),
      'message': message,
      'is_read': isRead,
    };
  }

  @override
  List<Object?> get props => [id, paymentRequestId, sentAt, message, isRead];
}

/// Payment request status enumeration
enum PaymentRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  paid('paid'),
  cancelled('cancelled'),
  expired('expired');

  const PaymentRequestStatus(this.value);
  final String value;

  static PaymentRequestStatus fromString(String value) {
    return PaymentRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentRequestStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'Pending';
      case PaymentRequestStatus.accepted:
        return 'Accepted';
      case PaymentRequestStatus.declined:
        return 'Declined';
      case PaymentRequestStatus.paid:
        return 'Paid';
      case PaymentRequestStatus.cancelled:
        return 'Cancelled';
      case PaymentRequestStatus.expired:
        return 'Expired';
    }
  }
}
