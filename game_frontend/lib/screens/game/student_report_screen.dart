import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/pdf_service.dart';

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({Key? key}) : super(key: key);

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  final AuthService _authService = AuthService();
  final PdfService _pdfService = PdfService();
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String? _error;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _authService.getStudentDetailedReport();
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePdfAction() async {
    if (_reportData == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      await _pdfService.generateAndShareReport(_reportData!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "PDF වාර්තාව සාර්ථකව සකසන ලදී!",
              style: GoogleFonts.notoSansSinhala(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "PDF සෑදීමේදී දෝෂයක්: $e",
              style: GoogleFonts.notoSansSinhala(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE8D3), // Matching app theme
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "දෙමාපිය වාර්තාව",
          style: GoogleFonts.notoSansSinhala(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isGeneratingPdf
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  tooltip: "PDF එක ලබාගන්න (Download/Share PDF)",
                  onPressed: _reportData != null ? _handlePdfAction : null,
                ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              "දත්ත ලබා ගනිමින්...",
              style: GoogleFonts.notoSansSinhala(color: Colors.brown.shade600),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 20),
              Text(
                "වාර්තාව ලබා ගැනීමේදී දෝෂයක්:",
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text(
                  "නැවත උත්සහ කරන්න",
                  style: GoogleFonts.notoSansSinhala(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_reportData == null) {
      return Center(
        child: Text(
          "දත්ත නොමැත",
          style: GoogleFonts.notoSansSinhala(fontSize: 18),
        ),
      );
    }

    final activities =
        (_reportData!['recent_activities'] as List<dynamic>?) ?? [];
    final learningCurve =
        (_reportData!['learning_curve'] as List<dynamic>?) ?? [];
    final dailyStats = (_reportData!['daily_stats'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (learningCurve.isNotEmpty) ...[
            _buildSectionTitle(
              "සමස්ත ප්‍රගතිය",
              Icons.trending_up,
              Colors.blue,
            ),
            const SizedBox(height: 15),
            _buildLearningCurveChart(learningCurve),
            const SizedBox(height: 30),
          ],

          if (dailyStats.isNotEmpty) ...[
            _buildSectionTitle(
              "දිනපතා සාරාංශය",
              Icons.calendar_month,
              Colors.purple,
            ),
            const SizedBox(height: 15),
            _buildDailyStatsList(dailyStats),
            const SizedBox(height: 30),
          ],

          _buildSectionTitle(
            "මෑත ක්‍රියාකාරකම්",
            Icons.history_edu,
            Colors.green,
          ),
          const SizedBox(height: 15),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "තවම ක්‍රියාකාරකම් කර නැත.",
                      style: GoogleFonts.notoSansSinhala(
                        color: Colors.brown.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final act = activities[index];
                final isCorrect = act['is_correct'] == true;
                final score = (act['score'] ?? 0).toDouble();
                final compType = act['component_type'] ?? '';
                final dateString = act['created_at'].toString();
                final dateStart = dateString.length > 10
                    ? dateString.substring(0, 10)
                    : dateString;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border(
                      left: BorderSide(
                        color: isCorrect
                            ? Colors.green.shade400
                            : Colors.red.shade400,
                        width: 5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCorrect ? Icons.star_rounded : Icons.close_rounded,
                          color: isCorrect
                              ? Colors.green.shade600
                              : Colors.red.shade400,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getComponentLabel(compType),
                              style: GoogleFonts.notoSansSinhala(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStart,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "ලකුණු",
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            "${score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1)}",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLearningCurveChart(List<dynamic> learningCurve) {
    if (learningCurve.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "ප්‍රස්ථාරය පෙන්වීමට දත්ත නොමැත.",
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansSinhala(color: Colors.brown.shade600),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double maxScore = 0;

    for (int i = 0; i < learningCurve.length; i++) {
      final item =
          learningCurve[learningCurve.length -
              1 -
              i]; // Display oldest to newest

      double score = (item['avg_score'] ?? item['daily_score'] ?? 0).toDouble();
      if (item.containsKey('avg_score') && score <= 1.0 && score > 0) {
        score = score * 100;
      }

      if (score > maxScore) maxScore = score;

      final xValue = learningCurve.length == 1 ? 0.5 : i.toDouble();
      spots.add(FlSpot(xValue, score));
    }

    // Give some padding to the max Y axis
    final maxY = (maxScore > 0 ? maxScore * 1.2 : 100)
        .clamp(10.0, 1000.0)
        .toDouble();

    final maxXValue = learningCurve.length > 1
        ? (learningCurve.length - 1).toDouble()
        : 1.0;
    final hInterval = (maxY / 4) > 0 ? (maxY / 4) : 1.0;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ළමයාගේ දිනපතා ලකුණු වර්ධනය",
            style: GoogleFonts.notoSansSinhala(
              color: Colors.brown.shade600,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: hInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (learningCurve.length == 1 && value.toInt() == 0) {
                          final curveItem = learningCurve[0];
                          final dateStr =
                              (curveItem['day']?.toString() ??
                              curveItem['date']?.toString() ??
                              '');
                          final dayComponent = dateStr.length >= 10
                              ? dateStr.substring(5, 10).replaceAll('-', '/')
                              : '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayComponent,
                              style: GoogleFonts.poppins(
                                color: Colors.brown.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        if (value.toInt() >= 0 &&
                            value.toInt() < learningCurve.length) {
                          // Display abbreviated date like "03/05"
                          final idx = learningCurve.length - 1 - value.toInt();
                          final curveItem = learningCurve[idx];
                          final dateStr =
                              (curveItem['day']?.toString() ??
                              curveItem['date']?.toString() ??
                              '');
                          final dayComponent = dateStr.length >= 10
                              ? dateStr.substring(5, 10).replaceAll('-', '/')
                              : '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayComponent,
                              style: GoogleFonts.poppins(
                                color: Colors.brown.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: hInterval,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.brown.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: maxXValue,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.orange.shade500,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: Colors.orange.shade700,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.notoSansSinhala(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
      ],
    );
  }

  String _getComponentLabel(String comp) {
    switch (comp) {
      case 'hw':
        return 'අකුරු ලිවීම';
      case 'pron':
        return 'උච්චාරණය';
      case 'gram':
        return 'ව්‍යාකරණ';
      case 'narr':
        return 'කතන්දර';
      default:
        return 'වෙනත්';
    }
  }

  Widget _buildDailyStatsList(List<dynamic> dailyStats) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dailyStats.length,
      itemBuilder: (context, index) {
        final stat = dailyStats[index];
        final dateStr = stat['date']?.toString() ?? 'N/A';
        final total = stat['total'] ?? 0;
        final correct = stat['correct'] ?? 0;
        final incorrect = stat['incorrect'] ?? 0;
        final percentageRaw = stat['percentage'];
        final percentage = percentageRaw != null
            ? double.parse(percentageRaw.toString())
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: Colors.purple.shade300,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: percentage >= 50
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${percentage.toStringAsFixed(1)}%",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: percentage >= 50
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBadge(
                    "මුළු ප්‍රමාණය",
                    total.toString(),
                    Colors.blue,
                  ),
                  _buildStatBadge("නිවැරදි", correct.toString(), Colors.green),
                  _buildStatBadge("වැරදි", incorrect.toString(), Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade100),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansSinhala(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
