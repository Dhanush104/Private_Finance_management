import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/contribution.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  List<Contribution> _contributions = [];
  List<User> _members = [];
  bool _loading = true;
  double _subscription = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    try {
      final cRes = await ApiService.get('/contributions');
      final mRes = await ApiService.get('/members');
      final gRes = await ApiService.get('/group');

      if (cRes.statusCode == 200) {
        final data = jsonDecode(cRes.body);
        final List<dynamic> list = data['contributions'] ?? [];
        setState(() => _contributions = list.map((json) => Contribution.fromJson(json)).toList());
      }
      if (mRes.statusCode == 200) {
        final data = jsonDecode(mRes.body);
        final List<dynamic> list = data['members'] ?? data['users'] ?? [];
        setState(() => _members = list.map((j) => User.fromJson(j)).where((m) => m.isActive == 1).toList());
      }
      if (gRes.statusCode == 200) {
        final data = jsonDecode(gRes.body);
        setState(() => _subscription = double.tryParse(data['config']?['monthly_subscription']?.toString() ?? '0') ?? 0);
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      final res = await ApiService.post('/contributions/$id/approve');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution Approved')));
        _fetchAll();
      }
    } catch (e) {
      //
    }
  }

  Future<void> _reject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Contribution'),
        content: const Text('Are you sure you want to reject this contribution?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await ApiService.post('/contributions/$id/reject');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution Rejected')));
        _fetchAll();
      }
    } catch (e) {
      //
    }
  }

  void _showRecordContributionDialog() {
    final now = DateTime.now();
    final monthYearC = TextEditingController(text: '${now.year}-${now.month.toString().padLeft(2, '0')}');
    final amountC = TextEditingController(text: _subscription > 0 ? _subscription.toStringAsFixed(0) : '');
    final notesC = TextEditingController();
    int? selectedUserId;
    String status = 'paid';
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
                DropdownButtonFormField<int>(
                  value: selectedUserId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Member *', border: OutlineInputBorder()),
                  items: _members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                  onChanged: (v) => setDialogState(() => selectedUserId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: monthYearC, decoration: const InputDecoration(labelText: 'Month (YYYY-MM) *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'missed', child: Text('Missed')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: notesC, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (selectedUserId == null || monthYearC.text.isEmpty || amountC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All required fields must be filled')));
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  final res = await ApiService.post('/contributions', body: {
                    'user_id': selectedUserId,
                    'month_year': monthYearC.text,
                    'amount': double.parse(amountC.text),
                    'status': status,
                    'notes': notesC.text,
                  });
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution recorded!')));
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
              child: Text(saving ? 'Saving...' : 'Record'),
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
    final isAdmin = context.read<AuthProvider>().isAdmin;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: _contributions.isEmpty
            ? const Center(child: Text('No contributions recorded yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _contributions.length,
                itemBuilder: (context, index) {
                  final c = _contributions[index];
                  return Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Flexible(child: Text(c.memberName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          const SizedBox(width: 6),
                          Text(c.monthYear, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text('₹${c.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (c.paidAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateTime.tryParse(c.paidAt!)?.toLocal().toString().substring(0, 10) ?? '',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatusBadge(c.status),
                          if (isAdmin && c.status == 'pending')
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _approve(c.id),
                                    child: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _reject(c.id),
                                    child: const Icon(Icons.cancel, color: Colors.red, size: 22),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showRecordContributionDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
