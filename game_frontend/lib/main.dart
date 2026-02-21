import 'package:flutter/material.dart';
import 'screens/auth/login_option_screen.dart';
import 'screens/auth/student_login_screen.dart'; // Pattern Screen එක
import 'screens/game/game_home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'සිංහල මිතුරු',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // කෙලින්ම Screen එකක් දෙනවා වෙනුවට, අපි Logic එකක් දුවනවා
      home: const AuthCheckScreen(),
    );
  }
}

// මේක තමයි App එකේ "මොළය" (The Brain)
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    // 1. මුලින්ම බලනවා Token එක තියෙනවද කියලා (Token තියෙනවා නම් කෙලින්ම Game එකට)
    bool loggedIn = await _authService.isLoggedIn();
    if (loggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GameHomeScreen()),
      );
      return;
    }

    // 2. Token නෑ (Expire වෙලා), හැබැයි කලින් දරුවෙක් Save වෙලා ඉන්නවද බලනවා
    final lastStudent = await _authService.getLastStudent();
    if (lastStudent != null && mounted) {
      // දරුවා Save නම්, කෙලින්ම Pattern ගහන තැනට යවනවා (Parent Phone ඕන නෑ)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentPatternScreen(
            studentId: int.parse(lastStudent['id']!),
            studentName: lastStudent['name']!,
          ),
        ),
      );
    } else {
      // 3. කවුරුත්ම නෑ (First Time) -> මුල් පිටුවට
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginOptionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check කරනකම් Loading එකක් පෙන්නනවා
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
