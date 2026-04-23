import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  // 1. Singleton Pattern: ඇප් එක පුරාම එකම Connection එකක් භාවිතා කරයි (Memory ඉතිරි කරයි)
  static final DioClient _singleton = DioClient._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Dio _dio;

  // ඔබේ Server IP එක මෙතනට දාන්න (AWS IP එක හෝ Local IP එක)
  // Emulator නම්: 10.0.2.2:8000
  // Phone එක WiFi නම්: 192.168.x.x:8000
  static const String _baseUrl = 'http://localhost:8080/';

  factory DioClient() {
    return _singleton;
  }

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(
          seconds: 60,
        ), // තත්පර 10කින් ප්‍රතිචාර නැත්නම් නවතී
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 2. Interceptors: සෑම request එකකටම Token එක ස්වයංක්‍රීයව අමුණයි
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Phone එකේ save කර ඇති token එක ගන්නවා
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // 🔴 වෙනස් කළ ස්ථානය: නියම Error එක පෙන්වයි
          print("API Error Status: ${e.response?.statusCode}");
          print(
            "API Error Data: ${e.response?.data}",
          ); // Backend එකෙන් එන නියම Error එක
          return handler.next(e);
        },
      ),
    );
  }

  // පිටතින් Dio එක ලබා ගැනීමට
  Dio get dio => _dio;
}
