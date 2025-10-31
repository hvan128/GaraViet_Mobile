import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gara/config.dart';
import 'package:gara/utils/debug_logger.dart';

class ForgotPasswordService {
  static Future<Map<String, dynamic>> sendOtp({required String phone}) async {
    final uri = Uri.parse('${Config.baseUrl}/auth/forgot-password');
    DebugLogger.log('ForgotPasswordService.sendOtp: POST $uri, phone=$phone');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'phone': phone}),
    );
    DebugLogger.log('ForgotPasswordService.sendOtp: status=${resp.statusCode}');
    if (resp.body.isNotEmpty) DebugLogger.log('ForgotPasswordService.sendOtp: body=${resp.body}');
    final ok = resp.statusCode >= 200 && resp.statusCode < 300;
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {}
    return {
      'success': ok,
      'statusCode': resp.statusCode,
      'data': parsed,
      'message': parsed?['message'] ?? (ok ? 'Gửi OTP thành công' : 'Gửi OTP thất bại'),
    };
  }

  static Future<Map<String, dynamic>> verifyOtp({required String phone, required String otp}) async {
    final uri = Uri.parse('${Config.baseUrl}/auth/verify-otp-reset-password');
    DebugLogger.log('ForgotPasswordService.verifyOtp: POST $uri, phone=$phone, otp=$otp');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    DebugLogger.log('ForgotPasswordService.verifyOtp: status=${resp.statusCode}');
    if (resp.body.isNotEmpty) DebugLogger.log('ForgotPasswordService.verifyOtp: body=${resp.body}');
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {}
    final ok = resp.statusCode >= 200 && resp.statusCode < 300;
    final resetToken = parsed?['data']?['reset_token'] as String?;
    return {
      'success': ok,
      'statusCode': resp.statusCode,
      'data': parsed,
      'reset_token': resetToken,
      'message': parsed?['message'] ?? (ok ? 'Xác thực OTP thành công' : 'Xác thực OTP thất bại'),
    };
  }

  static Future<Map<String, dynamic>> resetPassword({required String resetToken, required String newPassword}) async {
    final uri = Uri.parse('${Config.baseUrl}/auth/reset-password');
    DebugLogger.log('ForgotPasswordService.resetPassword: POST $uri');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reset_token': resetToken, 'new_password': newPassword}),
    );
    DebugLogger.log('ForgotPasswordService.resetPassword: status=${resp.statusCode}');
    if (resp.body.isNotEmpty) DebugLogger.log('ForgotPasswordService.resetPassword: body=${resp.body}');
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {}
    final ok = resp.statusCode >= 200 && resp.statusCode < 300;
    return {
      'success': ok,
      'statusCode': resp.statusCode,
      'data': parsed,
      'message': parsed?['message'] ?? (ok ? 'Đặt lại mật khẩu thành công' : 'Đặt lại mật khẩu thất bại'),
    };
  }
}
