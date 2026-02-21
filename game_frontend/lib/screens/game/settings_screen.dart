import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../auth/login_option_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool initialSoundState;
  final Function(bool) onSoundToggle;

  const SettingsScreen({
    super.key,
    required this.initialSoundState,
    required this.onSoundToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isSoundOn;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _isSoundOn = widget.initialSoundState;
  }

  void _toggleSound() {
    setState(() {
      _isSoundOn = !_isSoundOn;
    });
    widget.onSoundToggle(_isSoundOn);
  }

  Future<void> _logout() async {
    // Confirm logout first
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE8D3),
      body: Stack(
        children: [
          // Background decoration (optional, keeping it simple but premium)
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

                const SizedBox(height: 20),

                // Settings List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildSettingsTile(
                        title: "ශබ්දය",
                        subtitle: _isSoundOn ? "ක්‍රියාත්මකයි" : "අක්‍රියයි",
                        icon: _isSoundOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: const Color(0xFFA6CCE3),
                        trailing: Switch(
                          value: _isSoundOn,
                          onChanged: (_) => _toggleSound(),
                          activeColor: Colors.orange,
                        ),
                        onTap: _toggleSound,
                      ),

                      const SizedBox(height: 15),

                      _buildSettingsTile(
                        title: "ලොග් අවුට්",
                        subtitle: "ගිණුමෙන් ඉවත් වන්න",
                        icon: Icons.logout_rounded,
                        color: Colors.orange.shade100,
                        onTap: _logout,
                      ),

                      const SizedBox(height: 30),

                      // Version Info
                      Center(
                        child: Text(
                          "Version 1.0.0",
                          style: GoogleFonts.poppins(
                            color: Colors.brown.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ),
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

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
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
