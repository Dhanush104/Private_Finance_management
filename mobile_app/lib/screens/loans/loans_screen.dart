import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/loan.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<Loan> _loans = [];
  List<User> _members = [];
  bool _loading = true;
  String _filter = 'all';
  double _interestRate = 0;

  final List<String> _filterTabs = ['all', 'pending', 'active', 'closed', 'rejected'];

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    try {
      final auth = context.read<AuthProvider>();
      final lRes = await ApiService.get('/loans');
      final gRes = await ApiService.get('/group');

      if (lRes.statusCode == 200 && gRes.statusCode == 200) {
        final lData = jsonDecode(lRes.body);
        final gData = jsonDecode(gRes.body);
        final List<dynamic> lList = lData['loans'] ?? [];
        setState(() {
          _loans = lList.map((j) => Loan.fromJson(j)).toList();
          _interestRate = double.tryParse(gData['config']?['interest_rate']?.toString() ?? '0') ?? 0;
        });
      }
      if (auth.isAdmin) {
        final mRes = await ApiService.get('/members');
        if (mRes.statusCode == 200) {
          final mData = jsonDecode(mRes.body);
          final List<dynamic> mList = mData['members'] ?? mData['users'] ?? [];
          setState(() => _members = mList.map((j) => User.fromJson(j)).toList());
        }
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmt(num n) => '₹${n.toStringAsFixed(0)}';

  Map<String, int> get _counts {
    final c = {'pending': 0, 'active': 0, 'closed': 0, 'rejected': 0};
    for (final l in _loans) {
      if (c.containsKey(l.status)) c[l.status] = c[l.status]! + 1;
    }
    return c;
  }

  List<Loan> get _filtered => _filter == 'all' ? _loans : _loans.where((l) => l.status == _filter).toList();

  Future<void> _approve(int id) async {
    try {
      final res = await ApiService.post('/loans/$id/approve');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan Approved & Disbursed!')));
        _fetchLoans();
      }
    } catch (e) {
      //
    }
  }

  Future<void> _reject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Loan'),
        content: const Text('Reject this loan request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await ApiService.post('/loans/$id/reject');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan Rejected')));
        _fetchLoans();
      }
    } catch (e) {
      //
    }
  }

  void _showRecordLoanDialog() {
    final principalC = TextEditingController();
    final durationC = TextEditingController(text: '1');
    final purposeC = TextEditingController();
    int? selectedUserId;
    bool saving = false;
    Map<String, double>? preview;

    void recalc(StateSetter sd) {
      final p = double.tryParse(principalC.text);
      final t = int.tryParse(durationC.text);
      if (p == null || p <= 0 || t == null || t <= 0 || _interestRate <= 0) { sd(() => preview = null); return; }
      final si = (p * _interestRate * t) / 100;
      final perMonth = (p * _interestRate) / 100;
      sd(() => preview = {'interest': si, 'total': p + si, 'perMonth': perMonth});
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sd) => AlertDialog(
          title: const Text('Record Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedUserId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Member *', border: OutlineInputBorder()),
                  items: _members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                  onChanged: (v) => sd(() => selectedUserId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: principalC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Principal (₹) *', border: OutlineInputBorder()), onChanged: (_) => recalc(sd)),
                const SizedBox(height: 12),
                TextField(controller: durationC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (months) *', border: OutlineInputBorder()), onChanged: (_) => recalc(sd)),
                const SizedBox(height: 12),
                TextField(controller: purposeC, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder())),
                if (preview != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Loan Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('SI = P × R × T / 100', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        const SizedBox(height: 6),
                        _previewRow('Rate:', '$_interestRate%/mo'),
                        _previewRow('Monthly Interest:', _fmt(preview!['perMonth']!), color: Colors.purple),
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
                if (selectedUserId == null || principalC.text.isEmpty || durationC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select member and fill required fields')));
                  return;
                }
                sd(() => saving = true);
                try {
                  final res = await ApiService.post('/loans', body: {
                    'user_id': selectedUserId,
                    'principal': double.parse(principalC.text),
                    'duration_months': int.parse(durationC.text),
                    'purpose': purposeC.text,
                  });
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan recorded!')));
                    _fetchLoans();
                  } else {
                    if (!context.mounted) return;
                    final msg = jsonDecode(res.body)['message'] ?? 'Error';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                } catch (e) {
                  // ignore
                } finally {
                  sd(() => saving = false);
                }
              },
              child: Text(saving ? 'Recording...' : 'Record'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'active') bg = Colors.green;
    if (status == 'pending') bg = Colors.orange;
    if (status == 'rejected' || status == 'defaulted') bg = Colors.red;
    if (status == 'closed') bg = Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final counts = _counts;
    final filtered = _filtered;
    final totalActive = _loans.where((l) => l.status == 'active').fold<double>(0, (s, l) => s + l.remainingBalance);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchLoans,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Stats row
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _miniStat('Total', '${_loans.length}', Colors.blue, Icons.list),
                  _miniStat('Pending', '${counts['pending']}', Colors.orange, Icons.schedule),
                  _miniStat('Active', '${counts['active']}', Colors.green, Icons.trending_up),
                  _miniStat('Outstanding', _fmt(totalActive), Colors.red, Icons.money_off),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((f) {
                  final isSelected = _filter == f;
                  final count = f == 'all' ? _loans.length : (counts[f] ?? 0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('${f[0].toUpperCase()}${f.substring(1)} ($count)'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Loans list
            if (filtered.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No loans found'))))
            else
              ...filtered.map((l) {
                final pct = l.totalPayable > 0 ? ((l.totalPayable - l.remainingBalance) / l.totalPayable * 100).round() : 0;
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
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (l.purpose != null && l.purpose!.isNotEmpty)
                                    Text(l.purpose!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            _buildStatusBadge(l.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Principal: ${_fmt(l.principal)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${l.durationMonths} mo.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Interest: ${_fmt(l.interestAmount)}', style: const TextStyle(fontSize: 13)),
                            Text('Remaining: ${_fmt(l.remainingBalance)}', style: TextStyle(fontWeight: FontWeight.bold, color: l.remainingBalance > 0 ? Colors.red : Colors.green)),
                          ],
                        ),
                        if (l.status == 'active' || l.status == 'closed') ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              minHeight: 5,
                              color: pct == 100 ? Colors.green : Colors.blue,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          Text('$pct% repaid', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                        if (isAdmin && l.status == 'pending') ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _approve(l.id),
                                icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                label: const Text('Approve', style: TextStyle(color: Colors.green, fontSize: 13)),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: () => _reject(l.id),
                                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                label: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showRecordLoanDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
