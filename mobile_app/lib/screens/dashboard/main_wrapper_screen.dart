import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'member_dashboard_screen.dart';
import 'admin_more_screen.dart';
import '../contributions/contributions_screen.dart';
import '../contributions/my_contributions_screen.dart';
import '../loans/loans_screen.dart';
import '../loans/my_loans_screen.dart';
import '../profile/profile_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;
  Widget? _subScreen;
  String? _subTitle;

  void switchTab(int index) {
    setState(() {
      _selectedIndex = index;
      _subScreen = null;
      _subTitle = null;
    });
  }

  void _navigateToSub(Widget screen, String title) {
    setState(() {
      _subScreen = screen;
      _subTitle = title;
    });
  }

  void _backFromSub() {
    setState(() {
      _subScreen = null;
      _subTitle = null;
    });
  }

  List<Widget> _getScreens(bool isAdmin) {
    if (isAdmin) {
      return [
        const AdminDashboardScreen(),
        const ContributionsScreen(),
        const LoansScreen(),
        AdminMoreScreen(onNavigate: _navigateToSub),
      ];
    } else {
      return [
        MemberDashboardScreen(onSwitchTab: switchTab),
        const MyContributionsScreen(),
        const MyLoansScreen(),
        const ProfileScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final currentScreens = _getScreens(isAdmin);

    // If a sub-screen is active (from Admin More), show it with a back button
    if (_subScreen != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _backFromSub,
          ),
          title: Text(_subTitle ?? ''),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.logout(),
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: _subScreen,
      );
    }

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
          setState(() {
            _selectedIndex = index;
            _subScreen = null;
            _subTitle = null;
          });
        },
        destinations: isAdmin
            ? const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.credit_card), label: 'Contribs'),
                NavigationDestination(icon: Icon(Icons.money), label: 'Loans'),
                NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
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
