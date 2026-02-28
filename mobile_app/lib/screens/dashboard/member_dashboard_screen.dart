import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ApiService.get('/dashboard/member-stats');
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body));
      }
    } catch (e) {
      // ignore
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
    final user = context.read<AuthProvider>().user;
    
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const Center(child: Text('Failed to load stats'));

    final formatCur = (num v) => '₹${v.toStringAsFixed(0)}';

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome back, ${user?.name ?? ''}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('My Credit Score', '${user?.creditScore ?? 500}', Icons.star, Colors.amber),
              _buildStatCard('Total Contributed', formatCur(_stats!['total_contributed'] ?? 0), Icons.savings, Colors.blue),
              _buildStatCard('Outstanding Loans', formatCur(_stats!['outstanding_loans'] ?? 0), Icons.money_off, Colors.redAccent),
              _buildStatCard('Pending Approvals', '${_stats!['pending_loans'] ?? 0}', Icons.hourglass_empty, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info),
              title: Text('Use the bottom bar to navigate'),
              subtitle: Text('Check your contributions and loans.'),
            ),
          )
        ],
      ),
    );
  }
}
