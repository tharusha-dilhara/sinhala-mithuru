import 'dart:convert';
import 'package:dio/dio.dart';
import 'dio_client.dart';

class GameService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getNextTask() async {
    try {
      final response = await _dio.get('/game/next-task');

      if (response.statusCode == 200) {
        return response
            .data; // මෙහි state, targets, remaining සහ assets අඩංගු වේ
      } else {
        throw Exception('දත්ත ලබා ගැනීම අසාර්ථකයි');
      }
    } on DioException catch (e) {
      String errorMessage = 'සන්නිවේදන දෝෂයක්';
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  /// [audioFilePath] - Optional: .wav file path. If provided, file is sent
  /// directly as multipart/form-data instead of embedding as Base64.
  Future<Map<String, dynamic>> evaluateActivity({
    required String component,
    required Map<String, dynamic> rawInput,
    required double timeTaken,
    int? assignmentId,
    String? audioFilePath, // .wav ෆයිල් path එක (optional)
  }) async {
    try {
      // JSON දත්ත Form Data ලෙස සූදානම් කිරීම
      final formData = FormData.fromMap({
        "time_taken": timeTaken,
        "raw_input": jsonEncode(rawInput), // Map → JSON String
        "assignment_id": assignmentId, // null නම් FormData skip කරයි
      });

      // .wav ෆයිල් එකක් ලබා දී ඇත්නම් FormData එකට Add කිරීම
      if (audioFilePath != null) {
        formData.files.add(
          MapEntry(
            "audio_file",
            await MultipartFile.fromFile(
              audioFilePath,
              filename: audioFilePath.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/game/evaluate',
        queryParameters: {'component': component},
        data: formData, // JSON body වෙනුවට FormData
      );
      return response.data;
    } on DioException catch (e) {
      String errorMessage = 'ඇගයීම අසාර්ථකයි';
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }
}
