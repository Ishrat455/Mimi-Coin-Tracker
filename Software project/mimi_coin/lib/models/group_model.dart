class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String createdBy; // Maps to 'created_by' in database
  final String currency;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<GroupMember>? members;

  // Alias for backward compatibility
  String get adminId => createdBy;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.currency = 'USD',
    this.inviteCode,
    required this.createdAt,
    this.updatedAt,
    this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      currency: json['currency'] as String? ?? 'USD',
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'currency': currency,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    String? currency,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GroupMember>? members,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      currency: currency ?? this.currency,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
    );
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String role; // 'admin' or 'member'
  final double balance; // Calculated locally, not stored in DB
  final DateTime joinedAt;

  // Helper getter for backward compatibility
  bool get isAdmin => role == 'admin';

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.userName,
    this.userEmail,
    this.role = 'member',
    this.balance = 0.0,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      role: json['role'] as String? ?? 'member',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? userName,
    String? userEmail,
    String? role,
    double? balance,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      balance: balance ?? this.balance,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class ExpenseSplit {
  final String id;
  final String expenseId;
  final String userId;
  final String? userName;
  final double amount;
  final double? percentage;
  final bool isPaid;
  final DateTime createdAt;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    this.userName,
    required this.amount,
    this.percentage,
    this.isPaid = false,
    required this.createdAt,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      isPaid: json['is_paid'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'user_name': userName,
      'amount': amount,
      'percentage': percentage,
      'is_paid': isPaid,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
