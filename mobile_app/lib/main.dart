import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/main_wrapper_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const RoyalStarBoysApp(),
    ),
  );
}

class RoyalStarBoysApp extends StatelessWidget {
  const RoyalStarBoysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Royal Star Boys',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          primary: const Color(0xFF3B82F6),
          secondary: const Color(0xFF10B981),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Defaulting to Roboto
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (auth.isAuthenticated) {
            return const MainWrapperScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
