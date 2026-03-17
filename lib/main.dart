import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ktkjtcjmsuugogyejtwh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0a2p0Y2ptc3V1Z29neWVqdHdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwOTY3OTYsImV4cCI6MjA4ODY3Mjc5Nn0.Hu6cWispUu13a68lH8MzzAiVAePbZjqREPfFVfzed-8',
  );

  runApp(const ElectionsApp());
}

class ElectionsApp extends StatelessWidget {
  const ElectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Élections 2026 Djibouti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B3F),
          primary: const Color(0xFF006B3F),
          secondary: const Color(0xFF0066CC),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF006B3F),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      initialRoute: Supabase.instance.client.auth.currentSession != null
          ? '/dashboard'
          : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
