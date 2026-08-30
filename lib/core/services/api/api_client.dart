import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../utils/session_manager.dart';

/// Thin Dio wrapper. Every controller takes one of these by constructor
/// injection instead of calling Dio directly, so the auth header, timeouts and
/// 401 handling live in exactly one place.
class ApiClient {
  final String appBaseUrl;
  final int timeoutInSeconds = 30;

  String accessToken = '';
  late Dio _dio;
  late Map<String, String> _mainHeaders;

  ApiClient({required this.appBaseUrl}) {
    accessToken = SessionManager.getValue(kToken, value: '');
    _initDio();
    updateHeader(token: accessToken);
  }

  void _initDio() {
    final options = BaseOptions(
      baseUrl: appBaseUrl,
      connectTimeout: Duration(seconds: timeoutInSeconds),
      receiveTimeout: Duration(seconds: timeoutInSeconds),
      sendTimeout: Duration(seconds: timeoutInSeconds),
      // Accept 4xx so callers can read the server's error body instead of
      // catching an exception that has thrown the message away.
      validateStatus: (status) => status != null && status < 500,
    );

    _dio = Dio(options);

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (object) => debugPrint('====> $object'),
        ),
      );
    }
  }

  void removeToken() {
    accessToken = '';
    updateHeader();
  }

  void updateHeader({String? token}) {
    if (token != null) accessToken = token;

    _mainHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    _dio.options.headers = _mainHeaders;
  }

  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool isAutoLogout = true,
  }) async {
    try {
      final response = await _dio.get(
        uri,
        queryParameters: query,
        options: Options(headers: headers ?? _mainHeaders),
      );
      return _handleResponse(response, uri, isAutoLogout: isAutoLogout);
    } catch (e, s) {
      return _handleError(e, s);
    }
  }

  Future<Response> postData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    bool isAutoLogout = false,
  }) async {
    try {
      final response = await _dio.post(
        uri,
        data: body,
        options: Options(headers: headers ?? _mainHeaders),
      );
      return _handleResponse(response, uri, isAutoLogout: isAutoLogout);
    } catch (e, s) {
      return _handleError(e, s);
    }
  }

  Future<Response> putData(
    String uri,
    dynamic body, {
    Map<String, String>? headers,
    bool isAutoLogout = false,
  }) async {
    try {
      final response = await _dio.put(
        uri,
        data: body,
        options: Options(headers: headers ?? _mainHeaders),
      );
      return _handleResponse(response, uri, isAutoLogout: isAutoLogout);
    } catch (e, s) {
      return _handleError(e, s);
    }
  }

  Future<Response> deleteData(
    String uri, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool isAutoLogout = true,
  }) async {
    try {
      final response = await _dio.delete(
        uri,
        queryParameters: query,
        options: Options(headers: headers ?? _mainHeaders),
      );
      return _handleResponse(response, uri, isAutoLogout: isAutoLogout);
    } catch (e, s) {
      return _handleError(e, s);
    }
  }

  Response _handleResponse(
    Response response,
    String uri, {
    bool isAutoLogout = true,
  }) {
    if (response.statusCode == 401 && isAutoLogout) {
      accessToken = '';
      SessionManager.logout();
    }
    return response;
  }

  /// Never rethrows – callers always get a Response and only have to branch on
  /// `statusCode`. Status 0 means the request never reached the server.
  Future<Response> _handleError(dynamic error, StackTrace stackTrace) async {
    if (error is DioException) {
      if (error.response != null) return error.response!;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return Response(
          requestOptions: error.requestOptions,
          data: {'message': 'Request timeout'},
          statusCode: 408,
        );
      }

      if (error.type == DioExceptionType.connectionError) {
        return Response(
          requestOptions: error.requestOptions,
          data: {'message': 'No internet connection'},
          statusCode: 0,
        );
      }

      return Response(
        requestOptions: error.requestOptions,
        data: {'message': error.message ?? 'Unknown error occurred'},
        statusCode: 0,
      );
    }

    if (kDebugMode) {
      debugPrint('====> Non-Dio Error: $error');
      debugPrint('====> StackTrace: $stackTrace');
    }

    return Response(
      requestOptions: RequestOptions(path: ''),
      data: {'message': 'An unexpected error occurred'},
      statusCode: 0,
    );
  }
}
