import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_models.dart';
import '../../services/teacher_service.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<StudentRank> _students = [];
  final Set<int> _selectedStudents = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await _teacherService.getLeaderboard();
    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  Future<void> _bulkPromote() async {
    if (_selectedStudents.isEmpty) return;

    final success = await _teacherService.bulkPromoteStudents(
      _selectedStudents.toList(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("සිසුන් සාර්ථකව උසස් කරන ලදී.")),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedStudents.clear();
        });
        _loadStudents(); // Refresh to see changes (if any backend change is reflected)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("සිසුන් උසස් කිරීම අසාර්ථකයි.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? "${_selectedStudents.length} තෝරාගෙන ඇත"
              : "සිසුන් ලැයිස්තුව",
          style: GoogleFonts.notoSansSinhala(),
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.upgrade),
              onPressed: _bulkPromote,
              tooltip: "තෝරාගත් සිසුන් උසස් කරන්න",
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedStudents.clear();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final isSelected = _selectedStudents.contains(
                  student.studentId,
                );

                return Card(
                  child: ListTile(
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedStudents.add(student.studentId);
                                } else {
                                  _selectedStudents.remove(student.studentId);
                                }
                              });
                            },
                          )
                        : CircleAvatar(
                            child: Text(student.name[0].toUpperCase()),
                          ),
                    title: Text(
                      student.name,
                      style: GoogleFonts.notoSansSinhala(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "Level ${student.level} | Score: ${student.totalScore}",
                    ),
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
                  ),
                );
              },
            ),
    );
  }
}
