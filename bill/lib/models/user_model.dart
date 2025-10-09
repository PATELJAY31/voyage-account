enum AppRole {
  admin,
  engineer,
  employee,
  cashier;

  String get displayName {
    switch (this) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.engineer:
        return 'Engineer';
      case AppRole.employee:
        return 'Employee';
      case AppRole.cashier:
        return 'Cashier';
    }
  }

  String get value {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.engineer:
        return 'engineer';
      case AppRole.employee:
        return 'employee';
      case AppRole.cashier:
        return 'cashier';
    }
  }

  static AppRole fromString(String value) {
    switch (value) {
      case 'admin':
        return AppRole.admin;
      case 'engineer':
        return AppRole.engineer;
      case 'employee':
        return AppRole.employee;
      case 'cashier':
        return AppRole.cashier;
      default:
        return AppRole.employee;
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  
  // Get role as enum
  AppRole get roleEnum => AppRole.fromString(role);

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'employee',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': id,
      'email': email,
      'name': name,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
