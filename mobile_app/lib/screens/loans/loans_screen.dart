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
    IconData icon = Icons.help_outline_rounded;
    if (status == 'active') { bg = const Color(0xFF10B981); icon = Icons.verified_rounded; }
    if (status == 'pending') { bg = const Color(0xFFF59E0B); icon = Icons.schedule_rounded; }
    if (status == 'rejected' || status == 'defaulted') { bg = const Color(0xFFEF4444); icon = Icons.error_rounded; }
    if (status == 'closed') { bg = const Color(0xFF2563EB); icon = Icons.task_alt_rounded; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: bg),
          const SizedBox(width: 4),
          Text(status.toUpperCase(), style: TextStyle(color: bg, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Loans Management', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLoans,
        edgeOffset: 20,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // Stats row
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _miniStat('Total Requests', '${_loans.length}', const Color(0xFF2563EB), Icons.list_alt_rounded),
                  _miniStat('Pending', '${counts['pending']}', const Color(0xFFF59E0B), Icons.hourglass_empty_rounded),
                  _miniStat('Active', '${counts['active']}', const Color(0xFF10B981), Icons.trending_up_rounded),
                  _miniStat('Outstanding', _fmt(totalActive), const Color(0xFFEF4444), Icons.account_balance_wallet_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filterTabs.map((f) {
                  final isSelected = _filter == f;
                  final bg = isSelected ? const Color(0xFF2563EB) : Colors.white;
                  final fg = isSelected ? Colors.white : const Color(0xFF475569);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _filter = f),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.transparent : Colors.blueGrey.shade100),
                          boxShadow: isSelected ? [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Text(
                          '${f[0].toUpperCase()}${f.substring(1)}',
                          style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            // Loans list
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blueGrey.shade50)),
                child: Center(child: Text('No loans found matching your filter', style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500))),
              )
            else
              ...filtered.map((l) {
                final pct = l.totalPayable > 0 ? ((l.totalPayable - l.remainingBalance) / l.totalPayable * 100).round() : 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blueGrey.shade50),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l.memberName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                                        if (l.purpose != null && l.purpose!.isNotEmpty)
                                          Text(l.purpose!, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  _buildStatusBadge(l.status),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _labelValue('Principal', _fmt(l.principal)),
                                  _labelValue('Remaining', _fmt(l.remainingBalance), color: l.remainingBalance > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                                  _labelValue('Duration', '${l.durationMonths} mo'),
                                ],
                              ),
                              if (l.status == 'active' || l.status == 'closed') ...[
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Payment Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400)),
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
                            ],
                          ),
                        ),
                        if (isAdmin && l.status == 'pending')
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50.withOpacity(0.3),
                              border: Border(top: BorderSide(color: Colors.blueGrey.shade50)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _approve(l.id),
                                    icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                    label: const Text('Approve', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Container(width: 1, height: 24, color: Colors.blueGrey.shade100),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _reject(l.id),
                                    icon: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20),
                                    label: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showRecordLoanDialog,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record Loan', style: TextStyle(fontWeight: FontWeight.bold)),
              elevation: 4,
            )
          : null,
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

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 16),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
