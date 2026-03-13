import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/transaction.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Transaction> _transactions = [];
  int _total = 0;
  bool _loading = true;
  String _type = '';
  int _page = 0;
  final int _limit = 20;

  final List<Map<String, String>> _typeFilters = [
    {'value': '', 'label': 'All'},
    {'value': 'contribution', 'label': 'Contribution'},
    {'value': 'loan_disbursement', 'label': 'Loan Disbursement'},
    {'value': 'repayment', 'label': 'Repayment'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _loading = true);
    try {
      String endpoint = '/transactions?limit=$_limit&offset=${_page * _limit}';
      if (_type.isNotEmpty) endpoint += '&type=$_type';
      final res = await ApiService.get(endpoint);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['transactions'] ?? [];
        setState(() {
          _transactions = list.map((j) => Transaction.fromJson(j)).toList();
          _total = data['total'] ?? list.length;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'contribution': return Colors.green;
      case 'loan_disbursement': return Colors.orange;
      case 'repayment': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _formatCurrency(num n) => '₹${n.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _limit).ceil().clamp(1, 999);

    return Scaffold(
      body: Column(
        children: [
          // Type filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _typeFilters.map((f) {
                  final isSelected = _type == f['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f['label']!),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() { _type = f['value']!; _page = 0; });
                        _fetchTransactions();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Transactions list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchTransactions,
                    child: _transactions.isEmpty
                        ? const Center(child: Text('No transactions found'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final t = _transactions[index];
                              final isDebit = t.type == 'loan_disbursement';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _typeColor(t.type).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: _typeColor(t.type),
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _typeColor(t.type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          t.type.replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _typeColor(t.type)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        t.memberName ?? 'System',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        DateTime.tryParse(t.createdAt)?.toLocal().toString().substring(0, 16) ?? t.createdAt,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isDebit ? '-' : '+'}${_formatCurrency(t.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDebit ? Colors.red : Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Fund: ${_formatCurrency(t.groupFundAfter)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
          // Pagination
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _page > 0 ? () { setState(() => _page--); _fetchTransactions(); } : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Prev'),
                ),
                Text('Page ${_page + 1} of $totalPages', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                TextButton.icon(
                  onPressed: (_page + 1) * _limit < _total ? () { setState(() => _page++); _fetchTransactions(); } : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
