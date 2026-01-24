class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String baseCurrency;
  final double? monthlyBudget;
  final double? financialGoal;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.baseCurrency = 'USD',
    this.monthlyBudget,
    this.financialGoal,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      baseCurrency: json['base_currency'] as String? ?? 'USD',
      monthlyBudget: json['monthly_budget'] != null
          ? (json['monthly_budget'] as num).toDouble()
          : null,
      financialGoal: json['financial_goal'] != null
          ? (json['financial_goal'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'base_currency': baseCurrency,
      'monthly_budget': monthlyBudget,
      'financial_goal': financialGoal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? baseCurrency,
    double? monthlyBudget,
    double? financialGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      financialGoal: financialGoal ?? this.financialGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
