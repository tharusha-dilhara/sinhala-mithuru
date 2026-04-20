import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/story/models/quiz_model.dart';

/// Modal backend API එකට සම්බන්ධ වී කතා සහ ප්‍රශ්න ජනනය කරන සේවාව
class ComprehensionService {
  static const String _baseHost =
      'it22276100--sinhala-mithuru-backend-v10-fastapi-app.modal.run';

  /// AI කතාවක් ජනනය කරයි
  /// [level]  – "සරල", "මධ්‍යම", "උසස්" වැනි අගයක්
  /// [theme]  – "සතුන්", "පාසල" වැනි මාතෘකාවක්
  /// [context] – කතාවට සන්දර්භය ("හාවට පාසල කැවීම" වැනි)
  Future<String> generateStory({
    required String level,
    required String theme,
    required String context,
  }) async {
    final uri = Uri.https(_baseHost, '/generate_story');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'level': level, 'theme': theme, 'context': context}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Backend එකෙන් එන story text එක ලබා ගැනීම
      return data['story'] ?? data['text'] ?? response.body;
    } else {
      throw Exception('කතාව ජනනය කිරීම අසාර්ථකයි: ${response.statusCode}');
    }
  }

  /// කතාවට අදාළ ප්‍රශ්න ජනනය කරයි
  /// [story] – AI කතාවේ සම්පූර්ණ පාඨය
  /// [level] – "සරල", "මධ්‍යම", "උසස්"
  Future<List<QuizQuestion>> generateQuiz({
    required String story,
    required String level,
  }) async {
    final uri = Uri.https(_baseHost, '/generate_quiz');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'story': story, 'level': level}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Backend එකෙන් questions list එක ලබා ගැනීම
      List<dynamic> questionsList;
      if (data is List) {
        questionsList = data;
      } else if (data['questions'] != null) {
        questionsList = data['questions'];
      } else if (data['quiz'] != null) {
        questionsList = data['quiz'];
      } else {
        questionsList = [];
      }

      return questionsList
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('ප්‍රශ්න ජනනය කිරීම අසාර්ථකයි: ${response.statusCode}');
    }
  }
}
