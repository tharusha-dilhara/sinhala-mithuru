import 'package:shared_preferences/shared_preferences.dart';

/// Available background image paths
class AppBackgrounds {
  static const List<Map<String, String>> all = [
    {
      'key': 'bg1',
      'path': 'assets/images/background1.png',
      'label': 'නිල් අහස', // Blue sky (original)
    },
    {
      'key': 'bg2',
      'path': 'assets/images/background2.png',
      'label': 'කෙසෙල් වතු', // Meadow
    },
    {
      'key': 'bg3',
      'path': 'assets/images/background3.png',
      'label': 'රාත්‍රී හිසිළ', // Twilight
    },
  ];

  static const String _prefKey = 'selected_background';
  static const String _defaultBg = 'bg1';

  static Future<String> getSelectedPath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefKey) ?? _defaultBg;
    return all.firstWhere(
      (b) => b['key'] == key,
      orElse: () => all[0],
    )['path']!;
  }

  static Future<String> getSelectedKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? _defaultBg;
  }

  static Future<void> setBackground(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key);
  }
}
