import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/contribution.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  List<Contribution> _contributions = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  double _subscription = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id;
      final cRes = await ApiService.get('/contributions');
      final dRes = await ApiService.get('/dashboard/member');
      final gRes = await ApiService.get('/group');

      if (cRes.statusCode == 200 && dRes.statusCode == 200 && gRes.statusCode == 200) {
        final cData = jsonDecode(cRes.body);
        final dData = jsonDecode(dRes.body);
        final gData = jsonDecode(gRes.body);
        final List<dynamic> cList = cData['contributions'] ?? [];

        setState(() {
          _contributions = cList
              .map((j) => Contribution.fromJson(j))
              .where((c) => c.userId == userId)
              .toList();
          _stats = dData['dashboard']?['contribution_stats'] ?? {};
          _subscription = double.tryParse(gData['config']?['monthly_subscription']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }



  void _showRecordContributionDialog() {
    final now = DateTime.now();
    final monthYearC = TextEditingController(text: '${now.year}-${now.month.toString().padLeft(2, '0')}');
    final amountC = TextEditingController(text: _subscription > 0 ? _subscription.toStringAsFixed(0) : '');
    final notesC = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Contribution'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_subscription > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Fixed: ${_fmt(_subscription)}/month', style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
                  ),
                TextField(
                  controller: monthYearC,
                  decoration: const InputDecoration(labelText: 'Month (YYYY-MM) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountC,
                  keyboardType: TextInputType.number,
                  readOnly: _subscription > 0,
                  decoration: InputDecoration(
                    labelText: 'Amount (₹) *',
                    border: const OutlineInputBorder(),
                    helperText: _subscription > 0 ? 'Fixed monthly — cannot be changed' : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesC,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (monthYearC.text.isEmpty || amountC.text.isEmpty) return;
                setDialogState(() => saving = true);
                try {
                  final res = await ApiService.post('/contributions', body: {
                    'month_year': monthYearC.text,
                    'amount': double.parse(amountC.text),
                    'notes': notesC.text,
                  });
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution recorded!')));
                    _fetchData();
                  } else {
                    if (!context.mounted) return;
                    final msg = jsonDecode(res.body)['message'] ?? 'Error';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setDialogState(() => saving = false);
                }
              },
              child: Text(saving ? 'Recording...' : 'Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'paid') bg = Colors.green;
    if (status == 'pending') bg = Colors.orange;
    if (status == 'missed') bg = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  String _fmt(dynamic n) {
    if (n == null) return '₹0.00';
    if (n is String) return '₹${double.tryParse(n)?.toStringAsFixed(2) ?? '0.00'}';
    return '₹${(n as num).toStringAsFixed(2)}';
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

    final paid = _parseInt(_stats['paid_months']);
    final total = _parseInt(_stats['total_months']);
    final missed = total - paid;
    final payRate = total > 0 ? (paid / total * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        image: DecorationImage(
          image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
          opacity: 0.03,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Contributions', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchData,
          edgeOffset: 20,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // Stats Row
              Row(
                children: [
                  Expanded(child: _statCard('Total Paid', _fmt(_stats['total_paid']), const Color(0xFF10B981), Icons.account_balance_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _statCard('Completion', '$payRate%', const Color(0xFF2563EB), Icons.verified_user_rounded, progress: payRate / 100)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statCard('Paid Months', '$paid', const Color(0xFF6366F1), Icons.event_available_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _statCard('Pending', '$missed', missed > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981), Icons.event_busy_rounded)),
                ],
              ),
              
              const SizedBox(height: 48),
              const Text('Payment Journal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
              const SizedBox(height: 20),
              
              if (_contributions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blueGrey.shade100.withOpacity(0.5))),
                  child: Center(child: Text('No contributions found', style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600))),
                )
              else
                ..._contributions.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blueGrey.shade50),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (c.status == 'paid' ? Colors.green : (c.status == 'missed' ? Colors.red : Colors.orange)).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          c.status == 'paid' ? Icons.check_circle_rounded : c.status == 'missed' ? Icons.error_rounded : Icons.schedule_rounded,
                          color: c.status == 'paid' ? Colors.green : c.status == 'missed' ? Colors.red : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(c.monthYear, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B))),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          c.paidAt != null
                              ? 'Conf: ${DateTime.tryParse(c.paidAt!)?.toLocal().toString().substring(0, 10) ?? c.paidAt}'
                              : (c.notes ?? 'Transaction in progress'),
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500, fontWeight: FontWeight.bold),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            c.amount > 0 ? '₹${c.amount.toStringAsFixed(0)}' : '—',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: c.status == 'paid' ? const Color(0xFF1E293B) : Colors.blueGrey.shade300, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(c.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: (c.status == 'paid' ? Colors.green : (c.status == 'missed' ? Colors.red : Colors.orange)))),
                        ],
                      ),
                    ),
                  ),
                )),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showRecordContributionDialog,
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon, {double? progress}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (progress != null)
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color))
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          if (progress == null)
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 6, color: color, backgroundColor: color.withOpacity(0.1)),
            ),
          ],
        ],
      ),
    );
  }
}
