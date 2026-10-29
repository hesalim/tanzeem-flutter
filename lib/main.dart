import 'package:flutter/material.dart';

import 'auth/auth_session.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const TanzeemApp());
}

class TanzeemApp extends StatelessWidget {
  const TanzeemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanzeem',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B5F4A),
          primary: const Color(0xFF0B5F4A),
          surface: Colors.white,
        ),
      ),

      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    final restored = await AuthSession.restoreSession();

    if (!mounted) return;

    setState(() {
      isLoggedIn = restored;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9F8),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B5F4A)),
        ),
      );
    }

    if (isLoggedIn) {
      return const MainScreen();
    }

    return const LoginScreen();
  }
}
