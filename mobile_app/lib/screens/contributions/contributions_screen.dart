import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/contribution.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  List<Contribution> _contributions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchContributions();
  }

  Future<void> _fetchContributions() async {
    try {
      final res = await ApiService.get('/contributions');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['contributions'];
        setState(() {
          _contributions = list.map((json) => Contribution.fromJson(json)).toList();
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
      final res = await ApiService.post('/contributions/$id/approve');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution Approved')));
        _fetchContributions();
      }
    } catch (e) {
      //
    }
  }

  Future<void> _reject(int id) async {
    try {
      final res = await ApiService.post('/contributions/$id/reject');
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution Rejected')));
        _fetchContributions();
      }
    } catch (e) {
      //
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'paid') bg = Colors.green;
    if (status == 'pending') bg = Colors.orange;
    if (status == 'missed') bg = Colors.red;
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
      onRefresh: _fetchContributions,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _contributions.length,
        itemBuilder: (context, index) {
          final c = _contributions[index];
          return Card(
            child: ListTile(
              title: Text('${c.memberName} - ${c.monthYear}'),
              subtitle: Text('Amount: ₹${c.amount.toStringAsFixed(0)}'),
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
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _reject(c.id),
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
