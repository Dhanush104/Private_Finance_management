import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/transaction.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Transaction> _recentLedger = [];
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
      final res = await ApiService.get('/dashboard/admin');
      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200) {
        setState(() => _stats = data['dashboard']);
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Server error');
      }

      // Fetch recent ledger
      final tRes = await ApiService.get('/transactions?limit=10&offset=0');
      if (tRes.statusCode == 200) {
        final tData = jsonDecode(tRes.body);
        final List<dynamic> list = tData['transactions'] ?? [];
        setState(() => _recentLedger = list.map((j) => Transaction.fromJson(j)).toList());
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection failed. Please check your internet.');
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

  Color _typeColor(String type) {
    switch (type) {
      case 'contribution': return Colors.teal;
      case 'loan_disbursement': return Colors.pink;
      case 'repayment': return Colors.blue;
      default: return Colors.blueGrey;
    }
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
        edgeOffset: 20,
        color: const Color(0xFF2563EB),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.blue.shade700,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Icon(Icons.shield_rounded, color: Colors.blue.shade600),
                ),
              ],
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.0,
              children: [
                _buildStatCard('Group Fund', _fmt(_stats!['total_fund']), Icons.account_balance_rounded, [const Color(0xFF2563EB), const Color(0xFF1E40AF)]),
                _buildStatCard('Members', '${_parseInt(_stats!['total_members'])}', Icons.people_alt_rounded, [const Color(0xFF7C3AED), const Color(0xFF5B21B6)]),
                _buildStatCard('Active Loans', _fmt(_stats!['total_loaned']), Icons.payments_rounded, [const Color(0xFFF59E0B), const Color(0xFFB45309)]),
                _buildStatCard('Interest Earned', _fmt(_stats!['total_interest_earned']), Icons.trending_up_rounded, [const Color(0xFF10B981), const Color(0xFF047857)]),
              ],
            ),
            const SizedBox(height: 36),
            
            // Monthly Contribution Chart
            if (_stats!['monthly_contributions'] != null && (_stats!['monthly_contributions'] as List).isNotEmpty)
              _buildChartCard('Financial Growth', 'Monthly Contributions'),
            
            const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Recent Ledger',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(20)),
                child: Text('${_recentLedger.length} items', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentLedger.isEmpty)
            _emptyState()
          else
            ..._recentLedger.map((t) => _transactionItem(t)),
          const SizedBox(height: 40),
        ],
      ),
    ),
   );
  }

  Widget _buildChartCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade600, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.show_chart_rounded, color: Colors.blue.shade600, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              _getLineData(),
              duration: const Duration(milliseconds: 500),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _getLineData() {
    final List<dynamic> raw = _stats!['monthly_contributions'] ?? [];
    final List<FlSpot> spots = [];
    
    for (int i = 0; i < raw.length; i++) {
        final amount = double.tryParse(raw[i]['total']?.toString() ?? '0') ?? 0;
        spots.add(FlSpot(i.toDouble(), amount));
    }

    if (spots.isEmpty) spots.add(const FlSpot(0, 0));

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF2563EB),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF2563EB).withOpacity(0.2), const Color(0xFF2563EB).withOpacity(0.0)],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => const Color(0xFF0F172A),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((s) {
              return LineTooltipItem(
                '₹${s.y.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueGrey.shade100)),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.blueGrey.shade300),
          const SizedBox(height: 16),
          Text('No recent entries', style: TextStyle(color: Colors.blueGrey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _transactionItem(Transaction t) {
    final isDebit = t.type == 'loan_disbursement';
    final typeColor = _typeColor(t.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(isDebit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: typeColor, size: 20),
        ),
        title: Text(t.memberName ?? 'System', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          t.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDebit ? '−' : '+'}${_fmt(t.amount)}',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDebit ? Colors.red.shade600 : Colors.teal.shade600),
            ),
            const SizedBox(height: 2),
            Text(t.type.replaceAll('_', ' '), style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

