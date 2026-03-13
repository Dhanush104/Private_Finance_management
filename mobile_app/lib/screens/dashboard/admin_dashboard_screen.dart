import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/transaction.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Transaction> _recentLedger = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ApiService.get('/dashboard/admin');
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body)['dashboard']);
      }
      // Fetch recent ledger
      final tRes = await ApiService.get('/transactions?limit=10&offset=0');
      if (tRes.statusCode == 200) {
        final tData = jsonDecode(tRes.body);
        final List<dynamic> list = tData['transactions'] ?? [];
        setState(() => _recentLedger = list.map((j) => Transaction.fromJson(j)).toList());
      }
    } catch (e) {
      // Error fetching stats
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey))),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'contribution': return Colors.green;
      case 'loan_disbursement': return Colors.orange;
      case 'repayment': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _fmt(num n) => '₹${n.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const Center(child: Text('Failed to load stats'));

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _buildStatCard('Group Fund', _fmt(_stats!['total_fund'] ?? 0), Icons.account_balance, Colors.blue),
              _buildStatCard('Members', '${_stats!['active_members'] ?? 0}', Icons.people, Colors.purple),
              _buildStatCard('Active Loans', _fmt(_stats!['total_active_loan_principal'] ?? 0), Icons.money, Colors.orange),
              _buildStatCard('Interest Earned', _fmt(_stats!['total_interest_earned'] ?? 0), Icons.trending_up, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${_recentLedger.length} entries', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentLedger.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: Colors.grey),
                title: Text('No recent transactions'),
              ),
            )
          else
            ..._recentLedger.map((t) {
              final isDebit = t.type == 'loan_disbursement';
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _typeColor(t.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(isDebit ? Icons.arrow_downward : Icons.arrow_upward, color: _typeColor(t.type), size: 16),
                  ),
                  title: Text(t.memberName ?? 'System', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    t.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    '${isDebit ? '-' : '+'}${_fmt(t.amount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDebit ? Colors.red : Colors.green),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
