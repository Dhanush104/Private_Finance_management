import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MemberDashboardScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const MemberDashboardScreen({super.key, this.onSwitchTab});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  Map<String, dynamic>? _stats;
  String? _announcement;
  Function(int)? get onSwitchTab => widget.onSwitchTab;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await ApiService.get('/dashboard/member');
      if (res.statusCode == 200) {
        setState(() => _stats = jsonDecode(res.body)['dashboard']);
      }
      // Fetch announcement
      final gRes = await ApiService.get('/group');
      if (gRes.statusCode == 200) {
        final gData = jsonDecode(gRes.body);
        final ann = gData['config']?['announcement'];
        setState(() => _announcement = (ann != null && ann.toString().trim().isNotEmpty) ? ann.toString() : null);
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
        padding: const EdgeInsets.all(14.0),
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
          // Announcement banner
          if (_announcement != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.campaign, color: Colors.purple.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_announcement!, style: TextStyle(fontSize: 13, color: Colors.purple.shade800, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

          Text('Welcome back, ${user?.name ?? ''}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _buildStatCard('Credit Score', '${user?.creditScore ?? 500}', Icons.star, Colors.amber),
              _buildStatCard('Total Contributed', formatCur(_stats!['total_contributed'] ?? 0), Icons.savings, Colors.blue),
              _buildStatCard('Outstanding Loans', formatCur(_stats!['outstanding_loans'] ?? 0), Icons.money_off, Colors.redAccent),
              _buildStatCard('Pending Loans', '${_stats!['pending_loans'] ?? 0}', Icons.hourglass_empty, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.credit_card, color: Colors.blue.shade600),
                  title: const Text('My Contributions'),
                  subtitle: const Text('View and record your monthly payments'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate via bottom nav - tap index 1
                    if (onSwitchTab != null) onSwitchTab!(1);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.money, color: Colors.green.shade600),
                  title: const Text('My Loans'),
                  subtitle: const Text('Request loans and track repayments'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (onSwitchTab != null) onSwitchTab!(2);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
