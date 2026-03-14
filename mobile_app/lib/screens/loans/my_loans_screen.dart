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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Loans', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        edgeOffset: 20,
        child: _loans.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_rounded, size: 64, color: Colors.blueGrey.shade200),
                    const SizedBox(height: 16),
                    Text('No loan records found', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: _loans.length,
                itemBuilder: (context, index) {
                  final l = _loans[index];
                  final pct = l.totalPayable > 0 ? ((l.totalPayable - l.remainingBalance) / l.totalPayable * 100).round() : 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.blueGrey.shade50),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(l.principal).split('.')[0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
                              _statusBadge(l.status),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _infoChip('Interest', _fmt(l.interestAmount).split('.')[0], const Color(0xFFF59E0B)),
                              const SizedBox(width: 8),
                              _infoChip('Total', _fmt(l.totalPayable).split('.')[0], const Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              _infoChip('${l.durationMonths} mo', '', const Color(0xFF7C3AED), iconOnly: true),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _labelValue('Remaining Balance', _fmt(l.remainingBalance), color: l.remainingBalance > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                              if (l.dueDate != null)
                                _labelValue('Next Due', DateTime.tryParse(l.dueDate!)?.toLocal().toString().substring(0, 10) ?? l.dueDate!),
                            ],
                          ),
                          if (l.status == 'active' || l.status == 'closed') ...[
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Repayment Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400)),
                                    Text('$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: pct == 100 ? const Color(0xFF10B981) : const Color(0xFF2563EB))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    minHeight: 6,
                                    color: pct == 100 ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                    backgroundColor: Colors.blueGrey.shade100.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (l.purpose != null && l.purpose!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text('Purpose: ${l.purpose}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w500)),
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
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request Loan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Widget _labelValue(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color ?? const Color(0xFF0F172A), letterSpacing: -0.5)),
      ],
    );
  }

  Widget _infoChip(String label, String value, Color color, {bool iconOnly = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.1))),
      child: Text(
        iconOnly ? label : '$label: ₹$value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
