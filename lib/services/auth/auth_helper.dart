import 'package:flutter/material.dart';
import 'package:gara/navigation/navigation.dart';
import 'package:gara/services/storage_service.dart';

class AuthHelper {
  // Kiểm tra response có yêu cầu đăng nhập lại không
  static bool requiresLogin(Map<String, dynamic> response) {
    return response['requiresLogin'] == true || 
           (response['statusCode'] == 401 && !response['success']);
  }

  // Xử lý khi cần đăng nhập lại
  static void handleLoginRequired(BuildContext context, {String? message}) {
    // Xóa tất cả token
    Storage.removeAllToken();
    
    // Hiển thị thông báo
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // Chuyển về màn hình đăng nhập
    Navigate.pushNamed('/login');
  }

  // Kiểm tra và xử lý response với context
  static bool checkAndHandleAuthError(BuildContext context, Map<String, dynamic> response) {
    if (requiresLogin(response)) {
      handleLoginRequired(
        context, 
        message: response['message'] ?? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
      );
      return true;
    }
    return false;
  }

  // Kiểm tra và xử lý response không có context (cho các service)
  static bool checkAuthError(Map<String, dynamic> response) {
    if (requiresLogin(response)) {
      // Hiển thị thông báo trước khi navigate
      _showLogoutNotification(response);
      
      // Navigate đến login screen
      Navigate.pushNamedAndRemoveAll('/login');
      return true;
    }
    return false;
  }

  // Hiển thị thông báo logout
  static void _showLogoutNotification(Map<String, dynamic> response) {
    try {
      // Lấy context từ navigation key
      final context = Navigate().navigationKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Lỗi khi hiển thị thông báo: $e');
    }
  }
}
