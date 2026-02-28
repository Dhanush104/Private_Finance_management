import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  String _groupName = '';
  double _subscription = 0;
  double _interest = 0;
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await ApiService.get('/group');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['config'];
        setState(() {
          _groupName = data['group_name'];
          _subscription = double.tryParse(data['monthly_subscription'].toString()) ?? 0.0;
          _interest = double.tryParse(data['interest_rate'].toString()) ?? 0.0;
        });
      }
    } catch (e) {
      //
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addFunds() async {
    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt <= 0 || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid input')));
      return;
    }
    setState(() => _adding = true);
    try {
      final res = await ApiService.post('/group/add-funds', body: {
        'amount': amt,
        'description': _descController.text,
      });
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds added successfully!')));
        _amountController.clear();
        _descController.clear();
        FocusScope.of(context).unfocus();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
      }
    } catch (e) {
      //
    } finally {
      setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Group Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(title: const Text('Group Name'), subtitle: Text(_groupName)),
                ListTile(title: const Text('Monthly Subscription'), subtitle: Text('₹$_subscription')),
                ListTile(title: const Text('Interest Rate'), subtitle: Text('$_interest%')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Add Funds to Pool', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description / Source', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _adding ? null : _addFunds,
                  icon: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add),
                  label: Text(_adding ? 'Adding...' : 'Add Funds'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
