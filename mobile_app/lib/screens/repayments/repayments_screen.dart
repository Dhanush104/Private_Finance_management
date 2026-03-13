import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/repayment.dart';
import '../../models/loan.dart';

class RepaymentsScreen extends StatefulWidget {
  const RepaymentsScreen({super.key});

  @override
  State<RepaymentsScreen> createState() => _RepaymentsScreenState();
}

class _RepaymentsScreenState extends State<RepaymentsScreen> {
  List<Repayment> _repayments = [];
  List<Loan> _activeLoans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    try {
      final rRes = await ApiService.get('/repayments');
      final lRes = await ApiService.get('/loans');
      if (rRes.statusCode == 200 && lRes.statusCode == 200) {
        final rData = jsonDecode(rRes.body);
        final lData = jsonDecode(lRes.body);
        final List<dynamic> rList = rData['repayments'] ?? [];
        final List<dynamic> lList = lData['loans'] ?? [];
        setState(() {
          _repayments = rList.map((j) => Repayment.fromJson(j)).toList();
          _activeLoans = lList.map((j) => Loan.fromJson(j)).where((l) => l.status == 'active').toList();
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmt(num n) => '₹${n.toStringAsFixed(0)}';

  void _showRecordRepaymentDialog() {
    int? selectedLoanId;
    Loan? selectedLoan;
    final amountC = TextEditingController();
    final notesC = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Repayment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedLoanId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Active Loan *', border: OutlineInputBorder()),
                  items: _activeLoans.map((l) => DropdownMenuItem(
                    value: l.id,
                    child: Text('${l.memberName} — ${_fmt(l.remainingBalance)} remaining', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedLoanId = v;
                      selectedLoan = _activeLoans.firstWhere((l) => l.id == v);
                      amountC.text = selectedLoan!.remainingBalance.toStringAsFixed(0);
                    });
                  },
                ),
                if (selectedLoan != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Principal:', _fmt(selectedLoan!.principal)),
                        _infoRow('Total Payable:', _fmt(selectedLoan!.totalPayable)),
                        _infoRow('Remaining:', _fmt(selectedLoan!.remainingBalance), color: Colors.red),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: amountC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesC,
                  decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (selectedLoanId == null || amountC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a loan and enter amount')));
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  final res = await ApiService.post('/repayments', body: {
                    'loan_id': selectedLoanId,
                    'amount': double.parse(amountC.text),
                    'notes': notesC.text,
                  });
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    final resBody = jsonDecode(res.body);
                    final msg = resBody['loan_closed'] == true ? '✅ Loan fully repaid and closed!' : 'Repayment recorded!';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    _fetchAll();
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setDialogState(() => saving = false);
                }
              },
              child: Text(saving ? 'Saving...' : 'Record'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
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
        child: _repayments.isEmpty
            ? const Center(child: Text('No repayments recorded yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _repayments.length,
                itemBuilder: (context, index) {
                  final r = _repayments[index];
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
                              Text(r.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                _fmt(r.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _chip('Loan: ${_fmt(r.loanPrincipal)}', Colors.blue),
                              const SizedBox(width: 6),
                              _chip('P: ${_fmt(r.principalPortion)}', Colors.teal),
                              const SizedBox(width: 6),
                              _chip('I: ${_fmt(r.interestPortion)}', Colors.purple),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateTime.tryParse(r.createdAt)?.toLocal().toString().substring(0, 10) ?? r.createdAt,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (r.notes != null && r.notes!.isNotEmpty)
                                Flexible(
                                  child: Text(r.notes!, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRecordRepaymentDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
