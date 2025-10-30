import 'package:gara/config.dart';
import 'package:gara/models/payment/payment_model.dart';
import 'package:gara/services/api/auth_http_client.dart';
import 'package:gara/utils/debug_logger.dart';

class PaymentService {
  // Tạo mã QR thanh toán cho báo giá
  static Future<Map<String, dynamic>> createQrPayment({
    required int quotationId,
    required int deposit,
    int expiresMinutes = 30,
  }) async {
    try {
      final response = await AuthHttpClient.post(
        Config.paymentCreateQrUrl,
        body: {
          'quotation_id': quotationId,
          'deposit': deposit,
          'expires_minutes': expiresMinutes,
        },
      );

      DebugLogger.largeJson('[PaymentService.createQrPayment] response', response);

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(response['data']),
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Tạo mã QR thất bại',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi tạo mã QR: $e',
        'data': null,
      };
    }
  }

  // Tạo mã QR thanh toán phí nền tảng
  static Future<Map<String, dynamic>> createPlatformFeeQr({
    required int month,
    required int year,
    int expiresMinutes = 30,
  }) async {
    try {
      final response = await AuthHttpClient.post(
        Config.paymentCreatePlatformFeeQrUrl,
        body: {
          'month': month,
          'year': year,
          'expires_minutes': expiresMinutes,
        },
      );

      DebugLogger.largeJson('[PaymentService.createPlatformFeeQr] response', response['data']['transaction_id']);

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(response['data']),
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Tạo mã QR phí nền tảng thất bại',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi tạo QR phí nền tảng: $e',
        'data': null,
      };
    }
  }

  // Long polling kiểm tra thanh toán phí nền tảng
  static Future<Map<String, dynamic>> pollPlatformFeePayment({
    required String transactionId,
    int timeout = 30,
    int pollInterval = 2,
  }) async {
    try {
      final response = await AuthHttpClient.get(
        Config.paymentPollingPlatformFeeUrl,
        queryParams: {
          'transaction_id': transactionId,
          'timeout': timeout.toString(),
          'poll_interval': pollInterval.toString(),
        },
      );

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(response['data']),
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Kiểm tra trạng thái phí nền tảng thất bại',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi kiểm tra phí nền tảng: $e',
        'data': null,
      };
    }
  }

  // Long polling kiểm tra trạng thái thanh toán
  static Future<Map<String, dynamic>> pollPaymentStatus({
    required String transactionId,
    int timeout = 30,
    int pollInterval = 2,
  }) async {
    try {
      final response = await AuthHttpClient.get(
        Config.paymentPollingUrl,
        queryParams: {
          'transaction_id': transactionId,
          'timeout': timeout.toString(),
          'poll_interval': pollInterval.toString(),
        },
      );

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(response['data']),
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Kiểm tra trạng thái thất bại',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi kiểm tra trạng thái: $e',
        'data': null,
      };
    }
  }

  // Cập nhật trạng thái thanh toán thủ công
  static Future<Map<String, dynamic>> manualUpdatePaymentStatus({
    required String transactionId,
  }) async {
    try {
      final url = '${Config.paymentManualUpdateStatusUrl}?transaction_id=$transactionId';
      final response = await AuthHttpClient.post(url);

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(response['data']),
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Cập nhật trạng thái thất bại',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi cập nhật trạng thái: $e',
        'data': null,
      };
    }
  }

  // Kiểm tra trạng thái thanh toán theo transaction_id
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String transactionId,
  }) async {
    try {
      final url = '${Config.paymentCheckStatusUrl}?transaction_id=$transactionId';
      final response = await AuthHttpClient.get(url);

      if (response['success'] && response['data'] != null) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(response['data']),
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Kiểm tra trạng thái thất bại',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi kiểm tra trạng thái: $e',
        'data': null,
      };
    }
  }
}
