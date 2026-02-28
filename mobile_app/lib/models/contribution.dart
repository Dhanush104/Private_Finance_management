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
      id: json['id'],
      userId: json['user_id'],
      memberName: json['member_name'] ?? '',
      monthYear: json['month_year'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'],
      paidAt: json['paid_at'],
      notes: json['notes'],
    );
  }
}
