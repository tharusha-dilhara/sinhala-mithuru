import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class TeacherSignupScreen extends StatefulWidget {
  const TeacherSignupScreen({super.key});

  @override
  State<TeacherSignupScreen> createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<TeacherSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // School ID වෙනුවට මේ දෙක එකතු කළා
  final _schoolNameController = TextEditingController();
  // final _districtController = TextEditingController(); // Removed
  String? _selectedDistrict;

  final List<String> _districts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  final _authService = AuthService();
  bool _isLoading = false;

  void _signup() async {
    // Validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _schoolNameController.text.isEmpty ||
        _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර සියලු විස්තර පුරවන්න')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // දැන් අපි අලුත් ක්‍රමයට Data යවනවා
      bool success = await _authService.signupTeacher(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        schoolName: _schoolNameController.text,
        schoolDistrict: _selectedDistrict!,
      );

      if (success && mounted) {
        // සාර්ථකයි පණිවිඩය
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("සාර්ථකයි!"),
            content: const Text(
              "ගුරු ගිණුම සහ පාසල සාර්ථකව සම්බන්ධ විය. දැන් ඔබට ඇතුල් විය හැක.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog off
                  Navigator.pop(context); // Login screen එකට
                },
                child: const Text("හරි"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
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
                    width: size.width * 0.95,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(30),
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
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "ගුරු ලියාපදිංචිය",
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3B74),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Personal Info Section
                        _buildSectionTitle("පෞද්ගලික විස්තර"),
                        const SizedBox(height: 15),
                        _buildStyledTextField(
                          controller: _nameController,
                          label: "සම්පූර්ණ නම",
                          icon: Icons.person_rounded,
                          hint: "ඔබේ නම",
                        ),
                        const SizedBox(height: 15),
                        _buildStyledTextField(
                          controller: _emailController,
                          label: "විද්‍යුත් ලිපිනය (Email)",
                          icon: Icons.email_rounded,
                          hint: "example@mail.com",
                        ),
                        const SizedBox(height: 15),
                        _buildStyledTextField(
                          controller: _passwordController,
                          label: "මුරපදය (Password)",
                          icon: Icons.lock_rounded,
                          obscureText: true,
                          hint: "••••••••",
                        ),

                        const SizedBox(height: 30),

                        // School Info Section
                        _buildSectionTitle("පාසල් විස්තර"),
                        const SizedBox(height: 15),
                        _buildStyledTextField(
                          controller: _schoolNameController,
                          label: "පාසලේ නම",
                          icon: Icons.school_rounded,
                          hint: "රාහුල විද්‍යාලය",
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [Expanded(child: _buildStyledDropdown())],
                        ),

                        const SizedBox(height: 40),

                        _isLoading
                            ? const CircularProgressIndicator()
                            : Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _signup,
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
                                        "ලියාපදිංචි වන්න",
                                        style: GoogleFonts.notoSansSinhala(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.notoSansSinhala(
                                          fontSize: 15,
                                          color: Colors.black54,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: "දැනටමත් ගිණුමක් තිබේද? ",
                                          ),
                                          TextSpan(
                                            text: "ඇතුල් වන්න",
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.notoSansSinhala(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
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
              fontSize: 15,
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
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.notoSansSinhala(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF4A90E2), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            "දිස්ක්‍රික්කය",
            style: GoogleFonts.notoSansSinhala(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3B74),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E6F0)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.map_rounded,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            items: _districts.map((String district) {
              return DropdownMenuItem<String>(
                value: district,
                child: Text(
                  district,
                  style: GoogleFonts.notoSansSinhala(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedDistrict = newValue;
              });
            },
          ),
        ),
      ],
    );
  }
}
