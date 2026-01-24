class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final int iconCode;
  final String color;
  final bool isDefault;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconCode,
    required this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      iconCode: json['icon_code'] as int,
      color: json['color'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon_code': iconCode,
      'color': color,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
