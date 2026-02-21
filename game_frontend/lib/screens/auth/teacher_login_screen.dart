import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'teacher_signup_screen.dart';
import '../teacher/teacher_home_screen.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      bool success = await _authService.loginTeacher(
        _emailController.text,
        _passwordController.text,
      );
      if (success && mounted) {
        // Teacher ID එක ලබා ගැනීම
        final teacherId = await _authService.getTeacherId();

        if (teacherId != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherHomeScreen(teacherId: teacherId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login සාර්ථකයි, නමුත් දත්ත ලබා ගැනීමේ දෝෂයක්. නැවත උත්සාහ කරන්න.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherSignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE5E5F5), // Light lavender
              Color(0xFFFBE4D8), // Light peach
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF1A3B74),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  child: Container(
                    width: size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 25),
                        Text(
                          "ගුරු පිවිසුම",
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3B74),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "ඔබේ ගිණුමට ඇතුල් වන්න",
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildStyledTextField(
                          controller: _emailController,
                          label: "විද්‍යුත් ලිපිනය (Email)",
                          icon: Icons.email_rounded,
                          hint: "example@mail.com",
                        ),
                        const SizedBox(height: 20),
                        _buildStyledTextField(
                          controller: _passwordController,
                          label: "මුරපදය (Password)",
                          icon: Icons.lock_rounded,
                          obscureText: true,
                          hint: "••••••••",
                        ),
                        const SizedBox(height: 40),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1A3B74,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        elevation: 8,
                                        shadowColor: const Color(
                                          0xFF1A3B74,
                                        ).withOpacity(0.4),
                                      ),
                                      child: Text(
                                        "ඇතුල් වන්න",
                                        style: GoogleFonts.notoSansSinhala(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  TextButton(
                                    onPressed: _goToSignup,
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.notoSansSinhala(
                                          fontSize: 15,
                                          color: Colors.black54,
                                        ),
                                        children: const [
                                          TextSpan(text: "ගිණුමක් නැද්ද? "),
                                          TextSpan(
                                            text: "ලියාපදිංචි වන්න",
                                            style: TextStyle(
                                              color: Color(0xFF4A90E2),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3B74),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E6F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.notoSansSinhala(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
