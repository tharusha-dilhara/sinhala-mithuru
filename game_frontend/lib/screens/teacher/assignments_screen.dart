import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/teacher_service.dart';

class AssignmentsScreen extends StatefulWidget {
  final int? classId;
  const AssignmentsScreen({super.key, this.classId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final TeacherService _teacherService = TeacherService();
  final _formKey = GlobalKey<FormState>();

  String _componentType = 'hw';
  String _targetData = '';
  int _expiryHours = 24;
  bool _isCreating = false;

  void _createAssignment() async {
    if (widget.classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'කරුණාකර ඉහත Class Selector එකෙන් පන්නියක් තෝරන්න.',
            style: GoogleFonts.notoSansSinhala(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isCreating = true);

      final success = await _teacherService.createSmartAssignment(
        classId: widget.classId!,
        componentType: _componentType,
        targetData: _targetData,
        expiryHours: _expiryHours,
      );

      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'පැවරුම සාර්ථකව නිර්මාණය කරන ලදී ✓'
                  : 'දෝෂයක් සිදුවිය. නැවත උත්සාහ කරන්න.',
              style: GoogleFonts.notoSansSinhala(),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _formKey.currentState!.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasClass = widget.classId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // No class selected banner
          if (!hasClass)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'පැවරුමක් ලබා දීමට ඉහළ class selector එකෙන් නිශ්චිත පන්නියක් තෝරන්න.',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Create Assignment Card
          _buildSectionHeader(
            'නව පැවරුමක් ලබා දෙන්න',
            Icons.add_task_rounded,
            Colors.deepOrange,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Component type
                    Text(
                      'ක්‍රියාකාරිත්ව වර්ගය',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildComponentSelector(),
                    const SizedBox(height: 20),

                    // Target data
                    Text(
                      'ඉලක්ක අන්තර්ගතය',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: GoogleFonts.notoSansSinhala(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'උදාහරණ: "අම්මා", "ක", "ආ"',
                        hintStyle: GoogleFonts.notoSansSinhala(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                          borderSide: const BorderSide(
                            color: Colors.deepOrange,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'අන්තර්ගතය ඇතුළත් කරන්න'
                          : null,
                      onSaved: (val) => _targetData = val!.trim(),
                    ),
                    const SizedBox(height: 20),

                    // Expiry hours
                    Text(
                      'කාල සීමාව (පැය)',
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildExpirySelector(),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasClass
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: hasClass ? 2 : 0,
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'පැවරුම ලබා දෙන්න',
                                    style: GoogleFonts.notoSansSinhala(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
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
          ),

          const SizedBox(height: 28),

          // Info section
          _buildSectionHeader(
            'කාර්ය සාධන වාර්තා',
            Icons.analytics_outlined,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 48,
                  color: Colors.blue.shade200,
                ),
                const SizedBox(height: 12),
                Text(
                  'Assignment ID එකින් වාර්තාව ලබා ගත හැක',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                _buildReportIdField(),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
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

  Widget _buildComponentSelector() {
    final options = [
      {'value': 'hw', 'label': 'අත් අකුරු', 'icon': Icons.edit},
      {'value': 'pron', 'label': 'උච්චාරණය', 'icon': Icons.mic},
      {'value': 'gram', 'label': 'ව්‍යාකරණ', 'icon': Icons.book},
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = _componentType == opt['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _componentType = opt['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: opt['value'] != 'gram' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepOrange.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.deepOrange : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: isSelected ? Colors.deepOrange : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['label'] as String,
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.deepOrange.shade800
                          : Colors.grey.shade600,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpirySelector() {
    final options = [12, 24, 48, 72];
    return Row(
      children: options.map((h) {
        final isSelected = _expiryHours == h;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _expiryHours = h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: h != 72 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepOrange.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.deepOrange : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$h',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.deepOrange : Colors.grey,
                    ),
                  ),
                  Text(
                    'පැය',
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.deepOrange.shade700
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportIdField() {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Assignment ID ඇතුළත් කරන්න',
              hintStyle: GoogleFonts.notoSansSinhala(fontSize: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            final id = int.tryParse(controller.text);
            if (id == null) return;
            final report = await _teacherService.getAssignmentReport(id);
            if (mounted) {
              if (report != null) {
                _showReportDialog(report);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'වාර්තාව හමු නොවීය',
                      style: GoogleFonts.notoSansSinhala(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: const Icon(Icons.search, size: 20),
        ),
      ],
    );
  }

  void _showReportDialog(report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'පැවරුම් වාර්තාව',
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _reportRow('ඉලක්කය', report.targetData),
            _reportRow('ශිෂ්‍ය ගණන', '${report.totalStudents}'),
            _reportRow('සම්පූර්ණ', '${report.completedCount}', Colors.green),
            _reportRow('ප්‍රගතියේ', '${report.inProgressCount}', Colors.orange),
            _reportRow('මග හැර', '${report.missedCount}', Colors.red),
            if (report.insights.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                'Tips',
                style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
              ),
              ...report.insights.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          i,
                          style: GoogleFonts.notoSansSinhala(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('හරි', style: GoogleFonts.notoSansSinhala()),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansSinhala(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
