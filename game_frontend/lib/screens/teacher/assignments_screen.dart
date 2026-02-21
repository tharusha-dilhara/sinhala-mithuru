import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_models.dart';
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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isCreating = true);

      // classId is required by backend — show error if not available
      if (widget.classId == null) {
        if (mounted) {
          setState(() => _isCreating = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("පන්තියක් තෝරාගන්න")));
        }
        return;
      }

      final success = await _teacherService.createSmartAssignment(
        classId: widget.classId!,
        componentType: _componentType,
        targetData: _targetData,
        expiryHours: _expiryHours,
      );

      if (mounted) {
        setState(() => _isCreating = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("පැවරුම සාර්ථකව නිර්මාණය කරන ලදී")),
          );
          _formKey.currentState!.reset();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("දෝෂයක් සිදුවිය")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("පැවරුම්", style: GoogleFonts.notoSansSinhala()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "නව පැවරුමක් සදන්න",
              style: GoogleFonts.notoSansSinhala(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _componentType,
                        decoration: const InputDecoration(
                          labelText: "වර්ගය (Component)",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'hw',
                            child: Text("අත් අකුරු (Writing)"),
                          ),
                          DropdownMenuItem(
                            value: 'pron',
                            child: Text("උච්චාරණය (Pronunciation)"),
                          ),
                          DropdownMenuItem(
                            value: 'gram',
                            child: Text("ව්‍යාකරණ (Grammar)"),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _componentType = val!),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "අන්තර්ගතය (උදා: අම්මා)",
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? "Required" : null,
                        onSaved: (val) => _targetData = val!,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "කාලය (පැය)",
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: "24",
                        onSaved: (val) =>
                            _expiryHours = int.tryParse(val ?? '24') ?? 24,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCreating ? null : _createAssignment,
                          icon: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_task),
                          label: Text(_isCreating ? "Creating..." : "පවරන්න"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Placeholder for assignment reports as backend endpoint requires assignment ID
            // Ideally, we'd list assignments here first.
            Text(
              "Assignment Reports",
              style: GoogleFonts.notoSansSinhala(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "පැවරුම් ලැයිස්තුව ලබා ගැනීමට backend route එකක් නොමැත. (Only report by ID is available)",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
