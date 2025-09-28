import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
 
class ErrorHandler {
  // Debug mode - set to true để hiển thị thông tin lỗi chi tiết
  static bool debugMode = true;
  
  // Xử lý lỗi và trả về thông báo thân thiện với user
  static String getErrorMessage(dynamic error) {
    // Log lỗi chi tiết cho developer
    _logError(error);
    
    // Tạo mã lỗi duy nhất
    final errorCode = _generateErrorCode(error);
    if (error is SocketException) {
      final message = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
      return debugMode ? '$message [ERR-$errorCode]' : message;
    }
    
    if (error is HttpException) {
      final message = 'Lỗi kết nối mạng. Vui lòng thử lại sau.';
      return debugMode ? '$message [ERR-$errorCode]' : message;
    }
    
    if (error is FormatException) {
      final message = 'Dữ liệu không hợp lệ. Vui lòng thử lại.';
      return debugMode ? '$message [ERR-$errorCode]' : message;
    }
    
    if (error is TimeoutException) {
      final message = 'Kết nối quá thời gian. Vui lòng thử lại.';
      return debugMode ? '$message [ERR-$errorCode]' : message;
    }
    
    // Xử lý các lỗi API response
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message != null) {
        final friendlyMessage = _getFriendlyMessage(message.toString());
        return debugMode ? '$friendlyMessage [ERR-$errorCode]' : friendlyMessage;
      }
    }
    
    // Xử lý lỗi từ string
    if (error is String) {
      final friendlyMessage = _getFriendlyMessage(error);
      return debugMode ? '$friendlyMessage [ERR-$errorCode]' : friendlyMessage;
    }
    
    // Lỗi mặc định
    final defaultMessage = 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
    return debugMode ? '$defaultMessage [ERR-$errorCode]' : defaultMessage;
  }
  
  // Chuyển đổi thông báo lỗi kỹ thuật thành thông báo thân thiện
  static String _getFriendlyMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Lỗi kết nối
    if (lowerMessage.contains('connection') || 
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('socket') ||
        lowerMessage.contains('network')) {
      return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
    }
    
    // Lỗi xác thực
    if (lowerMessage.contains('unauthorized') || 
        lowerMessage.contains('forbidden') ||
        lowerMessage.contains('token')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    
    // Lỗi server
    if (lowerMessage.contains('server error') || 
        lowerMessage.contains('internal error') ||
        lowerMessage.contains('500')) {
      return 'Server đang gặp sự cố. Vui lòng thử lại sau.';
    }
    
    // Lỗi không tìm thấy
    if (lowerMessage.contains('not found') || 
        lowerMessage.contains('404')) {
      return 'Không tìm thấy dữ liệu yêu cầu.';
    }
    
    // Lỗi validation
    if (lowerMessage.contains('validation') || 
        lowerMessage.contains('invalid') ||
        lowerMessage.contains('payload')) {
      return 'Thông tin không hợp lệ. Vui lòng kiểm tra lại.';
    }
    
    // Lỗi OTP
    if (lowerMessage.contains('otp') || 
        lowerMessage.contains('verification')) {
      return 'Mã xác thực không đúng hoặc đã hết hạn.';
    }
    
    // Trả về message gốc nếu không match với pattern nào
    return message;
  }
  
  // Kiểm tra xem có phải lỗi kết nối không
  static bool isConnectionError(dynamic error) {
    if (error is SocketException || 
        error is TimeoutException || 
        error is HttpException) {
      return true;
    }
    
    if (error is String) {
      final lowerError = error.toLowerCase();
      return lowerError.contains('connection') || 
             lowerError.contains('timeout') ||
             lowerError.contains('socket') ||
             lowerError.contains('network');
    }
    
    return false;
  }
  
  // Kiểm tra xem có phải lỗi xác thực không
  static bool isAuthError(dynamic error) {
    if (error is Map<String, dynamic>) {
      final message = error['message']?.toString().toLowerCase() ?? '';
      return message.contains('unauthorized') || 
             message.contains('forbidden') ||
             message.contains('token');
    }
    
    if (error is String) {
      final lowerError = error.toLowerCase();
      return lowerError.contains('unauthorized') || 
             lowerError.contains('forbidden') ||
             lowerError.contains('token');
    }
    
    return false;
  }
  
  // Log lỗi chi tiết cho developer
  static void _logError(dynamic error) {
    final timestamp = DateTime.now().toIso8601String();
    final errorType = error.runtimeType.toString();
    
    developer.log(
      'ERROR [$timestamp]',
      name: 'ErrorHandler',
      error: error,
      stackTrace: StackTrace.current,
    );
    
    // Log thêm thông tin chi tiết
    if (error is Map<String, dynamic>) {
      developer.log(
        'API Error Details: $error',
        name: 'ErrorHandler',
      );
    } else if (error is SocketException) {
      developer.log(
        'Socket Error: ${error.message}, Address: ${error.address}, Port: ${error.port}',
        name: 'ErrorHandler',
      );
    } else if (error is TimeoutException) {
      developer.log(
        'Timeout Error: ${error.message}',
        name: 'ErrorHandler',
      );
    } else {
      developer.log(
        'Error Type: $errorType, Message: ${error.toString()}',
        name: 'ErrorHandler',
      );
    }
  }
  
  // Tạo mã lỗi duy nhất
  static String _generateErrorCode(dynamic error) {
    final errorType = error.runtimeType.toString();
    final hashCode = error.hashCode.abs();
    
    // Tạo mã lỗi ngắn gọn
    final shortType = errorType.length > 10 ? errorType.substring(0, 10) : errorType;
    return '${shortType.toUpperCase()}-${hashCode.toString().substring(0, 4)}';
  }
  
  // Method để developer có thể bật/tắt debug mode
  static void setDebugMode(bool enabled) {
    debugMode = enabled;
    developer.log(
      'Debug mode ${enabled ? 'enabled' : 'disabled'}',
      name: 'ErrorHandler',
    );
  }
  
  // Method để lấy thông tin lỗi chi tiết cho debug
  static Map<String, dynamic> getErrorDetails(dynamic error) {
    return {
      'type': error.runtimeType.toString(),
      'message': error.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'code': _generateErrorCode(error),
      'isConnectionError': isConnectionError(error),
      'isAuthError': isAuthError(error),
    };
  }
}
