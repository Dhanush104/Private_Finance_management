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
    IconData icon = Icons.help_outline_rounded;
    if (status == 'paid') {
      bg = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    }
    if (status == 'pending') {
      bg = const Color(0xFFF59E0B);
      icon = Icons.access_time_filled_rounded;
    }
    if (status == 'missed') {
      bg = const Color(0xFFEF4444);
      icon = Icons.error_rounded;
    }
    
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
          Text(
            status.toUpperCase(),
            style: TextStyle(color: bg, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final isAdmin = context.read<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Contributions', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        edgeOffset: 20,
        child: _contributions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: Colors.blueGrey.shade200),
                    const SizedBox(height: 16),
                    Text('No contributions yet', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: _contributions.length,
                itemBuilder: (context, index) {
                  final c = _contributions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: Colors.blueGrey.shade50),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(width: 6, color: c.status == 'paid' ? const Color(0xFF10B981) : (c.status == 'pending' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))),
                            Expanded(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(c.memberName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.blueGrey.shade300),
                                        const SizedBox(width: 4),
                                        Text(c.monthYear, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    if (c.paidAt != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Paid: ${DateTime.tryParse(c.paidAt!)?.toLocal().toString().substring(0, 10) ?? ''}',
                                        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${c.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                                    const SizedBox(height: 6),
                                    _buildStatusBadge(c.status),
                                  ],
                                ),
                              ),
                            ),
                            if (isAdmin && c.status == 'pending')
                              Container(
                                decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.blueGrey.shade50))),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(onPressed: () => _approve(c.id), icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28)),
                                    IconButton(onPressed: () => _reject(c.id), icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 28)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showRecordContributionDialog,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record', style: TextStyle(fontWeight: FontWeight.bold)),
              elevation: 4,
            )
          : null,
    );
  }
}
