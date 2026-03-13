class Transaction {
  final int id;
  final String type;
  final String? memberName;
  final double amount;
  final double groupFundAfter;
  final String description;
  final String createdAt;

  Transaction({
    required this.id,
    required this.type,
    this.memberName,
    required this.amount,
    required this.groupFundAfter,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'] ?? '',
      memberName: json['member_name'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      groupFundAfter: double.tryParse(json['group_fund_after'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
