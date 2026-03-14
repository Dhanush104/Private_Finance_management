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

    return Scaffold(
      appBar: AppBar(
        title: Text(_subTitle ?? 'Royal Star Boys'),
        leading: _subScreen != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _backFromSub,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded),
            onPressed: () => auth.logout(),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _subScreen ?? currentScreens[_selectedIndex],
      bottomNavigationBar: _subScreen != null
          ? null
          : Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 70,
                elevation: 0,
                backgroundColor: Colors.white,
                selectedIndex: _selectedIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _subScreen = null;
                    _subTitle = null;
                  });
                },
                destinations: isAdmin
                    ? const [
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_rounded, size: 24),
                          selectedIcon: Icon(Icons.grid_view_rounded, size: 24, color: Colors.blue),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
                          selectedIcon: Icon(Icons.account_balance_wallet_rounded, size: 24, color: Colors.blue),
                          label: 'Contribs',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.payments_outlined, size: 24),
                          selectedIcon: Icon(Icons.payments_rounded, size: 24, color: Colors.blue),
                          label: 'Loans',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.more_horiz_rounded, size: 24),
                          selectedIcon: Icon(Icons.more_horiz_rounded, size: 24, color: Colors.blue),
                          label: 'More',
                        ),
                      ]
                    : const [
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_rounded, size: 24),
                          selectedIcon: Icon(Icons.grid_view_rounded, size: 24, color: Colors.blue),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
                          selectedIcon: Icon(Icons.account_balance_wallet_rounded, size: 24, color: Colors.blue),
                          label: 'My Contribs',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.payments_outlined, size: 24),
                          selectedIcon: Icon(Icons.payments_rounded, size: 24, color: Colors.blue),
                          label: 'My Loans',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline_rounded, size: 24),
                          selectedIcon: Icon(Icons.person_rounded, size: 24, color: Colors.blue),
                          label: 'Profile',
                        ),
                      ],
              ),
            ),
    );
  }
}
