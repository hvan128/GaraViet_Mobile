import 'package:gara/config.dart';
import 'package:gara/services/api/auth_http_client.dart';
import 'package:gara/services/auth/auth_helper.dart';
import 'package:gara/services/error_handler.dart';
import 'package:gara/utils/network_utils.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:gara/widgets/app_toast.dart';

class BaseApiService {
  // GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      
      final url = '${Config.baseUrl}$endpoint';
      final response = await AuthHttpClient.get(
        url,
        queryParams: queryParams,
        includeAuth: includeAuth,
      );
      
      // Kiểm tra nếu response là HTML (thường là error page)
      if (response is String && response.toString().startsWith('<!doctype html>')) {
        AppToastHelper.showGlobalError('Lỗi hệ thống, vui lòng thử lại sau!');
        return {
          'success': false,
          'message': 'Lỗi hệ thống, vui lòng thử lại sau!',
          'data': null,
        };
      }
      
      // Tự động xử lý auth error cho tất cả request
      if (includeAuth && AuthHelper.checkAuthError(response)) {
        // AuthHelper đã tự động navigate đến login
        return response; // Response đã chứa thông tin lỗi auth
      }
      
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (response['isNetworkError'] == true) {
        return response;
      }
      
      return response;
    } catch (e) {
      // Log chi tiết lỗi API
      developer.log(
        'API Error: $endpoint',
        name: 'BaseApiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (NetworkUtils.isNetworkError(e)) {
        // Chỉ log, không hiển thị toast
      } else {
        AppToastHelper.showGlobalError(ErrorHandler.getErrorMessage(e));
      }
      
      return {
        'success': false,
        'message': ErrorHandler.getErrorMessage(e),
        'data': null,
        'error': e.toString(),
        'errorDetails': ErrorHandler.getErrorDetails(e),
        'endpoint': endpoint,
        'method': 'API',
      };
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      
      final url = '${Config.baseUrl}$endpoint';
      final response = await AuthHttpClient.post(
        url,
        body: body, 
        includeAuth: includeAuth,
      );
      
      // Kiểm tra nếu response là HTML (thường là error page)
      if (response is String && response.toString().startsWith('<!doctype html>')) {
        AppToastHelper.showGlobalError('Lỗi hệ thống, vui lòng thử lại sau!');
        return {
          'success': false,
          'message': 'Lỗi hệ thống, vui lòng thử lại sau!',
          'data': null,
        };
      }
      
      // Tự động xử lý auth error cho tất cả request  
      if (includeAuth && AuthHelper.checkAuthError(response)) {
        // AuthHelper đã tự động navigate đến login
        return response; // Response đã chứa thông tin lỗi auth
      }
      
      return response;
    } catch (e) {
      // Log chi tiết lỗi API
      developer.log(
        'API Error: $endpoint',
        name: 'BaseApiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (NetworkUtils.isNetworkError(e)) {
        // Chỉ log, không hiển thị toast
      } else {
        AppToastHelper.showGlobalError(ErrorHandler.getErrorMessage(e));
      }
      
      return {
        'success': false,
        'message': ErrorHandler.getErrorMessage(e),
        'data': null,
        'error': e.toString(),
        'errorDetails': ErrorHandler.getErrorDetails(e),
        'endpoint': endpoint,
        'method': 'API',
      };
    }
  }

  // POST request with form data
  static Future<Map<String, dynamic>> postFormData(
    String endpoint, {
    Map<String, String>? formData,
    bool includeAuth = true,
  }) async {
    try {
      final url = '${Config.baseUrl}$endpoint';
      final response = await AuthHttpClient.postFormData(
        url,
        formData: formData,
        includeAuth: includeAuth,
      );
      
      // Kiểm tra nếu response là HTML (thường là error page)
      if (response is String && response.toString().startsWith('<!doctype html>')) {
        AppToastHelper.showGlobalError('API endpoint không tồn tại hoặc server lỗi');
        return {
          'success': false,
          'message': 'API endpoint không tồn tại hoặc server lỗi',
          'data': null,
        };
      }
      
      // Tự động xử lý auth error cho tất cả request
      if (includeAuth && AuthHelper.checkAuthError(response)) {
        // AuthHelper đã tự động navigate đến login
        return response; // Response đã chứa thông tin lỗi auth
      }
      
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (response['isNetworkError'] == true) {
        return response;
      }
      
      return response;
    } catch (e) {
      // Log chi tiết lỗi API
      developer.log(
        'API Error: $endpoint',
        name: 'BaseApiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (NetworkUtils.isNetworkError(e)) {
        // Chỉ log, không hiển thị toast
      } else {
        AppToastHelper.showGlobalError(ErrorHandler.getErrorMessage(e));
      }
      
      return {
        'success': false,
        'message': ErrorHandler.getErrorMessage(e),
        'data': null,
        'error': e.toString(),
        'errorDetails': ErrorHandler.getErrorDetails(e),
        'endpoint': endpoint,
        'method': 'API',
      };
    }
  }

  // POST request with multipart form data
  static Future<Map<String, dynamic>> postMultipartFormData(
    String endpoint, {
    Map<String, String>? formData,
      List<dynamic>? files, // http.MultipartFile expected
    bool includeAuth = true,
  }) async {
    try {
      final url = '${Config.baseUrl}$endpoint';
      final response = await AuthHttpClient.postMultipartFormData(
        url,
        formData: formData,
        files: files?.cast(),
        includeAuth: includeAuth,
      );
      
      // Kiểm tra nếu response là HTML (thường là error page)
      if (response is String && response.toString().startsWith('<!doctype html>')) {
        AppToastHelper.showGlobalError('API endpoint không tồn tại hoặc server lỗi');
        return {
          'success': false,
          'message': 'API endpoint không tồn tại hoặc server lỗi',
          'data': null,
        };
      }
      
      // Tự động xử lý auth error cho tất cả request
      if (includeAuth && AuthHelper.checkAuthError(response)) {
        // AuthHelper đã tự động navigate đến login
        return response; // Response đã chứa thông tin lỗi auth
      }
      
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (response['isNetworkError'] == true) {
        return response;
      }
      
      return response;
    } catch (e) {
      // Log chi tiết lỗi API
      developer.log(
        'API Error: $endpoint',
        name: 'BaseApiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (NetworkUtils.isNetworkError(e)) {
        // Chỉ log, không hiển thị toast
      } else {
        AppToastHelper.showGlobalError(ErrorHandler.getErrorMessage(e));
      }
      
      return {
        'success': false,
        'message': ErrorHandler.getErrorMessage(e),
        'data': null,
        'error': e.toString(),
        'errorDetails': ErrorHandler.getErrorDetails(e),
        'endpoint': endpoint,
        'method': 'API',
      };
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = '${Config.baseUrl}$endpoint';
      final response = await AuthHttpClient.put(
        url,
        body: body,
        includeAuth: includeAuth,
      );
      
      // Kiểm tra nếu response là HTML (thường là error page)
      if (response is String && response.toString().startsWith('<!doctype html>')) {
        AppToastHelper.showGlobalError('API endpoint không tồn tại hoặc server lỗi');
        return {
          'success': false,
          'message': 'API endpoint không tồn tại hoặc server lỗi',
          'data': null,
        };
      }
      
      // Tự động xử lý auth error cho tất cả request
      if (includeAuth && AuthHelper.checkAuthError(response)) {
        // AuthHelper đã tự động navigate đến login
        return response; // Response đã chứa thông tin lỗi auth
      }
      
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (response['isNetworkError'] == true) {
        return response;
      }
      
      return response;
    } catch (e) {
      // Log chi tiết lỗi API
      developer.log(
        'API Error: $endpoint',
        name: 'BaseApiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (NetworkUtils.isNetworkError(e)) {
        // Chỉ log, không hiển thị toast
      } else {
        AppToastHelper.showGlobalError(ErrorHandler.getErrorMessage(e));
      }
      
      return {
        'success': false,
        'message': ErrorHandler.getErrorMessage(e),
        'data': null,
        'error': e.toString(),
        'errorDetails': ErrorHandler.getErrorDetails(e),
        'endpoint': endpoint,
        'method': 'API',
      };
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final url = '${Config.baseUrl}$endpoint';
      final response = await AuthHttpClient.delete(
        url,
        includeAuth: includeAuth,
      );
      
      // Kiểm tra nếu response là HTML (thường là error page)
      if (response is String && response.toString().startsWith('<!doctype html>')) {
        return {
          'success': false,
          'message': 'API endpoint không tồn tại hoặc server lỗi',
          'data': null,
        };
      }
      
      // Tự động xử lý auth error cho tất cả request
      if (includeAuth && AuthHelper.checkAuthError(response)) {
        // AuthHelper đã tự động navigate đến login
        return response; // Response đã chứa thông tin lỗi auth
      }
      
      // Không hiển thị toast lỗi nếu là lỗi mạng
      if (response['isNetworkError'] == true) {
        return response;
      }
      
      return response;
    } catch (e) {
      // Log chi tiết lỗi API
      developer.log(
        'API Error: $endpoint',
        name: 'BaseApiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      
      return {
        'success': false,
        'message': ErrorHandler.getErrorMessage(e),
        'data': null,
        'error': e,
        'errorDetails': ErrorHandler.getErrorDetails(e),
        'endpoint': endpoint,
        'method': 'API',
      };
    }
  }
}
