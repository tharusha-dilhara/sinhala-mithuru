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
      throw Exception(e.response?.data['detail'] ?? 'සන්නිවේදන දෝෂයක්');
    }
  }

  Future<Map<String, dynamic>> evaluateActivity({
    required String component,
    required Map<String, dynamic> rawInput,
    required double timeTaken,
    int? assignmentId,
  }) async {
    try {
      final response = await _dio.post(
        '/game/evaluate',
        queryParameters: {'component': component},
        data: {
          "assignment_id": assignmentId,
          "raw_input": rawInput,
          "time_taken": timeTaken,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'ඇගයීම අසාර්ථකයි');
    }
  }
}
