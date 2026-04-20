import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/background_service.dart';
import '../../services/sound_service.dart';
import '../auth/login_option_screen.dart';
import 'debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int currentLevel;
  final Function(String) onBackgroundChanged;

  const SettingsScreen({
    super.key,
    required this.currentLevel,
    required this.onBackgroundChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedBgKey = 'bg1';
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    final key = await AppBackgrounds.getSelectedKey();
    if (mounted) setState(() => _selectedBgKey = key);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "ලොග් අවුට් වෙන්නද?",
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.bold),
        ),
        content: Text("ඔබට විශ්වාසද?", style: GoogleFonts.notoSansSinhala()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "නැත",
              style: GoogleFonts.notoSansSinhala(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "ඔව්",
              style: GoogleFonts.notoSansSinhala(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginOptionScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _selectBackground(String key) async {
    await AppBackgrounds.setBackground(key);
    setState(() => _selectedBgKey = key);
    final path = AppBackgrounds.all.firstWhere((b) => b['key'] == key)['path']!;
    widget.onBackgroundChanged(path);
  }

  void _openDebugScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DebugScreen(currentLevel: widget.currentLevel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE8D3),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFBE8D3), Color(0xFFF7D1BA)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "සැකසුම්",
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Sound
                      _buildAudioSection(),

                      const SizedBox(height: 15),

                      // Background picker section
                      _buildBackgroundSection(),

                      const SizedBox(height: 15),

                      // Logout
                      _buildSettingsTile(
                        title: "ලොග් අවුට්",
                        subtitle: "ගිණුමෙන් ඉවත් වන්න",
                        icon: Icons.logout_rounded,
                        color: Colors.orange.shade100,
                        onTap: _logout,
                      ),

                      const SizedBox(height: 15),

                      // Debug
                      _buildSettingsTile(
                        title: "Debug",
                        subtitle: "Developer Panel — Level Debug",
                        icon: Icons.bug_report_rounded,
                        color: const Color(0xFF37474F),
                        onTap: _openDebugScreen,
                      ),

                      const SizedBox(height: 30),

                      Center(
                        child: Text(
                          "Version 1.0.0",
                          style: GoogleFonts.poppins(
                            color: Colors.brown.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Audio Section ────────────────────────────────────────────────────────
  Widget _buildAudioSection() {
    return AnimatedBuilder(
      animation: SoundService(),
      builder: (context, child) {
        final soundService = SoundService();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: soundService.isMuted
                              ? Colors.grey
                              : const Color(0xFFA6CCE3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          soundService.isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        "ශබ්ද පාලනය",
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: !soundService.isMuted,
                    onChanged: (_) => soundService.toggleMute(),
                    activeColor: Colors.orange,
                  ),
                ],
              ),
              if (!soundService.isMuted) ...[
                const SizedBox(height: 15),
                // BGM Volume Slider
                Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "පසුබිම් සංගීතය",
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade600,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.orange,
                    inactiveTrackColor: Colors.orange.shade100,
                    thumbColor: Colors.orange,
                    overlayColor: Colors.orange.withOpacity(0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: soundService.bgmVolume,
                    onChanged: (val) => soundService.setBgmVolume(val),
                  ),
                ),
                const SizedBox(height: 5),
                // Voice Volume Slider
                Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "කටහඬ",
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade600,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.blue.shade100,
                    thumbColor: Colors.blue,
                    overlayColor: Colors.blue.withOpacity(0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: soundService.voiceVolume,
                    onChanged: (val) => soundService.setVoiceVolume(val),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Background picker ────────────────────────────────────────────────────
  Widget _buildBackgroundSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFB39DDB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wallpaper_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "පසුබිම",
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                  Text(
                    "ක්‍රීඩා පසුබිම් රූපය",
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 13,
                      color: Colors.brown.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: AppBackgrounds.all.map((bg) {
              final isSelected = _selectedBgKey == bg['key'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectBackground(bg['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 9 / 14,
                            child: Image.asset(bg['path']!, fit: BoxFit.cover),
                          ),
                          // label overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.55),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Text(
                                bg['label']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansSinhala(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // checkmark if selected
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Settings tile ────────────────────────────────────────────────────────
  Widget _buildSettingsTile({
    required String title,
    String subtitle = '',
    required IconData icon,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansSinhala(
                        fontSize: 14,
                        color: Colors.brown.shade400,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
