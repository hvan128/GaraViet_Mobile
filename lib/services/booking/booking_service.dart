import 'package:gara/config.dart';
import 'package:gara/models/booking/booking_model.dart';
import 'package:gara/services/api/base_api_service.dart';
import 'package:gara/utils/debug_logger.dart';

class BookingServiceApi {
  static Future<BookingListResponse> getGarageBookedQuotations({
    int page = 1,
    int perPage = 10,
    String? statusCsv,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final res = await BaseApiService.get(
      Config.bookingGarageBookedQuotationsUrl.replaceFirst(Config.baseUrl, ''),
      queryParams: {
        'page': '$page',
        'per_page': '$perPage',
        if (statusCsv != null && statusCsv.isNotEmpty) 'status': statusCsv,
        if (fromDate != null) 'from_date': fromDate.toIso8601String(),
        if (toDate != null) 'to_date': toDate.toIso8601String(),
      },
    );
    DebugLogger.largeJson('res', res);
    return BookingListResponse.fromJson(res);
  }

  static Future<BookingListResponse> getUserBookedServices({
    int page = 1,
    int perPage = 10,
    String? statusCsv,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final res = await BaseApiService.get(
      Config.bookingUserBookedServicesUrl.replaceFirst(Config.baseUrl, ''),
      queryParams: {
        'page': '$page',
        'per_page': '$perPage',
        if (statusCsv != null && statusCsv.isNotEmpty) 'status': statusCsv,
        if (fromDate != null) 'from_date': fromDate.toIso8601String(),
        if (toDate != null) 'to_date': toDate.toIso8601String(),
      },
    );
    DebugLogger.largeJson('res', res);
    return BookingListResponse.fromJson(res);
  }

  static Future<Map<String, dynamic>> completeOrder({
    required int quotationId,
  }) async {
    final res = await BaseApiService.post(
      Config.bookingCompleteOrderUrl.replaceFirst(Config.baseUrl, ''),
      body: {
        'quotation_id': quotationId,
      },
    );
    DebugLogger.largeJson('completeOrder', res);
    return res;
  }

  static Future<Map<String, dynamic>> cancelOrder({
    required int quotationId,
  }) async {
    final res = await BaseApiService.post(
      Config.bookingCancelOrderUrl.replaceFirst(Config.baseUrl, ''),
      body: {
        'quotation_id': quotationId,
      },
    );
    DebugLogger.largeJson('cancelOrder', res);
    return res;
  }

  static Future<Map<String, dynamic>> calculateGarageOrdersPrice({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final res = await BaseApiService.get(
      Config.bookingCalculateGarageOrdersPriceUrl
          .replaceFirst(Config.baseUrl, ''),
      queryParams: {
        'from_date': fromDate.toIso8601String(),
        'to_date': toDate.toIso8601String(),
      },
    );
    DebugLogger.largeJson('calculateGarageOrdersPrice', res);
    return res;
  }
}


