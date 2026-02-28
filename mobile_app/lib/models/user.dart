class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int isActive;
  final String? joinedDate;
  final int creditScore;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    this.joinedDate,
    required this.creditScore,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone']?.toString(),
      role: json['role'] ?? 'member',
      isActive: json['is_active'] ?? 1,
      joinedDate: json['joined_date'],
      creditScore: json['credit_score'] ?? 500,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'joined_date': joinedDate,
      'credit_score': creditScore,
    };
  }
}
