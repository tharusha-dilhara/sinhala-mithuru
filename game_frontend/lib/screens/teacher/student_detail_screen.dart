import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/teacher_models.dart';
import '../../services/teacher_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final int studentId;
  final String studentName; // Pass name to show while loading
  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  StudentDetailedReport? _report;

  // For Reset Pattern Dialog
  final List<int> _newPattern = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final report = await _teacherService.getStudentDetailedReport(
      widget.studentId,
    );
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  Future<void> _showResetPatternDialog() async {
    _newPattern.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Pattern එක වෙනස් කරන්න",
                style: GoogleFonts.notoSansSinhala(),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("නව Pattern එක: ${_newPattern.join(' -> ')}"),
                  const SizedBox(height: 10),
                  Text(
                    "ඉලක්කම් 3ක් තෝරන්න (Test Impl)",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: List.generate(9, (index) {
                      final val = index + 1;
                      return ActionChip(
                        label: Text("$val"),
                        onPressed: () {
                          if (_newPattern.length < 3) {
                            setState(() => _newPattern.add(val));
                          }
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _newPattern.isNotEmpty
                        ? () => setState(() => _newPattern.clear())
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                    ),
                    child: const Text("Clear"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _newPattern.length == 3
                      ? () async {
                          Navigator.pop(context);
                          final success = await _teacherService
                              .resetStudentPattern(
                                widget.studentId,
                                _newPattern,
                              );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? "Pattern එක වෙනස් කරන ලදී"
                                      : "අසාර්ථකයි",
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName, style: GoogleFonts.notoSansSinhala()),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset),
            onPressed: _showResetPatternDialog,
            tooltip: "Reset Login Pattern",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
          ? const Center(child: Text("වාර්තාවක් හමු නොවීය"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEfficiencyCard(),
                  const SizedBox(height: 20),
                  Text(
                    "ඉගෙනුම් වක්‍රය (Learning Curve)",
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLearningCurveChart(),
                  const SizedBox(height: 20),
                  Text(
                    "දුර්වලතා සාරාංශය",
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildErrorSummaryList(),
                ],
              ),
            ),
    );
  }

  Widget _buildEfficiencyCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.blue, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "කාර්යක්ෂමතාව",
                  style: GoogleFonts.notoSansSinhala(
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  "${(_report!.attemptEfficiency * 100).toStringAsFixed(1)}%",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCurveChart() {
    if (_report!.learningCurve.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("දත්ත නොමැත")),
      );
    }
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false), // Simplified for now
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _report!.learningCurve
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.avgScore))
                  .toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSummaryList() {
    final Map<String, String> componentNames = {
      'pron': 'උච්චාරණය (Pronunciation)',
      'hw': 'අක්ෂර වින්‍යාසය (Handwriting)',
      'gram': 'ව්‍යාකරණ (Grammar)',
      'narr': 'අවබෝධය (Comprehension)',
    };

    final Map<String, IconData> componentIcons = {
      'pron': Icons.record_voice_over,
      'hw': Icons.draw,
      'gram': Icons.spellcheck,
      'narr': Icons.menu_book,
    };

    return Column(
      children: _report!.errorSummary.map((summary) {
        final friendlyName =
            componentNames[summary.component] ?? summary.component;
        final icon = componentIcons[summary.component] ?? Icons.error_outline;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: Icon(icon, color: Colors.red.shade700),
            ),
            title: Text(
              friendlyName,
              style: GoogleFonts.notoSansSinhala(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              "${summary.failureCount} වාරයක් වැරදී ඇත",
              style: GoogleFonts.notoSansSinhala(
                color: Colors.red.shade600,
                fontSize: 13,
              ),
            ),
            children: [
              if (summary.breakdown.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: summary.breakdown.map((detail) {
                        return Chip(
                          label: Text(
                            "${detail.target} (${detail.count})",
                            style: GoogleFonts.notoSansSinhala(fontSize: 13),
                          ),
                          backgroundColor: Colors.orange.shade50,
                          side: BorderSide(color: Colors.orange.shade200),
                        );
                      }).toList(),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("විස්තරාත්මක දත්ත නොමැත"),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
