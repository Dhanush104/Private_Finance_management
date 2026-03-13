import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _subscriptionController = TextEditingController();
  final _interestController = TextEditingController();
  final _addAmountC = TextEditingController();
  final _addDescC = TextEditingController();
  final _debitAmountC = TextEditingController();
  final _debitDescC = TextEditingController();
  final _debitDateC = TextEditingController();
  final _announcementC = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _adding = false;
  bool _debiting = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subscriptionController.dispose();
    _interestController.dispose();
    _addAmountC.dispose();
    _addDescC.dispose();
    _debitAmountC.dispose();
    _debitDescC.dispose();
    _debitDateC.dispose();
    _announcementC.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    try {
      final res = await ApiService.get('/group');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['config'];
        setState(() {
          _nameController.text = data['group_name'] ?? '';
          _subscriptionController.text = data['monthly_subscription']?.toString() ?? '';
          _interestController.text = data['interest_rate']?.toString() ?? '';
          _announcementC.text = data['announcement'] ?? '';
        });
      }
    } catch (e) {
      //
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.put('/group', body: {
        'group_name': _nameController.text,
        'monthly_subscription': double.parse(_subscriptionController.text),
        'interest_rate': double.parse(_interestController.text),
      });
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
      }
    } catch (e) {
      //
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _addFunds() async {
    final amt = double.tryParse(_addAmountC.text);
    if (amt == null || amt <= 0 || _addDescC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter amount and description')));
      return;
    }
    setState(() => _adding = true);
    try {
      final res = await ApiService.post('/group/add-funds', body: {
        'amount': amt,
        'description': _addDescC.text,
      });
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds added!')));
        _addAmountC.clear();
        _addDescC.clear();
        FocusScope.of(context).unfocus();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
      }
    } catch (e) {
      //
    } finally {
      setState(() => _adding = false);
    }
  }

  Future<void> _debitFunds() async {
    final amt = double.tryParse(_debitAmountC.text);
    if (amt == null || amt <= 0 || _debitDescC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter amount and reason')));
      return;
    }
    setState(() => _debiting = true);
    try {
      final body = <String, dynamic>{
        'amount': amt,
        'description': _debitDescC.text,
      };
      if (_debitDateC.text.isNotEmpty) body['date'] = _debitDateC.text;
      final res = await ApiService.post('/group/debit-funds', body: body);
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds debited!')));
        _debitAmountC.clear();
        _debitDescC.clear();
        _debitDateC.clear();
        FocusScope.of(context).unfocus();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
      }
    } catch (e) {
      //
    } finally {
      setState(() => _debiting = false);
    }
  }

  Future<void> _publishAnnouncement() async {
    setState(() => _publishing = true);
    try {
      final res = await ApiService.put('/group/announcement', body: {
        'announcement': _announcementC.text,
      });
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement published!')));
      }
    } catch (e) {
      //
    } finally {
      setState(() => _publishing = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      _debitDateC.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Group Configuration
        const Text('Group Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Group Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _subscriptionController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Subscription (₹)', border: OutlineInputBorder(), helperText: 'Amount each member must contribute monthly')),
                const SizedBox(height: 12),
                TextField(controller: _interestController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Interest Rate (%)', border: OutlineInputBorder(), helperText: 'SI = (P × R × T) / 100')),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveSettings,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save Settings'),
                ),
              ],
            ),
          ),
        ),

        // Add Funds
        const SizedBox(height: 24),
        const Text('Add Funds to Pool', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Manually inject capital into the group fund.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _addAmountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _addDescC, decoration: const InputDecoration(labelText: 'Description / Source', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _adding ? null : _addFunds,
                  icon: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                  label: Text(_adding ? 'Adding...' : 'Add Funds'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),
        ),

        // Debit Funds
        const SizedBox(height: 24),
        const Text('Debit Funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        Text('Withdraw capital from the group fund.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _debitAmountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                  controller: _debitDateC,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: _debitDescC, decoration: const InputDecoration(labelText: 'Reason / Purpose', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _debiting ? null : _debitFunds,
                  icon: _debiting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.remove),
                  label: Text(_debiting ? 'Debiting...' : 'Debit Funds'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ),

        // Credit Score Rules
        const SizedBox(height: 24),
        const Text('Credit Score Rules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _scoreRule('On-time contribution', '+10', Colors.green),
                _scoreRule('Missed contribution', '−15', Colors.red),
                _scoreRule('Early full repayment', '+20', Colors.green),
                _scoreRule('Delayed repayment', '−25', Colors.red),
                const SizedBox(height: 8),
                Text('Range: 300 (poor) – 900 (excellent). Starting: 500', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),

        // Announcement
        const SizedBox(height: 24),
        const Text('Global Announcement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 8),
        Text('Broadcast a message to all members.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _announcementC, maxLines: 3, decoration: const InputDecoration(labelText: 'Announcement', border: OutlineInputBorder(), hintText: 'Write announcement here...')),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _publishing ? null : _publishAnnouncement,
                  icon: _publishing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.campaign),
                  label: Text(_publishing ? 'Publishing...' : 'Publish Announcement'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _scoreRule(String event, String delta, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(delta, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 12),
          Text(event, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
