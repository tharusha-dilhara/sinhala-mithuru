import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_client.dart'; // කලින් සෑදූ ෆයිල් එක

class AuthService {
  final Dio _dio = DioClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Teacher Login
  Future<bool> loginTeacher(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/teacher/login',
        data: {"email": email, "password": password},
      );

      if (response.statusCode == 200) {
        // Token එක Phone එකේ ආරක්ෂිතව Save කිරීම
        final token = response.data['access_token'];
        await _storage.write(key: 'access_token', value: token);
        await _storage.write(key: 'user_role', value: 'teacher');

        // Token එකෙන් Teacher ID එක අරගැනීම (JWT Decode)
        try {
          final parts = token.split('.');
          if (parts.length != 3) throw Exception('Invalid token');

          final payload = _decodeBase64(parts[1]);
          final payloadMap = json.decode(payload);

          if (payloadMap != null && payloadMap['sub'] != null) {
            await _storage.write(
              key: 'teacher_id',
              value: payloadMap['sub'].toString(),
            );
          }
        } catch (e) {
          print("Token decode error: $e");
        }

        return true;
      }
      return false;
    } on DioException catch (e) {
      // වැරදි password හෝ වෙනත් දෝෂ
      throw Exception(e.response?.data['detail'] ?? 'Login අසාර්ථකයි');
    }
  }

  // Student Pattern Login (Visual Pattern)
  Future<bool> loginStudent(int studentId, List<int> pattern) async {
    try {
      final response = await _dio.post(
        '/auth/student/verify-pattern',
        data: {"student_id": studentId, "pattern": pattern},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final token = response.data['access_token'];
        await _storage.write(key: 'access_token', value: token);
        await _storage.write(key: 'user_role', value: 'student');
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'රූප රටාව වැරදියි');
    }
  }

  // Get Student Profile
  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final response = await _dio.get('/student/profile');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load profile');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error loading profile');
    }
  }

  // --- 1. ගුරුවරු සෙවීමේ පහසුකම ---
  // Response: [{id, full_name, schools: {name, district}, classes: [{id, grade, class_name}]}]
  Future<List<dynamic>> searchTeachers(String name) async {
    try {
      final response = await _dio.get(
        '/auth/teacher/search',
        queryParameters: {'name': name},
      );

      if (response.data is List) {
        return response.data;
      }
      return [];
    } catch (e) {
      print("Search Error: $e");
      return [];
    }
  }

  // --- 2. සිසු ලියාපදිංචිය (class_id භාවිතා කරයි) ---
  // Backend expects: {name, class_id, pattern, parent_phone}
  // Response: {status: "success", student_id: int}
  Future<bool> signupStudent({
    required String name,
    required int classId,
    required String parentPhone,
    required List<int> pattern,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/student/signup',
        data: {
          "name": name,
          "class_id": classId,
          "pattern": pattern,
          "parent_phone": parentPhone,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['detail'] ?? 'සිසු ලියාපදිංචිය අසාර්ථකයි',
      );
    }
  }

  Future<List<dynamic>> getStudentsByParent(String phoneNumber) async {
    try {
      final response = await _dio.get('/auth/parent/students/$phoneNumber');
      if (response.statusCode == 200) {
        return response.data; // මෙය List එකක් ලෙස පැමිණේ
      }
      return [];
    } on DioException catch (e) {
      throw Exception('දරුවන් සොයාගත නොහැක: ${e.response?.data['detail']}');
    }
  }

  // 1. අලුත් ෆන්ක්ෂන් එක: දරුවාගේ විස්තර Save කරගැනීම
  Future<void> saveLastStudent(int id, String name) async {
    await _storage.write(key: 'student_id', value: id.toString());
    await _storage.write(key: 'student_name', value: name);
  }

  // 2. අලුත් ෆන්ක්ෂන් එක: අන්තිමට ලොග් වුන දරුවාගේ විස්තර ගැනීම
  Future<Map<String, String>?> getLastStudent() async {
    final id = await _storage.read(key: 'student_id');
    final name = await _storage.read(key: 'student_name');

    if (id != null && name != null) {
      return {'id': id, 'name': name};
    }
    return null;
  }

  // 3. අලුත් ෆන්ක්ෂන් එක: වෙනත් ළමයෙක්ට මාරු වීමට (Clear Data)
  Future<void> clearUser() async {
    await _storage.deleteAll();
  }

  // 4. Token එක Valid ද කියා බැලීම (සරල check එකක්)
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  // Get currently saved teacher ID
  Future<int?> getTeacherId() async {
    final idStr = await _storage.read(key: 'teacher_id');
    if (idStr != null) {
      return int.tryParse(idStr);
    }
    return null;
  }

  // 1. පාසල සොයාගැනීම හෝ අලුතින් සාදා ID එක ගැනීම
  // /school/smart-create භාවිත කරයි
  // Response: {status: "exists"|"created", school: {id, name, district}}
  Future<int> _getOrAddSchool(String name, String district) async {
    try {
      final response = await _dio.post(
        '/school/smart-create',
        data: {"name": name, "district": district},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['school'] != null && data['school']['id'] != null) {
          return data['school']['id'];
        }
      }
      throw Exception("පාසල සොයාගැනීමට නොහැක.");
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['detail'] ?? 'පාසල ඇතුලත් කිරීමේ දෝෂයක්',
      );
    }
  }

  // 2. ගුරු ලියාපදිංචිය (නම සහ දිස්ත්‍රික්කය භාවිතා කරයි)
  // Backend expects: {name, email, password, school_id}
  Future<bool> signupTeacher({
    required String name,
    required String email,
    required String password,
    required String schoolName,
    required String schoolDistrict,
  }) async {
    try {
      // පියවර 1: පාසලේ ID එක backend එකෙන් ඉල්ලා ගැනීම
      int schoolId = await _getOrAddSchool(schoolName, schoolDistrict);

      // පියවර 2: එම ID එක භාවිතා කර ගුරුවරයා ලියාපදිංචි කිරීම
      final response = await _dio.post(
        '/auth/teacher/signup',
        data: {
          "name": name,
          "email": email,
          "password": password,
          "school_id": schoolId,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['detail'] ?? 'ගුරු ලියාපදිංචිය අසාර්ථකයි',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Helper to decode Base64Url
  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }
}
