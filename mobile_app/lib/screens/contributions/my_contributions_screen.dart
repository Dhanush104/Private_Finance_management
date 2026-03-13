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

  String _fmt(num n) => '₹${n.toStringAsFixed(2)}';

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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final paid = _stats['paid_months'] ?? 0;
    final total = _stats['total_months'] ?? 0;
    final missed = total - paid;
    final payRate = total > 0 ? (paid / total * 100).round() : 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Stats cards
            Row(
              children: [
                Expanded(child: _statCard('Total Paid', _fmt((_stats['total_paid'] ?? 0).toDouble()), Colors.green, Icons.trending_up)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Months Paid', '$paid / $total', Colors.blue, Icons.check_circle, progress: payRate / 100)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Missed', '$missed', missed > 0 ? Colors.red : Colors.green, missed > 0 ? Icons.cancel : Icons.check_circle)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Contribution History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_contributions.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No contributions recorded yet'))))
            else
              ..._contributions.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: Icon(
                    c.status == 'paid' ? Icons.check_circle : c.status == 'missed' ? Icons.cancel : Icons.schedule,
                    color: c.status == 'paid' ? Colors.green : c.status == 'missed' ? Colors.red : Colors.orange,
                  ),
                  title: Row(
                    children: [
                      Text(c.monthYear, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      _buildStatusBadge(c.status),
                    ],
                  ),
                  subtitle: Text(
                    c.paidAt != null
                        ? 'Paid: ${DateTime.tryParse(c.paidAt!)?.toLocal().toString().substring(0, 10) ?? c.paidAt}'
                        : (c.notes ?? ''),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Text(
                    c.amount > 0 ? _fmt(c.amount) : '—',
                    style: TextStyle(fontWeight: FontWeight.bold, color: c.status == 'paid' ? Colors.green : Colors.grey),
                  ),
                ),
              )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordContributionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record'),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon, {double? progress}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            if (progress != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, minHeight: 4, color: color, backgroundColor: color.withOpacity(0.15)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
