import 'dart:io';
import 'package:dio/dio.dart';
import '../constants.dart';

class DioClient {
  static final DioClient _singleton = DioClient._internal();
  late final Dio dio;

  factory DioClient() => _singleton;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // 1. Add Logging Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('[Dio Request] ${options.method} -> ${options.uri}');
          if (options.data != null) {
            print('[Dio Request Body] ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('[Dio Response] ${response.statusCode} <- ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('[Dio Error] ${e.type} : ${e.message} for ${e.requestOptions.uri}');
          return handler.next(e);
        },
      ),
    );

    // 2. Add Retry Interceptor
    dio.interceptors.add(_RetryInterceptor(dio));
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const int maxRetries = 3;

  _RetryInterceptor(this.dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    
    // Check if error is retryable (timeout, network issues, or 503/502)
    final isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
    
    final isNetworkError = err.type == DioExceptionType.connectionError ||
        err.error is SocketException;

    final isServerError = err.response != null &&
        (err.response!.statusCode == 502 || err.response!.statusCode == 503 || err.response!.statusCode == 504);

    final retryCount = options.extra['retryCount'] as int? ?? 0;

    if ((isTimeout || isNetworkError || isServerError) && retryCount < maxRetries) {
      final nextRetryCount = retryCount + 1;
      print('[Dio Retry] Retrying request (${options.uri}) - Attempt $nextRetryCount of $maxRetries');
      
      options.extra['retryCount'] = nextRetryCount;
      
      // Delay before retrying
      await Future.delayed(Duration(seconds: nextRetryCount * 2));
      
      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }
    
    return handler.next(err);
  }
}
