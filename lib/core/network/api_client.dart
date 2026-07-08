import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageService.instance.read('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final newToken = await SecureStorageService.instance.read('access_token');
            final req = error.requestOptions;
            req.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await _dio.fetch(req);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await SecureStorageService.instance.read('refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      await SecureStorageService.instance.write('access_token', data['accessToken']);
      await SecureStorageService.instance.write('refresh_token', data['refreshToken']);
      return true;
    } catch (_) {
      await SecureStorageService.instance.clear();
      return false;
    }
  }
}