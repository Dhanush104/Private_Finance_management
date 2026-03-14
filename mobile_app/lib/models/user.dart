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
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'member',
      isActive: json['is_active'] is int ? json['is_active'] : (int.tryParse(json['is_active']?.toString() ?? '1') ?? 1),
      joinedDate: json['joined_date']?.toString(),
      creditScore: json['credit_score'] is int ? json['credit_score'] : (int.tryParse(json['credit_score']?.toString() ?? '500') ?? 500),
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
