class Loan {
  final int id;
  final int userId;
  final String memberName;
  final double principal;
  final double interestRate;
  final int durationMonths;
  final double interestAmount;
  final double totalPayable;
  final double remainingBalance;
  final String? purpose;
  final String status;
  final String? approvedAt;
  final String? dueDate;
  final String createdAt;

  Loan({
    required this.id,
    required this.userId,
    required this.memberName,
    required this.principal,
    required this.interestRate,
    required this.durationMonths,
    required this.interestAmount,
    required this.totalPayable,
    required this.remainingBalance,
    this.purpose,
    required this.status,
    this.approvedAt,
    this.dueDate,
    required this.createdAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      userId: json['user_id'],
      memberName: json['member_name'] ?? '',
      principal: double.tryParse(json['principal'].toString()) ?? 0.0,
      interestRate: double.tryParse(json['interest_rate'].toString()) ?? 0.0,
      durationMonths: json['duration_months'],
      interestAmount: double.tryParse(json['interest_amount'].toString()) ?? 0.0,
      totalPayable: double.tryParse(json['total_payable'].toString()) ?? 0.0,
      remainingBalance: double.tryParse(json['remaining_balance'].toString()) ?? 0.0,
      purpose: json['purpose'],
      status: json['status'],
      approvedAt: json['approved_at'],
      dueDate: json['due_date'],
      createdAt: json['created_at'],
    );
  }
}
