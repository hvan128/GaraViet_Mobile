import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gara/config.dart';
import 'package:gara/services/storage_service.dart';
import 'package:gara/services/auth/token_cache.dart';
import 'package:gara/utils/debug_logger.dart';

class ChangePasswordResult {
  final bool success;
  final String? message;
  const ChangePasswordResult({required this.success, this.message});
}

class ChangePasswordService {
  static Future<ChangePasswordResult> changePassword({required String oldPassword, required String newPassword}) async {
    final tokenFromCache = TokenCache.getAccessToken();
    final tokenFromStorage = await Storage.getAccessToken();
    final accessToken = tokenFromCache ?? tokenFromStorage;
    if (accessToken == null) {
      DebugLogger.log('ChangePasswordService: missing access token');
      return const ChangePasswordResult(success: false, message: 'Không tìm thấy access token');
    }

    final uri = Uri.parse(Config.userChangePasswordUrl);
    DebugLogger.log('ChangePasswordService: PUT $uri');
    final resp = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    DebugLogger.log('ChangePasswordService: status=${resp.statusCode}');
    if (resp.body.isNotEmpty) {
      // Không log mật khẩu; chỉ log raw body trả về từ server để debug
      DebugLogger.log('ChangePasswordService: responseBody=${resp.body}');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      DebugLogger.log('ChangePasswordService: password changed successfully');
      return const ChangePasswordResult(success: true, message: 'Đổi mật khẩu thành công');
    }

    // Cố gắng lấy message từ body nếu có
    String? message;
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map) {
        if (decoded['message'] is String)
          message = decoded['message'] as String;
        else if (decoded['error'] is String)
          message = decoded['error'] as String;
        else if (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
          final first = (decoded['errors'] as List).first;
          if (first is String) message = first;
          if (first is Map && first['message'] is String) message = first['message'] as String;
        }
      }
    } catch (_) {}

    message ??= resp.statusCode == 400
        ? 'Mật khẩu cũ không đúng hoặc dữ liệu không hợp lệ'
        : (resp.statusCode == 401
            ? 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại'
            : 'Đổi mật khẩu thất bại (mã ${resp.statusCode})');

    return ChangePasswordResult(success: false, message: message);
  }
}
