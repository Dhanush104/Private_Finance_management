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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final res = await ApiService.get('/dashboard/member');
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() => _stats = data['dashboard']);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Unable to load stats');
      }

      // Fetch announcement
      final gRes = await ApiService.get('/group');
      if (gRes.statusCode == 200) {
        final gData = jsonDecode(gRes.body);
        final ann = gData['config']?['announcement'];
        setState(() => _announcement = (ann != null && ann.toString().trim().isNotEmpty) ? ann.toString() : null);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Check your connection and try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradient[0].withOpacity(0.9), gradient[1]],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic n) {
    if (n == null) return '₹0';
    if (n is String) return '₹${double.tryParse(n)?.toStringAsFixed(0) ?? '0'}';
    return '₹${(n as num).toStringAsFixed(0)}';
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 64),
              const SizedBox(height: 16),
              const Text('Oops!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _fetchStats,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_stats == null) return const Center(child: Text('Unexpected error.'));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        image: DecorationImage(
          image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
          opacity: 0.03,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _fetchStats,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header with User Profile
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.indigo.shade400]),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade400, letterSpacing: 0.5),
                      ),
                      Text(
                        user?.name ?? 'Member',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Announcement banner
            if (_announcement != null)
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade600, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ANNOUNCEMENT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(_announcement!, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.0,
              children: [
                _buildCreditScoreCard(_parseInt(user?.creditScore ?? 500)),
                _buildStatCard('Contributed', _fmt(_stats!['contribution_stats']?['total_paid']), Icons.payments_rounded, [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]),
                _buildStatCard('Outstanding', _fmt(_stats!['active_loan']?['remaining_balance']), Icons.money_off_csred_rounded, [const Color(0xFFEF4444), const Color(0xFFB91C1C)]),
                _buildStatCard('Pending Loans', '${_parseInt(_stats!['pending_loans'])}', Icons.hourglass_bottom_rounded, [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            const SizedBox(height: 20),
            _actionItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'My Contributions',
              subtitle: 'Manage your monthly payments',
              color: Colors.blue,
              onTap: () => onSwitchTab?.call(1),
            ),
            _actionItem(
              icon: Icons.currency_rupee_rounded,
              title: 'My Loans',
              subtitle: 'Request new loan or pay back',
              color: Colors.green,
              onTap: () => onSwitchTab?.call(2),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditScoreCard(int score) {
    final progress = score / 1000.0;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD97706).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Credit Score', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text('$score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
            const Spacer(),
            Text(
              score > 700 ? 'Excellent' : (score > 500 ? 'Good' : 'Fair'),
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionItem({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade500)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blueGrey.shade400),
        onTap: onTap,
      ),
    );
  }
}
