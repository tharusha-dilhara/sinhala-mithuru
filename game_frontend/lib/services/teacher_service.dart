import 'package:dio/dio.dart';
import '../models/teacher_models.dart';
import 'dio_client.dart';

class TeacherService {
  final Dio _dio = DioClient().dio;

  Future<TeacherDashboardSummary?> getDashboardSummary({int? classId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (classId != null) params['class_id'] = classId;
      final response = await _dio.get(
        '/teacher/summary',
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        return TeacherDashboardSummary.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching dashboard summary: $e');
    }
    return null;
  }

  Future<List<StudentRank>> getLeaderboard({int? classId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (classId != null) params['class_id'] = classId;
      final response = await _dio.get(
        '/teacher/leaderboard',
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => StudentRank.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
    }
    return [];
  }

  Future<ClassDifficultyAnalytics?> getClassWeaknesses({int? classId}) async {
    try {
      final Map<String, dynamic> params = {'component': 'pron'};
      if (classId != null) params['class_id'] = classId;
      final response = await _dio.get(
        '/teacher/analytics/difficult-items',
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        return ClassDifficultyAnalytics.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching class weaknesses: $e');
    }
    return null;
  }

  // --- Student Details ---
  Future<StudentDetailedReport?> getStudentDetailedReport(int studentId) async {
    try {
      final response = await _dio.get('/teacher/student/$studentId/report');
      if (response.statusCode == 200) {
        return StudentDetailedReport.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching student report: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getStudentAnalytics(int studentId) async {
    try {
      final response = await _dio.get('/teacher/analytics/student/$studentId');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error fetching student analytics: $e');
    }
    return null;
  }

  // --- Bulk Actions ---
  Future<bool> bulkPromoteStudents(List<int> studentIds) async {
    try {
      final response = await _dio.post(
        '/teacher/bulk-promote',
        data: {'student_ids': studentIds},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error promoting students: $e');
      return false;
    }
  }

  Future<bool> resetStudentPattern(int studentId, List<int> newPattern) async {
    try {
      final response = await _dio.post(
        '/teacher/reset-pattern',
        data: {'student_id': studentId, 'new_pattern': newPattern},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error resetting pattern: $e');
      return false;
    }
  }

  // --- Assignments ---

  // Create Smart Assignment
  Future<bool> createSmartAssignment({
    required int classId,
    required String componentType,
    required String targetData,
    required int expiryHours,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        '/teacher/smart-assign',
        data: {
          'class_id': classId,
          'component_type': componentType,
          'target_data': targetData,
          'expiry_hours': expiryHours,
          'metadata': metadata,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating assignment: $e');
      return false;
    }
  }

  Future<AssignmentDetailedReport?> getAssignmentReport(
    int assignmentId,
  ) async {
    try {
      final response = await _dio.get(
        '/teacher/assignment-report/$assignmentId',
      );
      if (response.statusCode == 200) {
        return AssignmentDetailedReport.fromJson(response.data);
      }
    } catch (e) {
      print('Error fetching assignment report: $e');
    }
    return null;
  }

  Future<bool> extendAssignmentDeadline(
    int assignmentId,
    int extensionHours,
  ) async {
    try {
      final response = await _dio.post(
        '/teacher/extend-deadline',
        data: {
          'assignment_id': assignmentId,
          'extension_hours': extensionHours,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error extending deadline: $e');
      return false;
    }
  }
}
