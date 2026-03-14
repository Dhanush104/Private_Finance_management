class Contribution {
  final int id;
  final int userId;
  final String memberName;
  final String monthYear;
  final double amount;
  final String status;
  final String? paidAt;
  final String? notes;

  Contribution({
    required this.id,
    required this.userId,
    required this.memberName,
    required this.monthYear,
    required this.amount,
    required this.status,
    this.paidAt,
    this.notes,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      memberName: json['member_name'] ?? 'Unknown Member',
      monthYear: json['month_year'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      paidAt: json['paid_at']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}
