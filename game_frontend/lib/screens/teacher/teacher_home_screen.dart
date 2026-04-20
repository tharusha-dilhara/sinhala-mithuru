import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/teacher_service.dart';
import '../../models/teacher_models.dart';
import '../auth/student_register_screen.dart';
import '../auth/login_option_screen.dart';
import 'student_list_screen.dart';
// import 'assignments_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  final int teacherId;
  const TeacherHomeScreen({super.key, required this.teacherId});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TeacherService _teacherService = TeacherService();

  int _currentIndex = 0;
  List<ClassInfo> _classes = [];
  ClassInfo? _selectedClass;
  bool _classesLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadClasses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _classesLoading = true);
    final classes = await _teacherService.getMyClasses();
    if (mounted) {
      setState(() {
        _classes = classes;
        _classesLoading = false;
      });
    }
  }

  void _selectClass(ClassInfo? c) {
    if (_selectedClass?.id == c?.id) return;
    setState(() => _selectedClass = c);
    _animationController.reset();
    _animationController.forward();
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginOptionScreen()),
        (route) => false,
      );
    }
  }

  void _showCreateClassDialog() {
    final formKey = GlobalKey<FormState>();
    String className = '';
    int grade = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.class_, color: Colors.deepOrange),
              ),
              const SizedBox(width: 12),
              Text(
                'නව පන්තිය',
                style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'පන්තියේ නම (e.g. A, B)',
                    labelStyle: GoogleFonts.notoSansSinhala(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'නම ඇතුළත් කරන්න' : null,
                  onSaved: (v) => className = v!.trim(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: grade,
                  decoration: InputDecoration(
                    labelText: 'ශ්‍රේණිය',
                    labelStyle: GoogleFonts.notoSansSinhala(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        '${i + 1} ශ්‍රේණිය',
                        style: GoogleFonts.notoSansSinhala(),
                      ),
                    ),
                  ),
                  onChanged: (v) => setDialogState(() => grade = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('අවලංගු', style: GoogleFonts.notoSansSinhala()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(ctx);
                  // Get school_id from teacher's existing class or use 1 as fallback
                  final schoolId = _classes.isNotEmpty
                      ? _classes.first.schoolId
                      : 1;
                  final newClass = await _teacherService.createClass(
                    className: className,
                    grade: grade,
                    schoolId: schoolId,
                  );
                  if (mounted) {
                    if (newClass != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'පන්තිය සාර්ථකව සෑදූහ!',
                            style: GoogleFonts.notoSansSinhala(),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      await _loadClasses();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'දෝෂයක් සිදුවිය. නැවත උත්සාහ කරන්න.',
                            style: GoogleFonts.notoSansSinhala(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text('සාදන්න', style: GoogleFonts.notoSansSinhala()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildClassSelector(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  DashboardOverviewTab(
                    classId: _selectedClass?.id,
                    className: _selectedClass?.displayName,
                    onRegisterStudent: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentRegisterScreen(),
                        ),
                      );
                    },
                    onCreateClass: _showCreateClassDialog,
                    onClassesRefresh: _loadClasses,
                  ),
                  StudentListScreen(classId: _selectedClass?.id),
                  //                   AssignmentsScreen(classId: _selectedClass?.id),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade700, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ගුරු පුවරුව',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_selectedClass != null)
                      Text(
                        _selectedClass!.displayName,
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      )
                    else
                      Text(
                        'සියලු පන්ති',
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade700, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _classesLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildClassChip(null, 'සියල්ල', Icons.grid_view_rounded),
                    ...(_classes.map(
                      (c) => _buildClassChip(c, c.displayName, Icons.class_),
                    )),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showCreateClassDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'නව පන්නිය',
                              style: GoogleFonts.notoSansSinhala(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildClassChip(ClassInfo? c, String label, IconData icon) {
    final isSelected = _selectedClass?.id == c?.id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _selectClass(c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.deepOrange.shade700 : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.deepOrange.shade700 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.notoSansSinhala(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansSinhala(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'දළ විශ්ලේෂණය',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'සිසුන්',
          ),
          /* BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'පැවරුම්',
          ), */
        ],
      ),
    );
  }
}

// ---- Dashboard Overview Tab ----

class DashboardOverviewTab extends StatefulWidget {
  final int? classId;
  final String? className;
  final VoidCallback onRegisterStudent;
  final VoidCallback onCreateClass;
  final Future<void> Function() onClassesRefresh;

  const DashboardOverviewTab({
    super.key,
    this.classId,
    this.className,
    required this.onRegisterStudent,
    required this.onCreateClass,
    required this.onClassesRefresh,
  });

  @override
  State<DashboardOverviewTab> createState() => _DashboardOverviewTabState();
}

class _DashboardOverviewTabState extends State<DashboardOverviewTab> {
  final TeacherService _teacherService = TeacherService();

  bool _isLoading = true;
  TeacherDashboardSummary? _summary;
  ClassDifficultyAnalytics? _weakness;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didUpdateWidget(DashboardOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final summary = await _teacherService.getDashboardSummary(
        classId: widget.classId,
      );
      final weakness = await _teacherService.getClassWeaknesses(
        classId: widget.classId,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _weakness = weakness;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: Colors.deepOrange,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                if (_summary != null) ...[
                  _buildSummaryStats(_summary!),
                  const SizedBox(height: 20),
                  if (_summary!.strugglingStudents.isNotEmpty) ...[
                    _buildSectionTitle(
                      ' අවධානය අවශ්‍ය සිසුන්',
                      Icons.warning_amber_rounded,
                      Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _buildStrugglingStudentsList(_summary!.strugglingStudents),
                    const SizedBox(height: 20),
                  ],
                  if (_summary!.skillStats.isNotEmpty) ...[
                    _buildSectionTitle(
                      'කුසලතා කාර්යසාධනය',
                      Icons.bar_chart_rounded,
                      Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _buildSkillStatsList(_summary!.skillStats),
                    const SizedBox(height: 20),
                  ],
                ],
                if (_weakness != null &&
                    _weakness!.topDifficultItems.isNotEmpty) ...[
                  _buildSectionTitle(
                    'පන්තියේ දුර්වලතා',
                    Icons.trending_down_rounded,
                    Colors.redAccent,
                  ),
                  const SizedBox(height: 10),
                  _buildWeaknessList(_weakness!),
                  const SizedBox(height: 20),
                ],
                _buildSectionTitle(
                  'කළමනාකරණය',
                  Icons.settings_outlined,
                  Colors.grey.shade700,
                ),
                const SizedBox(height: 10),
                _buildActionGrid(context),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.notoSansSinhala(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final String displayClass = widget.className ?? 'සියලු පන්ති';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade700, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ආයුබෝවන්! 👋',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayClass,
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ශිෂ්‍යයන්ගේ ප්‍රගතිය නිරීක්ෂණය කරන්න.',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(TeacherDashboardSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'මුළු සිසුන්',
                summary.totalStudents.toString(),
                Icons.groups_rounded,
                Colors.blue,
                Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'සාමාන්‍ය ශ්‍රේෂ්ඨාංකය',
                summary.classAverageLevel.toStringAsFixed(1),
                Icons.emoji_events_rounded,
                Colors.orange,
                Colors.orange.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'සම්පූර්ණ කිරීමේ අනුපාතය',
          '${(summary.assignmentCompletionRate * 100).toStringAsFixed(1)}%',
          Icons.task_alt_rounded,
          Colors.green,
          Colors.green.shade50,
          isWide: true,
          progress: summary.assignmentCompletionRate,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor, {
    bool isWide = false,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: isWide
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildStrugglingStudentsList(List<StrugglingStudent> students) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: students.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, indent: 60, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Text(
                students[index].name.isNotEmpty
                    ? students[index].name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '${students[index].name} (ID: ${students[index].id})',
              style: GoogleFonts.notoSansSinhala(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'සහාය අවශ්‍ය',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 11,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillStatsList(List<SkillPerformance> stats) {
    final Map<String, String> labels = {
      'hw': 'අත් අකුරු',
      'pron': 'උච්චාරණය',
      'gram': 'ව්‍යාකරණ',
      'narr': 'කතාව',
    };
    final Map<String, Color> colors = {
      'hw': Colors.purple,
      'pron': Colors.blue,
      'gram': Colors.teal,
      'narr': Colors.indigo,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: stats.map((skill) {
          final label = labels[skill.componentType] ?? skill.componentType;
          final color = colors[skill.componentType] ?? Colors.blueGrey;
          final pct = (skill.averageScore * 100).clamp(0, 100).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeaknessList(ClassDifficultyAnalytics weakness) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: weakness.topDifficultItems.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, indent: 70, color: Colors.grey.shade100),
        itemBuilder: (_, idx) {
          final item = weakness.topDifficultItems[idx];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 42,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.itemName,
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'වරදින වාර: ${item.failureCount}',
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            '${(item.averageScore * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.averageScore,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.redAccent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: [
        _buildActionCard(
          icon: Icons.person_add_rounded,
          title: 'සිසු ලියාපදිංචිය',
          subtitle: 'නව සිසුවෙකු add කරන්න',
          color: Colors.green,
          bgColor: Colors.green.shade50,
          onTap: widget.onRegisterStudent,
        ),
        _buildActionCard(
          icon: Icons.class_rounded,
          title: 'නව පන්නිය',
          subtitle: 'පන්නියක් සාදන්න',
          color: Colors.deepOrange,
          bgColor: Colors.deepOrange.shade50,
          onTap: widget.onCreateClass,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
