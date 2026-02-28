import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'member_dashboard_screen.dart';
import '../contributions/contributions_screen.dart';
import '../loans/loans_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;

  final List<Widget> _adminScreens = const [
    AdminDashboardScreen(),
    ContributionsScreen(),
    LoansScreen(),
    SettingsScreen(),
  ];

  final List<Widget> _memberScreens = const [
    MemberDashboardScreen(),
    ContributionsScreen(),
    LoansScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final currentScreens = isAdmin ? _adminScreens : _memberScreens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Royal Star Boys'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: currentScreens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: isAdmin
            ? const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.credit_card), label: 'Contribs'),
                NavigationDestination(icon: Icon(Icons.money), label: 'Loans'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ]
            : const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.credit_card), label: 'My Contribs'),
                NavigationDestination(icon: Icon(Icons.money), label: 'My Loans'),
                NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
              ],
      ),
    );
  }
}
