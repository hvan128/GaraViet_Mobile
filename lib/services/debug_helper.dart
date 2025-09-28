import 'dart:developer' as developer;
import 'package:gara/services/error_handler.dart';

class DebugHelper {
  // Hiển thị thông tin debug trong console
  static void logApiCall(String method, String endpoint, {Map<String, dynamic>? body}) {
    if (ErrorHandler.debugMode) {
      developer.log(
        'API Call: $method $endpoint',
        name: 'DebugHelper',
      );
      
      if (body != null) {
        developer.log(
          'Request Body: $body',
          name: 'DebugHelper',
        );
      }
    }
  }
  
  // Hiển thị response API
  static void logApiResponse(String endpoint, Map<String, dynamic> response) {
    if (ErrorHandler.debugMode) {
      developer.log(
        'API Response: $endpoint',
        name: 'DebugHelper',
      );
      
      developer.log(
        'Response Data: $response',
        name: 'DebugHelper',
      );
    }
  }
  
  // Hiển thị thông tin lỗi chi tiết
  static void logError(String context, dynamic error) {
    if (ErrorHandler.debugMode && error != null) {
      developer.log(
        'Error in $context',
        name: 'DebugHelper',
        error: error,
        stackTrace: StackTrace.current,
      );
      
      try {
        final errorDetails = ErrorHandler.getErrorDetails(error);
        developer.log(
          'Error Details: $errorDetails',
          name: 'DebugHelper',
        );
      } catch (e) {
        developer.log(
          'Error getting error details: $e',
          name: 'DebugHelper',
        );
      }
    }
  }
  
  // Hiển thị thông tin state
  static void logState(String context, Map<String, dynamic> state) {
    if (ErrorHandler.debugMode) {
      developer.log(
        'State in $context: $state',
        name: 'DebugHelper',
      );
    }
  }
  
  // Hiển thị thông tin user action
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    if (ErrorHandler.debugMode) {
      developer.log(
        'User Action: $action',
        name: 'DebugHelper',
      );
      
      if (data != null) {
        developer.log(
          'Action Data: $data',
          name: 'DebugHelper',
        );
      }
    }
  }
  
  // Bật/tắt debug mode
  static void toggleDebugMode() {
    ErrorHandler.setDebugMode(!ErrorHandler.debugMode);
    developer.log(
      'Debug mode toggled: ${ErrorHandler.debugMode ? 'ON' : 'OFF'}',
      name: 'DebugHelper',
    );
  }
  
  // Hiển thị thông tin debug trong UI (chỉ khi debug mode)
  static String getDebugInfo(dynamic error) {
    if (!ErrorHandler.debugMode) return '';
    
    final details = ErrorHandler.getErrorDetails(error);
    return '''
Debug Info:
- Type: ${details['type']}
- Code: ${details['code']}
- Time: ${details['timestamp']}
- Connection Error: ${details['isConnectionError']}
- Auth Error: ${details['isAuthError']}
''';
  }
}
