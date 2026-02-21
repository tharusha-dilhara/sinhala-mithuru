import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../game/game_home_screen.dart';
import 'login_option_screen.dart';

// 1. දෙමව්පියන්ගේ අංකය ගසා දරුවා තෝරාගැනීම (Lookup Screen)
class StudentLookupScreen extends StatefulWidget {
  const StudentLookupScreen({super.key});

  @override
  State<StudentLookupScreen> createState() => _StudentLookupScreenState();
}

class _StudentLookupScreenState extends State<StudentLookupScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  List<dynamic> _students = [];
  bool _isLoading = false;

  void _searchStudents() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final students = await _authService.getStudentsByParent(
        _phoneController.text,
      );
      if (mounted) setState(() => _students = students);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 10,
                top: 5,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  child: Container(
                    width: size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 450),
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
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "දුවා/පුතා තෝරන්න",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3B74),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "දුරකථන අංකය ඇතුළත් කර දුබල සොයන්න",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30),

                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 10,
                          textAlign: TextAlign.center,
                          buildCounter:
                              (
                                context, {
                                required currentLength,
                                required isFocused,
                                required maxLength,
                              }) => null,
                          onChanged: (val) {
                            if (val.length == 10) {
                              _searchStudents();
                            }
                          },
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF0F4FF),
                            hintText: "07X XXX XXXX",
                            hintStyle: GoogleFonts.notoSansSinhala(
                              fontSize: 18,
                              color: Colors.grey.shade400,
                              letterSpacing: 1,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_android,
                              color: Color(0xFF1A3B74),
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1A3B74),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _searchStudents,
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),

                        if (_students.isNotEmpty)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: size.height * 0.45,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final List<Color> cardColors = [
                                  const Color(0xFFFFE0E0),
                                  const Color(0xFFE0F7FA),
                                  const Color(0xFFF3E5F5),
                                  const Color(0xFFFFF9C4),
                                ];
                                final color =
                                    cardColors[index % cardColors.length];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentPatternScreen(
                                            studentId: student['id'],
                                            studentName: student['name'],
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(25),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.white,
                                            child: Text(
                                              student['name'][0],
                                              style:
                                                  GoogleFonts.notoSansSinhala(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student['name'],
                                                  style:
                                                      GoogleFonts.notoSansSinhala(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 22,
                                                        color: Colors.black87,
                                                      ),
                                                ),
                                                Text(
                                                  "${student['grade']} ශ්‍රේණිය",
                                                  style:
                                                      GoogleFonts.notoSansSinhala(
                                                        fontSize: 14,
                                                        color: Colors.black54,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
}

// 2. පින්තූර 9 පැටන් එක (Pattern Screen)
class StudentPatternScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentPatternScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentPatternScreen> createState() => _StudentPatternScreenState();
}

class _StudentPatternScreenState extends State<StudentPatternScreen> {
  final _authService = AuthService();
  final List<int> _selectedPattern = [];
  bool _isVerifying = false;

  static const List<IconData> _icons = [
    Icons.pets,
    Icons.wb_sunny,
    Icons.directions_car,
    Icons.home,
    Icons.star,
    Icons.icecream,
    Icons.local_pizza,
    Icons.flight,
    Icons.music_note,
  ];

  void _onItemTapped(int index) {
    if (_isVerifying) return;
    setState(() {
      if (_selectedPattern.contains(index + 1)) {
        _selectedPattern.remove(index + 1);
      } else {
        if (_selectedPattern.length < 3) {
          _selectedPattern.add(index + 1);
        }
      }
    });

    // Auto-submit if 3 items selected
    if (_selectedPattern.length == 3) {
      _submitPattern();
    }
  }

  void _submitPattern() async {
    if (_selectedPattern.isEmpty || _isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      bool success = await _authService.loginStudent(
        widget.studentId,
        _selectedPattern,
      );
      if (success && mounted) {
        await _authService.saveLastStudent(
          widget.studentId,
          widget.studentName,
        );
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const SuccessDialog(),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GameHomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('රටාව වැරදියි, නැවත උත්සාහ කරන්න.')),
          );
          setState(() => _selectedPattern.clear());
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _selectedPattern.clear());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _switchUser() async {
    await _authService.clearUser();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginOptionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width && size.height < 500;

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Container(
                    width: isLandscape ? size.width * 0.95 : size.width * 0.9,
                    constraints: BoxConstraints(
                      maxWidth: isLandscape ? 800 : 420,
                    ),
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
                    child: isLandscape
                        ? _buildLandscapeLayout()
                        : _buildPortraitLayout(),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 5,
                child: CompactSwitchButton(onTap: _switchUser),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          _buildStudentNameBadge(),
          const SizedBox(height: 25),
          Text(
            "රහස් රටාව තෝරන්න",
            style: GoogleFonts.notoSansSinhala(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3B74),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "රූප 3ක් පිළිවෙලට තෝරන්න",
            style: GoogleFonts.notoSansSinhala(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 25),
          _buildPatternGrid(size: 280),
          const SizedBox(height: 30),
          const SizedBox(height: 30),
          if (_isVerifying) const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Info and Buttons
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStudentNameBadge(),
              const SizedBox(height: 25),
              Text(
                "රහස් රටාව තෝරන්න",
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A3B74),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "රූප 3ක් පිළිවෙලට තෝරන්න",
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              if (_isVerifying) const CircularProgressIndicator(),
            ],
          ),
        ),
        const VerticalDivider(
          width: 40,
          thickness: 1,
          indent: 20,
          endIndent: 20,
        ),
        // Right side: Pattern Grid
        Expanded(
          flex: 3,
          child: Center(
            child: _buildPatternGrid(
              size: MediaQuery.of(context).size.height * 0.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentNameBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3B74),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3B74).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFFFFD700), size: 24),
          const SizedBox(width: 10),
          Text(
            widget.studentName,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternGrid({required double size}) {
    // Increase size for easier tapping
    final effectiveSize = size < 350 ? 350.0 : size;
    return Container(
      width: effectiveSize,
      height: effectiveSize,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final isSelected = _selectedPattern.contains(index + 1);
          return PatternItem(
            icon: _icons[index],
            isSelected: isSelected,
            order: _selectedPattern.indexOf(index + 1) + 1,
            onTap: () => _onItemTapped(index),
            isLandscape: size > 300, // Hint to increase icon size
          );
        },
      ),
    );
  }
}

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 15),
            Text(
              "නියමයි!",
              style: GoogleFonts.notoSansSinhala(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "අපි සෙල්ලම් කරමු!",
              style: GoogleFonts.notoSansSinhala(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatternItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final int order;
  final VoidCallback onTap;
  final bool isLandscape;

  const PatternItem({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.order,
    required this.onTap,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFFFD700).withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 15 : 5,
                spreadRadius: isSelected ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFB300)
                  : Colors.grey.shade200,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: isLandscape ? 56 : 48,
                color: isSelected
                    ? const Color(0xFF1A3B74)
                    : Colors.blueGrey.shade400,
              ),
              if (isSelected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A3B74),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$order",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
}

class LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  const LoginButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF66BB6A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "පිවිසෙන්න",
              style: GoogleFonts.notoSansSinhala(
                fontSize: 24, // Increased from 20
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class CompactSwitchButton extends StatelessWidget {
  final VoidCallback onTap;
  const CompactSwitchButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.group_add_outlined, size: 18),
      label: Text(
        "මාරු වන්න",
        style: GoogleFonts.notoSansSinhala(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blueGrey,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}
