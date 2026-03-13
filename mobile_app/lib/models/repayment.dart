class Repayment {
  final int id;
  final int loanId;
  final String memberName;
  final double loanPrincipal;
  final double amount;
  final double principalPortion;
  final double interestPortion;
  final String? notes;
  final String createdAt;

  Repayment({
    required this.id,
    required this.loanId,
    required this.memberName,
    required this.loanPrincipal,
    required this.amount,
    required this.principalPortion,
    required this.interestPortion,
    this.notes,
    required this.createdAt,
  });

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'],
      loanId: json['loan_id'],
      memberName: json['member_name'] ?? '',
      loanPrincipal: double.tryParse(json['loan_principal'].toString()) ?? 0.0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      principalPortion: double.tryParse(json['principal_portion'].toString()) ?? 0.0,
      interestPortion: double.tryParse(json['interest_portion'].toString()) ?? 0.0,
      notes: json['notes'],
      createdAt: json['created_at'],
    );
  }
}
