import 'dart:io';
import 'package:gara/config.dart';
import 'package:gara/services/api/auth_http_client.dart';
import '../../utils/debug_logger.dart';
import 'push_notification_service.dart';

/// Service để quản lý FCM token và gửi lên server
class FcmTokenService {
  
  /// Lấy FCM token và gửi lên server
  static Future<String?> getAndRegisterFcmToken() async {
    try {
      DebugLogger.log('🔑 Getting FCM token for server registration...');
      
      final token = await PushNotificationService.getFcmTokenSafely();
      
      if (token != null) {
        DebugLogger.log('✅ FCM Token obtained successfully');
        
        // Gửi token lên server để lưu vào database
        await _sendTokenToServer(token);
        
        return token;
      } else {
        DebugLogger.log('❌ Failed to get FCM token');
        return null;
      }
    } catch (e) {
      DebugLogger.log('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Gửi FCM token lên server
  static Future<bool> _sendTokenToServer(String token) async {
    try {
      DebugLogger.log('📤 Sending FCM token to server...');
      final deviceType = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      final body = <String, dynamic>{
        'fcm_token': token,
        'device_type': deviceType,
      };
      // device_id optional: thêm nếu có thể lấy
      // body['device_id'] = await DeviceInfoHelper.getUniqueId(); // nếu có helper

      final response = await AuthHttpClient.post(
        Config.firebaseRegisterTokenUrl,
        body: body,
        includeAuth: true, // cần Bearer token
      );

      if (response['success'] == true) {
        DebugLogger.largeJson('✅ FCM token registered', response);
        return true;
      }
      DebugLogger.largeJson('❌ Register FCM token failed', response);
      return false;
    } catch (e) {
      DebugLogger.log('❌ Error sending FCM token to server: $e');
      return false;
    }
  }

  /// Refresh FCM token (khi token thay đổi)
  static Future<void> refreshFcmToken() async {
    try {
      DebugLogger.log('🔄 Refreshing FCM token...');
      
      final newToken = await PushNotificationService.getFcmTokenSafely();
      
      if (newToken != null) {
        DebugLogger.log('✅ New FCM token obtained');
        
        // Gửi token mới lên server
        await _sendTokenToServer(newToken);
      } else {
        DebugLogger.log('❌ Failed to refresh FCM token');
      }
    } catch (e) {
      DebugLogger.log('❌ Error refreshing FCM token: $e');
    }
  }
}
