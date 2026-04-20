import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  Future<void> generateAndShareReport(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Load a font that supports Sinhala characters if possible, or use a default one.
    // For full Sinhala support in PDF, a TTF font file containing Sinhala glyphs is needed.
    // Here we'll use a standard font, but in a real app, you'd load a custom TTF.
    // final fontData = await rootBundle.load("assets/fonts/NotoSansSinhala.ttf");
    // final ttf = pw.Font.ttf(fontData);

    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final activities = (data['recent_activities'] as List<dynamic>?) ?? [];
    final dailyStats = (data['daily_stats'] as List<dynamic>?) ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 10),
            _buildStudentDetails(profile),
            pw.SizedBox(height: 20),
            _buildDailyStatsSection(dailyStats),
            pw.SizedBox(height: 20),
            _buildActivitiesSection(activities),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    // Use Printing.sharePdf which works universally:
    // On mobile screens, it opens the native share dialog.
    // On Windows/Desktop, it opens a "Save As" file dialog, letting the user chose where to save it.
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'student_performance_report.pdf',
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sinhala Mithuru', // Branding
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepOrange700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Student Performance Report',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.normal,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.orange400, thickness: 2),
      ],
    );
  }

  pw.Widget _buildStudentDetails(Map<String, dynamic> profile) {
    if (profile.isEmpty) return pw.SizedBox();

    final name = profile['name'] ?? 'Not Provided';
    final grade = profile['class_name'] ?? 'Not Provided';
    final gameState = profile['game_state'] as Map<String, dynamic>? ?? {};
    final totalScore = gameState['total_score'] ?? 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Student Name:',
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 12),
              ),
              pw.Text(
                name.toString(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total Score:',
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 12),
              ),
              pw.Text(
                totalScore.toString(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  color: PdfColors.green700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDailyStatsSection(List<dynamic> dailyStats) {
    if (dailyStats.isEmpty) {
      return pw.Text(
        "No daily summary data available.",
        style: const pw.TextStyle(color: PdfColors.grey700),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Progress Summary',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Total', 'Correct', 'Incorrect', 'Percentage'],
          data: dailyStats.map((stat) {
            final dateStr = stat['date']?.toString() ?? 'N/A';
            final total = stat['total']?.toString() ?? '0';
            final correct = stat['correct']?.toString() ?? '0';
            final incorrect = stat['incorrect']?.toString() ?? '0';
            final percentage = stat['percentage'];
            final percStr = percentage != null
                ? '${double.parse(percentage.toString()).toStringAsFixed(1)}%'
                : '0%';

            return [dateStr, total, correct, incorrect, percStr];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue400),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          cellAlignment: pw.Alignment.center,
        ),
      ],
    );
  }

  pw.Widget _buildActivitiesSection(List<dynamic> activities) {
    if (activities.isEmpty) {
      return pw.Text(
        "No recent activities.",
        style: const pw.TextStyle(color: PdfColors.grey700),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Activities',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Task', 'Score', 'Status'],
          data: activities.map((act) {
            final dateStr = act['created_at'].toString();
            final date = dateStr.length > 10
                ? dateStr.substring(0, 10)
                : dateStr;
            final compType = act['component_type'] ?? 'Other';

            String label = 'Other';
            switch (compType) {
              case 'hw':
                label = 'Writing';
                break;
              case 'pron':
                label = 'Pronunciation';
                break;
              case 'gram':
                label = 'Grammar';
                break;
              case 'narr':
                label = 'Narrative';
                break;
            }

            final score = act['score']?.toString() ?? '0';
            final status = (act['is_correct'] == true) ? 'Passed' : 'Failed';

            return [date, label, score, status];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green400),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          cellAlignment: pw.Alignment.center,
        ),
      ],
    );
  }
}
