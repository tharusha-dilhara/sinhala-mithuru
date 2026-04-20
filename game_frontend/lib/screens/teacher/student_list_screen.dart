import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_models.dart';
import '../../services/teacher_service.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  final int? classId;
  const StudentListScreen({super.key, this.classId});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<StudentRank> _students = [];
  final Set<int> _selectedStudents = {};
  bool _isSelectionMode = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void didUpdateWidget(StudentListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _isSelectionMode = false;
      _selectedStudents.clear();
    });
    final students = await _teacherService.getLeaderboard(
      classId: widget.classId,
    );
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  Future<void> _bulkPromote() async {
    if (_selectedStudents.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.upgrade, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(
              'සිසුන් උසස් කිරීම',
              style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '${_selectedStudents.length} සිසුන් මීළඟ ලෙවල් එකට නිකුත් කිරීමට ඔබ සහතික ද?',
          style: GoogleFonts.notoSansSinhala(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('නැත', style: GoogleFonts.notoSansSinhala()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'ඔව්, උසස් කරන්න',
              style: GoogleFonts.notoSansSinhala(),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _teacherService.bulkPromoteStudents(
      _selectedStudents.toList(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'සිසුන් සාර්ථකව උසස් කරන ලදී.'
                : 'සිසුන් උසස් කිරීම අසාර්ථකයි.',
            style: GoogleFonts.notoSansSinhala(),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        setState(() {
          _isSelectionMode = false;
          _selectedStudents.clear();
        });
        _loadStudents();
      }
    }
  }

  List<StudentRank> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Search + Selection Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'සිසුන් සොයන්න...',
                      hintStyle: GoogleFonts.notoSansSinhala(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.deepOrange),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_isSelectionMode)
                  ElevatedButton.icon(
                    onPressed: _selectedStudents.isNotEmpty
                        ? _bulkPromote
                        : null,
                    icon: const Icon(Icons.upgrade, size: 18),
                    label: Text(
                      '${_selectedStudents.length}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isSelectionMode ? Icons.close : Icons.checklist_rounded,
                    color: _isSelectionMode ? Colors.red : Colors.deepOrange,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = !_isSelectionMode;
                      _selectedStudents.clear();
                    });
                  },
                  tooltip: _isSelectionMode ? 'Cancel' : 'Select Students',
                ),
              ],
            ),
          ),
          // Count bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  _isLoading
                      ? 'Loading...'
                      : '${filtered.length} සිසුන්${_searchQuery.isNotEmpty ? ' (සෙවුම)' : ''}',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                if (_isSelectionMode && filtered.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedStudents.length == filtered.length) {
                          _selectedStudents.clear();
                        } else {
                          _selectedStudents.addAll(
                            filtered.map((s) => s.studentId),
                          );
                        }
                      });
                    },
                    child: Text(
                      _selectedStudents.length == filtered.length
                          ? 'සියල්ල ඉවත් කරන්න'
                          : 'සියල්ල තෝරන්න',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 12,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  )
                : filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadStudents,
                    color: Colors.deepOrange,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildStudentCard(filtered[index], index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isNotEmpty
                ? 'ගැලපෙන සිසුවෙකු හමු නොවීය'
                : widget.classId != null
                ? 'මෙම පන්තියේ සිසුන් නොමැත'
                : 'සිසුන් නොමැත',
            style: GoogleFonts.notoSansSinhala(
              fontSize: 15,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentRank student, int index) {
    final isSelected = _selectedStudents.contains(student.studentId);
    final rank = index + 1;

    Color rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.grey.shade400;
      rankIcon = null;
    }

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedStudents.remove(student.studentId);
            } else {
              _selectedStudents.add(student.studentId);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(
                studentId: student.studentId,
                studentName: student.name,
              ),
            ),
          );
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedStudents.add(student.studentId);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepOrange.shade300 : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Rank / Checkbox
              if (_isSelectionMode)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepOrange
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check : null,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                SizedBox(
                  width: 28,
                  child: rankIcon != null
                      ? Icon(rankIcon, color: rankColor, size: 22)
                      : Text(
                          '#$rank',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              const SizedBox(width: 14),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange.shade300,
                      Colors.orange.shade300,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.name} (ID: ${student.studentId})',
                      style: GoogleFonts.notoSansSinhala(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniChip(
                          'Level ${student.level}',
                          Colors.blue.shade50,
                          Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        _buildMiniChip(
                          '${student.totalScore} pts',
                          Colors.orange.shade50,
                          Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
