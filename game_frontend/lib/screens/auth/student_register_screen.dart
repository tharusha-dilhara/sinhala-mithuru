import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

// Unified Pattern Icons and Colors (Matching StudentLoginScreen)
// Pattern Selection logic is limited to 3 icons as per requirements.

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  // Navigation## Implementation
  // - [x] Implement `isTablet` responsive logic
  // - [x] Refactor layout to support Landscape Split-View on tablets
  // - [x] Polish Step 1: Student Details (larger inputs, kid-friendly icons)
  // - [x] Polish Step 2: Teacher Search (extended height list, premium cards)
  // - [x] Polish Step 3: Pattern Selection (unified logic, preview row, large targets)
  // - [x] Add visual polish (background elements, animations)

  // Navigation State
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Student Details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2: Teacher & Class Search
  final _teacherSearchController = TextEditingController();
  int? _selectedClassId;
  String _selectedClassInfo = "";

  // Step 3: Pattern
  List<int> _selectedPattern = [];
  final List<IconData> _icons = [
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

  final _authService = AuthService();
  bool _isLoading = false;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  // --- Search Logic ---
  void _performSearch(StateSetter modalSetState) async {
    modalSetState(() => _isSearching = true);
    try {
      final results = await _authService.searchTeachers(
        _teacherSearchController.text,
      );
      modalSetState(() => _searchResults = results);
    } catch (e) {
      modalSetState(() => _searchResults = []);
    } finally {
      modalSetState(() => _isSearching = false);
    }
  }

  // --- Step Navigation Logic ---
  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('කරුණාකර සියලු විස්තර පුරවන්න')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedClassId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('කරුණාකර පන්තියක් තෝරාගන්න')),
        );
        return;
      }
    }

    setState(() {
      if (_currentStep < _totalSteps - 1) {
        _currentStep++;
      } else {
        _registerStudent();
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  // --- Register Logic (Final Step) ---
  void _registerStudent() async {
    if (_selectedPattern.length < 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('කරුණාකර රූප 3ක් තෝරන්න')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool success = await _authService.signupStudent(
        name: _nameController.text,
        classId: _selectedClassId!,
        parentPhone: _phoneController.text,
        pattern: _selectedPattern,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "සාර්ථකයි!",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text("${_nameController.text} දරුවා ලියාපදිංචි කරන ලදී."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Close Screen
                },
                child: const Text(
                  "හරි",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
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

          // 2. Playful Background Elements (Kid-friendly)
          if (isTablet) ...[
            Positioned(
              left: -50,
              top: 100,
              child: _buildPlayfulCircle(Colors.blue.withOpacity(0.05), 150),
            ),
            Positioned(
              right: -30,
              bottom: 150,
              child: _buildPlayfulCircle(Colors.orange.withOpacity(0.05), 200),
            ),
          ],

          SafeArea(
            child: isTablet && isLandscape
                ? Row(
                    children: [
                      // Sidebar for Tablet Landscape
                      _buildSidebar(context),
                      // Content Area
                      Expanded(child: _buildMainContent(context, true, true)),
                    ],
                  )
                : Column(
                    children: [
                      // Condensed Header for Landscape
                      if (isLandscape)
                        _buildLandscapeHeader(context)
                      else ...[
                        _buildHeader(context),
                        _buildStepIndicator(),
                      ],

                      Expanded(
                        child: _buildMainContent(
                          context,
                          isLandscape,
                          isTablet,
                        ),
                      ),

                      // 4. Navigation Buttons (More compact in landscape)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 60 : 30,
                          vertical: isLandscape ? 10 : 20,
                        ),
                        child: _buildBottomButtons(isLandscape),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayfulCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      color: Colors.white.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1A3B74),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 40),
          Text(
            "නව සිසුන්\nලියාපදිංචිය",
            style: GoogleFonts.notoSansSinhala(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3B74),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          // Sidebar Step Indicator
          Expanded(
            child: ListView.builder(
              itemCount: _totalSteps,
              itemBuilder: (context, index) {
                bool isActive = index == _currentStep;
                bool isCompleted = index < _currentStep;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: [
                      _buildSidebarStepIcon(index, isActive, isCompleted),
                      const SizedBox(width: 15),
                      Text(
                        _getStepTitle(index),
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 18,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActive
                              ? const Color(0xFF1A3B74)
                              : Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarStepIcon(int index, bool isActive, bool isCompleted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green
            : (isActive ? const Color(0xFF1A3B74) : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive || isCompleted
              ? Colors.transparent
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF1A3B74).withOpacity(0.3),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                "${index + 1}",
                style: GoogleFonts.outfit(
                  color: isActive ? Colors.white : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return "දරුවාගේ විස්තර";
      case 1:
        return "ගුරුවරයා තෝරන්න";
      case 2:
        return "රහස් රටාව";
      default:
        return "";
    }
  }

  Widget _buildMainContent(
    BuildContext context,
    bool isLandscape,
    bool isTablet,
  ) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 40 : 20,
          vertical: isLandscape ? 5 : 10,
        ),
        child: Column(
          children: [
            Container(
              width: isTablet && isLandscape
                  ? double.infinity
                  : size.width * (isLandscape ? 0.85 : 0.95),
              constraints: BoxConstraints(
                maxWidth: isTablet ? 900 : (isLandscape ? 800 : 550),
              ),
              padding: EdgeInsets.all(isTablet ? 40 : (isLandscape ? 20 : 40)),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<int>(_currentStep),
                  child: _buildStepContent(isLandscape),
                ),
              ),
            ),
            if (isTablet && isLandscape)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: _buildBottomButtons(true),
              ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Text(
            "නව සිසුන් ලියාපදිංචිය",
            style: GoogleFonts.notoSansSinhala(
              fontSize: 28, // Increased from 22
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.blueGrey,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 5),
              Text(
                "ලියාපදිංචිය",
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          // Integrated compact indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildCompactStepIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        bool isActive = index == _currentStep;
        bool isCompleted = index < _currentStep;
        return Row(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : (isActive ? Colors.blue : Colors.grey.shade300),
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (index < _totalSteps - 1)
              Container(
                width: 15,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          bool isActive = index == _currentStep;
          bool isCompleted = index < _currentStep;

          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: isActive ? 45 : 35,
                height: isActive ? 45 : 35,
                curve: Curves.elasticOut,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF66BB6A) // Soft green
                      : (isActive ? const Color(0xFF4A90E2) : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isActive || isCompleted)
                        ? Colors.transparent
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4A90E2).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          "${index + 1}",
                          style: GoogleFonts.outfit(
                            color: isActive
                                ? Colors.white
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: isActive ? 20 : 16,
                          ),
                        ),
                ),
              ),
              if (index < _totalSteps - 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF66BB6A)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(bool isLandscape) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(isLandscape);
      case 1:
        return _buildStep2(isLandscape);
      case 2:
        return _buildStep3(isLandscape);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(bool isLandscape) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          Icons.face_retouching_natural_rounded,
          "1. දරුවාගේ විස්තර",
          "දරුවාගේ මූලික විස්තර මෙහි ඇතුලත් කරන්න. අපි ලස්සනට පටන් ගමු!",
          isLandscape: isLandscape,
        ),
        SizedBox(height: isTablet ? 30 : (isLandscape ? 15 : 25)),
        _buildStyledTextField(
          controller: _nameController,
          label: "දරුවාගේ නම",
          icon: Icons.badge_rounded,
          hint: "උදා: කමල් පෙරේරා",
        ),
        const SizedBox(height: 20),
        _buildStyledTextField(
          controller: _phoneController,
          label: "දෙමව්පියන්ගේ දුරකථන අංකය",
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          hint: "07xxxxxxxx",
        ),
      ],
    );
  }

  Widget _buildStep2(bool isLandscape) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          Icons.search_rounded,
          "2. ගුරුවරයා තෝරන්න",
          "ඔබේ දරුවාගේ පන්ති භාර ගුරුතුමා හෝ ගුරුතුමිය සොයාගන්න.",
          isLandscape: isLandscape,
        ),
        SizedBox(height: isTablet ? 30 : (isLandscape ? 10 : 20)),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _teacherSearchController,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: "ගුරුතුමාගේ/ගුරුතුමියගේ නම",
              hintStyle: GoogleFonts.notoSansSinhala(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF4A90E2),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90E2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _performSearch(setState),
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),

        if (_selectedClassId != null) _buildSelectedTeacherCard(),

        SizedBox(
          height: isTablet ? 400 : 250,
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: isTablet ? 80 : 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "ගුරුවරුන් සොයන්න...",
                        style: GoogleFonts.notoSansSinhala(
                          color: Colors.grey.shade400,
                          fontSize: isTablet ? 22 : 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final teacher = _searchResults[index];
                    final school = teacher['schools'];
                    final List classes = teacher['classes'] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0E6F0),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Teacher header
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFFE0E6F0),
                              child: Text(
                                teacher['full_name'][0].toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A3B74),
                                ),
                              ),
                            ),
                            title: Text(
                              teacher['full_name'],
                              style: GoogleFonts.notoSansSinhala(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: const Color(0xFF1A3B74),
                              ),
                            ),
                            subtitle: Text(
                              "${school['name']} - ${school['district']}",
                              style: GoogleFonts.notoSansSinhala(
                                fontSize: 14,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          // Classes list
                          if (classes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 15,
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: classes.map<Widget>((cls) {
                                  final bool isSelected =
                                      _selectedClassId == cls['id'];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedClassId = cls['id'];
                                        _selectedClassInfo =
                                            "${teacher['full_name']} › ${cls['class_name']} (ශ්‍රේණිය ${cls['grade']})";
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF4A90E2)
                                            : const Color(0xFFF0F4FF),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF4A90E2)
                                              : const Color(0xFFD0D8F0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons.class_rounded,
                                            size: 18,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF4A90E2),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${cls['class_name']} (ශ්‍රේණිය ${cls['grade']})",
                                            style: GoogleFonts.notoSansSinhala(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF1A3B74),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStep3(bool isLandscape) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          Icons.category_rounded,
          "3. රහස් රටාව",
          "ලියාපදිංචි වීමට ඔබට කැමති පින්තූර 3ක් පිළිවෙලට තෝරන්න.",
          isLandscape: isLandscape,
        ),
        SizedBox(height: isTablet ? 30 : (isLandscape ? 10 : 20)),

        // Selected Icons Preview
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              bool hasIcon = _selectedPattern.length > index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: isTablet ? 70 : 55,
                height: isTablet ? 70 : 55,
                decoration: BoxDecoration(
                  color: hasIcon ? const Color(0xFF4A90E2) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: hasIcon
                        ? const Color(0xFF4A90E2)
                        : const Color(0xFFE0E6F0),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: hasIcon
                      ? Icon(
                          _icons[_selectedPattern[index]],
                          color: Colors.white,
                          size: isTablet ? 35 : 28,
                        )
                      : Text(
                          "${index + 1}",
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade300,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 30),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLandscape ? 5 : 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: _icons.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedPattern.contains(index);
            final selectionIndex = _selectedPattern.indexOf(index);

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPattern.remove(index);
                  } else if (_selectedPattern.length < 3) {
                    _selectedPattern.add(index);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.orange : const Color(0xFFE0E6F0),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _icons[index],
                        size: isTablet ? 45 : 35,
                        color: isSelected
                            ? Colors.orange
                            : const Color(0xFF1A3B74),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${selectionIndex + 1}",
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepHeader(
    IconData icon,
    String title,
    String subtitle, {
    bool isLandscape = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isLandscape ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade900,
            size: isLandscape ? 20 : 24,
          ),
        ),
        SizedBox(width: isLandscape ? 10 : 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: isLandscape ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: isLandscape ? 11 : 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
            keyboardType: keyboardType,
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

  Widget _buildSelectedTeacherCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedClassInfo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: () => setState(() {
              _selectedClassId = null;
              _selectedClassInfo = "";
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isLandscape) {
    final bool isLastStep = _currentStep == _totalSteps - 1;

    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
              label: Text(
                "ආපසු",
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 22),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A3B74),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE0E6F0), width: 2),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 22),
              backgroundColor: isLastStep
                  ? Colors.orange.shade600
                  : const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor:
                  (isLastStep ? Colors.orange : const Color(0xFF4A90E2))
                      .withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep
                            ? (isLandscape
                                  ? "නිම කරන්න"
                                  : "ලියාපදිංචිය අවසන් කරන්න")
                            : "ඊළඟ පියවර",
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isLastStep
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        size: 26,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
