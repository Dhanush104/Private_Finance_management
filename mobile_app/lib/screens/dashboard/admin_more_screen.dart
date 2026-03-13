import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../members/members_screen.dart';
import '../ledger/ledger_screen.dart';
import '../repayments/repayments_screen.dart';
import '../settings/settings_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  final Function(Widget, String) onNavigate;

  const AdminMoreScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('More', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _menuCard(context, 'Members', 'Manage all group members', Icons.people, Colors.purple, const MembersScreen()),
        _menuCard(context, 'Ledger', 'View all financial transactions', Icons.receipt_long, Colors.blue, const LedgerScreen()),
        _menuCard(context, 'Repayments', 'Record and view loan repayments', Icons.payments, Colors.teal, const RepaymentsScreen()),
        _menuCard(context, 'Settings', 'Configure group parameters', Icons.settings, Colors.grey, const SettingsScreen()),
      ],
    );
  }

  Widget _menuCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onNavigate(screen, title),
      ),
    );
  }
}
