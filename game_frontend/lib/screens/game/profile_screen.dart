import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _error = "";
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await _authService.getStudentProfile();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE8D3),
      appBar: AppBar(
        title: Text(
          "මගේ විස්තර",
          style: GoogleFonts.notoSansSinhala(
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.brown),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _error.isNotEmpty
          ? Center(
              child: Text(
                "දෝෂයක්: $_error",
                style: TextStyle(color: Colors.red.shade400),
              ),
            )
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_profileData == null) return const SizedBox.shrink();

    final name = _profileData!['name'] ?? "සිසුවා";
    final school = _profileData!['school_name'] ?? "පාසල නොදනී";
    final className = _profileData!['class_name'] ?? "";
    final currentLevel = _profileData!['current_level'] ?? 1;
    final totalScore = _profileData!['total_score'] ?? 0.0;
    final pattern = (_profileData!['pattern'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar & Name
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.shade300, width: 4),
                    color: Colors.white,
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800,
                  ),
                ),
                Text(
                  school,
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 16,
                    color: Colors.brown.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Stats Cards
          _buildInfoCard("පන්තිය", "$className ශ්‍රේණියේ"),
          _buildInfoCard("දැනට පවතින මට්ටම", "Level $currentLevel"),
          _buildInfoCard("මුළු ලකුණු", totalScore.toStringAsFixed(1)),

          const SizedBox(height: 20),

          // Pattern Display (Optional - if we want to show their pattern)
          if (pattern.isNotEmpty) ...[
            Text(
              "මගේ රටාව",
              style: GoogleFonts.notoSansSinhala(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 100, // Fixed height for 3x3 grid preview
              width: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final isSelected = pattern.contains(index);
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansSinhala(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
