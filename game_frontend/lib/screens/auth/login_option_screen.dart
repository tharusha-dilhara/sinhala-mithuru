import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_login_screen.dart';
import 'student_register_screen.dart';
import 'teacher_login_screen.dart';
import 'teacher_signup_screen.dart';

class LoginOptionScreen extends StatefulWidget {
  const LoginOptionScreen({super.key});

  @override
  State<LoginOptionScreen> createState() => _LoginOptionScreenState();
}

class _LoginOptionScreenState extends State<LoginOptionScreen> {
  String _selectedRole = 'student'; // 'student' or 'teacher'

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE5E5F5), // Light lavender top
                  Color(0xFFFBE4D8), // Light peach bottom
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: isTablet ? 850 : 500),
                    margin: EdgeInsets.symmetric(
                      vertical: isLandscape ? 15 : 30,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isLandscape ? 25 : (isTablet ? 60 : 40),
                      horizontal: isTablet ? 50 : 25,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 50 : 35),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A3B74).withOpacity(0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo & Branding
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: isTablet ? 120 : 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: isLandscape ? 10 : 20),

                        // Title
                        Text(
                          'සිංහල මිතුරු',
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: isTablet ? 52 : 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3B74),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle (Meaningful Sinhala)
                        Text(
                          'ඉගෙනීම ආරම්භ කිරීමට පිවිසෙන ආකාරය තෝරන්න',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: isTablet ? 22 : 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(
                          height: isLandscape ? 20 : (isTablet ? 50 : 35),
                        ),

                        // Role Selectors
                        isLandscape && isTablet
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _buildRoleSelectors(isTablet),
                              )
                            : Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                alignment: WrapAlignment.center,
                                children: _buildRoleSelectors(isTablet),
                              ),

                        SizedBox(
                          height: isLandscape ? 25 : (isTablet ? 50 : 40),
                        ),

                        // Main Action Button (Prioritize Login)
                        _buildActionButton(isTablet),

                        SizedBox(height: isLandscape ? 15 : 25),

                        // Footer (Registration Flow)
                        _buildFooter(isTablet),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRoleSelectors(bool isTablet) {
    return [
      _RoleSelector(
        label: 'ශිෂ්‍යයෙක්',
        iconData: Icons.face_retouching_natural_rounded,
        isSelected: _selectedRole == 'student',
        isTablet: isTablet,
        onTap: () => setState(() => _selectedRole = 'student'),
      ),
      if (!isTablet &&
          !(MediaQuery.of(context).size.width >
              MediaQuery.of(context).size.height))
        const SizedBox(width: 5),
      _RoleSelector(
        label: 'ගුරුවරයෙක්',
        iconData: Icons.auto_stories_rounded,
        isSelected: _selectedRole == 'teacher',
        isTablet: isTablet,
        onTap: () => setState(() => _selectedRole = 'teacher'),
      ),
    ];
  }

  Widget _buildActionButton(bool isTablet) {
    final isStudent = _selectedRole == 'student';
    return GestureDetector(
      onTap: () {
        if (isStudent) {
          // Navigating to Login/Lookup (Prioritized)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentLookupScreen()),
          );
        } else {
          // Teacher Login
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherLoginScreen()),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: isTablet ? 550 : 400),
        height: isTablet ? 85 : 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90E2).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: isTablet ? 25 : 15,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.login_rounded,
                  color: const Color(0xFF4A90E2),
                  size: isTablet ? 26 : 20,
                ),
              ),
            ),
            Text(
              isStudent ? 'පිවිසෙන්න' : 'ගුරුතුමෙක් ලෙස පිවිසෙන්න',
              style: GoogleFonts.notoSansSinhala(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isTablet) {
    return Column(
      children: [
        Text(
          'තවමත් ලියාපදිංචි වී නොමැතිද?',
          style: GoogleFonts.notoSansSinhala(
            fontSize: isTablet ? 19 : 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            if (_selectedRole == 'student') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentRegisterScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherSignupScreen()),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'මෙතනින් ලියාපදිංචි වන්න',
              style: GoogleFonts.notoSansSinhala(
                fontSize: isTablet ? 20 : 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A90E2),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String label;
  final IconData iconData;
  final bool isSelected;
  final bool isTablet;
  final VoidCallback onTap;

  const _RoleSelector({
    required this.label,
    required this.iconData,
    required this.isSelected,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isTablet
        ? (isSelected ? 170.0 : 150.0)
        : (isSelected ? 135.0 : 120.0);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.grey.shade200,
                width: isSelected ? 6 : 3,
              ),
              color: isSelected ? Colors.white : Colors.grey.shade50,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                iconData,
                size: isTablet ? 85 : 70,
                color: isSelected
                    ? const Color(0xFF1A3B74)
                    : Colors.blueGrey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.notoSansSinhala(
              fontSize: isTablet ? 22 : 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF1A3B74)
                  : Colors.blueGrey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
