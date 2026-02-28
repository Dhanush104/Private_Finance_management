class GroupConfig {
  final int id;
  final String groupName;
  final double monthlySubscription;
  final double interestRate;
  final double totalFund;

  GroupConfig({
    required this.id,
    required this.groupName,
    required this.monthlySubscription,
    required this.interestRate,
    required this.totalFund,
  });

  factory GroupConfig.fromJson(Map<String, dynamic> json) {
    return GroupConfig(
      id: json['id'],
      groupName: json['group_name'],
      monthlySubscription: double.tryParse(json['monthly_subscription'].toString()) ?? 0.0,
      interestRate: double.tryParse(json['interest_rate'].toString()) ?? 0.0,
      totalFund: double.tryParse(json['total_fund'].toString()) ?? 0.0,
    );
  }
}
