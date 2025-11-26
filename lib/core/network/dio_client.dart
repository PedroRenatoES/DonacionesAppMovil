import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../error/exceptions.dart';

class DioClient {
  final Dio dio;
  final SharedPreferences sharedPreferences;
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  DioClient({required this.sharedPreferences})
    : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          // Verificar si hay error en el body aunque el código HTTP sea 200
          if (response.data is Map &&
              (response.data['error'] != null ||
                  response.data['message'] != null)) {
            final errorMessage = response.data['error'];

            // Convertir a DioException para manejo consistente
            final dioError = DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: errorMessage,
            );

            return handler.reject(dioError);
          }

          return handler.next(response);
        },
        onRequest: (options, handler) {
          final token = sharedPreferences.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Elimina el throw directo, deja que _handleError se encargue
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    // Primero verifica errores del body
    if (e.response?.data is Map &&
        (e.response?.data['error'] != null ||
            e.response?.data['message'] != null)) {
      final errorMessage =
          e.response?.data['error'] ?? e.response?.data['message'];
      return ServerException('${e.response?.statusCode} - $errorMessage');
    }

    // Luego verifica códigos de estado
    if (e.response?.statusCode == 401) {
      return TokenExpiredException(
        ' ${e.response?.statusCode}: Token expirado o inválido',
        e.response?.statusCode,
      );
    } else if (e.response?.statusCode == 404) {
      return NotFoundException('Recurso no encontrado');
    }

    // Luego errores de conexión
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException('Tiempo de conexión agotado');
    }

    // Fallback
    return ServerException(e.message ?? 'Error desconocido del servidor');
  }
}
