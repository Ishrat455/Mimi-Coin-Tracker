class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String type;
  final DateTime reminderDate;
  final String recurrence;
  final bool isActive;
  final double? amount;
  final String? groupId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.reminderDate,
    this.recurrence = 'Once',
    this.isActive = true,
    this.amount,
    this.groupId,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      reminderDate: DateTime.parse(json['reminder_date'] as String),
      recurrence: json['recurrence'] as String? ?? 'Once',
      isActive: json['is_active'] as bool? ?? true,
      amount: (json['amount'] as num?)?.toDouble(),
      groupId: json['group_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'type': type,
      'reminder_date': reminderDate.toIso8601String(),
      'recurrence': recurrence,
      'is_active': isActive,
      'amount': amount,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? type,
    DateTime? reminderDate,
    String? recurrence,
    bool? isActive,
    double? amount,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      reminderDate: reminderDate ?? this.reminderDate,
      recurrence: recurrence ?? this.recurrence,
      isActive: isActive ?? this.isActive,
      amount: amount ?? this.amount,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
