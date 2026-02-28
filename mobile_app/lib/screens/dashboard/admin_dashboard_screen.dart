import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ApiService.get('/dashboard/admin-stats');
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body));
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
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const Center(child: Text('Failed to load stats'));

    final formatCur = (num v) => '₹${v.toStringAsFixed(0)}';

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
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('Group Fund', formatCur(_stats!['total_fund']), Icons.account_balance, Colors.blue),
              _buildStatCard('Members', '${_stats!['active_members']}', Icons.people, Colors.purple),
              _buildStatCard('Active Loans', formatCur(_stats!['total_active_loan_principal'] ?? 0), Icons.money, Colors.orange),
              _buildStatCard('Monthly Earned', formatCur(_stats!['total_interest_earned'] ?? 0), Icons.trending_up, Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Ledger', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Placeholder for recent ledger list
          const Card(
            child: ListTile(
              title: Text('Ledger view not fully implemented here yet.'),
              subtitle: Text('Pull to refresh data.'),
            ),
          )
        ],
      ),
    );
  }
}
