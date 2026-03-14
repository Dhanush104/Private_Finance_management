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
    const primaryBlue = Color(0xFF2563EB);
    const slateBackground = Color(0xFFF8FAFC);
    const slateDark = Color(0xFF0F172A);
    const emeraldAccent = Color(0xFF10B981);

    return MaterialApp(
      title: 'Royal Star Boys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          surface: slateBackground,
          secondary: emeraldAccent,
          onSurface: slateDark,
        ),
        scaffoldBackgroundColor: slateBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: slateDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: slateDark),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        fontFamily: 'Roboto',
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
