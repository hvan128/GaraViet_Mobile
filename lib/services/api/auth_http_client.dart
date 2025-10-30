import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'package:gara/services/auth/token_cache.dart';
import 'package:gara/services/auth/jwt_token_manager.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/services/error_handler.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/providers/user_provider.dart';
import 'package:gara/utils/network_utils.dart';

class AuthHttpClient {
  static HttpClient? _httpClient;
  static IOClient? _ioClient;

  // Tạo HttpClient với cấu hình bỏ qua SSL certificate
  static HttpClient _createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return true; // Bỏ qua việc xác thực certificate
    };
    return client;
  }

  // Lấy IOClient instance
  static IOClient get _client {
    _httpClient ??= _createHttpClient();
    _ioClient ??= IOClient(_httpClient!);
    return _ioClient!;
  }

  // Lấy headers với authentication token
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (includeAuth) {
      // Lazy refresh - check token trước khi gửi request
      await JwtTokenManager.ensureValidToken();

      final token = TokenCache.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Xử lý request với retry khi gặp 401/403
  static Future<Map<String, dynamic>> _makeRequestWithRetry(
    Future<Map<String, dynamic>> Function() requestFunction,
    bool includeAuth,
  ) async {
    // Thực hiện request lần đầu
    var response = await requestFunction();

    // Nếu là lỗi 401/403 và có authentication
    // Nhưng không refresh nếu là lỗi mạng
    final int? statusCode = response['statusCode'] as int?;
    final bool isNetworkError = response['isNetworkError'] == true;
    if (!response['success'] && includeAuth && !isNetworkError && (statusCode == 401 || statusCode == 403)) {
      // Với 403: không thử refresh, navigate thẳng về login
      if (statusCode == 403) {
        _navigateToLogin();
        return {
          'success': false,
          'message': response['message'] ?? 'Không có quyền truy cập. Vui lòng đăng nhập lại.',
          'data': null,
          'statusCode': 403,
          'requiresLogin': true,
        };
      }

      print('Gặp lỗi 401, thử refresh token...');
      final refreshSuccess = await JwtTokenManager.refreshTokenIfNeeded();

      if (refreshSuccess) {
        // Thử lại request với token mới
        response = await requestFunction();
        print('Retry request sau khi refresh token');
      } else {
        // Kiểm tra xem refresh token có còn tồn tại không
        final refreshToken = await Storage.getRefreshToken();
        if (refreshToken == null) {
          // Refresh token đã bị xóa, cần đăng nhập lại
          print('Refresh token đã bị xóa, cần đăng nhập lại');
          _navigateToLogin();
          return {
            'success': false,
            'message': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            'data': null,
            'statusCode': 401,
            'requiresLogin': true,
          };
        } else {
          // Vẫn còn refresh token. Chỉ coi là lỗi mạng nếu thực sự mất mạng
          if (!NetworkUtils.isConnected || isNetworkError) {
            print('Refresh token còn nhưng đang mất mạng, không navigate đến login');
            return {
              'success': false,
              'message': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
              'data': null,
              'statusCode': 0,
              'isNetworkError': true,
            };
          }
          // Không mất mạng: buộc đăng nhập lại để tránh kẹt ở màn hiện tại
          print('Refresh thất bại không do mạng, buộc điều hướng về login');
          _navigateToLogin();
          return {
            'success': false,
            'message': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            'data': null,
            'statusCode': 401,
            'requiresLogin': true,
          };
        }
      }
    }

    // Nếu là lỗi mạng và có refresh token, không navigate đến login
    if (!response['success'] && response['isNetworkError'] == true && includeAuth) {
      final refreshToken = await Storage.getRefreshToken();
      if (refreshToken != null) {
        print('Lỗi mạng nhưng vẫn có refresh token, không navigate đến login');
        return response; // Trả về response lỗi mạng mà không navigate
      }
    }

    return response;
  }

  // GET request
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    return await _makeRequestWithRetry(() async {
      try {
        final requestHeaders = await _getHeaders(includeAuth: includeAuth);
        if (headers != null) {
          requestHeaders.addAll(headers);
        }

        final uri = Uri.parse(url);
        final uriWithParams = queryParams != null ? uri.replace(queryParameters: queryParams) : uri;

        final response = await _client.get(uriWithParams, headers: requestHeaders);
        return _handleResponse(response);
      } catch (e) {
        // Xử lý lỗi mạng
        if (NetworkUtils.isNetworkError(e)) {
          return {
            'success': false,
            'message': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
            'data': null,
            'statusCode': 0,
            'isNetworkError': true,
          };
        }
        // Re-throw các lỗi khác
        rethrow;
      }
    }, includeAuth);
  }

  // POST request
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    bool includeAuth = true,
  }) async {
    return await _makeRequestWithRetry(() async {
      try {
        final requestHeaders = await _getHeaders(includeAuth: includeAuth);
        if (headers != null) {
          requestHeaders.addAll(headers);
        }

        final response = await _client.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );

        return _handleResponse(response);
      } catch (e) {
        // Xử lý lỗi mạng
        if (NetworkUtils.isNetworkError(e)) {
          return {
            'success': false,
            'message': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
            'data': null,
            'statusCode': 0,
            'isNetworkError': true,
          };
        }
        // Re-throw các lỗi khác
        rethrow;
      }
    }, includeAuth);
  }

  // POST request with form data
  static Future<Map<String, dynamic>> postFormData(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? formData,
    bool includeAuth = true,
  }) async {
    return await _makeRequestWithRetry(() async {
      try {
        final requestHeaders = await _getHeaders(includeAuth: includeAuth);
        // Override Content-Type for form data
        requestHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
        if (headers != null) {
          requestHeaders.addAll(headers);
        }

        // Convert form data to URL encoded string
        String body = '';
        if (formData != null && formData.isNotEmpty) {
          body = formData.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
        }

        final response = await _client.post(Uri.parse(url), headers: requestHeaders, body: body);

        return _handleResponse(response);
      } catch (e) {
        // Xử lý lỗi mạng
        if (NetworkUtils.isNetworkError(e)) {
          return {
            'success': false,
            'message': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
            'data': null,
            'statusCode': 0,
            'isNetworkError': true,
          };
        }
        // Re-throw các lỗi khác
        rethrow;
      }
    }, includeAuth);
  }

  // POST request with multipart form data
  static Future<Map<String, dynamic>> postMultipartFormData(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? formData,
    List<http.MultipartFile>? files,
    bool includeAuth = true,
  }) async {
    return await _makeRequestWithRetry(() async {
      try {
        final requestHeaders = await _getHeaders(includeAuth: includeAuth);
        // Remove Content-Type header to let http package set it automatically for multipart
        requestHeaders.remove('Content-Type');
        if (headers != null) {
          requestHeaders.addAll(headers);
        }

        // Create multipart request
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers.addAll(requestHeaders);

        // Add form fields
        if (formData != null && formData.isNotEmpty) {
          request.fields.addAll(formData);
        }

        // Add files
        if (files != null && files.isNotEmpty) {
          request.files.addAll(files);
        }

        final streamedResponse = await _client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        return _handleResponse(response);
      } catch (e) {
        // Xử lý lỗi mạng
        if (NetworkUtils.isNetworkError(e)) {
          return {
            'success': false,
            'message': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
            'data': null,
            'statusCode': 0,
            'isNetworkError': true,
          };
        }
        // Re-throw các lỗi khác
        rethrow;
      }
    }, includeAuth);
  }

  // PUT request
  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    bool includeAuth = true,
  }) async {
    return await _makeRequestWithRetry(() async {
      try {
        final requestHeaders = await _getHeaders(includeAuth: includeAuth);
        if (headers != null) {
          requestHeaders.addAll(headers);
        }

        final response = await _client.put(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );

        return _handleResponse(response);
      } catch (e) {
        // Xử lý lỗi mạng
        if (NetworkUtils.isNetworkError(e)) {
          return {
            'success': false,
            'message': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
            'data': null,
            'statusCode': 0,
            'isNetworkError': true,
          };
        }
        // Re-throw các lỗi khác
        rethrow;
      }
    }, includeAuth);
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool includeAuth = true,
  }) async {
    return await _makeRequestWithRetry(() async {
      try {
        final requestHeaders = await _getHeaders(includeAuth: includeAuth);
        if (headers != null) {
          requestHeaders.addAll(headers);
        }

        final response = await _client.delete(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );

        return _handleResponse(response);
      } catch (e) {
        // Xử lý lỗi mạng
        if (NetworkUtils.isNetworkError(e)) {
          return {
            'success': false,
            'message': 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
            'data': null,
            'statusCode': 0,
            'isNetworkError': true,
          };
        }
        // Re-throw các lỗi khác
        rethrow;
      }
    }, includeAuth);
  }

  // Xử lý response
  static Map<String, dynamic> _handleResponse(dynamic response) {
    try {
      final responseBody = response.body as String;

      // Kiểm tra nếu response là HTML (thường là error page)
      if (responseBody.startsWith('<!doctype html>') || responseBody.startsWith('<html')) {
        return {
          'success': false,
          'message': 'API endpoint không tồn tại hoặc server lỗi (HTML response)',
          'data': null,
          'statusCode': response.statusCode,
        };
      }

      // Kiểm tra nếu response không phải JSON
      if (!responseBody.trim().startsWith('{') && !responseBody.trim().startsWith('[')) {
        return {
          'success': false,
          'message': 'Response không phải JSON format',
          'data': responseBody,
          'statusCode': response.statusCode,
        };
      }

      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      // Kiểm tra xem backend đã trả về cấu trúc chuẩn chưa
      if (responseData.containsKey('success') && responseData.containsKey('message')) {
        // Backend đã trả về cấu trúc chuẩn, không cần wrap
        return {...responseData, 'statusCode': response.statusCode};
      } else {
        // Backend chưa có cấu trúc chuẩn, wrap như cũ
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
            'success': true,
            'message': responseData['message'],
            'data': responseData['data'] ?? responseData,
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Request failed',
            'data': responseData,
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': ErrorHandler.getErrorMessage(e),
        'data': response.body,
        'statusCode': response.statusCode,
      };
    }
  }

  // Navigate đến login screen
  static void _navigateToLogin() {
    try {
      // Clear auth state trước khi navigate
      JwtTokenManager.clearTokens();
      // Đồng thời clear UserProvider để tránh hiển thị dữ liệu người dùng cũ
      UserProvider().clearUserInfo();

      // Hiển thị thông báo trước khi navigate
      _showLogoutNotification();

      // Navigate đến login screen
      Navigate.pushNamedAndRemoveAll('/login');
    } catch (e) {
      print('Lỗi khi navigate đến login: $e');
    }
  }

  // Hiển thị thông báo logout
  static void _showLogoutNotification() {
    try {
      // Lấy context từ navigation key
      final context = Navigate().navigationKey.currentContext;
      if (context != null) {
        AppToastHelper.showInfo(context, message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
    } catch (e) {
      print('Lỗi khi hiển thị thông báo: $e');
    }
  }

  // Đóng client
  static void close() {
    _ioClient?.close();
    _httpClient?.close();
    _ioClient = null;
    _httpClient = null;
  }
}
