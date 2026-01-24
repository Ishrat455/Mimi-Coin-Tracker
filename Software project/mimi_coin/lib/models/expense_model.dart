class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final String paymentMethod;
  final String? groupId;
  final bool isGroupExpense;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.paymentMethod,
    this.groupId,
    this.isGroupExpense = false,
    this.currency = 'USD',
    required this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['payment_method'] as String,
      groupId: json['group_id'] as String?,
      isGroupExpense: json['is_group_expense'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'USD',
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
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'group_id': groupId,
      'is_group_expense': isGroupExpense,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? paymentMethod,
    String? groupId,
    bool? isGroupExpense,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      groupId: groupId ?? this.groupId,
      isGroupExpense: isGroupExpense ?? this.isGroupExpense,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
