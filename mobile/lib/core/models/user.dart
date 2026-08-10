enum UserRole {
  customer,
  merchant,
  admin;

  static UserRole fromJson(String value) =>
      UserRole.values.firstWhere((r) => r.name == value, orElse: () => UserRole.customer);
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromJson(json['role'] as String),
      isActive: json['is_active'] as bool,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String? avatarUrl;
}
