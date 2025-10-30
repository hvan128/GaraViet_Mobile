import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:gara/widgets/app_toast.dart';
import 'package:gara/utils/debug_logger.dart';

class PhoneService {
  /// Gọi điện thoại với số điện thoại được cung cấp
  static Future<void> makePhoneCall(String phoneNumber, BuildContext context) async {
    if (phoneNumber.isEmpty) {
      AppToastHelper.showError(context, message: 'Số điện thoại không hợp lệ');
      return;
    }

    // Làm sạch số điện thoại (loại bỏ khoảng trắng, dấu gạch ngang, v.v.)
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    DebugLogger.largeJson('[PhoneService.makePhoneCall]', {
      'originalPhone': phoneNumber,
      'cleanPhone': cleanPhoneNumber,
    });

    try {
      // Tạo URI với scheme tel: và path
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhoneNumber);

      DebugLogger.largeJson('[PhoneService.makePhoneCall] URI created', {
        'uri': phoneUri.toString(),
        'scheme': phoneUri.scheme,
        'path': phoneUri.path,
      });

      // Kiểm tra xem có thể launch không
      final canLaunch = await canLaunchUrl(phoneUri);
      DebugLogger.largeJson('[PhoneService.makePhoneCall] canLaunch check', {'canLaunch': canLaunch});

      if (canLaunch) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        DebugLogger.largeJson('[PhoneService.makePhoneCall] launchUrl successful', {});
      } else {
        throw Exception('Cannot launch tel: URL');
      }
    } catch (e) {
      DebugLogger.largeJson('[PhoneService.makePhoneCall] primary method failed', {'error': e.toString()});

      // Fallback: thử với Uri.parse nếu cách trên không hoạt động
      try {
        final Uri fallbackUri = Uri.parse('tel:$cleanPhoneNumber');
        DebugLogger.largeJson('[PhoneService.makePhoneCall] trying fallback', {'fallbackUri': fallbackUri.toString()});

        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        DebugLogger.largeJson('[PhoneService.makePhoneCall] fallback successful', {});

        // Hiển thị thông báo thành công
        AppToastHelper.showSuccess(context, message: 'Đang mở ứng dụng gọi điện...');
      } catch (fallbackError) {
        DebugLogger.largeJson('[PhoneService.makePhoneCall] fallback failed', {
          'fallbackError': fallbackError.toString(),
        });

        // Thử telprompt: scheme (iOS specific)
        try {
          final Uri telpromptUri = Uri.parse('telprompt:$cleanPhoneNumber');
          DebugLogger.largeJson('[PhoneService.makePhoneCall] trying telprompt', {
            'telpromptUri': telpromptUri.toString(),
          });

          await launchUrl(telpromptUri, mode: LaunchMode.externalApplication);
          DebugLogger.largeJson('[PhoneService.makePhoneCall] telprompt successful', {});

          AppToastHelper.showSuccess(context, message: 'Đang mở ứng dụng gọi điện...');
        } catch (telpromptError) {
          DebugLogger.largeJson('[PhoneService.makePhoneCall] telprompt failed', {
            'telpromptError': telpromptError.toString(),
          });

          AppToastHelper.showError(
            context,
            message: 'Không thể mở ứng dụng gọi điện. Vui lòng kiểm tra ứng dụng điện thoại.',
          );
        }
      }
    }
  }

  /// Gửi tin nhắn SMS với số điện thoại được cung cấp
  static Future<void> sendSMS(String phoneNumber, BuildContext context, {String? message}) async {
    if (phoneNumber.isEmpty) {
      AppToastHelper.showError(context, message: 'Số điện thoại không hợp lệ');
      return;
    }

    // Làm sạch số điện thoại
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Tạo URL SMS
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhoneNumber,
      query: message != null ? 'body=${Uri.encodeComponent(message)}' : null,
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        AppToastHelper.showError(context, message: 'Không thể mở ứng dụng tin nhắn');
      }
    } catch (e) {
      AppToastHelper.showError(context, message: 'Lỗi khi gửi tin nhắn: ${e.toString()}');
    }
  }

  /// Mở ứng dụng email với địa chỉ email được cung cấp
  static Future<void> sendEmail(String email, BuildContext context, {String? subject, String? body}) async {
    if (email.isEmpty) {
      AppToastHelper.showError(context, message: 'Địa chỉ email không hợp lệ');
      return;
    }

    final Uri emailUri = Uri(scheme: 'mailto', path: email, query: _buildEmailQuery(subject, body));

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        AppToastHelper.showError(context, message: 'Không thể mở ứng dụng email');
      }
    } catch (e) {
      AppToastHelper.showError(context, message: 'Lỗi khi gửi email: ${e.toString()}');
    }
  }

  /// Xây dựng query string cho email
  static String? _buildEmailQuery(String? subject, String? body) {
    final List<String> queryParts = [];

    if (subject != null && subject.isNotEmpty) {
      queryParts.add('subject=${Uri.encodeComponent(subject)}');
    }

    if (body != null && body.isNotEmpty) {
      queryParts.add('body=${Uri.encodeComponent(body)}');
    }

    return queryParts.isNotEmpty ? queryParts.join('&') : null;
  }
}
