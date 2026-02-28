import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/loan.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<Loan> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    try {
      final res = await ApiService.get('/loans');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['loans'];
        setState(() {
          _loans = list.map((json) => Loan.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      final res = await ApiService.post('/loans/$id/approve');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan Approved')));
        _fetchLoans();
      }
    } catch (e) {
      //
    }
  }

  Future<void> _reject(int id) async {
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

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'active') bg = Colors.green;
    if (status == 'pending') bg = Colors.orange;
    if (status == 'rejected' || status == 'defaulted') bg = Colors.red;
    if (status == 'completed') bg = Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final isAdmin = context.read<AuthProvider>().isAdmin;

    return RefreshIndicator(
      onRefresh: _fetchLoans,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _loans.length,
        itemBuilder: (context, index) {
          final l = _loans[index];
          return Card(
            child: ListTile(
              title: Text('${l.memberName} - ₹${l.principal.toStringAsFixed(0)}'),
              subtitle: Text('Duration: ${l.durationMonths} months\nRemaining: ₹${l.remainingBalance.toStringAsFixed(0)}'),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusBadge(l.status),
                  if (isAdmin && l.status == 'pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _approve(l.id),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _reject(l.id),
                            child: const Icon(Icons.cancel, color: Colors.red, size: 20),
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
    );
  }
}
