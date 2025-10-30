import 'dart:io';
import 'package:gara/config.dart';
import 'package:gara/services/api/auth_http_client.dart';
import '../../utils/debug_logger.dart';
import 'push_notification_service.dart';

/// Service để quản lý FCM token và gửi lên server
class FcmTokenService {
  static String? _lastRegisteredToken;
  static DateTime? _lastRegisteredAt;

  /// Lấy FCM token và gửi lên server
  static Future<String?> getAndRegisterFcmToken() async {
    try {
      DebugLogger.log('🔑 Getting FCM token for server registration...');

      // Lấy FCM token trực tiếp (không retry để tránh block UI)
      final token = await PushNotificationService.getFcmTokenSafely();

      if (token != null && token.trim().isNotEmpty) {
        DebugLogger.log('✅ FCM Token obtained successfully');

        // Gửi token lên server để lưu vào database
        await _sendTokenToServer(token.trim());

        return token;
      } else {
        DebugLogger.log('❌ Failed to get FCM token - token is null/empty');
        return null;
      }
    } catch (e) {
      DebugLogger.log('❌ Error getting FCM token: $e');
      DebugLogger.log('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Gửi FCM token lên server
  static Future<bool> _sendTokenToServer(String token) async {
    try {
      final trimmed = token.trim();
      if (trimmed.isEmpty) {
        DebugLogger.log('🚫 Skip sending FCM token: empty string');
        return false;
      }

      // Debounce đăng ký trùng một token trong khoảng thời gian ngắn
      if (_lastRegisteredToken == trimmed && _lastRegisteredAt != null) {
        final diff = DateTime.now().difference(_lastRegisteredAt!);
        if (diff.inMinutes < 5) {
          DebugLogger.log('⏱️ Skip duplicate FCM token registration within 5 minutes');
          return true;
        }
      }

      DebugLogger.log('📤 Sending FCM token to server...');
      final deviceType = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      final body = <String, dynamic>{'fcm_token': trimmed, 'device_type': deviceType};
      // device_id optional: thêm nếu có thể lấy
      // body['device_id'] = await DeviceInfoHelper.getUniqueId(); // nếu có helper

      final response = await AuthHttpClient.post(
        Config.firebaseRegisterTokenUrl,
        body: body,
        includeAuth: true, // cần Bearer token
      );

      if (response['success'] == true) {
        DebugLogger.largeJson('✅ FCM token registered', response);
        _lastRegisteredToken = trimmed;
        _lastRegisteredAt = DateTime.now();
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
  static Future<void> refreshFcmToken({String? newToken}) async {
    try {
      DebugLogger.log('🔄 Refreshing FCM token...');

      final tokenToUse =
          (newToken != null && newToken.trim().isNotEmpty)
              ? newToken.trim()
              : await PushNotificationService.getFcmTokenSafely();

      if (tokenToUse != null && tokenToUse.trim().isNotEmpty) {
        DebugLogger.log('✅ New FCM token obtained');

        // Gửi token mới lên server
        await _sendTokenToServer(tokenToUse.trim());
      } else {
        DebugLogger.log('❌ Failed to refresh FCM token');
      }
    } catch (e) {
      DebugLogger.log('❌ Error refreshing FCM token: $e');
    }
  }
}
