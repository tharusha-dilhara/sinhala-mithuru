import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTopBar extends StatelessWidget {
  final int currentLevel;
  final double levelProgress;
  final bool isSoundOn;
  final VoidCallback onToggleSound;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap; // Add this
  final VoidCallback onLogoutTap;
  final bool isSmallScreen;

  const GameTopBar({
    super.key,
    required this.currentLevel,
    required this.levelProgress,
    required this.isSoundOn,
    required this.onToggleSound,
    required this.onSettingsTap,
    required this.onProfileTap, // Add this
    required this.onLogoutTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level Indicator Box (Now Clickable for Profile)
          GestureDetector(onTap: onProfileTap, child: _buildLevelBox()),

          // Action Buttons (Sound, Settings, Logout)
          Row(
            children: [
              _buildRoundIconButton(
                isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                isSoundOn ? const Color(0xFFA6CCE3) : Colors.grey,
                onTap: onToggleSound,
              ),
              const SizedBox(width: 10),
              _buildRoundIconButton(
                Icons.settings,
                const Color(0xFFF2D1D1),
                onTap: onSettingsTap,
              ),
              const SizedBox(width: 10),
              _buildRoundIconButton(
                Icons.logout_rounded,
                Colors.orange.shade100,
                onTap: onLogoutTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBox() {
    return Container(
      width: isSmallScreen ? 100 : 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "Level $currentLevel",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.stars_rounded, color: Colors.orange, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: levelProgress,
              backgroundColor: Colors.brown.shade50,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton(
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
