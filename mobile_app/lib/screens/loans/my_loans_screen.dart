import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/loan.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  List<Loan> _loans = [];
  bool _loading = true;
  double _interestRate = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id;
      final lRes = await ApiService.get('/loans');
      final gRes = await ApiService.get('/group');

      if (lRes.statusCode == 200 && gRes.statusCode == 200) {
        final lData = jsonDecode(lRes.body);
        final gData = jsonDecode(gRes.body);
        final List<dynamic> lList = lData['loans'] ?? [];
        setState(() {
          _loans = lList.map((j) => Loan.fromJson(j)).where((l) => l.userId == userId).toList();
          _interestRate = double.tryParse(gData['config']?['interest_rate']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmt(num n) => '₹${n.toStringAsFixed(2)}';

  Widget _statusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'active') bg = Colors.green;
    if (status == 'pending') bg = Colors.orange;
    if (status == 'rejected') bg = Colors.red;
    if (status == 'closed') bg = Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _showRequestLoanDialog() {
    final principalC = TextEditingController();
    final durationC = TextEditingController(text: '1');
    final purposeC = TextEditingController();
    bool saving = false;
    Map<String, double>? preview;

    void recalc(StateSetter setDialogState) {
      final p = double.tryParse(principalC.text);
      final t = int.tryParse(durationC.text);
      if (p == null || p <= 0 || t == null || t <= 0 || _interestRate <= 0) {
        setDialogState(() => preview = null);
        return;
      }
      final si = (p * _interestRate * t) / 100;
      final perMonth = (p * _interestRate) / 100;
      setDialogState(() => preview = {'interest': si, 'total': p + si, 'perMonth': perMonth});
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request a Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: principalC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Principal Amount (₹) *', border: OutlineInputBorder()),
                  onChanged: (_) => recalc(setDialogState),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (months) *', border: OutlineInputBorder()),
                  onChanged: (_) => recalc(setDialogState),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeC,
                  decoration: const InputDecoration(labelText: 'Purpose (optional)', border: OutlineInputBorder()),
                ),
                if (preview != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Loan Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('SI = P × R × T / 100', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        _previewRow('Interest Rate:', '$_interestRate% per month'),
                        _previewRow('Per Month Interest:', _fmt(preview!['perMonth']!), color: Colors.purple),
                        _previewRow('Total Interest:', _fmt(preview!['interest']!), color: Colors.orange),
                        _previewRow('Total Payable:', _fmt(preview!['total']!), color: Colors.red),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (principalC.text.isEmpty || durationC.text.isEmpty) return;
                setDialogState(() => saving = true);
                try {
                  final res = await ApiService.post('/loans', body: {
                    'principal': double.parse(principalC.text),
                    'duration_months': int.parse(durationC.text),
                    'purpose': purposeC.text,
                  });
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan request submitted!')));
                    _fetchAll();
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
              child: Text(saving ? 'Submitting...' : 'Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: _loans.isEmpty
            ? const Center(child: Text('No loan requests yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _loans.length,
                itemBuilder: (context, index) {
                  final l = _loans[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(l.principal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              _statusBadge(l.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoChip('Interest', _fmt(l.interestAmount), Colors.orange),
                              const SizedBox(width: 6),
                              _infoChip('Total', _fmt(l.totalPayable), Colors.blue),
                              const SizedBox(width: 6),
                              _infoChip('${l.durationMonths} mo.', '', Colors.purple, iconOnly: true),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Remaining: ${_fmt(l.remainingBalance)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: l.remainingBalance > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                              Text(
                                l.dueDate != null
                                    ? 'Due: ${DateTime.tryParse(l.dueDate!)?.toLocal().toString().substring(0, 10) ?? l.dueDate}'
                                    : '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (l.purpose != null && l.purpose!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Purpose: ${l.purpose}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestLoanDialog,
        icon: const Icon(Icons.add),
        label: const Text('Request Loan'),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color, {bool iconOnly = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        iconOnly ? label : '$label: $value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
